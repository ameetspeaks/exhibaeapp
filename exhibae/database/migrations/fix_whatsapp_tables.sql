-- Fix WhatsApp tables - Handle existing tables and add missing components
-- This migration safely handles tables that may already exist

-- 1. Fix profiles table - Add WhatsApp-related columns if they don't exist
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
    
    -- Add auth_provider check constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'profiles' 
                   AND constraint_name = 'profiles_auth_provider_check') THEN
        ALTER TABLE public.profiles 
        ADD CONSTRAINT profiles_auth_provider_check 
        CHECK (auth_provider IN ('email', 'whatsapp', 'both'));
    END IF;
    
    -- Add indexes if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_profiles_phone_verified') THEN
        CREATE INDEX idx_profiles_phone_verified ON public.profiles(phone_verified);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_profiles_phone') THEN
        CREATE INDEX idx_profiles_phone ON public.profiles(phone) WHERE phone IS NOT NULL;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_profiles_auth_provider') THEN
        CREATE INDEX idx_profiles_auth_provider ON public.profiles(auth_provider);
    END IF;
    
END $$;

-- 2. Create otp_verifications table if it doesn't exist
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

-- 3. Create auth_tokens table if it doesn't exist
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

-- 4. Create whatsapp_message_logs table if it doesn't exist
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

-- 5. Create indexes for all tables
DO $$ 
BEGIN
    -- OTP verifications indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_otp_user_id') THEN
        CREATE INDEX idx_otp_user_id ON public.otp_verifications(user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_otp_phone') THEN
        CREATE INDEX idx_otp_phone ON public.otp_verifications(phone_number);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_otp_email') THEN
        CREATE INDEX idx_otp_email ON public.otp_verifications(email);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_otp_type') THEN
        CREATE INDEX idx_otp_type ON public.otp_verifications(otp_type);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_otp_expires') THEN
        CREATE INDEX idx_otp_expires ON public.otp_verifications(expires_at);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_otp_verified') THEN
        CREATE INDEX idx_otp_verified ON public.otp_verifications(verified);
    END IF;
    
    -- Auth tokens indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_tokens_user_id') THEN
        CREATE INDEX idx_tokens_user_id ON public.auth_tokens(user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_tokens_type') THEN
        CREATE INDEX idx_tokens_type ON public.auth_tokens(token_type);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_tokens_hash') THEN
        CREATE INDEX idx_tokens_hash ON public.auth_tokens(token_hash);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_tokens_expires') THEN
        CREATE INDEX idx_tokens_expires ON public.auth_tokens(expires_at);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_tokens_revoked') THEN
        CREATE INDEX idx_tokens_revoked ON public.auth_tokens(is_revoked);
    END IF;
    
    -- WhatsApp message logs indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_whatsapp_logs_phone') THEN
        CREATE INDEX idx_whatsapp_logs_phone ON public.whatsapp_message_logs(phone_number);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_whatsapp_logs_status') THEN
        CREATE INDEX idx_whatsapp_logs_status ON public.whatsapp_message_logs(status);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_whatsapp_logs_created') THEN
        CREATE INDEX idx_whatsapp_logs_created ON public.whatsapp_message_logs(created_at);
    END IF;
    
END $$;

-- 6. Enable RLS for all tables
ALTER TABLE public.otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auth_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_message_logs ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies (drop existing ones first)
-- OTP verifications policies
DROP POLICY IF EXISTS "Users can view own OTP verifications" ON public.otp_verifications;
DROP POLICY IF EXISTS "Users can insert own OTP verifications" ON public.otp_verifications;
DROP POLICY IF EXISTS "Users can update own OTP verifications" ON public.otp_verifications;
DROP POLICY IF EXISTS "Service role can manage all OTP verifications" ON public.otp_verifications;

CREATE POLICY "Users can view own OTP verifications" ON public.otp_verifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own OTP verifications" ON public.otp_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own OTP verifications" ON public.otp_verifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all OTP verifications" ON public.otp_verifications
    FOR ALL USING (auth.role() = 'service_role');

-- Auth tokens policies
DROP POLICY IF EXISTS "Users can view own tokens" ON public.auth_tokens;
DROP POLICY IF EXISTS "Users can insert own tokens" ON public.auth_tokens;
DROP POLICY IF EXISTS "Users can update own tokens" ON public.auth_tokens;
DROP POLICY IF EXISTS "Service role can manage all tokens" ON public.auth_tokens;

CREATE POLICY "Users can view own tokens" ON public.auth_tokens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tokens" ON public.auth_tokens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens" ON public.auth_tokens
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all tokens" ON public.auth_tokens
    FOR ALL USING (auth.role() = 'service_role');

-- WhatsApp message logs policies
DROP POLICY IF EXISTS "Service role can manage all whatsapp logs" ON public.whatsapp_message_logs;
DROP POLICY IF EXISTS "Users can view own whatsapp logs" ON public.whatsapp_message_logs;

CREATE POLICY "Service role can manage all whatsapp logs" ON public.whatsapp_message_logs
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Users can view own whatsapp logs" ON public.whatsapp_message_logs
    FOR SELECT USING (phone_number IN (
        SELECT phone FROM public.profiles WHERE id = auth.uid()
    ));

-- 8. Grant permissions
GRANT ALL ON public.otp_verifications TO anon, authenticated, service_role;
GRANT ALL ON public.auth_tokens TO anon, authenticated, service_role;
GRANT ALL ON public.whatsapp_message_logs TO anon, authenticated, service_role;

-- 9. Update existing profiles to set default auth_provider
UPDATE public.profiles 
SET auth_provider = 'email' 
WHERE auth_provider IS NULL;
