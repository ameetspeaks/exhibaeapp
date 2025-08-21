-- Gallery Storage Policies Setup
-- Run this script in Supabase SQL Editor to set up policies for the gallery bucket

-- First, ensure the gallery bucket exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'gallery',
  'gallery',
  true,
  52428800, -- 50MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
) ON CONFLICT (id) DO NOTHING;

-- Create storage policies (these should work with standard permissions)

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow public read access to gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated uploads to gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates to gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes from gallery" ON storage.objects;

-- Policy 1: Allow public read access to gallery images
CREATE POLICY "Allow public read access to gallery" ON storage.objects
FOR SELECT USING (
  bucket_id = 'gallery'
);

-- Policy 2: Allow authenticated users to upload images
CREATE POLICY "Allow authenticated uploads to gallery" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'gallery' 
  AND auth.role() = 'authenticated'
);

-- Policy 3: Allow authenticated users to update images
CREATE POLICY "Allow authenticated updates to gallery" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'gallery' 
  AND auth.role() = 'authenticated'
);

-- Policy 4: Allow authenticated users to delete images
CREATE POLICY "Allow authenticated deletes from gallery" ON storage.objects
FOR DELETE USING (
  bucket_id = 'gallery' 
  AND auth.role() = 'authenticated'
);

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
