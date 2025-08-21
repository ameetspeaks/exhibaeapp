-- Storage Policies Setup Instructions
-- IMPORTANT: Storage policies must be created manually in Supabase Dashboard
-- SQL migrations cannot create storage policies due to permission restrictions

-- MANUAL SETUP REQUIRED:
-- 1. Go to Supabase Dashboard > Storage > Policies
-- 2. Create the following policies manually for each bucket:

-- BUCKET: lookbooks
-- Policy 1: "Users can upload lookbooks to their own folder"
-- - Policy name: "Users can upload lookbooks to their own folder"
-- - Operation: INSERT
-- - Target roles: authenticated
-- - Policy definition: 
--   bucket_id = 'lookbooks' 
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy 2: "Public read access to lookbooks"
-- - Policy name: "Public read access to lookbooks"
-- - Operation: SELECT
-- - Target roles: public
-- - Policy definition: bucket_id = 'lookbooks'

-- Policy 3: "Users can update their own lookbooks"
-- - Policy name: "Users can update their own lookbooks"
-- - Operation: UPDATE
-- - Target roles: authenticated
-- - Policy definition:
--   bucket_id = 'lookbooks'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy 4: "Users can delete their own lookbooks"
-- - Policy name: "Users can delete their own lookbooks"
-- - Operation: DELETE
-- - Target roles: authenticated
-- - Policy definition:
--   bucket_id = 'lookbooks'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- BUCKET: gallery
-- Policy 1: "Users can upload gallery files to their own folder"
-- - Policy name: "Users can upload gallery files to their own folder"
-- - Operation: INSERT
-- - Target roles: authenticated
-- - Policy definition:
--   bucket_id = 'gallery'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy 2: "Public read access to gallery"
-- - Policy name: "Public read access to gallery"
-- - Operation: SELECT
-- - Target roles: public
-- - Policy definition: bucket_id = 'gallery'

-- Policy 3: "Users can update their own gallery files"
-- - Policy name: "Users can update their own gallery files"
-- - Operation: UPDATE
-- - Target roles: authenticated
-- - Policy definition:
--   bucket_id = 'gallery'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy 4: "Users can delete their own gallery files"
-- - Policy name: "Users can delete their own gallery files"
-- - Operation: DELETE
-- - Target roles: authenticated
-- - Policy definition:
--   bucket_id = 'gallery'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- BUCKET: exhibition-images
-- Policy 1: "Users can upload exhibition images to their own folder"
-- - Policy name: "Users can upload exhibition images to their own folder"
-- - Operation: INSERT
-- - Target roles: authenticated
-- - Policy definition:
--   bucket_id = 'exhibition-images'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy 2: "Public read access to exhibition images"
-- - Policy name: "Public read access to exhibition images"
-- - Operation: SELECT
-- - Target roles: public
-- - Policy definition: bucket_id = 'exhibition-images'

-- Policy 3: "Users can update their own exhibition images"
-- - Policy name: "Users can update their own exhibition images"
-- - Operation: UPDATE
-- - Target roles: authenticated
-- - Policy definition:
--   bucket_id = 'exhibition-images'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy 4: "Users can delete their own exhibition images"
-- - Policy name: "Users can delete their own exhibition images"
-- - Operation: DELETE
-- - Target roles: authenticated
-- - Policy definition:
--   bucket_id = 'exhibition-images'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- STEP-BY-STEP INSTRUCTIONS:
-- 1. Go to Supabase Dashboard
-- 2. Navigate to Storage section
-- 3. Click on each bucket (lookbooks, gallery, exhibition-images)
-- 4. Go to the "Policies" tab
-- 5. Click "New Policy" for each policy listed above
-- 6. Fill in the policy details as specified
-- 7. Save each policy

-- NOTE: These policies ensure that:
-- - Users can only upload/update/delete files in their own folders
-- - All files are publicly readable
-- - Only authenticated users can upload files
-- - File organization is maintained by user ID folders
