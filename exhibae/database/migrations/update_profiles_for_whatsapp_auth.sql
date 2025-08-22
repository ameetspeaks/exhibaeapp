-- Update existing profiles table for WhatsApp authentication
-- Add new columns to support WhatsApp OTP authentication

-- Add new columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS phone_verified_at TIMESTAMP WITH TIME ZONE NULL,
ADD COLUMN IF NOT EXISTS whatsapp_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) DEFAULT 'email' CHECK (auth_provider IN ('email', 'whatsapp', 'both'));

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_profiles_phone_verified ON public.profiles(phone_verified);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_auth_provider ON public.profiles(auth_provider);

-- Create OTP table for all types of OTP verification
CREATE TABLE IF NOT EXISTS public.otp_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    otp_code VARCHAR(6) NOT NULL,
    otp_type VARCHAR(20) NOT NULL CHECK (otp_type IN ('whatsapp', 'email', 'sms', 'login', 'registration', 'password_reset', 'phone_update')),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for OTP table
CREATE INDEX IF NOT EXISTS idx_otp_user_id ON public.otp_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_otp_phone ON public.otp_verifications(phone_number);
CREATE INDEX IF NOT EXISTS idx_otp_email ON public.otp_verifications(email);
CREATE INDEX IF NOT EXISTS idx_otp_type ON public.otp_verifications(otp_type);
CREATE INDEX IF NOT EXISTS idx_otp_expires ON public.otp_verifications(expires_at);
CREATE INDEX IF NOT EXISTS idx_otp_verified ON public.otp_verifications(verified);

-- Create tokens table for session management and API access
CREATE TABLE IF NOT EXISTS public.auth_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
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

-- Create indexes for tokens table
CREATE INDEX IF NOT EXISTS idx_tokens_user_id ON public.auth_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_tokens_type ON public.auth_tokens(token_type);
CREATE INDEX IF NOT EXISTS idx_tokens_hash ON public.auth_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_tokens_expires ON public.auth_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_tokens_revoked ON public.auth_tokens(is_revoked);

-- Create phone_verifications table for WhatsApp-specific verification tracking
CREATE TABLE IF NOT EXISTS public.phone_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    verification_type VARCHAR(20) DEFAULT 'whatsapp_login' CHECK (verification_type IN ('whatsapp_login', 'phone_update', 'registration')),
    whatsapp_message_id VARCHAR(255),
    otp_verification_id UUID REFERENCES public.otp_verifications(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'verified')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for phone_verifications table
CREATE INDEX IF NOT EXISTS idx_phone_verifications_user_id ON public.phone_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_phone ON public.phone_verifications(phone_number);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_status ON public.phone_verifications(status);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_otp_id ON public.phone_verifications(otp_verification_id);

-- Create whatsapp_message_logs table for tracking message delivery
CREATE TABLE IF NOT EXISTS public.whatsapp_message_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    message_type VARCHAR(50) NOT NULL,
    message_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'sent',
    error_message TEXT,
    delivery_timestamp TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for whatsapp_message_logs table
CREATE INDEX IF NOT EXISTS idx_whatsapp_logs_phone ON public.whatsapp_message_logs(phone_number);
CREATE INDEX IF NOT EXISTS idx_whatsapp_logs_status ON public.whatsapp_message_logs(status);
CREATE INDEX IF NOT EXISTS idx_whatsapp_logs_created ON public.whatsapp_message_logs(created_at);

-- Enable Row Level Security (RLS) for new tables
ALTER TABLE public.otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auth_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phone_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_message_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for OTP verifications
CREATE POLICY "Users can view own OTP verifications" ON public.otp_verifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own OTP verifications" ON public.otp_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own OTP verifications" ON public.otp_verifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all OTP verifications" ON public.otp_verifications
    FOR ALL USING (auth.role() = 'service_role');

-- RLS Policies for auth tokens
CREATE POLICY "Users can view own tokens" ON public.auth_tokens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tokens" ON public.auth_tokens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens" ON public.auth_tokens
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all tokens" ON public.auth_tokens
    FOR ALL USING (auth.role() = 'service_role');

-- RLS Policies for phone_verifications
CREATE POLICY "Users can view own phone verifications" ON public.phone_verifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own phone verifications" ON public.phone_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own phone verifications" ON public.phone_verifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all phone verifications" ON public.phone_verifications
    FOR ALL USING (auth.role() = 'service_role');

-- RLS Policies for whatsapp_message_logs
CREATE POLICY "Service role can manage all whatsapp logs" ON public.whatsapp_message_logs
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Users can view own whatsapp logs" ON public.whatsapp_message_logs
    FOR SELECT USING (phone_number IN (
        SELECT phone FROM public.profiles WHERE id = auth.uid()
    ));

-- Create PostgreSQL functions for OTP and token management

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
    ) RETURNING id INTO v_otp_id;
    
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
    otp_id UUID
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
        WHERE id = v_otp_record.id;
        
        RETURN QUERY SELECT FALSE, 'Too many failed attempts. Please request a new OTP.', FALSE, v_otp_record.id;
        RETURN;
    END IF;
    
    -- Mark as verified
    UPDATE public.otp_verifications
    SET verified = TRUE,
        attempts = v_attempts,
        verified_at = NOW(),
        updated_at = NOW()
    WHERE id = v_otp_record.id;
    
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
        v_otp_record.id;
END;
$$ LANGUAGE plpgsql;

-- Function to create auth token
CREATE OR REPLACE FUNCTION create_auth_token(
    p_user_id UUID DEFAULT NULL,
    p_token_type VARCHAR(20) DEFAULT 'access',
    p_expires_in_hours INTEGER DEFAULT 24,
    p_device_info JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS TABLE(
    id UUID,
    token_hash VARCHAR(255),
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_token VARCHAR(64);
    v_token_hash VARCHAR(255);
    v_expires_at TIMESTAMP WITH TIME ZONE;
    v_token_id UUID;
BEGIN
    -- Validate required parameters
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;
    
    -- Generate token
    v_token := generate_secure_token();
    v_token_hash := encode(sha256(v_token::bytea), 'hex');
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
    ) RETURNING id INTO v_token_id;
    
    -- Return the token details (actual token for client, hash for storage)
    RETURN QUERY SELECT v_token_id, v_token, v_expires_at;
END;
$$ LANGUAGE plpgsql;

-- Function to validate auth token
CREATE OR REPLACE FUNCTION validate_auth_token(
    p_token VARCHAR(255) DEFAULT NULL,
    p_token_type VARCHAR(20) DEFAULT 'access'
)
RETURNS TABLE(
    valid BOOLEAN,
    user_id UUID,
    message TEXT
) AS $$
DECLARE
    v_token_record RECORD;
    v_token_hash VARCHAR(255);
BEGIN
    -- Validate required parameters
    IF p_token IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, 'Token is required';
        RETURN;
    END IF;
    
    -- Generate hash from token
    v_token_hash := encode(sha256(p_token::bytea), 'hex');
    
    -- Find the token record
    SELECT * INTO v_token_record
    FROM public.auth_tokens
    WHERE token_hash = v_token_hash
      AND token_type = p_token_type
      AND expires_at > NOW()
      AND NOT is_revoked;
    
    -- Check if token exists and is valid
    IF v_token_record IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, 'Invalid or expired token';
        RETURN;
    END IF;
    
    RETURN QUERY SELECT TRUE, v_token_record.user_id, 'Token is valid';
END;
$$ LANGUAGE plpgsql;

-- Function to revoke auth token
CREATE OR REPLACE FUNCTION revoke_auth_token(
    p_token VARCHAR(255) DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_token_hash VARCHAR(255);
    v_updated_count INTEGER;
BEGIN
    -- Validate required parameters
    IF p_token IS NULL AND p_user_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- If token provided, revoke specific token
    IF p_token IS NOT NULL THEN
        v_token_hash := encode(sha256(p_token::bytea), 'hex');
        
        UPDATE public.auth_tokens
        SET is_revoked = TRUE,
            revoked_at = NOW(),
            updated_at = NOW()
        WHERE token_hash = v_token_hash
          AND NOT is_revoked;
        
        GET DIAGNOSTICS v_updated_count = ROW_COUNT;
        RETURN v_updated_count > 0;
    END IF;
    
    -- If user_id provided, revoke all user tokens
    IF p_user_id IS NOT NULL THEN
        UPDATE public.auth_tokens
        SET is_revoked = TRUE,
            revoked_at = NOW(),
            updated_at = NOW()
        WHERE user_id = p_user_id
          AND NOT is_revoked;
        
        GET DIAGNOSTICS v_updated_count = ROW_COUNT;
        RETURN v_updated_count > 0;
    END IF;
    
    RETURN FALSE;
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
    WHERE p.phone = p_phone_number
      AND p.phone_verified = TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup expired OTPs and tokens
CREATE OR REPLACE FUNCTION cleanup_expired_auth_data()
RETURNS TABLE(
    expired_otps INTEGER,
    expired_tokens INTEGER
) AS $$
DECLARE
    v_otp_count INTEGER;
    v_token_count INTEGER;
BEGIN
    -- Cleanup expired OTPs
    DELETE FROM public.otp_verifications
    WHERE expires_at < NOW() AND NOT verified;
    
    GET DIAGNOSTICS v_otp_count = ROW_COUNT;
    
    -- Cleanup expired tokens
    DELETE FROM public.auth_tokens
    WHERE expires_at < NOW() OR is_revoked = TRUE;
    
    GET DIAGNOSTICS v_token_count = ROW_COUNT;
    
    RETURN QUERY SELECT v_otp_count, v_token_count;
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
    ) RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- Note: Cron scheduling requires the pg_cron extension
-- To enable automatic cleanup, you can:
-- 1. Enable pg_cron extension in Supabase dashboard
-- 2. Or run cleanup manually: SELECT cleanup_expired_auth_data();
-- 3. Or set up a scheduled job in your application

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON public.otp_verifications TO anon, authenticated, service_role;
GRANT ALL ON public.auth_tokens TO anon, authenticated, service_role;
GRANT ALL ON public.phone_verifications TO anon, authenticated, service_role;
GRANT ALL ON public.whatsapp_message_logs TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Update existing profiles to set default auth_provider
UPDATE public.profiles 
SET auth_provider = 'email' 
WHERE auth_provider IS NULL;

-- Add comments for documentation
COMMENT ON TABLE public.otp_verifications IS 'Stores OTP verification records for all authentication types';
COMMENT ON TABLE public.auth_tokens IS 'Stores authentication tokens for session management and API access';
COMMENT ON TABLE public.phone_verifications IS 'Tracks WhatsApp-specific phone verification processes';
COMMENT ON TABLE public.whatsapp_message_logs IS 'Tracks WhatsApp message delivery status';
COMMENT ON COLUMN public.profiles.phone_verified IS 'Whether the user has verified their phone number';
COMMENT ON COLUMN public.profiles.phone_verified_at IS 'Timestamp when phone was verified';
COMMENT ON COLUMN public.profiles.whatsapp_enabled IS 'Whether WhatsApp login is enabled for this user';
COMMENT ON COLUMN public.profiles.auth_provider IS 'Primary authentication method: email, whatsapp, or both';
