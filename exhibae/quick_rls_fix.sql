-- Quick fix: Disable RLS on otp_verifications and phone_verifications tables
-- Run this in your Supabase SQL editor

-- Disable RLS on otp_verifications table
ALTER TABLE public.otp_verifications DISABLE ROW LEVEL SECURITY;

-- Disable RLS on phone_verifications table  
ALTER TABLE public.phone_verifications DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('otp_verifications', 'phone_verifications');

-- Alternative: If you want to keep RLS enabled but make it more permissive
-- Uncomment the lines below and comment out the ALTER TABLE lines above

/*
-- Enable RLS but with permissive policies
ALTER TABLE public.otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phone_verifications ENABLE ROW LEVEL SECURITY;

-- Create very permissive policies
CREATE POLICY "Allow all operations for authenticated users" ON public.otp_verifications
    FOR ALL 
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow all operations for authenticated users" ON public.phone_verifications
    FOR ALL 
    TO authenticated
    USING (true)
    WITH CHECK (true);
*/
