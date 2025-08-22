-- Fix RLS policies for otp_verifications table
-- Run this in your Supabase SQL editor

-- First, let's check the current RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'otp_verifications';

-- Check if RLS is enabled on the table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'otp_verifications';

-- Drop existing restrictive policies (if any)
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.otp_verifications;
DROP POLICY IF EXISTS "Enable read for authenticated users only" ON public.otp_verifications;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON public.otp_verifications;
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON public.otp_verifications;

-- Create more permissive policies for otp_verifications
-- Allow inserts for any authenticated user
CREATE POLICY "Enable insert for authenticated users" ON public.otp_verifications
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

-- Allow reads for authenticated users
CREATE POLICY "Enable read for authenticated users" ON public.otp_verifications
    FOR SELECT 
    TO authenticated
    USING (true);

-- Allow updates for authenticated users
CREATE POLICY "Enable update for authenticated users" ON public.otp_verifications
    FOR UPDATE 
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Allow deletes for authenticated users
CREATE POLICY "Enable delete for authenticated users" ON public.otp_verifications
    FOR DELETE 
    TO authenticated
    USING (true);

-- Also check and fix phone_verifications table if needed
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'phone_verifications';

-- Drop existing restrictive policies for phone_verifications (if any)
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.phone_verifications;
DROP POLICY IF EXISTS "Enable read for authenticated users only" ON public.phone_verifications;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON public.phone_verifications;
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON public.phone_verifications;

-- Create more permissive policies for phone_verifications
CREATE POLICY "Enable insert for authenticated users" ON public.phone_verifications
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Enable read for authenticated users" ON public.phone_verifications
    FOR SELECT 
    TO authenticated
    USING (true);

CREATE POLICY "Enable update for authenticated users" ON public.phone_verifications
    FOR UPDATE 
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users" ON public.phone_verifications
    FOR DELETE 
    TO authenticated
    USING (true);

-- Verify the policies were created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename IN ('otp_verifications', 'phone_verifications')
ORDER BY tablename, cmd;
