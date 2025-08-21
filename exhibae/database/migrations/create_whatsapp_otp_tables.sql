-- WhatsApp OTP Authentication Tables
-- This migration adds WhatsApp OTP functionality while preserving existing auth

-- Create phone_verifications table for OTP management
CREATE TABLE IF NOT EXISTS public.phone_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    attempts INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT FALSE,
    verification_type VARCHAR(20) DEFAULT 'login' CHECK (verification_type IN ('login', 'phone_update', 'registration', 'whatsapp_login')),
    whatsapp_message_id VARCHAR(255), -- Store WhatsApp message ID for tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_phone_verifications_user_id ON public.phone_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_phone ON public.phone_verifications(phone_number);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_expires ON public.phone_verifications(expires_at);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_type ON public.phone_verifications(verification_type);

-- Add phone verification fields to existing profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_verified_at TIMESTAMP WITH TIME ZONE NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS whatsapp_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) DEFAULT 'email' CHECK (auth_provider IN ('email', 'whatsapp', 'both'));

-- Create index for phone verification status
CREATE INDEX IF NOT EXISTS idx_profiles_phone_verified ON public.profiles(phone_verified);

-- Enable RLS on phone_verifications table
ALTER TABLE public.phone_verifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for phone_verifications
-- Users can only see their own phone verifications
CREATE POLICY "Users can view own phone verifications" ON public.phone_verifications
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own phone verifications
CREATE POLICY "Users can insert own phone verifications" ON public.phone_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own phone verifications
CREATE POLICY "Users can update own phone verifications" ON public.phone_verifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Service role can manage all phone verifications (for backend API)
CREATE POLICY "Service role can manage phone verifications" ON public.phone_verifications
    FOR ALL USING (auth.role() = 'service_role');

-- Create function to clean up expired OTPs
CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS void AS $$
BEGIN
    DELETE FROM public.phone_verifications 
    WHERE expires_at < NOW() AND verified = FALSE;
END;
$$ LANGUAGE plpgsql;

-- Create function to generate OTP
CREATE OR REPLACE FUNCTION generate_otp()
RETURNS VARCHAR(6) AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Create function to create phone verification
CREATE OR REPLACE FUNCTION create_phone_verification(
    p_user_id UUID,
    p_phone_number VARCHAR(20),
    p_verification_type VARCHAR(20) DEFAULT 'login'
)
RETURNS TABLE(
    id UUID,
    otp_code VARCHAR(6),
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_otp VARCHAR(6);
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Generate OTP
    v_otp := generate_otp();
    v_expires_at := NOW() + INTERVAL '5 minutes';
    
    -- Insert verification record
    INSERT INTO public.phone_verifications (
        user_id, 
        phone_number, 
        otp_code, 
        expires_at, 
        verification_type
    ) VALUES (
        p_user_id,
        p_phone_number,
        v_otp,
        v_expires_at,
        p_verification_type
    );
    
    -- Return the created verification
    RETURN QUERY
    SELECT 
        pv.id,
        pv.otp_code,
        pv.expires_at
    FROM public.phone_verifications pv
    WHERE pv.user_id = p_user_id 
    AND pv.phone_number = p_phone_number
    AND pv.verification_type = p_verification_type
    ORDER BY pv.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to verify OTP
CREATE OR REPLACE FUNCTION verify_phone_otp(
    p_user_id UUID,
    p_phone_number VARCHAR(20),
    p_otp_code VARCHAR(6),
    p_verification_type VARCHAR(20) DEFAULT 'login'
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    phone_verified BOOLEAN
) AS $$
DECLARE
    v_verification RECORD;
    v_attempts INTEGER;
BEGIN
    -- Get the verification record
    SELECT * INTO v_verification
    FROM public.phone_verifications
    WHERE user_id = p_user_id 
    AND phone_number = p_phone_number
    AND verification_type = p_verification_type
    AND verified = FALSE
    AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Check if verification exists
    IF v_verification IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Invalid or expired OTP', FALSE;
        RETURN;
    END IF;
    
    -- Check attempts
    v_attempts := v_verification.attempts + 1;
    
    -- Update attempts
    UPDATE public.phone_verifications
    SET attempts = v_attempts, updated_at = NOW()
    WHERE id = v_verification.id;
    
    -- Check if too many attempts
    IF v_attempts > 3 THEN
        RETURN QUERY SELECT FALSE, 'Too many attempts. Please request a new OTP', FALSE;
        RETURN;
    END IF;
    
    -- Check if OTP matches
    IF v_verification.otp_code != p_otp_code THEN
        RETURN QUERY SELECT FALSE, 'Invalid OTP code', FALSE;
        RETURN;
    END IF;
    
    -- Mark as verified
    UPDATE public.phone_verifications
    SET verified = TRUE, updated_at = NOW()
    WHERE id = v_verification.id;
    
    -- Update profile if user exists
    IF p_user_id IS NOT NULL THEN
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
    
    RETURN QUERY SELECT TRUE, 'Phone number verified successfully', TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to find user by phone number
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
    AND p.phone_verified = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create scheduled job to clean up expired OTPs (runs every hour)
SELECT cron.schedule(
    'cleanup-expired-otps',
    '0 * * * *', -- Every hour
    'SELECT cleanup_expired_otps();'
);

-- Create WhatsApp message logs table for tracking
CREATE TABLE IF NOT EXISTS public.whatsapp_message_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    message_type VARCHAR(50) NOT NULL,
    message_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'sent',
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for WhatsApp logs
CREATE INDEX IF NOT EXISTS idx_whatsapp_logs_phone ON public.whatsapp_message_logs(phone_number);
CREATE INDEX IF NOT EXISTS idx_whatsapp_logs_status ON public.whatsapp_message_logs(status);
CREATE INDEX IF NOT EXISTS idx_whatsapp_logs_created ON public.whatsapp_message_logs(created_at);

-- Enable RLS on WhatsApp logs
ALTER TABLE public.whatsapp_message_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for WhatsApp logs (service role only)
CREATE POLICY "Service role can manage WhatsApp logs" ON public.whatsapp_message_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Create function to log WhatsApp messages
CREATE OR REPLACE FUNCTION log_whatsapp_message(
    p_phone_number VARCHAR(20),
    p_message_type VARCHAR(50),
    p_message_id VARCHAR(255) DEFAULT NULL,
    p_status VARCHAR(50) DEFAULT 'sent',
    p_error_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
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
    ) RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON public.phone_verifications TO anon, authenticated, service_role;
GRANT ALL ON public.whatsapp_message_logs TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Update existing profiles to set default auth_provider
UPDATE public.profiles 
SET auth_provider = 'email' 
WHERE auth_provider IS NULL;
