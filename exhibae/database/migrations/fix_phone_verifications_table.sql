-- Fix phone_verifications table - Add missing columns and constraints
-- This migration handles the case where the table already exists

-- Add missing columns to phone_verifications table if they don't exist
DO $$ 
BEGIN
    -- Add otp_verification_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'phone_verifications' 
                   AND column_name = 'otp_verification_id') THEN
        ALTER TABLE public.phone_verifications 
        ADD COLUMN otp_verification_id UUID;
    END IF;
    
    -- Add foreign key constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'phone_verifications' 
                   AND constraint_name = 'phone_verifications_otp_verification_id_fkey') THEN
        ALTER TABLE public.phone_verifications 
        ADD CONSTRAINT phone_verifications_otp_verification_id_fkey 
        FOREIGN KEY (otp_verification_id) REFERENCES otp_verifications (otp_id) ON DELETE CASCADE;
    END IF;
    
    -- Add status check constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'phone_verifications' 
                   AND constraint_name = 'phone_verifications_status_check') THEN
        ALTER TABLE public.phone_verifications 
        ADD CONSTRAINT phone_verifications_status_check 
        CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'verified'));
    END IF;
    
    -- Add verification_type check constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'phone_verifications' 
                   AND constraint_name = 'phone_verifications_verification_type_check') THEN
        ALTER TABLE public.phone_verifications 
        ADD CONSTRAINT phone_verifications_verification_type_check 
        CHECK (verification_type IN ('whatsapp_login', 'phone_update', 'registration'));
    END IF;
    
    -- Add indexes if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_phone_verifications_otp_id') THEN
        CREATE INDEX idx_phone_verifications_otp_id ON public.phone_verifications(otp_verification_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_phone_verifications_status') THEN
        CREATE INDEX idx_phone_verifications_status ON public.phone_verifications(status);
    END IF;
    
END $$;

-- Enable RLS if not already enabled
ALTER TABLE public.phone_verifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist and recreate them
DROP POLICY IF EXISTS "Users can view own phone verifications" ON public.phone_verifications;
DROP POLICY IF EXISTS "Users can insert own phone verifications" ON public.phone_verifications;
DROP POLICY IF EXISTS "Users can update own phone verifications" ON public.phone_verifications;
DROP POLICY IF EXISTS "Service role can manage all phone verifications" ON public.phone_verifications;

-- Create RLS policies
CREATE POLICY "Users can view own phone verifications" ON public.phone_verifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own phone verifications" ON public.phone_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own phone verifications" ON public.phone_verifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all phone verifications" ON public.phone_verifications
    FOR ALL USING (auth.role() = 'service_role');

-- Grant permissions
GRANT ALL ON public.phone_verifications TO anon, authenticated, service_role;
