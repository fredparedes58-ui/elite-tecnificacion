-- Add new reservation statuses for negotiation workflow
-- First drop the existing enum values constraint and recreate with new values

-- Add new values to the reservation_status enum
ALTER TYPE reservation_status ADD VALUE IF NOT EXISTS 'counter_proposal';
ALTER TYPE reservation_status ADD VALUE IF NOT EXISTS 'parent_review';

-- Add a column to track proposal messages between admin and parent
ALTER TABLE public.reservations 
ADD COLUMN IF NOT EXISTS proposal_message TEXT,
ADD COLUMN IF NOT EXISTS proposed_start_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS proposed_end_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS proposed_by UUID;

-- Add foreign key for proposed_by (could be admin or parent)
COMMENT ON COLUMN public.reservations.proposal_message IS 'Message explaining the proposal/counter-proposal';
COMMENT ON COLUMN public.reservations.proposed_start_time IS 'New proposed start time for counter-proposal';
COMMENT ON COLUMN public.reservations.proposed_end_time IS 'New proposed end time for counter-proposal';
COMMENT ON COLUMN public.reservations.proposed_by IS 'User ID of who made the last proposal';