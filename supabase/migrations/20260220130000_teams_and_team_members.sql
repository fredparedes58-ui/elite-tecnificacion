-- =============================================================================
-- Tablas teams y team_members que la app usa en plantilla, roles, carta FIFA, etc.
-- Crea la estructura mínima para que SquadScreen, PlayerCardScreen y RLS de stats funcionen.
-- =============================================================================

-- Equipos (categoría U8, U10, Alevín, etc.)
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.teams IS 'Equipos del club; category identifica U8, U10, Alevín, etc.';

-- Miembros del equipo (jugadores, coaches, admin por equipo)
CREATE TABLE IF NOT EXISTS public.team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('coach', 'admin', 'player', 'parent', 'staff')),
  match_status TEXT DEFAULT 'sub' CHECK (match_status IN ('starter', 'sub', 'unselected')),
  is_starter BOOLEAN DEFAULT FALSE,
  status_note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, team_id)
);

COMMENT ON TABLE public.team_members IS 'Relación usuario-equipo con rol (coach, admin, player...); la app usa role para permisos y carta FIFA';
COMMENT ON COLUMN public.team_members.role IS 'coach, admin, player, parent, staff';
COMMENT ON COLUMN public.team_members.match_status IS 'starter, sub, unselected (convocatoria)';

CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON public.team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_role ON public.team_members(role);

-- Trigger updated_at para teams
CREATE OR REPLACE FUNCTION public.set_teams_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_teams_updated_at ON public.teams;
CREATE TRIGGER trg_teams_updated_at
  BEFORE UPDATE ON public.teams FOR EACH ROW EXECUTE FUNCTION public.set_teams_updated_at();

-- Trigger updated_at para team_members
CREATE OR REPLACE FUNCTION public.set_team_members_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_team_members_updated_at ON public.team_members;
CREATE TRIGGER trg_team_members_updated_at
  BEFORE UPDATE ON public.team_members FOR EACH ROW EXECUTE FUNCTION public.set_team_members_updated_at();

-- Un equipo por defecto para que la app no falle al abrir plantilla (SquadScreen hace .from('teams').limit(1).single())
INSERT INTO public.teams (id, name, category)
SELECT gen_random_uuid(), 'Mi Equipo', 'Alevín'
WHERE NOT EXISTS (SELECT 1 FROM public.teams LIMIT 1);

-- =============================================================================
-- RLS: permitir lectura/escritura según rol (simplificado para que la app funcione)
-- =============================================================================

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

-- Teams: usuarios autenticados pueden ver
DROP POLICY IF EXISTS "Authenticated can view teams" ON public.teams;
CREATE POLICY "Authenticated can view teams"
  ON public.teams FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admins can manage teams" ON public.teams;
CREATE POLICY "Admins can manage teams"
  ON public.teams FOR ALL
  TO authenticated
  USING (public.is_admin());

-- Team_members: ver si eres el usuario o del mismo equipo; insert/update con restricciones
DROP POLICY IF EXISTS "Users can view own team_members" ON public.team_members;
CREATE POLICY "Users can view own team_members"
  ON public.team_members FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can view team_members of same team" ON public.team_members;
CREATE POLICY "Users can view team_members of same team"
  ON public.team_members FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.team_members tm2
      WHERE tm2.team_id = team_members.team_id AND tm2.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage team_members" ON public.team_members;
CREATE POLICY "Admins can manage team_members"
  ON public.team_members FOR ALL
  TO authenticated
  USING (public.is_admin());

-- Coaches pueden gestionar team_members de su equipo
DROP POLICY IF EXISTS "Coaches can manage team_members of own team" ON public.team_members;
CREATE POLICY "Coaches can manage team_members of own team"
  ON public.team_members FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.team_members tm2
      WHERE tm2.team_id = team_members.team_id
        AND tm2.user_id = auth.uid()
        AND tm2.role IN ('coach', 'admin')
    )
  );
