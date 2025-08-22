-- Fix verify_otp function to resolve ambiguous column reference
-- Run this migration to fix the OTP verification error

-- Drop and recreate the verify_otp function with correct column names
DROP FUNCTION IF EXISTS verify_otp(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;

-- Function to verify OTP
CREATE OR REPLACE FUNCTION verify_otp(
    p_user_id UUID DEFAULT NULL,
    p_phone_number VARCHAR(20) DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_otp_code VARCHAR(6) DEFAULT NULL,
    p_otp_type VARCHAR(20) DEFAULT 'whatsapp'
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    phone_verified BOOLEAN,
    verification_otp_id UUID
) AS $$
DECLARE
    v_otp_record RECORD;
    v_attempts INTEGER;
BEGIN
    -- Validate required parameters
    IF (p_phone_number IS NULL AND p_email IS NULL) OR p_otp_code IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Phone number/email and OTP code are required', FALSE, NULL::UUID;
        RETURN;
    END IF;
    
    -- Find the OTP record
    SELECT * INTO v_otp_record
    FROM public.otp_verifications
    WHERE (phone_number = p_phone_number OR email = p_email)
      AND otp_code = p_otp_code
      AND otp_type = p_otp_type
      AND expires_at > NOW()
      AND NOT verified
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Check if OTP exists
    IF v_otp_record IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Invalid or expired OTP', FALSE, NULL::UUID;
        RETURN;
    END IF;
    
    -- Check attempts
    v_attempts := v_otp_record.attempts + 1;
    
    IF v_attempts >= v_otp_record.max_attempts THEN
        -- Mark as failed after max attempts
        UPDATE public.otp_verifications
        SET attempts = v_attempts,
            verified = FALSE
        WHERE otp_id = v_otp_record.otp_id;
        
        RETURN QUERY SELECT FALSE, 'Too many failed attempts. Please request a new OTP.', FALSE, v_otp_record.otp_id;
        RETURN;
    END IF;
    
    -- Mark as verified
    UPDATE public.otp_verifications
    SET verified = TRUE,
        attempts = v_attempts,
        verified_at = NOW(),
        updated_at = NOW()
    WHERE otp_id = v_otp_record.otp_id;
    
    -- Update user profile if user_id is provided and it's a phone verification
    IF p_user_id IS NOT NULL AND p_phone_number IS NOT NULL AND p_otp_type = 'whatsapp' THEN
        UPDATE public.profiles
        SET phone = p_phone_number,
            phone_verified = TRUE,
            phone_verified_at = NOW(),
            whatsapp_enabled = TRUE,
            auth_provider = CASE 
                WHEN auth_provider = 'email' THEN 'both'
                ELSE auth_provider
            END,
            updated_at = NOW()
        WHERE id = p_user_id;
    END IF;
    
    -- Return success with phone_verified status
    RETURN QUERY SELECT TRUE, 'OTP verified successfully', 
        CASE WHEN p_user_id IS NOT NULL AND p_phone_number IS NOT NULL AND p_otp_type = 'whatsapp' THEN TRUE ELSE FALSE END, 
        v_otp_record.otp_id;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION verify_otp(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO anon, authenticated, service_role;

-- Verify the function was created successfully
SELECT 'verify_otp function fixed successfully' as status;
