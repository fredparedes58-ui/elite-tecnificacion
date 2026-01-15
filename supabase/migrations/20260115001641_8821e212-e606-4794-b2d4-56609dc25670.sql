-- Add missing columns to players table
ALTER TABLE public.players 
ADD COLUMN IF NOT EXISTS current_club text,
ADD COLUMN IF NOT EXISTS dominant_leg text DEFAULT 'right' CHECK (dominant_leg IN ('right', 'left', 'both'));

-- Add some variety to existing players
UPDATE public.players 
SET 
  current_club = (ARRAY['FC Barcelona', 'Real Madrid CF', 'Atlético Madrid', 'Valencia CF', 'Sevilla FC', 'Real Betis', 'Athletic Bilbao', 'Real Sociedad', 'Villarreal CF', 'Celta de Vigo', 'Deportivo', 'Levante UD', 'Sin Club', 'Escuela Municipal', 'Academia Local'])[1 + floor(random() * 15)::int],
  dominant_leg = (ARRAY['right', 'right', 'right', 'left', 'left', 'both'])[1 + floor(random() * 6)::int]
WHERE current_club IS NULL;