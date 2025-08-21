-- Fresh Lookbooks Setup - Complete Reset
-- This migration deletes everything and starts fresh with a simple approach

-- Step 1: Drop existing brand_lookbooks table if it exists
DROP TABLE IF EXISTS public.brand_lookbooks CASCADE;

-- Step 2: Drop any existing lookbook-related policies
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Drop all policies on storage.objects that contain 'lookbook'
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
        AND (policyname ILIKE '%lookbook%' OR policyname ILIKE '%Lookbook%')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON storage.objects';
        RAISE NOTICE 'Dropped object policy: %', policy_record.policyname;
    END LOOP;
    
    -- Drop all policies on storage.buckets that contain 'lookbook'
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'buckets' 
        AND schemaname = 'storage'
        AND (policyname ILIKE '%lookbook%' OR policyname ILIKE '%Lookbook%')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON storage.buckets';
        RAISE NOTICE 'Dropped bucket policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Step 3: Delete any existing lookbooks bucket and its contents
DELETE FROM storage.objects WHERE bucket_id = 'lookbooks';
DELETE FROM storage.buckets WHERE id = 'lookbooks';

-- Step 4: Create a simple function to create the bucket with proper permissions
CREATE OR REPLACE FUNCTION setup_lookbooks_storage()
RETURNS void AS $$
BEGIN
    -- Create the lookbooks bucket
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
    
    RAISE NOTICE '✓ Created lookbooks bucket';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Execute the function to create the bucket
SELECT setup_lookbooks_storage();

-- Step 6: Clean up the function
DROP FUNCTION setup_lookbooks_storage();

-- Step 7: Create simple, working policies for storage.objects
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

-- Step 8: Create the brand_lookbooks table with simple structure
CREATE TABLE public.brand_lookbooks (
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

-- Step 9: Create indexes
CREATE INDEX idx_brand_lookbooks_brand_id ON public.brand_lookbooks(brand_id);
CREATE INDEX idx_brand_lookbooks_created_at ON public.brand_lookbooks(created_at);

-- Step 10: Enable RLS on brand_lookbooks table
ALTER TABLE public.brand_lookbooks ENABLE ROW LEVEL SECURITY;

-- Step 11: Create simple RLS policy for brand_lookbooks
CREATE POLICY "brand_lookbooks_policy" ON public.brand_lookbooks
    FOR ALL USING (brand_id = auth.uid());

-- Step 12: Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_brand_lookbooks_updated_at 
    BEFORE UPDATE ON public.brand_lookbooks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 13: Log completion
DO $$
BEGIN
    RAISE NOTICE '✓ Fresh lookbooks setup completed successfully';
    RAISE NOTICE '✓ Deleted all existing lookbook data and policies';
    RAISE NOTICE '✓ Created new lookbooks bucket with simple policies';
    RAISE NOTICE '✓ Created brand_lookbooks table with minimal structure';
    RAISE NOTICE '✓ Set up RLS policies for both storage and database';
    RAISE NOTICE '✓ Ready for brand lookbook uploads!';
END $$;
