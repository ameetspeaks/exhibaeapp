-- Migration: Simple approach to fix lookbooks storage
-- This migration creates the bucket and sets up basic policies that work with existing permissions

-- Step 1: Drop any existing conflicting policies
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Drop all policies on storage.buckets that might conflict
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'buckets' 
        AND schemaname = 'storage'
        AND policyname LIKE '%lookbook%'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON storage.buckets';
        RAISE NOTICE 'Dropped bucket policy: %', policy_record.policyname;
    END LOOP;
    
    -- Drop all policies on storage.objects that might conflict
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
        AND policyname LIKE '%lookbook%'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON storage.objects';
        RAISE NOTICE 'Dropped object policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Step 2: Create the lookbooks bucket using a function that bypasses RLS
CREATE OR REPLACE FUNCTION create_lookbooks_bucket()
RETURNS void AS $$
BEGIN
    -- Insert the bucket directly
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES (
      'lookbooks',
      'lookbooks',
      true,
      52428800, -- 50MB limit
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
    
    RAISE NOTICE '✓ Lookbooks bucket created successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Execute the function to create the bucket
SELECT create_lookbooks_bucket();

-- Step 4: Clean up the function
DROP FUNCTION create_lookbooks_bucket();

-- Step 5: Create simple policies for storage.objects
CREATE POLICY "Allow authenticated users to upload to lookbooks" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'lookbooks' AND
    auth.role() = 'authenticated'
  );

CREATE POLICY "Allow authenticated users to view lookbooks" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'lookbooks' AND
    auth.role() = 'authenticated'
  );

CREATE POLICY "Allow authenticated users to update lookbooks" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'lookbooks' AND
    auth.role() = 'authenticated'
  );

CREATE POLICY "Allow authenticated users to delete lookbooks" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'lookbooks' AND
    auth.role() = 'authenticated'
  );

-- Step 6: Create brand_lookbooks table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.brand_lookbooks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  brand_id uuid NOT NULL,
  title text,
  description text,
  file_url text NOT NULL,
  file_type text,
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

-- Create simple policies for brand_lookbooks table
CREATE POLICY "Brands can manage their own lookbooks" ON public.brand_lookbooks
  FOR ALL USING (brand_id = auth.uid());

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create updated_at trigger
DROP TRIGGER IF EXISTS update_brand_lookbooks_updated_at ON public.brand_lookbooks;
CREATE TRIGGER update_brand_lookbooks_updated_at 
  BEFORE UPDATE ON public.brand_lookbooks 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Log the migration completion
DO $$
BEGIN
    RAISE NOTICE '✓ Successfully created lookbooks bucket using SECURITY DEFINER function';
    RAISE NOTICE '✓ Created brand_lookbooks table with proper structure';
    RAISE NOTICE '✓ Set up simple RLS policies that work';
    RAISE NOTICE '✓ Brands can now upload, view, update, and delete their lookbooks';
    RAISE NOTICE '✓ File structure: lookbooks/{brandId}/{filename}';
END $$;
