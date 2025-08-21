-- Create Gallery Bucket and Policies
-- Run this script in Supabase SQL Editor

-- Step 1: Create the gallery bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'gallery',
  'gallery',
  true,
  52428800, -- 50MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
) ON CONFLICT (id) DO NOTHING;

-- Step 2: Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 3: Create policies for the gallery bucket

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow public read access to gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated uploads to gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates to gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes from gallery" ON storage.objects;

-- Policy 1: Allow public read access
CREATE POLICY "Allow public read access to gallery" ON storage.objects
FOR SELECT USING (
  bucket_id = 'gallery'
);

-- Policy 2: Allow authenticated uploads
CREATE POLICY "Allow authenticated uploads to gallery" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'gallery' 
  AND auth.role() = 'authenticated'
);

-- Policy 3: Allow authenticated updates
CREATE POLICY "Allow authenticated updates to gallery" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'gallery' 
  AND auth.role() = 'authenticated'
);

-- Policy 4: Allow authenticated deletes
CREATE POLICY "Allow authenticated deletes from gallery" ON storage.objects
FOR DELETE USING (
  bucket_id = 'gallery' 
  AND auth.role() = 'authenticated'
);

-- Step 4: Verify the bucket was created
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'gallery';

-- Step 5: List all buckets to verify
SELECT id, name, public FROM storage.buckets;
