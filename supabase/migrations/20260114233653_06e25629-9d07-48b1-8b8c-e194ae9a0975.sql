-- Create trainers table
CREATE TABLE public.trainers (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  photo_url TEXT,
  specialty TEXT,
  bio TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS on trainers
ALTER TABLE public.trainers ENABLE ROW LEVEL SECURITY;

-- Trainers policies
CREATE POLICY "Anyone approved can view trainers"
ON public.trainers FOR SELECT
USING (is_approved() OR is_admin());

CREATE POLICY "Only admins can manage trainers"
ON public.trainers FOR ALL
USING (is_admin());

-- Add new reservation statuses
ALTER TYPE public.reservation_status ADD VALUE IF NOT EXISTS 'completed';
ALTER TYPE public.reservation_status ADD VALUE IF NOT EXISTS 'no_show';

-- Add trainer_id to reservations
ALTER TABLE public.reservations 
ADD COLUMN trainer_id UUID REFERENCES public.trainers(id);

-- Update trigger for trainers
CREATE TRIGGER update_trainers_updated_at
  BEFORE UPDATE ON public.trainers
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- Enable realtime for reservations
ALTER PUBLICATION supabase_realtime ADD TABLE public.reservations;