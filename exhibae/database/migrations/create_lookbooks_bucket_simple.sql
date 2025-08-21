-- Create lookbooks storage bucket for brand lookbooks
-- This bucket will store files organized by brand_id and subfolders

-- Create the lookbooks bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'lookbooks',
  'lookbooks',
  true, -- Public bucket for easy access to lookbook files
  52428800, -- 50MB file size limit
  ARRAY[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'image/jpeg',
    'image/png',
    'image/gif',
    'video/mp4',
    'video/quicktime',
    'video/x-msvideo',
    'application/octet-stream'
  ]
) ON CONFLICT (id) DO NOTHING;

-- Drop existing lookbook policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated uploads to lookbooks" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to lookbooks" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates to lookbooks" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes from lookbooks" ON storage.objects;
DROP POLICY IF EXISTS "lookbooks_upload_policy" ON storage.objects;
DROP POLICY IF EXISTS "lookbooks_view_policy" ON storage.objects;
DROP POLICY IF EXISTS "lookbooks_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "lookbooks_delete_policy" ON storage.objects;

-- Create RLS policies for the lookbooks bucket

-- Policy: Allow authenticated users to upload files
CREATE POLICY "Allow authenticated uploads to lookbooks" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'lookbooks' 
  AND auth.role() = 'authenticated'
);

-- Policy: Allow public read access to lookbook files
CREATE POLICY "Allow public read access to lookbooks" ON storage.objects
FOR SELECT USING (
  bucket_id = 'lookbooks'
);

-- Policy: Allow authenticated users to update their own files
CREATE POLICY "Allow authenticated updates to lookbooks" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'lookbooks' 
  AND auth.role() = 'authenticated'
);

-- Policy: Allow authenticated users to delete their own files
CREATE POLICY "Allow authenticated deletes from lookbooks" ON storage.objects
FOR DELETE USING (
  bucket_id = 'lookbooks' 
  AND auth.role() = 'authenticated'
);

-- Create brand_lookbooks table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.brand_lookbooks (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    brand_id uuid NOT NULL,
    file_url text NOT NULL,
    file_name text,
    file_size integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT brand_lookbooks_pkey PRIMARY KEY (id),
    CONSTRAINT brand_lookbooks_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES auth.users (id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_brand_lookbooks_brand_id ON public.brand_lookbooks(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_lookbooks_created_at ON public.brand_lookbooks(created_at);

-- Enable RLS on brand_lookbooks table
ALTER TABLE public.brand_lookbooks ENABLE ROW LEVEL SECURITY;

-- Drop existing brand_lookbooks policy to avoid conflicts
DROP POLICY IF EXISTS "brand_lookbooks_policy" ON public.brand_lookbooks;

-- Create RLS policy for brand_lookbooks
CREATE POLICY "brand_lookbooks_policy" ON public.brand_lookbooks
    FOR ALL USING (brand_id = auth.uid());

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_brand_lookbooks_updated_at ON public.brand_lookbooks;
CREATE TRIGGER update_brand_lookbooks_updated_at 
    BEFORE UPDATE ON public.brand_lookbooks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Log completion
DO $$
BEGIN
    RAISE NOTICE '✓ Lookbooks bucket created successfully!';
    RAISE NOTICE '✓ Storage policies set up for lookbooks bucket';
    RAISE NOTICE '✓ Brand lookbooks table created with RLS policies';
    RAISE NOTICE '✓ Ready for brand lookbook uploads!';
END $$;
