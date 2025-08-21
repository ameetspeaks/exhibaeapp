-- Update stall_applications status constraint to allow 'approved' status
-- First, drop the existing constraint
ALTER TABLE public.stall_applications DROP CONSTRAINT IF EXISTS stall_applications_status_check;

-- Create new constraint that includes 'approved' status
ALTER TABLE public.stall_applications ADD CONSTRAINT stall_applications_status_check 
CHECK (status IN ('pending', 'approved', 'rejected', 'booked', 'payment_pending', 'payment_review'));
