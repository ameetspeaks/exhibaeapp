-- Make email field optional for WhatsApp authentication
-- This allows users to sign up with phone numbers only

-- Check if email column exists and is NOT NULL
DO $$ 
BEGIN
    -- Check if email column is NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'email' 
        AND is_nullable = 'NO'
    ) THEN
        -- Make email column nullable
        ALTER TABLE public.profiles ALTER COLUMN email DROP NOT NULL;
        
        -- Add a comment to explain the change
        COMMENT ON COLUMN public.profiles.email IS 'Email is optional for WhatsApp authentication users';
        
        RAISE NOTICE 'Email column made nullable for WhatsApp authentication';
    ELSE
        RAISE NOTICE 'Email column is already nullable or does not exist';
    END IF;
END $$;

-- Add a check constraint to ensure either email or phone is provided
DO $$ 
BEGIN
    -- Drop existing constraint if it exists
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_email_or_phone_check;
    
    -- Add new constraint
    ALTER TABLE public.profiles ADD CONSTRAINT profiles_email_or_phone_check 
    CHECK (email IS NOT NULL OR phone IS NOT NULL);
    
    RAISE NOTICE 'Added constraint: either email or phone must be provided';
END $$;
