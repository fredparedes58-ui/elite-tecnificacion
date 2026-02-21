-- =============================================================================
-- Fase de Transparencia: Calendario Escolar, Realtime Créditos, Términos Imagen
-- =============================================================================

-- 1. Calendario escolar (solo lectura para padres y todos los autenticados)
CREATE TABLE IF NOT EXISTS public.school_calendar_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  event_type TEXT NOT NULL DEFAULT 'event'
    CHECK (event_type IN ('event', 'closure', 'special_training')),
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.school_calendar_events IS 'Calendario general de la escuela: eventos, cierres, entrenamientos especiales. Solo lectura para padres.';

CREATE INDEX IF NOT EXISTS idx_school_calendar_events_start ON public.school_calendar_events(start_at);
CREATE INDEX IF NOT EXISTS idx_school_calendar_events_type ON public.school_calendar_events(event_type);

ALTER TABLE public.school_calendar_events ENABLE ROW LEVEL SECURITY;

-- Todos los usuarios autenticados pueden ver el calendario (solo lectura)
CREATE POLICY "Authenticated can view school calendar"
  ON public.school_calendar_events FOR SELECT
  USING (auth.role() = 'authenticated');

-- Solo admins pueden insertar/actualizar/borrar eventos del calendario
CREATE POLICY "Admins can manage school calendar"
  ON public.school_calendar_events FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- 2. Habilitar Realtime en user_credits para el widget de saldo en tiempo real
--    (solo si la tabla existe y aún no está en la publicación)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_credits')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND tablename = 'user_credits'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_credits;
  END IF;
END $$;

-- 3. Aceptación de Términos de Seguridad y Derechos de Imagen (para subida de foto del hijo)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS image_rights_terms_accepted_at TIMESTAMPTZ;

COMMENT ON COLUMN public.profiles.image_rights_terms_accepted_at IS 'Fecha en que el padre/tutor aceptó los términos de seguridad y derechos de imagen antes de subir foto del menor.';
