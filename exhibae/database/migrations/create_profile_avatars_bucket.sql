-- Create profile-avatars storage bucket and update profiles table
-- This migration sets up storage for profile pictures and company logos

-- Storage Bucket Setup Instructions
-- IMPORTANT: Storage bucket must be created manually in Supabase Dashboard
-- SQL migrations cannot create storage buckets due to permission restrictions

-- MANUAL SETUP REQUIRED:
-- 1. Go to Supabase Dashboard > Storage
-- 2. Create the following bucket manually:

-- BUCKET: profile-avatars
-- - Name: profile-avatars
-- - Public: true
-- - File size limit: 10MB
-- - Allowed MIME types: image/jpeg,image/png,image/gif,image/webp

-- After creating the bucket, run the storage policies below
-- in Supabase Dashboard > SQL Editor

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can upload their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Public read access to profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own company logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own company logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own company logos" ON storage.objects;

-- Create storage policies for profile-avatars bucket
-- Policy 1: "Users can upload their own profile pictures"
CREATE POLICY "Users can upload their own profile pictures" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-avatars' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
        AND (storage.foldername(name))[2] LIKE 'profile_' || auth.uid()::text || '_%'
    );

-- Policy 2: "Public read access to profile pictures"
CREATE POLICY "Public read access to profile pictures" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'profile-avatars');

-- Policy 3: "Users can update their own profile pictures"
CREATE POLICY "Users can update their own profile pictures" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
        AND (storage.foldername(name))[2] LIKE 'profile_' || auth.uid()::text || '_%'
    );

-- Policy 4: "Users can delete their own profile pictures"
CREATE POLICY "Users can delete their own profile pictures" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
        AND (storage.foldername(name))[2] LIKE 'profile_' || auth.uid()::text || '_%'
    );

-- Policy 5: "Users can upload their own company logos"
CREATE POLICY "Users can upload their own company logos" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-avatars' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'logos'
        AND (storage.foldername(name))[2] LIKE 'logo_' || auth.uid()::text || '_%'
    );

-- Policy 6: "Users can update their own company logos"
CREATE POLICY "Users can update their own company logos" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'logos'
        AND (storage.foldername(name))[2] LIKE 'logo_' || auth.uid()::text || '_%'
    );

-- Policy 7: "Users can delete their own company logos"
CREATE POLICY "Users can delete their own company logos" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'logos'
        AND (storage.foldername(name))[2] LIKE 'logo_' || auth.uid()::text || '_%'
    );

-- Update profiles table to add company_logo_url field
-- This allows brands and organizers to have company logos
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS company_logo_url TEXT;

-- Add comment to explain the field
COMMENT ON COLUMN profiles.company_logo_url IS 'URL to the company logo image for brands and organizers';

-- Create index for better performance on company_logo_url queries
CREATE INDEX IF NOT EXISTS idx_profiles_company_logo_url ON profiles(company_logo_url) WHERE company_logo_url IS NOT NULL;
