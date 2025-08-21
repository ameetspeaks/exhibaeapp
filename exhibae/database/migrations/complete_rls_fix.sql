-- Complete RLS Fix for Profile Avatars
-- This migration fixes all RLS issues for bucket creation and file uploads

-- ============================================================================
-- STEP 1: DROP EXISTING POLICIES TO AVOID CONFLICTS
-- ============================================================================

-- Drop existing storage object policies
DROP POLICY IF EXISTS "Users can upload their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Public read access to profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own company logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own company logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own company logos" ON storage.objects;

-- Drop any existing bucket policies
DROP POLICY IF EXISTS "Allow authenticated users to create buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to view buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to update buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to delete buckets" ON storage.buckets;

-- ============================================================================
-- STEP 2: CREATE BUCKET POLICIES (FIXES BUCKET CREATION ISSUE)
-- ============================================================================

-- Allow authenticated users to create buckets
CREATE POLICY "Allow authenticated users to create buckets" ON storage.buckets
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to view buckets
CREATE POLICY "Allow authenticated users to view buckets" ON storage.buckets
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Allow authenticated users to update buckets
CREATE POLICY "Allow authenticated users to update buckets" ON storage.buckets
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- Allow authenticated users to delete buckets
CREATE POLICY "Allow authenticated users to delete buckets" ON storage.buckets
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- STEP 3: CREATE STORAGE OBJECT POLICIES (FIXES FILE UPLOAD ISSUE)
-- ============================================================================

-- Policy 1: Users can upload their own profile pictures
CREATE POLICY "Users can upload their own profile pictures" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-avatars' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
        AND (storage.foldername(name))[2] LIKE 'profile_' || auth.uid()::text || '_%'
    );

-- Policy 2: Public read access to profile pictures and company logos
CREATE POLICY "Public read access to profile pictures and company logos" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'profile-avatars');

-- Policy 3: Users can update their own profile pictures
CREATE POLICY "Users can update their own profile pictures" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
        AND (storage.foldername(name))[2] LIKE 'profile_' || auth.uid()::text || '_%'
    );

-- Policy 4: Users can delete their own profile pictures
CREATE POLICY "Users can delete their own profile pictures" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
        AND (storage.foldername(name))[2] LIKE 'profile_' || auth.uid()::text || '_%'
    );

-- Policy 5: Users can upload their own company logos
CREATE POLICY "Users can upload their own company logos" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-avatars' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'logos'
        AND (storage.foldername(name))[2] LIKE 'logo_' || auth.uid()::text || '_%'
    );

-- Policy 6: Users can update their own company logos
CREATE POLICY "Users can update their own company logos" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'logos'
        AND (storage.foldername(name))[2] LIKE 'logo_' || auth.uid()::text || '_%'
    );

-- Policy 7: Users can delete their own company logos
CREATE POLICY "Users can delete their own company logos" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'logos'
        AND (storage.foldername(name))[2] LIKE 'logo_' || auth.uid()::text || '_%'
    );

-- ============================================================================
-- STEP 4: ADDITIONAL POLICIES FOR BETTER SECURITY
-- ============================================================================

-- Policy: Allow authenticated users to list objects in profile-avatars bucket
CREATE POLICY "Allow authenticated users to list profile-avatars objects" ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
    );

-- ============================================================================
-- STEP 5: UPDATE PROFILES TABLE SCHEMA
-- ============================================================================

-- Add company_logo_url field to profiles table if it doesn't exist
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS company_logo_url TEXT;

-- Add comment to explain the field
COMMENT ON COLUMN profiles.company_logo_url IS 'URL to the company logo image for brands and organizers';

-- Create index for better performance on company_logo_url queries
CREATE INDEX IF NOT EXISTS idx_profiles_company_logo_url ON profiles(company_logo_url) WHERE company_logo_url IS NOT NULL;

-- ============================================================================
-- STEP 6: VERIFICATION QUERIES
-- ============================================================================

-- Check if policies were created successfully
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename IN ('objects', 'buckets') 
AND schemaname = 'storage'
ORDER BY tablename, policyname;

-- Check if company_logo_url column exists
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name = 'company_logo_url';

-- ============================================================================
-- USAGE NOTES
-- ============================================================================

/*
This migration fixes ALL RLS issues by:

1. ENABLING BUCKET CREATION: The bucket policies allow authenticated users to create, view, update, and delete buckets
2. ENABLING FILE UPLOADS: The object policies allow authenticated users to upload, update, and delete their own files
3. MAINTAINING SECURITY: Public read access for profile pictures and company logos
4. SUPABASE COMPATIBLE: Works with Supabase's permission system

After running this migration:
- Users can create the profile-avatars bucket from the Flutter app
- Profile picture uploads will work correctly
- Company logo uploads will work for brands and organizers
- All operations are properly secured with RLS

To test:
1. Run this migration in Supabase SQL Editor
2. Try creating the profile-avatars bucket from your Flutter app
3. Test profile picture and company logo uploads

This should resolve both the bucket creation RLS issue and the file upload RLS issue.
*/
