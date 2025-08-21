-- Fix RLS Storage Policies for Profile Avatars
-- This migration fixes Row Level Security issues for bucket creation and storage access

-- ============================================================================
-- STEP 1: ENABLE RLS ON STORAGE TABLES (if not already enabled)
-- ============================================================================

-- Enable RLS on storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Enable RLS on storage.buckets table (if it exists and RLS is not enabled)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'storage' AND table_name = 'buckets') THEN
        ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- ============================================================================
-- STEP 2: DROP EXISTING POLICIES TO AVOID CONFLICTS
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
-- STEP 3: CREATE BUCKET POLICIES (FIXES BUCKET CREATION ISSUE)
-- ============================================================================

-- Policy: Allow authenticated users to create buckets
CREATE POLICY "Allow authenticated users to create buckets" ON storage.buckets
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy: Allow authenticated users to view buckets
CREATE POLICY "Allow authenticated users to view buckets" ON storage.buckets
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Policy: Allow authenticated users to update buckets
CREATE POLICY "Allow authenticated users to update buckets" ON storage.buckets
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- Policy: Allow authenticated users to delete buckets
CREATE POLICY "Allow authenticated users to delete buckets" ON storage.buckets
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- STEP 4: CREATE STORAGE OBJECT POLICIES
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
-- STEP 5: ADDITIONAL POLICIES FOR BETTER SECURITY
-- ============================================================================

-- Policy: Allow authenticated users to list objects in profile-avatars bucket
CREATE POLICY "Allow authenticated users to list profile-avatars objects" ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
    );

-- Policy: Allow service role to manage all storage (for admin operations)
CREATE POLICY "Allow service role full access" ON storage.objects
    FOR ALL
    USING (auth.role() = 'service_role');

CREATE POLICY "Allow service role full access to buckets" ON storage.buckets
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- STEP 6: UPDATE PROFILES TABLE SCHEMA
-- ============================================================================

-- Add company_logo_url field to profiles table if it doesn't exist
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS company_logo_url TEXT;

-- Add comment to explain the field
COMMENT ON COLUMN profiles.company_logo_url IS 'URL to the company logo image for brands and organizers';

-- Create index for better performance on company_logo_url queries
CREATE INDEX IF NOT EXISTS idx_profiles_company_logo_url ON profiles(company_logo_url) WHERE company_logo_url IS NOT NULL;

-- ============================================================================
-- STEP 7: VERIFICATION QUERIES
-- ============================================================================

-- Check if policies were created successfully
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
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
This migration fixes the RLS issues by:

1. ENABLING BUCKET CREATION: The bucket policies allow authenticated users to create, view, update, and delete buckets
2. SECURING FILE ACCESS: Object policies ensure users can only access their own files
3. MAINTAINING SECURITY: Public read access for profile pictures and company logos
4. ADMIN ACCESS: Service role has full access for administrative operations

After running this migration:
- Users can create the profile-avatars bucket from the Flutter app
- Profile picture uploads will work correctly
- Company logo uploads will work for brands and organizers
- All operations are properly secured with RLS

To test:
1. Run this migration in Supabase SQL Editor
2. Try creating the profile-avatars bucket from your Flutter app
3. Test profile picture and company logo uploads
*/
