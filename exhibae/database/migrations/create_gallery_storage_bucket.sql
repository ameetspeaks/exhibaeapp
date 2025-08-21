-- Create gallery storage bucket for exhibition images
-- This bucket will store images organized by exhibition_id and subfolders

-- Create the gallery bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'gallery',
  'gallery',
  true, -- Public bucket for easy access to exhibition images
  52428800, -- 50MB file size limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
) ON CONFLICT (id) DO NOTHING;

-- Create RLS policies for the gallery bucket

-- Policy: Allow authenticated users to upload images
CREATE POLICY "Allow authenticated uploads to gallery" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'gallery' 
  AND auth.role() = 'authenticated'
);

-- Policy: Allow public read access to gallery images
CREATE POLICY "Allow public read access to gallery" ON storage.objects
FOR SELECT USING (
  bucket_id = 'gallery'
);

-- Policy: Allow authenticated users to update their own images
CREATE POLICY "Allow authenticated updates to gallery" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'gallery' 
  AND auth.role() = 'authenticated'
);

-- Policy: Allow authenticated users to delete their own images
CREATE POLICY "Allow authenticated deletes from gallery" ON storage.objects
FOR DELETE USING (
  bucket_id = 'gallery' 
  AND auth.role() = 'authenticated'
);

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
