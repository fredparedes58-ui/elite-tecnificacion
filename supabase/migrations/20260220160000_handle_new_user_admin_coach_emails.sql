-- =============================================================================
-- Registro: usar tabla admin_coach_emails (admin/coach) y el resto = padre
-- + RPC para sincronizar roles al agregar correos (usuarios ya existentes)
-- =============================================================================

-- Reemplazar handle_new_user: si email está en admin_coach_emails → admin+coach;
-- si no → parent. Todo correo que no esté en la lista es padre.
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

  -- Crear perfil (auto-aprobar a admin/coach)
  INSERT INTO public.profiles (id, email, full_name, is_approved)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    is_admin_coach
  );

  -- Asignar roles: admin+coach si está en la lista, si no → parent
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

  -- Créditos iniciales
  INSERT INTO public.user_credits (user_id, balance)
  VALUES (NEW.id, initial_credits);

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS 'Nuevos usuarios: si email en admin_coach_emails → admin+coach; si no → parent';

-- =============================================================================
-- RPC: sincronizar roles desde admin_coach_emails (para usuarios ya existentes)
-- Solo admins pueden llamarla. Útil al agregar un nuevo correo a la lista.
-- =============================================================================

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

COMMENT ON FUNCTION public.sync_admin_coach_roles() IS 'Asigna admin+coach en user_roles a todos los perfiles cuyo email está en admin_coach_emails. Solo admins.';
