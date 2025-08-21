-- Add company_logo_url field to profiles table
-- This migration only handles the database schema changes

-- Update profiles table to add company_logo_url field
-- This allows brands and organizers to have company logos
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS company_logo_url TEXT;

-- Add comment to explain the field
COMMENT ON COLUMN profiles.company_logo_url IS 'URL to the company logo image for brands and organizers';

-- Create index for better performance on company_logo_url queries
CREATE INDEX IF NOT EXISTS idx_profiles_company_logo_url ON profiles(company_logo_url) WHERE company_logo_url IS NOT NULL;
