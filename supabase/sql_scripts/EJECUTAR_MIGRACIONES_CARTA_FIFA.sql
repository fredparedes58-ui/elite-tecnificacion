-- =============================================================================
-- MIGRACIONES CARTA FIFA + STATS + ADMIN/COACH POR CORREO
-- Ejecutar en Supabase SQL Editor en este orden (o todo de una vez).
-- Si falla "relation user_roles does not exist", este script crea lo necesario al inicio.
-- =============================================================================

-- ############################################################################
-- 0) PRERREQUISITOS: app_role, user_roles, is_admin() (si no existen)
-- ############################################################################

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
    CREATE TYPE public.app_role AS ENUM ('admin', 'parent', 'player', 'coach');
  END IF;
END
$$;

-- Si app_role ya existía con solo 3 valores, añadir 'coach' (necesario antes de cualquier INSERT con role 'coach')
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'coach';

CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role public.app_role NOT NULL DEFAULT 'parent',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);

-- Reemplazar is_admin para que use user_roles (no borrar: las políticas dependen de is_admin(uuid))
CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_roles.user_id = is_admin.user_id AND user_roles.role = 'admin'
  );
$$;

-- ############################################################################
-- 1) 20260220120000_elite_stats_table.sql
-- ############################################################################

-- Tabla stats para la Carta FIFA (ElitePlayerCard): PAC, SHO, PAS, DRI, DEF, PHY + notas
-- player_id = profiles.id (usuario/jugador en la app); una fila por jugador

CREATE TABLE IF NOT EXISTS public.stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  pac INTEGER CHECK (pac >= 0 AND pac <= 100),
  sho INTEGER CHECK (sho >= 0 AND sho <= 100),
  pas INTEGER CHECK (pas >= 0 AND pas <= 100),
  dri INTEGER CHECK (dri >= 0 AND dri <= 100),
  def INTEGER CHECK (def >= 0 AND def <= 100),
  phy INTEGER CHECK (phy >= 0 AND phy <= 100),
  notes TEXT,
  updated_by_coach_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(player_id)
);

COMMENT ON TABLE public.stats IS 'Estadísticas FIFA (PAC, SHO, PAS, DRI, DEF, PHY) y notas por jugador (profiles.id)';
COMMENT ON COLUMN public.stats.player_id IS 'ID del perfil del jugador (profiles.id)';
COMMENT ON COLUMN public.stats.updated_by_coach_id IS 'ID del coach que actualizó las estadísticas';

CREATE INDEX IF NOT EXISTS idx_stats_player_id ON public.stats(player_id);
CREATE INDEX IF NOT EXISTS idx_stats_updated_by_coach ON public.stats(updated_by_coach_id);

CREATE OR REPLACE FUNCTION public.set_stats_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stats_updated_at ON public.stats;
CREATE TRIGGER trg_stats_updated_at
  BEFORE UPDATE ON public.stats
  FOR EACH ROW EXECUTE FUNCTION public.set_stats_updated_at();

ALTER TABLE public.stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Players can view own stats" ON public.stats;
DROP POLICY IF EXISTS "Coaches can view all stats" ON public.stats;
DROP POLICY IF EXISTS "Coaches can manage stats" ON public.stats;
DROP POLICY IF EXISTS "Admins can view all stats" ON public.stats;
DROP POLICY IF EXISTS "Admins can manage all stats" ON public.stats;

CREATE POLICY "Players can view own stats"
  ON public.stats FOR SELECT
  USING (player_id = auth.uid());

CREATE POLICY "Admins can view all stats"
  ON public.stats FOR SELECT
  USING (public.is_admin());

CREATE POLICY "Admins can manage all stats"
  ON public.stats FOR ALL
  USING (public.is_admin());


-- ############################################################################
-- 2) 20260220130000_teams_and_team_members.sql
-- ############################################################################

CREATE TABLE IF NOT EXISTS public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.teams IS 'Equipos del club; category identifica U8, U10, Alevín, etc.';

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

CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON public.team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_role ON public.team_members(role);

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

INSERT INTO public.teams (id, name, category)
SELECT gen_random_uuid(), 'Mi Equipo', 'Alevín'
WHERE NOT EXISTS (SELECT 1 FROM public.teams LIMIT 1);

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view teams" ON public.teams;
CREATE POLICY "Authenticated can view teams"
  ON public.teams FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins can manage teams" ON public.teams;
CREATE POLICY "Admins can manage teams"
  ON public.teams FOR ALL TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "Users can view own team_members" ON public.team_members;
CREATE POLICY "Users can view own team_members"
  ON public.team_members FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can view team_members of same team" ON public.team_members;
CREATE POLICY "Users can view team_members of same team"
  ON public.team_members FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.team_members tm2
      WHERE tm2.team_id = team_members.team_id AND tm2.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage team_members" ON public.team_members;
CREATE POLICY "Admins can manage team_members"
  ON public.team_members FOR ALL TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "Coaches can manage team_members of own team" ON public.team_members;
CREATE POLICY "Coaches can manage team_members of own team"
  ON public.team_members FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.team_members tm2
      WHERE tm2.team_id = team_members.team_id
        AND tm2.user_id = auth.uid()
        AND tm2.role IN ('coach', 'admin')
    )
  );


-- ############################################################################
-- 3) 20260220140000_stats_coach_policies.sql
-- ############################################################################

DROP POLICY IF EXISTS "Coaches can view all stats" ON public.stats;
CREATE POLICY "Coaches can view all stats"
  ON public.stats FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('coach', 'admin'))
    OR EXISTS (SELECT 1 FROM public.team_members WHERE user_id = auth.uid() AND role IN ('coach', 'admin'))
  );

DROP POLICY IF EXISTS "Coaches can manage stats" ON public.stats;
CREATE POLICY "Coaches can manage stats"
  ON public.stats FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('coach', 'admin'))
    OR EXISTS (SELECT 1 FROM public.team_members WHERE user_id = auth.uid() AND role IN ('coach', 'admin'))
  )
  WITH CHECK (updated_by_coach_id = auth.uid());


-- ############################################################################
-- 4) 20260220150000_admin_coach_by_email.sql
-- ############################################################################

ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'coach';

CREATE TABLE IF NOT EXISTS public.admin_coach_emails (
  email TEXT PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.admin_coach_emails IS 'Correos con rol admin y coach por usuario (user_roles), no por equipo.';

INSERT INTO public.admin_coach_emails (email)
VALUES ('fredparedes58@gmail.com')
ON CONFLICT (email) DO NOTHING;

ALTER TABLE public.admin_coach_emails ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage admin_coach_emails" ON public.admin_coach_emails;
CREATE POLICY "Admins can manage admin_coach_emails"
  ON public.admin_coach_emails FOR ALL
  USING (public.is_admin());

DROP POLICY IF EXISTS "Authenticated can read admin_coach_emails" ON public.admin_coach_emails;
CREATE POLICY "Authenticated can read admin_coach_emails"
  ON public.admin_coach_emails FOR SELECT TO authenticated USING (true);

INSERT INTO public.user_roles (user_id, role)
SELECT p.id, 'admin'::public.app_role
FROM public.profiles p
WHERE p.email IN (SELECT email FROM public.admin_coach_emails)
ON CONFLICT (user_id, role) DO NOTHING;

INSERT INTO public.user_roles (user_id, role)
SELECT p.id, 'coach'::public.app_role
FROM public.profiles p
WHERE p.email IN (SELECT email FROM public.admin_coach_emails)
ON CONFLICT (user_id, role) DO NOTHING;

CREATE OR REPLACE FUNCTION public.grant_admin_coach_on_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.admin_coach_emails WHERE email = NEW.email) THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'admin'::public.app_role)
    ON CONFLICT (user_id, role) DO NOTHING;
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'coach'::public.app_role)
    ON CONFLICT (user_id, role) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_grant_admin_coach_on_signup ON public.profiles;
CREATE TRIGGER trg_grant_admin_coach_on_signup
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.grant_admin_coach_on_signup();

-- ############################################################################
-- 5) handle_new_user usa admin_coach_emails; resto = padre. RPC sync roles
-- ############################################################################

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  is_admin_coach BOOLEAN;
  initial_credits INTEGER;
BEGIN
  is_admin_coach := EXISTS (
    SELECT 1 FROM public.admin_coach_emails WHERE email = NEW.email
  );

  IF is_admin_coach THEN
    initial_credits := 999;
  ELSE
    initial_credits := 0;
  END IF;

  INSERT INTO public.profiles (id, email, full_name, is_approved)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    is_admin_coach
  );

  IF is_admin_coach THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'admin'::public.app_role)
    ON CONFLICT (user_id, role) DO NOTHING;
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'coach'::public.app_role)
    ON CONFLICT (user_id, role) DO NOTHING;
  ELSE
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'parent'::public.app_role)
    ON CONFLICT (user_id, role) DO NOTHING;
  END IF;

  INSERT INTO public.user_credits (user_id, balance)
  VALUES (NEW.id, initial_credits);

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_admin_coach_roles()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo un administrador puede sincronizar roles';
  END IF;

  INSERT INTO public.user_roles (user_id, role)
  SELECT p.id, 'admin'::public.app_role
  FROM public.profiles p
  WHERE p.email IN (SELECT email FROM public.admin_coach_emails)
  ON CONFLICT (user_id, role) DO NOTHING;

  INSERT INTO public.user_roles (user_id, role)
  SELECT p.id, 'coach'::public.app_role
  FROM public.profiles p
  WHERE p.email IN (SELECT email FROM public.admin_coach_emails)
  ON CONFLICT (user_id, role) DO NOTHING;
END;
$$;
