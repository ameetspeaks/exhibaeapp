-- Migration: Create storage buckets for all existing brands
-- This migration ensures all current brands have their storage buckets set up
-- Run this migration after the main lookbook storage bucket migration

-- Create function to create storage bucket for existing brands
CREATE OR REPLACE FUNCTION create_storage_buckets_for_existing_brands()
RETURNS void AS $$
DECLARE
    brand_record RECORD;
    brands_count INTEGER := 0;
    bucket_created BOOLEAN := false;
    folders_created INTEGER := 0;
BEGIN
    -- Count total brands
    SELECT COUNT(*) INTO brands_count 
    FROM public.profiles 
    WHERE role = 'brand';
    
    RAISE NOTICE 'Found % existing brand(s) to process', brands_count;
    
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
        
        bucket_created := true;
        RAISE NOTICE '✓ Created shared lookbooks bucket for all brands';
    ELSE
        RAISE NOTICE '○ Shared lookbooks bucket already exists';
    END IF;
    
    -- Create brand-specific folders in the storage bucket
    RAISE NOTICE '';
    RAISE NOTICE '=== CREATING BRAND FOLDERS ===';
    FOR brand_record IN 
        SELECT id, full_name, company_name, email
        FROM public.profiles 
        WHERE role = 'brand'
        ORDER BY created_at
    LOOP
        -- Create a placeholder file to establish the brand folder
        -- This ensures the folder structure exists in the storage bucket
        INSERT INTO storage.objects (bucket_id, name, owner, metadata)
        VALUES (
            'lookbooks',
            brand_record.id || '/.folder_placeholder',
            brand_record.id,
            '{"content-type": "application/octet-stream", "placeholder": "true"}'::jsonb
        )
        ON CONFLICT (bucket_id, name) DO NOTHING;
        
        -- Check if folder was created (placeholder file exists)
        IF EXISTS (
            SELECT 1 FROM storage.objects 
            WHERE bucket_id = 'lookbooks' 
            AND name = brand_record.id || '/.folder_placeholder'
        ) THEN
            folders_created := folders_created + 1;
            RAISE NOTICE '✓ Created folder for brand: % (ID: %)', 
                COALESCE(brand_record.company_name, brand_record.full_name), 
                brand_record.id;
        ELSE
            RAISE NOTICE '○ Folder already exists for brand: % (ID: %)', 
                COALESCE(brand_record.company_name, brand_record.full_name), 
                brand_record.id;
        END IF;
    END LOOP;
    
    -- Summary
    RAISE NOTICE '';
    RAISE NOTICE '=== MIGRATION SUMMARY ===';
    RAISE NOTICE 'Total brands processed: %', brands_count;
    RAISE NOTICE 'Shared bucket created: %', CASE WHEN bucket_created THEN 'Yes' ELSE 'No (already existed)' END;
    RAISE NOTICE 'Brand folders created: %', folders_created;
    RAISE NOTICE 'Storage structure: lookbooks/{brandId}/{filename}';
    RAISE NOTICE 'Migration completed successfully!';
    RAISE NOTICE '========================';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Execute the migration to create buckets for existing brands
SELECT create_storage_buckets_for_existing_brands();

-- Clean up the migration function
DROP FUNCTION create_storage_buckets_for_existing_brands();

-- Verify the migration by checking the shared bucket
DO $$
DECLARE
    total_brands INTEGER;
    bucket_exists BOOLEAN;
BEGIN
    -- Count brands
    SELECT COUNT(*) INTO total_brands 
    FROM public.profiles 
    WHERE role = 'brand';
    
    -- Check if shared bucket exists
    SELECT EXISTS(
        SELECT 1 FROM storage.buckets 
        WHERE id = 'lookbooks'
    ) INTO bucket_exists;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION ===';
    RAISE NOTICE 'Total brands: %', total_brands;
    RAISE NOTICE 'Shared lookbooks bucket exists: %', CASE WHEN bucket_exists THEN 'Yes' ELSE 'No' END;
    
    IF bucket_exists THEN
        RAISE NOTICE '✓ All brands can use the shared lookbooks bucket!';
        RAISE NOTICE '  Storage path: lookbooks/{brandId}/{filename}';
    ELSE
        RAISE NOTICE '⚠ Warning: Shared lookbooks bucket not found';
    END IF;
    RAISE NOTICE '==================';
END $$;
