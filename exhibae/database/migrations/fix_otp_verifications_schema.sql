-- Fix OTP verifications table schema inconsistencies
-- This migration ensures the otp_verifications table uses consistent column names

-- First, let's check if the table exists and what columns it has
DO $$ 
DECLARE
    column_exists BOOLEAN;
    constraint_exists BOOLEAN;
BEGIN
    -- Check if otp_verifications table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'otp_verifications') THEN
        
        -- Check if the table has 'id' column (old schema)
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'otp_verifications' AND column_name = 'id'
        ) INTO column_exists;
        
        -- If table has 'id' column, rename it to 'otp_id' to match the correct schema
        IF column_exists THEN
            -- Rename the primary key column from 'id' to 'otp_id'
            ALTER TABLE public.otp_verifications RENAME COLUMN id TO otp_id;
            
            -- Drop the old primary key constraint
            ALTER TABLE public.otp_verifications DROP CONSTRAINT IF EXISTS otp_verifications_pkey;
            
            -- Add the new primary key constraint
            ALTER TABLE public.otp_verifications ADD CONSTRAINT otp_verifications_pkey PRIMARY KEY (otp_id);
            
            RAISE NOTICE 'Renamed id column to otp_id in otp_verifications table';
        END IF;
        
        -- Check if verification_type column exists (should be otp_type)
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'otp_verifications' AND column_name = 'verification_type'
        ) INTO column_exists;
        
        -- If verification_type exists, rename it to otp_type
        IF column_exists THEN
            ALTER TABLE public.otp_verifications RENAME COLUMN verification_type TO otp_type;
            RAISE NOTICE 'Renamed verification_type column to otp_type in otp_verifications table';
        END IF;
        
        -- Check if status column exists (should not exist in otp_verifications)
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'otp_verifications' AND column_name = 'status'
        ) INTO column_exists;
        
        -- If status column exists, drop it (it belongs in phone_verifications table)
        IF column_exists THEN
            ALTER TABLE public.otp_verifications DROP COLUMN status;
            RAISE NOTICE 'Dropped status column from otp_verifications table (belongs in phone_verifications)';
        END IF;
        
        -- Ensure all required columns exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'otp_id') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN otp_id UUID DEFAULT gen_random_uuid() PRIMARY KEY;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'user_id') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'phone_number') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN phone_number VARCHAR(20) NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'email') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN email VARCHAR(255);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'otp_code') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN otp_code VARCHAR(6) NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'otp_type') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN otp_type VARCHAR(20) NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'expires_at') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN expires_at TIMESTAMP WITH TIME ZONE NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'attempts') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN attempts INTEGER DEFAULT 0;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'max_attempts') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN max_attempts INTEGER DEFAULT 3;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'verified') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN verified BOOLEAN DEFAULT FALSE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'verified_at') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN verified_at TIMESTAMP WITH TIME ZONE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'created_at') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = 'otp_verifications' AND column_name = 'updated_at') THEN
            ALTER TABLE public.otp_verifications ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        END IF;
        
        -- Add constraints if they don't exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                      WHERE table_name = 'otp_verifications' 
                      AND constraint_name = 'otp_verifications_otp_type_check') THEN
            ALTER TABLE public.otp_verifications 
            ADD CONSTRAINT otp_verifications_otp_type_check 
            CHECK (otp_type IN ('whatsapp', 'whatsapp_login', 'email', 'sms', 'login', 'registration', 'password_reset', 'phone_update'));
        END IF;
        
    ELSE
        -- Create the table if it doesn't exist
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
        
        RAISE NOTICE 'Created otp_verifications table with correct schema';
    END IF;
END $$;

-- Create indexes for otp_verifications table
DO $$ 
BEGIN
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
END $$;

-- Enable RLS on otp_verifications table
ALTER TABLE public.otp_verifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own OTP verifications" ON public.otp_verifications;
DROP POLICY IF EXISTS "Users can insert own OTP verifications" ON public.otp_verifications;
DROP POLICY IF EXISTS "Users can update own OTP verifications" ON public.otp_verifications;
DROP POLICY IF EXISTS "Service role can manage all OTP verifications" ON public.otp_verifications;

-- Create RLS policies for otp_verifications
CREATE POLICY "Users can view own OTP verifications" ON public.otp_verifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own OTP verifications" ON public.otp_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own OTP verifications" ON public.otp_verifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all OTP verifications" ON public.otp_verifications
    FOR ALL USING (auth.role() = 'service_role');

-- Grant permissions
GRANT ALL ON public.otp_verifications TO anon, authenticated, service_role;
