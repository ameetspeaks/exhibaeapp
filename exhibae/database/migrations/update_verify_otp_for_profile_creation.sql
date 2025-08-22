-- Update verify_otp function to return user ID and handle profile creation
-- This ensures profiles are created immediately after OTP verification

-- First, add the is_temp_profile column to profiles table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' 
                   AND column_name = 'is_temp_profile') THEN
        ALTER TABLE public.profiles 
        ADD COLUMN is_temp_profile BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Drop the existing verify_otp function first (to allow return type change)
DROP FUNCTION IF EXISTS verify_otp(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR);

-- Create the updated verify_otp function with new return type
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
    verification_otp_id UUID,
    user_id UUID
) AS $$
DECLARE
    v_otp_record RECORD;
    v_attempts INTEGER;
    v_existing_user_id UUID;
    v_new_user_id UUID;
    v_temp_email VARCHAR(255);
    v_temp_password VARCHAR(255);
BEGIN
    -- Validate required parameters
    IF (p_phone_number IS NULL AND p_email IS NULL) OR p_otp_code IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Phone number/email and OTP code are required', FALSE, NULL::UUID, NULL::UUID;
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
        RETURN QUERY SELECT FALSE, 'Invalid or expired OTP', FALSE, NULL::UUID, NULL::UUID;
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
        
        RETURN QUERY SELECT FALSE, 'Too many failed attempts. Please request a new OTP.', FALSE, v_otp_record.otp_id, NULL::UUID;
        RETURN;
    END IF;
    
    -- Mark as verified
    UPDATE public.otp_verifications
    SET verified = TRUE,
        attempts = v_attempts,
        verified_at = NOW(),
        updated_at = NOW()
    WHERE otp_id = v_otp_record.otp_id;
    
    -- For WhatsApp authentication, handle phone verification and profile creation
    IF p_phone_number IS NOT NULL AND (p_otp_type = 'whatsapp' OR p_otp_type = 'whatsapp_login' OR p_otp_type = 'registration') THEN
        -- Find existing user with this phone number
        SELECT id INTO v_existing_user_id
        FROM public.profiles
        WHERE phone = p_phone_number;
        
        -- If user exists, update their phone verification status
        IF v_existing_user_id IS NOT NULL THEN
            UPDATE public.profiles
            SET phone_verified = TRUE,
                phone_verified_at = NOW(),
                whatsapp_enabled = TRUE,
                auth_provider = CASE 
                    WHEN auth_provider = 'email' THEN 'both'
                    ELSE 'whatsapp'
                END,
                updated_at = NOW()
            WHERE id = v_existing_user_id;
            
            -- Return success with phone verified and existing user ID
            RETURN QUERY SELECT TRUE, 'OTP verified successfully', TRUE, v_otp_record.otp_id, v_existing_user_id;
            RETURN;
        ELSE
            -- No existing user found - create a new user and profile
            -- Generate temporary credentials for Supabase auth
            v_temp_email := p_phone_number || '@whatsapp.exhibae.com';
            v_temp_password := 'whatsapp_' || p_phone_number;
            
            -- Create user in auth.users (this will be handled by the Flutter app)
            -- For now, we'll create a profile entry that will be linked later
            v_new_user_id := gen_random_uuid();
            
            -- Create a temporary profile entry
            INSERT INTO public.profiles (
                id,
                phone,
                phone_verified,
                phone_verified_at,
                whatsapp_enabled,
                auth_provider,
                role,
                full_name,
                is_temp_profile,
                created_at,
                updated_at
            ) VALUES (
                v_new_user_id,
                p_phone_number,
                TRUE,
                NOW(),
                TRUE,
                'whatsapp',
                'shopper',
                'User_' || REPLACE(REPLACE(REPLACE(p_phone_number, '+', ''), '-', ''), ' ', ''),
                TRUE,
                NOW(),
                NOW()
            );
            
            -- Return success with new user ID
            RETURN QUERY SELECT TRUE, 'OTP verified successfully. New user created.', TRUE, v_otp_record.otp_id, v_new_user_id;
            RETURN;
        END IF;
    END IF;
    
    -- For other verification types or if no phone number
    RETURN QUERY SELECT TRUE, 'OTP verified successfully', FALSE, v_otp_record.otp_id, NULL::UUID;
END;
$$ LANGUAGE plpgsql;

-- Update the find_user_by_phone function to handle temporary profiles
CREATE OR REPLACE FUNCTION find_user_by_phone(p_phone_number VARCHAR(20))
RETURNS TABLE(
    user_id UUID,
    phone_verified BOOLEAN,
    auth_provider VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.phone_verified,
        p.auth_provider
    FROM public.profiles p
    WHERE p.phone = p_phone_number
    ORDER BY p.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Add comment to explain the changes
COMMENT ON FUNCTION verify_otp(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR) IS 'Updated to return user_id and handle profile creation for WhatsApp authentication';
COMMENT ON COLUMN public.profiles.is_temp_profile IS 'Flag to indicate if this is a temporary profile created during OTP verification that needs to be updated with user details';
