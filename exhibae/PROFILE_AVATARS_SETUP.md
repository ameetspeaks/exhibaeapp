# Profile Avatars and Company Logo Setup

This guide explains how to set up the profile-avatars storage bucket and enable company logo functionality for brands and organizers.

## Overview

The profile-avatars bucket handles two types of images:
1. **Profile Pictures** - Personal profile photos for all users
2. **Company Logos** - Business logos for brands and organizers

## Database Migration

First, run the database migration to add the company_logo_url field to the profiles table:

```sql
-- Run this in Supabase Dashboard > SQL Editor
-- Update profiles table to add company_logo_url field
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS company_logo_url TEXT;

-- Add comment to explain the field
COMMENT ON COLUMN profiles.company_logo_url IS 'URL to the company logo image for brands and organizers';

-- Create index for better performance on company_logo_url queries
CREATE INDEX IF NOT EXISTS idx_profiles_company_logo_url ON profiles(company_logo_url) WHERE company_logo_url IS NOT NULL;
```

## Storage Bucket Setup

### 1. Create the Storage Bucket

1. Go to **Supabase Dashboard** > **Storage**
2. Click **"Create a new bucket"**
3. Configure the bucket:
   - **Name**: `profile-avatars`
   - **Public bucket**: ✅ **Enable** (checked)
   - **File size limit**: `10MB`
   - **Allowed MIME types**: 
     - `image/jpeg`
     - `image/png`
     - `image/gif`
     - `image/webp`

### 2. Create Storage Policies

Run the following SQL in **Supabase Dashboard** > **SQL Editor**:

```sql
-- Create storage policies for profile-avatars bucket
-- Policy 1: "Users can upload their own profile pictures"
CREATE POLICY "Users can upload their own profile pictures" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-avatars' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
        AND (storage.foldername(name))[2] LIKE 'profile_' || auth.uid()::text || '_%'
    );

-- Policy 2: "Public read access to profile pictures"
CREATE POLICY "Public read access to profile pictures" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'profile-avatars');

-- Policy 3: "Users can update their own profile pictures"
CREATE POLICY "Users can update their own profile pictures" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
        AND (storage.foldername(name))[2] LIKE 'profile_' || auth.uid()::text || '_%'
    );

-- Policy 4: "Users can delete their own profile pictures"
CREATE POLICY "Users can delete their own profile pictures" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
        AND (storage.foldername(name))[2] LIKE 'profile_' || auth.uid()::text || '_%'
    );

-- Policy 5: "Users can upload their own company logos"
CREATE POLICY "Users can upload their own company logos" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-avatars' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'logos'
        AND (storage.foldername(name))[2] LIKE 'logo_' || auth.uid()::text || '_%'
    );

-- Policy 6: "Users can update their own company logos"
CREATE POLICY "Users can update their own company logos" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'logos'
        AND (storage.foldername(name))[2] LIKE 'logo_' || auth.uid()::text || '_%'
    );

-- Policy 7: "Users can delete their own company logos"
CREATE POLICY "Users can delete their own company logos" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'profile-avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'logos'
        AND (storage.foldername(name))[2] LIKE 'logo_' || auth.uid()::text || '_%'
    );
```

## File Structure

The bucket will organize files as follows:

```
profile-avatars/
├── avatars/
│   ├── profile_user123_1234567890.jpg
│   ├── profile_user456_1234567891.png
│   └── ...
└── logos/
    ├── logo_user123_1234567890.jpg
    ├── logo_user456_1234567891.png
    └── ...
```

## Features

### Profile Pictures
- Available for all user types (shoppers, brands, organizers)
- Stored in `avatars/` folder
- File naming: `profile_{userId}_{timestamp}.{extension}`

### Company Logos
- Available for brands and organizers only
- Stored in `logos/` folder
- File naming: `logo_{userId}_{timestamp}.{extension}`

## Usage in Flutter App

### Profile Pictures
```dart
ProfilePictureWidget(
  userId: currentUser.id,
  currentAvatarUrl: profile['avatar_url'],
  size: 100,
  showEditButton: true,
  showDeleteButton: true,
  onAvatarChanged: (url) => print('Avatar changed: $url'),
  onAvatarDeleted: () => print('Avatar deleted'),
)
```

### Company Logos
```dart
CompanyLogoWidget(
  userId: currentUser.id,
  currentLogoUrl: profile['company_logo_url'],
  size: 100,
  showEditButton: true,
  showDeleteButton: true,
  onLogoChanged: (url) => print('Logo changed: $url'),
  onLogoDeleted: () => print('Logo deleted'),
)
```

## API Methods

The following methods are available in `SupabaseService`:

### Profile Pictures
- `uploadProfilePicture(userId, filePath)`
- `uploadProfilePictureFromBytes(userId, fileBytes, fileName)`
- `deleteProfilePicture(userId)`

### Company Logos
- `uploadCompanyLogo(userId, filePath)`
- `uploadCompanyLogoFromBytes(userId, fileBytes, fileName)`
- `deleteCompanyLogo(userId)`

## Troubleshooting

### Common Issues

1. **"Bucket not found" error**
   - Ensure the `profile-avatars` bucket exists in Supabase Storage
   - Check that the bucket name is exactly `profile-avatars`

2. **"Unauthorized" error**
   - Verify that the storage policies are correctly applied
   - Check that the user is authenticated

3. **"RLS policy violation" error**
   - Ensure the storage policies allow the current user to perform the operation
   - Check that the file path matches the policy requirements

### Debug Logs

The app includes debug logs for troubleshooting:
- Profile picture upload attempts
- Company logo upload attempts
- Bucket creation attempts
- Error messages with details

Check the console output for these logs when troubleshooting upload issues.

### Debug Widget

A debug widget is available to help troubleshoot storage issues:

```dart
// Navigate to the debug screen
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const StorageDebugWidget(),
  ),
);
```

The debug widget provides:
- Real-time bucket status information
- Manual bucket creation capability
- Detailed error reporting
- List of all available storage buckets

### Enhanced Error Handling

The app now includes enhanced error handling for storage bucket creation:

1. **Automatic Bucket Creation**: The app attempts to create the bucket automatically when needed
2. **Fallback Mechanism**: If automatic creation fails, users are notified with clear error messages
3. **Debug Information**: Comprehensive logging helps identify issues quickly
4. **User-Friendly Messages**: Clear feedback about what went wrong and how to resolve it

### Testing the Setup

To test if everything is working:

1. **Use the Debug Widget**: Navigate to the storage debug screen to check bucket status
2. **Try Profile Picture Upload**: Attempt to upload a profile picture and check for success
3. **Check Console Logs**: Monitor the console for detailed debug information
4. **Verify Database**: Check that the `company_logo_url` field exists in the profiles table
