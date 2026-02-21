-- =============================================================================
-- Admin-Gated Onboarding: is_approved, notificación a admin, bienvenida al aprobar
-- =============================================================================
-- 1. Asegura columna is_approved en profiles (default false).
-- 2. Trigger: al registrarse un padre (is_approved = false) → notificar a admins.
-- 3. Trigger: al pasar is_approved a true → enviar correo de bienvenida al padre.
-- =============================================================================

-- 1. Columna is_approved en profiles (idempotente)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'is_approved'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN is_approved BOOLEAN NOT NULL DEFAULT false;
    COMMENT ON COLUMN public.profiles.is_approved IS 'Si false, el padre no puede usar la app hasta que un admin lo apruebe.';
  END IF;
END $$;

-- Asegurar default por si la columna ya existía sin default
ALTER TABLE public.profiles ALTER COLUMN is_approved SET DEFAULT false;

-- 2. Notificar a admins cuando se registra un padre (is_approved = false)
-- Inserta una notificación in-app para cada admin (por user_id)
CREATE OR REPLACE FUNCTION public.trigger_notify_admin_pending_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_rec RECORD;
  supabase_url TEXT;
  anon_key TEXT;
BEGIN
  -- Solo cuando es una cuenta pendiente de aprobación (nuevo padre)
  IF COALESCE(NEW.is_approved, true) = true THEN
    RETURN NEW;
  END IF;

  -- Notificación in-app para cada admin (user_id de perfiles con email en admin_coach_emails)
  FOR admin_rec IN
    SELECT p.id AS admin_id
    FROM public.profiles p
    INNER JOIN public.admin_coach_emails ace ON ace.email = p.email
  LOOP
    INSERT INTO public.notifications (user_id, type, title, message, metadata)
    VALUES (
      admin_rec.admin_id,
      'pending_approval',
      'Nueva cuenta pendiente de aprobación',
      COALESCE(NEW.full_name, NEW.email) || ' se ha registrado y está esperando aprobación.',
      jsonb_build_object('profile_id', NEW.id, 'email', NEW.email, 'full_name', NEW.full_name)
    );
  END LOOP;

  -- Llamar Edge Function para enviar email a Pedro (admins)
  supabase_url := coalesce(nullif(current_setting('app.settings.supabase_url', true), ''), 'https://hquoczkfumtpolyomrlg.supabase.co');
  anon_key := coalesce(nullif(current_setting('app.settings.supabase_anon_key', true), ''), 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxdW9jemtmdW10cG9seW9tcmxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MjY3NDQsImV4cCI6MjA4NDAwMjc0NH0.M-u1yVs4jQjIy5ncoOyc9bgGwZtZGycUZSGyn4d3elo');

  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/notify_admin_pending_approval',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || anon_key),
    body := jsonb_build_object(
      'record', jsonb_build_object(
        'id', NEW.id,
        'email', NEW.email,
        'full_name', COALESCE(NEW.full_name, NEW.email)
      )
    )
  );

  RETURN NEW;
END;
$$;

-- Quitar envío de bienvenida en INSERT (ahora solo se envía al aprobar)
DROP TRIGGER IF EXISTS trg_notify_on_registration ON public.profiles;

DROP TRIGGER IF EXISTS trg_notify_admin_pending_approval ON public.profiles;
CREATE TRIGGER trg_notify_admin_pending_approval
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  WHEN (COALESCE(NEW.is_approved, true) = false)
  EXECUTE FUNCTION public.trigger_notify_admin_pending_approval();

-- 3. Al aprobar (is_approved false → true): enviar correo de bienvenida al padre
CREATE OR REPLACE FUNCTION public.trigger_welcome_on_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  supabase_url TEXT;
  anon_key TEXT;
BEGIN
  IF OLD.is_approved = true OR NEW.is_approved <> true THEN
    RETURN NEW;
  END IF;

  supabase_url := coalesce(nullif(current_setting('app.settings.supabase_url', true), ''), 'https://hquoczkfumtpolyomrlg.supabase.co');
  anon_key := coalesce(nullif(current_setting('app.settings.supabase_anon_key', true), ''), 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxdW9jemtmdW10cG9seW9tcmxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MjY3NDQsImV4cCI6MjA4NDAwMjc0NH0.M-u1yVs4jQjIy5ncoOyc9bgGwZtZGycUZSGyn4d3elo');

  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/notify_on_registration',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || anon_key),
    body := jsonb_build_object(
      'welcome_on_approval', true,
      'profile_id', NEW.id,
      'record', jsonb_build_object(
        'id', NEW.id,
        'email', NEW.email,
        'full_name', COALESCE(NEW.full_name, NEW.email),
        'role', 'parent'
      )
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_welcome_on_approval ON public.profiles;
CREATE TRIGGER trg_welcome_on_approval
  AFTER UPDATE OF is_approved ON public.profiles
  FOR EACH ROW
  WHEN (OLD.is_approved = false AND NEW.is_approved = true)
  EXECUTE FUNCTION public.trigger_welcome_on_approval();

-- =============================================================================
-- RPC: Aprobar padre (solo admins). Actualiza is_approved y el trigger envía el email.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.approve_parent(profile_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo un administrador puede aprobar cuentas';
  END IF;

  UPDATE public.profiles
  SET is_approved = true
  WHERE id = profile_id
    AND (is_approved IS NULL OR is_approved = false);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Perfil no encontrado o ya estaba aprobado';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.approve_parent(UUID) IS 'Marca is_approved = true para un perfil. Solo admins. Dispara correo de bienvenida.';
