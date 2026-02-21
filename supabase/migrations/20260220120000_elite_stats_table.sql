-- =============================================================================
-- Tabla stats para la Carta FIFA (ElitePlayerCard): PAC, SHO, PAS, DRI, DEF, PHY + notas
-- player_id = profiles.id (usuario/jugador en la app); una fila por jugador
-- Requiere: public.profiles. RLS usa auth.uid() e is_admin() (user_roles).
-- =============================================================================

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

-- Trigger updated_at
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

-- =============================================================================
-- RLS (solo profiles + is_admin; no depende de team_members)
-- =============================================================================

ALTER TABLE public.stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Players can view own stats" ON public.stats;
DROP POLICY IF EXISTS "Coaches can view all stats" ON public.stats;
DROP POLICY IF EXISTS "Coaches can manage stats" ON public.stats;
DROP POLICY IF EXISTS "Admins can view all stats" ON public.stats;
DROP POLICY IF EXISTS "Admins can manage all stats" ON public.stats;

-- Ver: el propio jugador o un admin
CREATE POLICY "Players can view own stats"
  ON public.stats FOR SELECT
  USING (player_id = auth.uid());

CREATE POLICY "Admins can view all stats"
  ON public.stats FOR SELECT
  USING (public.is_admin());

-- Escribir: solo admins (role admin en user_roles)
CREATE POLICY "Admins can manage all stats"
  ON public.stats FOR ALL
  USING (public.is_admin());
