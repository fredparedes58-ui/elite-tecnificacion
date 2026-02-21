-- =============================================================================
-- Políticas RLS en stats para coaches/admins por usuario (user_roles) o por equipo (team_members)
-- =============================================================================

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
