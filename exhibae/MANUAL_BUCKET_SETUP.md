# Manual Bucket Setup Instructions

Since automatic bucket creation from the Flutter app is restricted by RLS policies, you need to create the `profile-avatars` bucket manually in the Supabase Dashboard.

## Step-by-Step Instructions

### 1. Create the Storage Bucket

1. **Go to Supabase Dashboard**
   - Open your Supabase project dashboard
   - Navigate to **Storage** in the left sidebar

2. **Create New Bucket**
   - Click **"Create a new bucket"** button
   - Fill in the following details:
     - **Name**: `profile-avatars` (exactly as shown)
     - **Public bucket**: ✅ **Enable** (check this box)
     - **File size limit**: `10MB`
     - **Allowed MIME types**: 
       - `image/jpeg`
       - `image/png`
       - `image/gif`
       - `image/webp`

3. **Save the Bucket**
   - Click **"Create bucket"** to save

### 2. Run the Database Migration

1. **Go to SQL Editor**
   - In Supabase Dashboard, navigate to **SQL Editor**

2. **Run the Migration**
   - Copy and paste the contents of `database/migrations/create_profile_avatars_bucket.sql`
   - Click **"Run"** to execute the SQL

### 3. Test the Setup

1. **Try Profile Picture Upload**
   - Go to any profile edit screen in your app
   - Try uploading a profile picture
   - It should work now!

2. **Check Console Logs**
   - Monitor the console for success messages
   - You should see: "profile-avatars bucket already exists"

## Expected Behavior

After manual setup:
- ✅ Bucket creation attempts will show "bucket already exists"
- ✅ Profile picture uploads will work
- ✅ Company logo uploads will work (for brands/organizers)
- ✅ No more "Unauthorized" errors

## Troubleshooting

If you still get errors:

1. **Verify Bucket Name**: Ensure the bucket is named exactly `profile-avatars`
2. **Check Public Setting**: Make sure "Public bucket" is enabled
3. **Verify MIME Types**: Ensure image types are allowed
4. **Check Storage Policies**: Run the SQL migration to create policies

## Success Indicators

You'll know it's working when:
- Console shows: "profile-avatars bucket already exists"
- Profile picture upload completes successfully
- No "Unauthorized" or "Bucket not found" errors
