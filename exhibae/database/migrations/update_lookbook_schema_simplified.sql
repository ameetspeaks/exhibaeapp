-- Migration: Update brand_lookbooks table schema for simplified form
-- This migration makes title and file_type nullable since we removed these fields from the UI

-- Update the brand_lookbooks table to make title nullable
ALTER TABLE public.brand_lookbooks 
ALTER COLUMN title DROP NOT NULL;

-- Update the brand_lookbooks table to make file_type nullable (auto-detected from file extension)
ALTER TABLE public.brand_lookbooks 
ALTER COLUMN file_type DROP NOT NULL;

-- Add file_name and file_size columns if they don't exist (for better file metadata)
DO $$
BEGIN
    -- Add file_name column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'brand_lookbooks' 
        AND column_name = 'file_name'
    ) THEN
        ALTER TABLE public.brand_lookbooks ADD COLUMN file_name text;
    END IF;
    
    -- Add file_size column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'brand_lookbooks' 
        AND column_name = 'file_size'
    ) THEN
        ALTER TABLE public.brand_lookbooks ADD COLUMN file_size integer;
    END IF;
END $$;

-- Add a comment to document the schema change
COMMENT ON TABLE public.brand_lookbooks IS 'Simplified lookbook storage - title and file_type are now optional, auto-detected from file metadata';

-- Update existing records to set file_type based on file_url extension if file_type is null
UPDATE public.brand_lookbooks 
SET file_type = CASE 
    WHEN file_url LIKE '%.pdf' THEN 'pdf'
    WHEN file_url LIKE '%.doc' OR file_url LIKE '%.docx' THEN 'document'
    WHEN file_url LIKE '%.ppt' OR file_url LIKE '%.pptx' THEN 'presentation'
    WHEN file_url LIKE '%.xls' OR file_url LIKE '%.xlsx' THEN 'spreadsheet'
    WHEN file_url LIKE '%.jpg' OR file_url LIKE '%.jpeg' OR file_url LIKE '%.png' OR file_url LIKE '%.gif' THEN 'image'
    WHEN file_url LIKE '%.mp4' OR file_url LIKE '%.mov' OR file_url LIKE '%.avi' THEN 'video'
    ELSE 'unknown'
END
WHERE file_type IS NULL AND file_url IS NOT NULL;

-- Update existing records to set file_name based on file_url if file_name is null
-- Use a simpler approach to extract filename from URL
UPDATE public.brand_lookbooks 
SET file_name = SPLIT_PART(file_url, '/', -1)
WHERE file_name IS NULL AND file_url IS NOT NULL;

-- Log the migration completion
DO $$
BEGIN
    RAISE NOTICE '✓ Updated brand_lookbooks schema: title and file_type are now nullable';
    RAISE NOTICE '✓ Added file_name and file_size columns for better metadata';
    RAISE NOTICE '✓ Updated existing records with auto-detected file types and names';
    RAISE NOTICE '✓ Schema is now compatible with simplified lookbook form';
END $$;
