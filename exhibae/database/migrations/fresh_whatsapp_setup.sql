-- Fresh WhatsApp Authentication Setup
-- This migration completely sets up the WhatsApp authentication system
-- Run this to fix all existing issues

-- 1. Drop existing tables if they exist (clean slate)
DROP TABLE IF EXISTS public.phone_verifications CASCADE;
DROP TABLE IF EXISTS public.otp_verifications CASCADE;
DROP TABLE IF EXISTS public.auth_tokens CASCADE;
DROP TABLE IF EXISTS public.whatsapp_message_logs CASCADE;

-- 2. Drop existing functions
DROP FUNCTION IF EXISTS generate_otp() CASCADE;
DROP FUNCTION IF EXISTS generate_secure_token() CASCADE;
DROP FUNCTION IF EXISTS create_otp_verification(UUID, VARCHAR, VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS verify_otp(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS create_auth_token(UUID, VARCHAR, INTEGER, JSONB, INET, TEXT) CASCADE;
DROP FUNCTION IF EXISTS validate_auth_token(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS revoke_auth_token(VARCHAR, UUID) CASCADE;
DROP FUNCTION IF EXISTS find_user_by_phone(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS cleanup_expired_auth_data() CASCADE;
DROP FUNCTION IF EXISTS log_whatsapp_message(VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT) CASCADE;

-- 3. Add WhatsApp columns to profiles table
DO $$ 
BEGIN
    -- Add phone_verified column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' 
                   AND column_name = 'phone_verified') THEN
        ALTER TABLE public.profiles 
        ADD COLUMN phone_verified BOOLEAN DEFAULT FALSE;
    END IF;
    
    -- Add phone_verified_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' 
                   AND column_name = 'phone_verified_at') THEN
        ALTER TABLE public.profiles 
        ADD COLUMN phone_verified_at TIMESTAMP WITH TIME ZONE NULL;
    END IF;
    
    -- Add whatsapp_enabled column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' 
                   AND column_name = 'whatsapp_enabled') THEN
        ALTER TABLE public.profiles 
        ADD COLUMN whatsapp_enabled BOOLEAN DEFAULT FALSE;
    END IF;
    
    -- Add auth_provider column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' 
                   AND column_name = 'auth_provider') THEN
        ALTER TABLE public.profiles 
        ADD COLUMN auth_provider VARCHAR(20) DEFAULT 'email';
    END IF;
    
END $$;

-- 4. Create OTP verifications table
CREATE TABLE public.otp_verifications (
    otp_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    otp_code VARCHAR(6) NOT NULL,
    otp_type VARCHAR(20) NOT NULL CHECK (otp_type IN ('whatsapp', 'whatsapp_login', 'email', 'sms', 'login', 'registration', 'password_reset', 'phone_update')),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create phone verifications table
CREATE TABLE public.phone_verifications (
    verification_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    verification_type VARCHAR(20) DEFAULT 'whatsapp_login' CHECK (verification_type IN ('whatsapp_login', 'phone_update', 'registration')),
    whatsapp_message_id VARCHAR(255),
    otp_verification_id UUID REFERENCES public.otp_verifications(otp_id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'verified')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create auth tokens table
CREATE TABLE public.auth_tokens (
    token_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    token_type VARCHAR(20) NOT NULL CHECK (token_type IN ('access', 'refresh', 'reset', 'verification', 'api')),
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    device_info JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Create whatsapp message logs table
CREATE TABLE public.whatsapp_message_logs (
    log_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    message_type VARCHAR(50) NOT NULL,
    message_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'sent',
    error_message TEXT,
    delivery_timestamp TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Create indexes
CREATE INDEX idx_otp_user_id ON public.otp_verifications(user_id);
CREATE INDEX idx_otp_phone ON public.otp_verifications(phone_number);
CREATE INDEX idx_otp_email ON public.otp_verifications(email);
CREATE INDEX idx_otp_type ON public.otp_verifications(otp_type);
CREATE INDEX idx_otp_expires ON public.otp_verifications(expires_at);
CREATE INDEX idx_otp_verified ON public.otp_verifications(verified);

CREATE INDEX idx_phone_verifications_user_id ON public.phone_verifications(user_id);
CREATE INDEX idx_phone_verifications_phone ON public.phone_verifications(phone_number);
CREATE INDEX idx_phone_verifications_status ON public.phone_verifications(status);
CREATE INDEX idx_phone_verifications_otp_id ON public.phone_verifications(otp_verification_id);

CREATE INDEX idx_tokens_user_id ON public.auth_tokens(user_id);
CREATE INDEX idx_tokens_type ON public.auth_tokens(token_type);
CREATE INDEX idx_tokens_hash ON public.auth_tokens(token_hash);
CREATE INDEX idx_tokens_expires ON public.auth_tokens(expires_at);
CREATE INDEX idx_tokens_revoked ON public.auth_tokens(is_revoked);

CREATE INDEX idx_whatsapp_logs_phone ON public.whatsapp_message_logs(phone_number);
CREATE INDEX idx_whatsapp_logs_status ON public.whatsapp_message_logs(status);
CREATE INDEX idx_whatsapp_logs_created ON public.whatsapp_message_logs(created_at);

-- Add indexes to profiles table
CREATE INDEX IF NOT EXISTS idx_profiles_phone_verified ON public.profiles(phone_verified);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_auth_provider ON public.profiles(auth_provider);

-- 9. Enable RLS
ALTER TABLE public.otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phone_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auth_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_message_logs ENABLE ROW LEVEL SECURITY;

-- 10. Create RLS policies
-- OTP verifications policies
CREATE POLICY "Users can view own OTP verifications" ON public.otp_verifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own OTP verifications" ON public.otp_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own OTP verifications" ON public.otp_verifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all OTP verifications" ON public.otp_verifications
    FOR ALL USING (auth.role() = 'service_role');

-- Phone verifications policies
CREATE POLICY "Users can view own phone verifications" ON public.phone_verifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own phone verifications" ON public.phone_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own phone verifications" ON public.phone_verifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all phone verifications" ON public.phone_verifications
    FOR ALL USING (auth.role() = 'service_role');

-- Auth tokens policies
CREATE POLICY "Users can view own tokens" ON public.auth_tokens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tokens" ON public.auth_tokens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens" ON public.auth_tokens
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all tokens" ON public.auth_tokens
    FOR ALL USING (auth.role() = 'service_role');

-- WhatsApp message logs policies
CREATE POLICY "Service role can manage all whatsapp logs" ON public.whatsapp_message_logs
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Users can view own whatsapp logs" ON public.whatsapp_message_logs
    FOR SELECT USING (phone_number IN (
        SELECT phone FROM public.profiles WHERE id = auth.uid()
    ));

-- 11. Grant permissions
GRANT ALL ON public.otp_verifications TO anon, authenticated, service_role;
GRANT ALL ON public.phone_verifications TO anon, authenticated, service_role;
GRANT ALL ON public.auth_tokens TO anon, authenticated, service_role;
GRANT ALL ON public.whatsapp_message_logs TO anon, authenticated, service_role;

-- 12. Create functions with proper column names
-- Function to generate a random 6-digit OTP
CREATE OR REPLACE FUNCTION generate_otp()
RETURNS VARCHAR(6) AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Function to generate a secure token
CREATE OR REPLACE FUNCTION generate_secure_token()
RETURNS VARCHAR(64) AS $$
BEGIN
    RETURN encode(gen_random_bytes(32), 'hex');
END;
$$ LANGUAGE plpgsql;

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
    v_existing_user_id UUID;
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
    
    -- For WhatsApp authentication, handle phone verification
    IF p_phone_number IS NOT NULL AND p_otp_type = 'whatsapp' THEN
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
            
            -- Return success with phone verified
            RETURN QUERY SELECT TRUE, 'OTP verified successfully', TRUE, v_otp_record.otp_id;
            RETURN;
        ELSE
            -- No existing user found - this is a new registration
            -- The phone verification will be handled during account creation
            RETURN QUERY SELECT TRUE, 'OTP verified successfully', FALSE, v_otp_record.otp_id;
            RETURN;
        END IF;
    END IF;
    
    -- For other verification types or if no phone number
    RETURN QUERY SELECT TRUE, 'OTP verified successfully', FALSE, v_otp_record.otp_id;
END;
$$ LANGUAGE plpgsql;

-- Function to find user by phone number
CREATE OR REPLACE FUNCTION find_user_by_phone(p_phone_number VARCHAR(20) DEFAULT NULL)
RETURNS TABLE(
    user_id UUID,
    phone_verified BOOLEAN,
    auth_provider VARCHAR(20)
) AS $$
BEGIN
    -- Validate required parameters
    IF p_phone_number IS NULL THEN
        RETURN;
    END IF;
    
    RETURN QUERY
    SELECT 
        p.id as user_id,
        p.phone_verified,
        p.auth_provider
    FROM public.profiles p
    WHERE p.phone = p_phone_number;
    -- Removed the phone_verified = TRUE condition to allow finding users
    -- who might not have their phone marked as verified yet
END;
$$ LANGUAGE plpgsql;

-- Function to log WhatsApp messages
CREATE OR REPLACE FUNCTION log_whatsapp_message(
    p_phone_number VARCHAR(20) DEFAULT NULL,
    p_message_type VARCHAR(50) DEFAULT NULL,
    p_message_id VARCHAR(255) DEFAULT NULL,
    p_status VARCHAR(50) DEFAULT 'sent',
    p_error_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    -- Validate required parameters
    IF p_phone_number IS NULL OR p_message_type IS NULL THEN
        RAISE EXCEPTION 'Phone number and message type are required';
    END IF;
    
    INSERT INTO public.whatsapp_message_logs (
        phone_number,
        message_type,
        message_id,
        status,
        error_message,
        delivery_timestamp
    ) VALUES (
        p_phone_number,
        p_message_type,
        p_message_id,
        p_status,
        p_error_message,
        CASE WHEN p_status = 'delivered' THEN NOW() ELSE NULL END
    ) RETURNING log_id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- 13. Grant execute permissions on all functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- 14. Update existing profiles to set default auth_provider
UPDATE public.profiles 
SET auth_provider = 'email' 
WHERE auth_provider IS NULL;

-- 15. Add auth_provider check constraint if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'profiles' 
                   AND constraint_name = 'profiles_auth_provider_check') THEN
        ALTER TABLE public.profiles 
        ADD CONSTRAINT profiles_auth_provider_check 
        CHECK (auth_provider IN ('email', 'whatsapp', 'both'));
    END IF;
END $$;
