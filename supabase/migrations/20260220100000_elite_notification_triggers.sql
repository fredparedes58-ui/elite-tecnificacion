-- =============================================================================
-- Elite Performance - Triggers para invocar Edge Functions de notificaciones
-- Requiere: pg_net habilitado, tablas profiles, wallets (esquema Elite Performance)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Opcional: configurar en la sesión o en app.settings para otro proyecto:
-- SET app.settings.supabase_url = 'https://TU_PROYECTO.supabase.co';
-- SET app.settings.supabase_anon_key = 'tu_anon_key';

-- =============================================================================
-- 1. TRIGGER: Al crear perfil de padre → notify_on_registration (email confirmación)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.trigger_notify_on_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  supabase_url TEXT;
  anon_key TEXT;
BEGIN
  IF NEW.role <> 'parent' THEN
    RETURN NEW;
  END IF;

  supabase_url := coalesce(nullif(current_setting('app.settings.supabase_url', true), ''), 'https://hquoczkfumtpolyomrlg.supabase.co');
  anon_key := coalesce(nullif(current_setting('app.settings.supabase_anon_key', true), ''), 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxdW9jemtmdW10cG9seW9tcmxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MjY3NDQsImV4cCI6MjA4NDAwMjc0NH0.M-u1yVs4jQjIy5ncoOyc9bgGwZtZGycUZSGyn4d3elo');

  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/notify_on_registration',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || anon_key
    ),
    body := jsonb_build_object(
      'record', jsonb_build_object(
        'id', NEW.id,
        'email', NEW.email,
        'full_name', NEW.full_name,
        'role', NEW.role
      )
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_registration ON public.profiles;
CREATE TRIGGER trg_notify_on_registration
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_on_registration();

-- =============================================================================
-- 2. TRIGGER: Cuando credit_balance llega a 1 → low_credits_alert (Pedro + Padre)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.trigger_low_credits_alert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  supabase_url TEXT;
  anon_key TEXT;
BEGIN
  IF NEW.credit_balance <> 1 THEN
    RETURN NEW;
  END IF;

  supabase_url := coalesce(nullif(current_setting('app.settings.supabase_url', true), ''), 'https://hquoczkfumtpolyomrlg.supabase.co');
  anon_key := coalesce(nullif(current_setting('app.settings.supabase_anon_key', true), ''), 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxdW9jemtmdW10cG9seW9tcmxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MjY3NDQsImV4cCI6MjA4NDAwMjc0NH0.M-u1yVs4jQjIy5ncoOyc9bgGwZtZGycUZSGyn4d3elo');

  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/low_credits_alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || anon_key
    ),
    body := jsonb_build_object(
      'record', jsonb_build_object(
        'parent_id', NEW.parent_id,
        'credit_balance', NEW.credit_balance
      )
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_low_credits_alert ON public.wallets;
CREATE TRIGGER trg_low_credits_alert
  AFTER UPDATE OF credit_balance ON public.wallets
  FOR EACH ROW
  WHEN (NEW.credit_balance = 1)
  EXECUTE FUNCTION public.trigger_low_credits_alert();

-- =============================================================================
-- session_management: se invoca desde el cliente (Flutter) tras crear/actualizar
-- o cancelar una sesión: supabase.functions.invoke('session_management', { body: { action, session_id } })
-- =============================================================================

-- =============================================================================
-- daily_report_generator: invocar por cron o manualmente
-- POST /functions/v1/daily_report_generator { "period": "weekly" | "monthly", "date": "YYYY-MM-DD" }
-- =============================================================================
