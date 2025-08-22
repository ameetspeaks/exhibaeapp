-- Quick fix: Add is_temp_profile column to profiles table
-- Run this immediately to fix the database error

-- Add the is_temp_profile column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' 
                   AND column_name = 'is_temp_profile'
                   AND table_schema = 'public') THEN
        ALTER TABLE public.profiles 
        ADD COLUMN is_temp_profile BOOLEAN DEFAULT FALSE;
        
        RAISE NOTICE 'Added is_temp_profile column to profiles table';
    ELSE
        RAISE NOTICE 'is_temp_profile column already exists';
    END IF;
END $$;

-- Verify the column was added
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name = 'is_temp_profile'
AND table_schema = 'public';
