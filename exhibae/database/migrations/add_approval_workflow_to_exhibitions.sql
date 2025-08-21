-- Add approval workflow to exhibitions table
-- This migration adds approval workflow functionality using existing status column

-- Step 1: Add approval-related columns to exhibitions table
ALTER TABLE public.exhibitions 
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS submitted_for_approval_at TIMESTAMP WITH TIME ZONE;

-- Step 2: Create index for faster approval status queries
CREATE INDEX IF NOT EXISTS idx_exhibitions_submitted_at ON public.exhibitions(submitted_for_approval_at);

-- Step 3: Update existing exhibitions to have proper status
-- Keep existing status values but ensure they align with approval workflow
UPDATE public.exhibitions 
SET status = CASE 
    WHEN status = 'published' THEN 'approved'
    WHEN status = 'draft' THEN 'draft'
    ELSE 'draft'
END
WHERE status NOT IN ('draft', 'pending_approval', 'approved', 'rejected');

-- Step 3.1: Add constraint to ensure status values are valid
ALTER TABLE public.exhibitions 
ADD CONSTRAINT IF NOT EXISTS exhibitions_status_check 
CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected'));

-- Step 4: Create RLS policies for approval workflow

-- Policy: Organizers can view their own exhibitions
DROP POLICY IF EXISTS "Organizers can view own exhibitions" ON public.exhibitions;
CREATE POLICY "Organizers can view own exhibitions" ON public.exhibitions
FOR SELECT USING (
    auth.uid() = organiser_id
);

-- Policy: Organizers can update their own exhibitions (only if not approved)
DROP POLICY IF EXISTS "Organizers can update own exhibitions" ON public.exhibitions;
CREATE POLICY "Organizers can update own exhibitions" ON public.exhibitions
FOR UPDATE USING (
    auth.uid() = organiser_id AND 
    status IN ('draft', 'rejected')
);

-- Policy: Organizers can submit for approval
DROP POLICY IF EXISTS "Organizers can submit for approval" ON public.exhibitions;
CREATE POLICY "Organizers can submit for approval" ON public.exhibitions
FOR UPDATE USING (
    auth.uid() = organiser_id AND 
    status = 'draft'
);

-- Policy: Managers/Admins can view all exhibitions
DROP POLICY IF EXISTS "Managers can view all exhibitions" ON public.exhibitions;
CREATE POLICY "Managers can view all exhibitions" ON public.exhibitions
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('manager', 'admin')
    )
);

-- Policy: Managers/Admins can approve/reject exhibitions
DROP POLICY IF EXISTS "Managers can approve exhibitions" ON public.exhibitions;
CREATE POLICY "Managers can approve exhibitions" ON public.exhibitions
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('manager', 'admin')
    ) AND 
    status = 'pending_approval'
);

-- Policy: Public can view approved exhibitions
DROP POLICY IF EXISTS "Public can view approved exhibitions" ON public.exhibitions;
CREATE POLICY "Public can view approved exhibitions" ON public.exhibitions
FOR SELECT USING (
    status = 'approved'
);

-- Step 5: Create function to handle approval submission
CREATE OR REPLACE FUNCTION submit_exhibition_for_approval(exhibition_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.exhibitions 
    SET 
        status = 'pending_approval',
        submitted_for_approval_at = NOW(),
        updated_at = NOW()
    WHERE 
        id = exhibition_id 
        AND organiser_id = auth.uid()
        AND status = 'draft';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Create function to handle approval/rejection
CREATE OR REPLACE FUNCTION approve_exhibition(
    exhibition_id UUID, 
    is_approved BOOLEAN, 
    rejection_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user is manager/admin
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('manager', 'admin')
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Update exhibition status
    UPDATE public.exhibitions 
    SET 
        status = CASE WHEN is_approved THEN 'approved' ELSE 'rejected' END,
        approved_at = CASE WHEN is_approved THEN NOW() ELSE NULL END,
        approved_by = CASE WHEN is_approved THEN auth.uid() ELSE NULL END,
        rejection_reason = CASE WHEN NOT is_approved THEN rejection_reason ELSE NULL END,
        updated_at = NOW()
    WHERE 
        id = exhibition_id 
        AND status = 'pending_approval';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Grant necessary permissions
GRANT EXECUTE ON FUNCTION submit_exhibition_for_approval(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION approve_exhibition(UUID, BOOLEAN, TEXT) TO authenticated;

-- Step 8: Verify the migration
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'exhibitions' 
AND column_name IN ('approved_at', 'approved_by', 'rejection_reason', 'submitted_for_approval_at')
ORDER BY column_name;
