-- Fix WhatsApp functions to use correct column names
-- This migration updates all functions to use otp_id instead of id for otp_verifications table

-- Drop existing functions first to avoid return type conflicts
DROP FUNCTION IF EXISTS create_otp_verification(UUID, VARCHAR, VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS verify_otp(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS create_auth_token(UUID, VARCHAR, INTEGER, JSONB, INET, TEXT) CASCADE;
DROP FUNCTION IF EXISTS log_whatsapp_message(VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT) CASCADE;

-- Function to create OTP verification record
CREATE OR REPLACE FUNCTION create_otp_verification(
    p_user_id UUID DEFAULT NULL,
    p_phone_number VARCHAR(20) DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_otp_type VARCHAR(20) DEFAULT 'whatsapp',
    p_expires_in_minutes INTEGER DEFAULT 5
)
RETURNS TABLE(
    verification_id UUID,
    otp_code VARCHAR(6),
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_otp VARCHAR(6);
    v_expires_at TIMESTAMP WITH TIME ZONE;
    v_otp_id UUID;
BEGIN
    -- Validate required parameters
    IF p_phone_number IS NULL AND p_email IS NULL THEN
        RAISE EXCEPTION 'Either phone number or email is required';
    END IF;
    
    -- Generate OTP
    v_otp := generate_otp();
    v_expires_at := NOW() + (p_expires_in_minutes || ' minutes')::INTERVAL;
    
    -- Insert OTP verification record
    INSERT INTO public.otp_verifications (
        user_id,
        phone_number,
        email,
        otp_code,
        otp_type,
        expires_at
    ) VALUES (
        p_user_id,
        p_phone_number,
        p_email,
        v_otp,
        p_otp_type,
        v_expires_at
    ) RETURNING otp_id INTO v_otp_id;
    
    -- Return the verification details
    RETURN QUERY SELECT v_otp_id, v_otp, v_expires_at;
END;
$$ LANGUAGE plpgsql;

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
        SET 
            phone_verified = TRUE,
            phone_verified_at = NOW(),
            phone = p_phone_number,
            whatsapp_enabled = TRUE,
            auth_provider = CASE 
                WHEN auth_provider = 'email' THEN 'both'
                ELSE auth_provider
            END,
            updated_at = NOW()
        WHERE id = p_user_id;
    END IF;
    
    RETURN QUERY SELECT TRUE, 'OTP verified successfully', TRUE, v_otp_record.otp_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create auth token
CREATE OR REPLACE FUNCTION create_auth_token(
    p_user_id UUID,
    p_token_type VARCHAR(20) DEFAULT 'access',
    p_expires_in_hours INTEGER DEFAULT 24,
    p_device_info JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS TABLE(
    token_id UUID,
    token_hash VARCHAR(255),
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_token_hash VARCHAR(255);
    v_expires_at TIMESTAMP WITH TIME ZONE;
    v_token_id UUID;
BEGIN
    -- Generate secure token hash
    v_token_hash := generate_secure_token();
    v_expires_at := NOW() + (p_expires_in_hours || ' hours')::INTERVAL;
    
    -- Insert token record
    INSERT INTO public.auth_tokens (
        user_id,
        token_type,
        token_hash,
        expires_at,
        device_info,
        ip_address,
        user_agent
    ) VALUES (
        p_user_id,
        p_token_type,
        v_token_hash,
        v_expires_at,
        p_device_info,
        p_ip_address,
        p_user_agent
    ) RETURNING token_id INTO v_token_id;
    
    -- Return token details
    RETURN QUERY SELECT v_token_id, v_token_hash, v_expires_at;
END;
$$ LANGUAGE plpgsql;

-- Function to log WhatsApp message
CREATE OR REPLACE FUNCTION log_whatsapp_message(
    p_phone_number VARCHAR(20),
    p_message_type VARCHAR(50),
    p_message_id VARCHAR(255) DEFAULT NULL,
    p_status VARCHAR(50) DEFAULT 'sent',
    p_error_message TEXT DEFAULT NULL
)
RETURNS TABLE(
    log_id UUID,
    message_id VARCHAR(255)
) AS $$
DECLARE
    v_log_id UUID;
BEGIN
    -- Insert log record
    INSERT INTO public.whatsapp_message_logs (
        phone_number,
        message_type,
        message_id,
        status,
        error_message
    ) VALUES (
        p_phone_number,
        p_message_type,
        p_message_id,
        p_status,
        p_error_message
    ) RETURNING log_id INTO v_log_id;
    
    -- Return log details
    RETURN QUERY SELECT v_log_id, p_message_id;
END;
$$ LANGUAGE plpgsql;
