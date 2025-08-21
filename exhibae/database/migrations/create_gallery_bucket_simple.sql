-- Create gallery storage bucket and brand_gallery table
-- This migration sets up the gallery storage system similar to lookbooks

-- Create gallery storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'gallery',
  'gallery',
  true,
  52428800, -- 50MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
) ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated uploads to gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates to gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes from gallery" ON storage.objects;

-- Create RLS policies for storage.objects (gallery bucket)
CREATE POLICY "Allow authenticated uploads to gallery" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'gallery' AND auth.role() = 'authenticated'
  );

CREATE POLICY "Allow public read access to gallery" ON storage.objects
  FOR SELECT USING (bucket_id = 'gallery');

CREATE POLICY "Allow authenticated updates to gallery" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'gallery' AND auth.role() = 'authenticated'
  );

CREATE POLICY "Allow authenticated deletes from gallery" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'gallery' AND auth.role() = 'authenticated'
  );

-- Create brand_gallery table
CREATE TABLE IF NOT EXISTS public.brand_gallery (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  brand_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  description TEXT,
  image_url TEXT NOT NULL,
  file_name TEXT,
  file_size INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_brand_gallery_brand_id ON public.brand_gallery(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_gallery_created_at ON public.brand_gallery(created_at);

-- Enable RLS on brand_gallery table
ALTER TABLE public.brand_gallery ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "brand_gallery_policy" ON public.brand_gallery;

-- Create RLS policy for brand_gallery
CREATE POLICY "brand_gallery_policy" ON public.brand_gallery
  FOR ALL USING (brand_id = auth.uid());

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_brand_gallery_updated_at ON public.brand_gallery;

-- Create trigger for updated_at
CREATE TRIGGER update_brand_gallery_updated_at
  BEFORE UPDATE ON public.brand_gallery
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
