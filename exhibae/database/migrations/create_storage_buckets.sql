-- Storage Buckets Setup Instructions
-- IMPORTANT: Storage buckets must be created manually in Supabase Dashboard
-- SQL migrations cannot create storage buckets due to permission restrictions

-- MANUAL SETUP REQUIRED:
-- 1. Go to Supabase Dashboard > Storage
-- 2. Create the following buckets manually:

-- BUCKET 1: lookbooks
-- - Name: lookbooks
-- - Public: true
-- - File size limit: 50MB
-- - Allowed MIME types: image/jpeg,image/png,image/gif,image/webp,application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.ms-powerpoint,application/vnd.openxmlformats-officedocument.presentationml.presentation,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,text/plain

-- BUCKET 2: gallery
-- - Name: gallery
-- - Public: true
-- - File size limit: 50MB
-- - Allowed MIME types: image/jpeg,image/png,image/gif,image/webp

-- BUCKET 3: exhibition-images
-- - Name: exhibition-images
-- - Public: true
-- - File size limit: 50MB
-- - Allowed MIME types: image/jpeg,image/png,image/gif,image/webp

-- After creating the buckets, run the storage policies migration
-- in Supabase Dashboard > SQL Editor using the create_storage_policies.sql file
