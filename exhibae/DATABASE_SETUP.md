# Database Setup for Shopper Features

## Overview
The shopper features require two new database tables to be created in your Supabase database:
- `exhibition_attendees` - Tracks which users are attending which exhibitions
- `brand_favorites` - Tracks which users have favorited which brands

## Running the Migration

### Option 1: Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of `database/migrations/create_shopper_tables.sql`
4. Paste and run the SQL commands

### Option 2: Supabase CLI
If you have Supabase CLI installed:
```bash
supabase db push
```

### Option 3: Direct SQL Execution
1. Connect to your Supabase database
2. Execute the SQL commands from `database/migrations/create_shopper_tables.sql`

## What the Migration Creates

### Tables
1. **exhibition_attendees**
   - Tracks user attendance at exhibitions
   - Prevents duplicate attendance records
   - Links to `auth.users` and `exhibitions` tables

2. **brand_favorites**
   - Tracks user favorites for brands
   - Prevents duplicate favorite records
   - Links to `auth.users` and `profiles` tables

### Security Policies
- Row Level Security (RLS) enabled on both tables
- Users can only view, insert, and delete their own records
- Secure access control for user data

### Performance Indexes
- Indexes on user_id and foreign key columns
- Optimized for fast queries

## Verification
After running the migration, you can verify the tables were created by:
1. Going to **Table Editor** in Supabase Dashboard
2. Checking that both tables exist
3. Verifying RLS policies are active

## Troubleshooting
If you encounter errors:
1. Make sure you have the necessary permissions
2. Check that the referenced tables (`exhibitions`, `profiles`) exist
3. Verify your Supabase project is properly configured
