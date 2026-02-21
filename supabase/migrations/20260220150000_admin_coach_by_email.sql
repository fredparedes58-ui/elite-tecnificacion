-- =============================================================================
-- Admin y coach definidos por correo (por usuario/jugador, no por equipo).
-- fredparedes58@gmail.com = admin y coach en user_roles.
-- =============================================================================

-- Añadir 'coach' al enum app_role (por usuario, no por equipo)
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'coach';

-- Tabla de correos que deben ser admin y coach (añade más filas cuando quieras)
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

-- =============================================================================
-- Asignar admin + coach en user_roles a quienes tengan ese correo (por usuario)
-- =============================================================================

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

-- =============================================================================
-- Trigger: nuevos perfiles con correo en la lista → admin + coach en user_roles
-- =============================================================================

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
