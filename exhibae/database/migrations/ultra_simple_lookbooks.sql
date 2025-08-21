-- Ultra Simple Lookbooks Setup
-- This doesn't try to create buckets - just sets up the table and policies

-- Step 1: Create brand_lookbooks table if it doesn't exist
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

-- Step 2: Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_brand_lookbooks_brand_id ON public.brand_lookbooks(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_lookbooks_created_at ON public.brand_lookbooks(created_at);

-- Step 3: Enable RLS on brand_lookbooks table
ALTER TABLE public.brand_lookbooks ENABLE ROW LEVEL SECURITY;

-- Step 4: Create simple RLS policy for brand_lookbooks
DROP POLICY IF EXISTS "brand_lookbooks_policy" ON public.brand_lookbooks;
CREATE POLICY "brand_lookbooks_policy" ON public.brand_lookbooks
    FOR ALL USING (brand_id = auth.uid());

-- Step 5: Create updated_at trigger if it doesn't exist
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

-- Step 6: Create simple storage policies (these will work with any bucket)
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

-- Step 7: Log completion
DO $$
BEGIN
    RAISE NOTICE '✓ Ultra simple lookbooks setup completed!';
    RAISE NOTICE '✓ Created brand_lookbooks table with policies';
    RAISE NOTICE '✓ Created storage policies for lookbooks bucket';
    RAISE NOTICE '✓ The Flutter app will create the bucket automatically';
    RAISE NOTICE '✓ Ready for brand lookbook uploads!';
END $$;
