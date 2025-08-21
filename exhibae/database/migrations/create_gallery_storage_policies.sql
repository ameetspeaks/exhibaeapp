-- Gallery Storage Bucket Setup
-- This migration creates the gallery bucket for exhibition images
-- Note: Storage policies are managed through Supabase Dashboard

-- Create the gallery bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'gallery',
  'gallery',
  true, -- Public bucket for easy access to exhibition images
  52428800, -- 50MB file size limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
) ON CONFLICT (id) DO NOTHING;

-- Note: Storage policies need to be created manually in Supabase Dashboard
-- Go to Storage > Policies and add the following policies:

/*
Policy 1: Allow public read access
- Policy Name: "Allow public read access to gallery"
- Target Roles: public
- Using expression: bucket_id = 'gallery'

Policy 2: Allow authenticated uploads
- Policy Name: "Allow authenticated uploads to gallery"
- Target Roles: authenticated
- Using expression: bucket_id = 'gallery' AND auth.role() = 'authenticated'

Policy 3: Allow authenticated updates
- Policy Name: "Allow authenticated updates to gallery"
- Target Roles: authenticated
- Using expression: bucket_id = 'gallery' AND auth.role() = 'authenticated'

Policy 4: Allow authenticated deletes
- Policy Name: "Allow authenticated deletes from gallery"
- Target Roles: authenticated
- Using expression: bucket_id = 'gallery' AND auth.role() = 'authenticated'
*/
