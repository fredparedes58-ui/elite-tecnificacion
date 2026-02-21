-- =============================================================================
-- Crear user_credits si no existe (requiere tabla profiles) y habilitar Realtime
-- No modifica is_admin(uuid): usa la función existente en las políticas.
-- =============================================================================

-- Solo crear la tabla si no existe y profiles existe
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_credits')
     AND EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
    CREATE TABLE public.user_credits (
      user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
      balance INTEGER NOT NULL DEFAULT 0,
      updated_at TIMESTAMPTZ DEFAULT NOW()
    );
    COMMENT ON TABLE public.user_credits IS 'Saldo de créditos por usuario (padre).';
  END IF;
END $$;

-- Habilitar RLS en user_credits si la tabla existe
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_credits') THEN
    ALTER TABLE public.user_credits ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Políticas RLS (crear solo si no existen)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_credits') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'user_credits' AND policyname = 'Users can view own credits') THEN
      CREATE POLICY "Users can view own credits" ON public.user_credits FOR SELECT USING (user_id = auth.uid());
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'user_credits' AND policyname = 'Admins can view all credits') THEN
      CREATE POLICY "Admins can view all credits" ON public.user_credits FOR SELECT USING (public.is_admin(auth.uid()));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'user_credits' AND policyname = 'Only admins can update credits') THEN
      CREATE POLICY "Only admins can update credits" ON public.user_credits FOR UPDATE USING (public.is_admin(auth.uid()));
    END IF;
  END IF;
END $$;

-- Añadir a Realtime si la tabla existe y aún no está en la publicación
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
