-- Add trainer comments to reservations for completed sessions
ALTER TABLE public.reservations 
ADD COLUMN IF NOT EXISTS trainer_comments TEXT;

-- Create table for tracking player stats history over time
CREATE TABLE IF NOT EXISTS public.player_stats_history (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  reservation_id UUID REFERENCES public.reservations(id) ON DELETE SET NULL,
  recorded_by UUID NOT NULL,
  stats JSONB NOT NULL DEFAULT '{}',
  notes TEXT,
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.player_stats_history ENABLE ROW LEVEL SECURITY;

-- Parents can view their own player's history
CREATE POLICY "Parents can view own player stats history"
ON public.player_stats_history
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.players 
    WHERE players.id = player_stats_history.player_id 
    AND players.parent_id = auth.uid()
  )
);

-- Admins can view all stats history
CREATE POLICY "Admins can view all stats history"
ON public.player_stats_history
FOR SELECT
USING (is_admin());

-- Admins can insert stats history
CREATE POLICY "Admins can insert stats history"
ON public.player_stats_history
FOR INSERT
WITH CHECK (is_admin());

-- Admins can update stats history
CREATE POLICY "Admins can update stats history"
ON public.player_stats_history
FOR UPDATE
USING (is_admin());

-- Admins can delete stats history
CREATE POLICY "Admins can delete stats history"
ON public.player_stats_history
FOR DELETE
USING (is_admin());

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_player_stats_history_player_id 
ON public.player_stats_history(player_id);

CREATE INDEX IF NOT EXISTS idx_player_stats_history_recorded_at 
ON public.player_stats_history(recorded_at DESC);