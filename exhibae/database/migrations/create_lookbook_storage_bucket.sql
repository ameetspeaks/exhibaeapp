-- Create lookbook storage bucket
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

-- Drop ALL existing lookbook policies to avoid conflicts
-- This ensures we start with a clean slate
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Drop all policies that reference the lookbooks bucket
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
        AND (policyname LIKE '%lookbook%' OR policyname LIKE '%Lookbook%')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON storage.objects';
        RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Create RLS policies for lookbook storage with specific names
CREATE POLICY "Lookbook upload policy" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'lookbooks' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Lookbook view policy" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'lookbooks' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Lookbook update policy" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'lookbooks' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Lookbook delete policy" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'lookbooks' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Create brand_lookbooks table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.brand_lookbooks (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  brand_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  file_type text NOT NULL,
  file_url text NOT NULL,
  file_name text,
  file_size integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT brand_lookbooks_pkey PRIMARY KEY (id),
  CONSTRAINT brand_lookbooks_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_brand_lookbooks_brand_id ON public.brand_lookbooks(brand_id);
CREATE INDEX IF NOT EXISTS idx_brand_lookbooks_created_at ON public.brand_lookbooks(created_at);

-- Enable RLS
ALTER TABLE public.brand_lookbooks ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing lookbook table policies to avoid conflicts
-- This ensures we start with a clean slate for table policies too
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Drop all policies that reference the brand_lookbooks table
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'brand_lookbooks' 
        AND schemaname = 'public'
        AND (policyname LIKE '%lookbook%' OR policyname LIKE '%Lookbook%')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON public.brand_lookbooks';
        RAISE NOTICE 'Dropped table policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Create RLS policies for brand_lookbooks table with specific names
CREATE POLICY "Brand lookbook view policy" ON public.brand_lookbooks
  FOR SELECT USING (auth.uid() = brand_id);

CREATE POLICY "Brand lookbook insert policy" ON public.brand_lookbooks
  FOR INSERT WITH CHECK (auth.uid() = brand_id);

CREATE POLICY "Brand lookbook update policy" ON public.brand_lookbooks
  FOR UPDATE USING (auth.uid() = brand_id);

CREATE POLICY "Brand lookbook delete policy" ON public.brand_lookbooks
  FOR DELETE USING (auth.uid() = brand_id);

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_brand_lookbooks_updated_at ON public.brand_lookbooks;

-- Create updated_at trigger
CREATE TRIGGER update_brand_lookbooks_updated_at 
  BEFORE UPDATE ON public.brand_lookbooks 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to automatically create storage bucket for new brands
CREATE OR REPLACE FUNCTION create_brand_storage_bucket()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create bucket for brand profiles
  IF NEW.role = 'brand' THEN
    -- Insert into storage.buckets for the new brand (shared bucket)
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES (
      'lookbooks',
      'lookbooks',
      true,
      '52428800',
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
    )
    ON CONFLICT (id) DO NOTHING;
    
    -- Create brand-specific folder in the storage bucket
    INSERT INTO storage.objects (bucket_id, name, owner, metadata)
    VALUES (
      'lookbooks',
      NEW.id || '/.folder_placeholder',
      NEW.id,
      '{"content-type": "application/octet-stream", "placeholder": "true"}'::jsonb
    )
    ON CONFLICT (bucket_id, name) DO NOTHING;
    
    RAISE NOTICE '✓ Created storage bucket and folder for new brand: % (ID: %)', 
      COALESCE(NEW.company_name, NEW.full_name), 
      NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create storage bucket when brand profile is created
DROP TRIGGER IF EXISTS trigger_create_brand_storage_bucket ON public.profiles;
CREATE TRIGGER trigger_create_brand_storage_bucket
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION create_brand_storage_bucket();

-- Create function to clean up storage bucket when brand profile is deleted
CREATE OR REPLACE FUNCTION cleanup_brand_storage_bucket()
RETURNS TRIGGER AS $$
BEGIN
  -- Only cleanup bucket for brand profiles (but keep shared bucket)
  IF OLD.role = 'brand' THEN
    -- Remove brand-specific folder and all files in it
    DELETE FROM storage.objects 
    WHERE bucket_id = 'lookbooks' 
    AND name LIKE OLD.id || '/%';
    
    -- Note: We don't delete the shared lookbooks bucket
    -- Individual brand files are cleaned up via the above DELETE
    RAISE NOTICE '✓ Cleaned up storage folder for deleted brand: % (ID: %). Shared lookbooks bucket remains.', 
      COALESCE(OLD.company_name, OLD.full_name), 
      OLD.id;
  END IF;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically cleanup storage bucket when brand profile is deleted
DROP TRIGGER IF EXISTS trigger_cleanup_brand_storage_bucket ON public.profiles;
CREATE TRIGGER trigger_cleanup_brand_storage_bucket
  AFTER DELETE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_brand_storage_bucket();

-- Migration: Create storage buckets for all existing brands
-- This ensures all current brands have their storage buckets set up

-- Create function to create storage bucket for existing brands
CREATE OR REPLACE FUNCTION create_storage_buckets_for_existing_brands()
RETURNS void AS $$
DECLARE
    brand_record RECORD;
    brands_count INTEGER := 0;
BEGIN
    -- Count total brands
    SELECT COUNT(*) INTO brands_count 
    FROM public.profiles 
    WHERE role = 'brand';
    
    RAISE NOTICE 'Found % existing brand(s)', brands_count;
    
    -- Create shared lookbooks bucket if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM storage.buckets 
        WHERE id = 'lookbooks'
    ) THEN
        -- Create shared storage bucket for all brands
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'lookbooks',
            'lookbooks',
            true,
            '52428800',
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
        );
        
        RAISE NOTICE '✓ Created shared lookbooks bucket for all brands';
    ELSE
        RAISE NOTICE '○ Shared lookbooks bucket already exists';
    END IF;
    
    -- Log all brands that can now use the shared bucket
    FOR brand_record IN 
        SELECT id, full_name, company_name 
        FROM public.profiles 
        WHERE role = 'brand'
        ORDER BY created_at
    LOOP
        RAISE NOTICE 'Brand can use shared bucket: % (ID: %)', 
            COALESCE(brand_record.company_name, brand_record.full_name), 
            brand_record.id;
    END LOOP;
    
    RAISE NOTICE 'Migration completed: Shared lookbooks bucket ready for all brands';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Execute the migration to create buckets for existing brands
SELECT create_storage_buckets_for_existing_brands();

-- Clean up the migration function
DROP FUNCTION create_storage_buckets_for_existing_brands();
