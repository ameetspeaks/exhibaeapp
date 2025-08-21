-- Add images column to exhibitions table
ALTER TABLE public.exhibitions 
ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT '{}';

-- Add comment to explain the column
COMMENT ON COLUMN public.exhibitions.images IS 'Array of image URLs for the exhibition';
