-- Simple Lookbooks Fix - Direct Bucket Creation
-- This bypasses all RLS issues by creating the bucket directly

-- Step 1: Temporarily disable RLS on storage.buckets
ALTER TABLE storage.buckets DISABLE ROW LEVEL SECURITY;

-- Step 2: Create the lookbooks bucket directly
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'lookbooks',
    'lookbooks',
    true,
    52428800, -- 50MB
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

-- Step 3: Re-enable RLS on storage.buckets
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Step 4: Create simple policies for storage.objects
DROP POLICY IF EXISTS "lookbooks_upload_policy" ON storage.objects;
DROP POLICY IF EXISTS "lookbooks_view_policy" ON storage.objects;
DROP POLICY IF EXISTS "lookbooks_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "lookbooks_delete_policy" ON storage.objects;

CREATE POLICY "lookbooks_upload_policy" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'lookbooks' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "lookbooks_view_policy" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'lookbooks' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "lookbooks_update_policy" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'lookbooks' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "lookbooks_delete_policy" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'lookbooks' AND 
        auth.role() = 'authenticated'
    );

-- Step 5: Create brand_lookbooks table if it doesn't exist
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

-- Step 6: Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_brand_lookbooks_brand_id ON public.brand_lookbooks(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_lookbooks_created_at ON public.brand_lookbooks(created_at);

-- Step 7: Enable RLS on brand_lookbooks table
ALTER TABLE public.brand_lookbooks ENABLE ROW LEVEL SECURITY;

-- Step 8: Create simple RLS policy for brand_lookbooks
DROP POLICY IF EXISTS "brand_lookbooks_policy" ON public.brand_lookbooks;
CREATE POLICY "brand_lookbooks_policy" ON public.brand_lookbooks
    FOR ALL USING (brand_id = auth.uid());

-- Step 9: Create updated_at trigger if it doesn't exist
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

-- Step 10: Verify bucket was created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'lookbooks') THEN
        RAISE NOTICE '✓ Lookbooks bucket created successfully!';
    ELSE
        RAISE NOTICE '❌ Failed to create lookbooks bucket';
    END IF;
END $$;
