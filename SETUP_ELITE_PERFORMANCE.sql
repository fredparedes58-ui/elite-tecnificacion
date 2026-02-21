-- =============================================================================
-- Elite Performance - Schema Completo con RLS Estricto
-- Arquitecto de Datos Senior
-- =============================================================================
-- Este script crea todas las tablas necesarias para el sistema Elite Performance
-- con Row Level Security (RLS) estricto y reglas de negocio implementadas
-- mediante triggers y funciones.
-- =============================================================================

-- =============================================================================
-- 1. TIPOS ENUM
-- =============================================================================

-- Tipo para roles de usuario
CREATE TYPE public.user_role AS ENUM ('admin', 'coach', 'parent');

-- Tipo para estado de sesiones
CREATE TYPE public.session_status AS ENUM ('pending', 'approved', 'cancelled');

-- Tipo para estado de reservas
CREATE TYPE public.booking_status AS ENUM ('confirmed', 'waitlist');

-- =============================================================================
-- 2. TABLAS PRINCIPALES
-- =============================================================================

-- Tabla de perfiles de usuario
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  role public.user_role NOT NULL DEFAULT 'parent',
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'Perfiles de usuarios del sistema (admin, coach, parent)';
COMMENT ON COLUMN public.profiles.role IS 'Rol del usuario: admin, coach o parent';

-- Tabla de jugadores
CREATE TABLE public.players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  age INTEGER NOT NULL CHECK (age > 0 AND age < 100),
  club TEXT,
  position TEXT,
  level TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.players IS 'Jugadores registrados por los padres';
COMMENT ON COLUMN public.players.parent_id IS 'ID del padre responsable del jugador';

-- Tabla de sesiones de entrenamiento
CREATE TABLE public.sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  max_capacity INTEGER NOT NULL DEFAULT 10 CHECK (max_capacity > 0),
  status public.session_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.sessions IS 'Sesiones de entrenamiento creadas por coaches';
COMMENT ON COLUMN public.sessions.max_capacity IS 'Capacidad máxima de jugadores por sesión (default: 10)';
COMMENT ON COLUMN public.sessions.status IS 'Estado de la sesión: pending, approved, cancelled';

-- Tabla de reservas/inscripciones
CREATE TABLE public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  status public.booking_status NOT NULL DEFAULT 'waitlist',
  attended BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, player_id)
);

COMMENT ON TABLE public.bookings IS 'Reservas de jugadores para sesiones';
COMMENT ON COLUMN public.bookings.status IS 'Estado: confirmed (plaza) o waitlist';
COMMENT ON COLUMN public.bookings.attended IS 'Si el jugador asistió a la sesión (descuenta crédito)';

-- Tabla de billeteras de créditos
CREATE TABLE public.wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  credit_balance INTEGER NOT NULL DEFAULT 0 CHECK (credit_balance >= 0),
  last_update TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.wallets IS 'Billeteras de créditos de los padres';
COMMENT ON COLUMN public.wallets.credit_balance IS 'Balance de créditos disponible (no puede ser negativo)';

-- Tabla de estadísticas de jugadores
CREATE TABLE public.stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  pac INTEGER CHECK (pac >= 0 AND pac <= 100),
  sho INTEGER CHECK (sho >= 0 AND sho <= 100),
  pas INTEGER CHECK (pas >= 0 AND pas <= 100),
  dri INTEGER CHECK (dri >= 0 AND dri <= 100),
  def INTEGER CHECK (def >= 0 AND def <= 100),
  phy INTEGER CHECK (phy >= 0 AND phy <= 100),
  total_value INTEGER GENERATED ALWAYS AS (COALESCE(pac, 0) + COALESCE(sho, 0) + COALESCE(pas, 0) + COALESCE(dri, 0) + COALESCE(def, 0) + COALESCE(phy, 0)) STORED,
  notes TEXT,
  updated_by_coach_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.stats IS 'Estadísticas de jugadores (PAC, SHO, PAS, DRI, DEF, PHY)';
COMMENT ON COLUMN public.stats.total_value IS 'Valor total calculado automáticamente como suma de todas las estadísticas';
COMMENT ON COLUMN public.stats.updated_by_coach_id IS 'ID del coach que actualizó las estadísticas';

-- =============================================================================
-- 3. ÍNDICES PARA OPTIMIZACIÓN
-- =============================================================================

CREATE INDEX idx_players_parent_id ON public.players(parent_id);
CREATE INDEX idx_sessions_coach_id ON public.sessions(coach_id);
CREATE INDEX idx_sessions_date ON public.sessions(date);
CREATE INDEX idx_bookings_session_id ON public.bookings(session_id);
CREATE INDEX idx_bookings_player_id ON public.bookings(player_id);
CREATE INDEX idx_bookings_status ON public.bookings(status);
CREATE INDEX idx_wallets_parent_id ON public.wallets(parent_id);
CREATE INDEX idx_stats_player_id ON public.stats(player_id);
CREATE INDEX idx_stats_updated_by_coach ON public.stats(updated_by_coach_id);

-- =============================================================================
-- 4. FUNCIONES AUXILIARES
-- =============================================================================

-- Función para verificar si un usuario es admin
CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id AND role = 'admin'
  );
$$;

-- Función para verificar si un usuario es coach
CREATE OR REPLACE FUNCTION public.is_coach(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id AND role = 'coach'
  );
$$;

-- Función para verificar si un usuario es parent
CREATE OR REPLACE FUNCTION public.is_parent(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id AND role = 'parent'
  );
$$;

-- Función para contar reservas confirmadas de una sesión
CREATE OR REPLACE FUNCTION public.count_confirmed_bookings(session_uuid UUID)
RETURNS INTEGER
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::INTEGER
  FROM public.bookings
  WHERE session_id = session_uuid AND status = 'confirmed';
$$;

-- =============================================================================
-- 5. TRIGGERS Y REGLAS DE NEGOCIO
-- =============================================================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Triggers para updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_players_updated_at
  BEFORE UPDATE ON public.players
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_sessions_updated_at
  BEFORE UPDATE ON public.sessions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_stats_updated_at
  BEFORE UPDATE ON public.stats
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Función para validar capacidad de sesión y asignar waitlist
CREATE OR REPLACE FUNCTION public.validate_session_capacity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_max_capacity INTEGER;
  v_confirmed_count INTEGER;
BEGIN
  -- Obtener capacidad máxima de la sesión
  SELECT max_capacity INTO v_max_capacity
  FROM public.sessions
  WHERE id = NEW.session_id;

  -- Contar reservas confirmadas
  SELECT COUNT(*) INTO v_confirmed_count
  FROM public.bookings
  WHERE session_id = NEW.session_id AND status = 'confirmed';

  -- Si es una nueva reserva o cambio de status
  IF TG_OP = 'INSERT' THEN
    -- Si ya hay 10 confirmados, el nuevo va a waitlist
    IF v_confirmed_count >= v_max_capacity THEN
      NEW.status := 'waitlist';
    ELSE
      NEW.status := 'confirmed';
    END IF;
  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    -- Si se está cambiando a confirmed y ya hay 10, mantener waitlist
    IF NEW.status = 'confirmed' AND v_confirmed_count >= v_max_capacity THEN
      NEW.status := 'waitlist';
      RAISE WARNING 'Sesión llena. Reserva asignada a waitlist.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger para validar capacidad antes de insertar/actualizar bookings
CREATE TRIGGER trg_validate_session_capacity
  BEFORE INSERT OR UPDATE OF status ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.validate_session_capacity();

-- Función para descontar crédito cuando se marca attended = TRUE
CREATE OR REPLACE FUNCTION public.handle_attendance_credit_deduction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_parent_id UUID;
  v_current_balance INTEGER;
  v_credit_cost INTEGER := 1;
BEGIN
  -- Solo procesar cuando attended cambia de FALSE a TRUE
  IF (TG_OP = 'UPDATE' AND OLD.attended = FALSE AND NEW.attended = TRUE)
     OR (TG_OP = 'INSERT' AND NEW.attended = TRUE) THEN

    -- Verificar que la reserva esté confirmada (no waitlist)
    IF NEW.status != 'confirmed' THEN
      RAISE EXCEPTION 'No se puede marcar asistencia para reservas en waitlist';
    END IF;

    -- Obtener el parent_id del jugador
    SELECT parent_id INTO v_parent_id
    FROM public.players
    WHERE id = NEW.player_id;

    IF v_parent_id IS NULL THEN
      RAISE EXCEPTION 'Jugador no tiene parent_id asignado';
    END IF;

    -- Obtener balance actual con lock para evitar race conditions
    SELECT credit_balance INTO v_current_balance
    FROM public.wallets
    WHERE parent_id = v_parent_id
    FOR UPDATE;

    IF v_current_balance IS NULL THEN
      -- Crear wallet si no existe
      INSERT INTO public.wallets (parent_id, credit_balance, last_update)
      VALUES (v_parent_id, 0, NOW())
      ON CONFLICT (parent_id) DO NOTHING;
      
      SELECT credit_balance INTO v_current_balance
      FROM public.wallets
      WHERE parent_id = v_parent_id
      FOR UPDATE;
    END IF;

    -- Verificar que tenga créditos suficientes
    IF v_current_balance < v_credit_cost THEN
      RAISE EXCEPTION 'Créditos insuficientes. Balance actual: %, requerido: %', v_current_balance, v_credit_cost;
    END IF;

    -- Descontar crédito
    UPDATE public.wallets
    SET credit_balance = credit_balance - v_credit_cost,
        last_update = NOW()
    WHERE parent_id = v_parent_id;

  END IF;

  RETURN NEW;
END;
$$;

-- Trigger para descontar crédito al marcar asistencia
CREATE TRIGGER trg_handle_attendance_credit_deduction
  AFTER INSERT OR UPDATE OF attended ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.handle_attendance_credit_deduction();

-- Función para crear wallet automáticamente cuando se crea un perfil parent
CREATE OR REPLACE FUNCTION public.create_wallet_for_parent()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role = 'parent' THEN
    INSERT INTO public.wallets (parent_id, credit_balance, last_update)
    VALUES (NEW.id, 0, NOW())
    ON CONFLICT (parent_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

-- Trigger para crear wallet automáticamente
CREATE TRIGGER trg_create_wallet_for_parent
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.create_wallet_for_parent();

-- =============================================================================
-- 6. ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stats ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 7. POLÍTICAS RLS PARA PROFILES
-- =============================================================================

-- Los usuarios pueden ver su propio perfil
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Los admins pueden ver todos los perfiles
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (public.is_admin());

-- Los admins pueden actualizar todos los perfiles
CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  USING (public.is_admin());

-- Los coaches pueden ver perfiles de padres y jugadores
CREATE POLICY "Coaches can view parent profiles"
  ON public.profiles FOR SELECT
  USING (public.is_coach() AND role IN ('parent', 'coach'));

-- =============================================================================
-- 8. POLÍTICAS RLS PARA PLAYERS
-- =============================================================================

-- Los padres pueden ver solo sus propios jugadores
CREATE POLICY "Parents can view own players"
  ON public.players FOR SELECT
  USING (parent_id = auth.uid());

-- Los padres pueden crear jugadores para sí mismos
CREATE POLICY "Parents can create own players"
  ON public.players FOR INSERT
  WITH CHECK (parent_id = auth.uid());

-- Los padres pueden actualizar sus propios jugadores
CREATE POLICY "Parents can update own players"
  ON public.players FOR UPDATE
  USING (parent_id = auth.uid());

-- Los admins pueden ver todos los jugadores
CREATE POLICY "Admins can view all players"
  ON public.players FOR SELECT
  USING (public.is_admin());

-- Los admins pueden gestionar todos los jugadores
CREATE POLICY "Admins can manage all players"
  ON public.players FOR ALL
  USING (public.is_admin());

-- Los coaches pueden ver todos los jugadores
CREATE POLICY "Coaches can view all players"
  ON public.players FOR SELECT
  USING (public.is_coach());

-- =============================================================================
-- 9. POLÍTICAS RLS PARA SESSIONS
-- =============================================================================

-- Los coaches pueden ver sus propias sesiones
CREATE POLICY "Coaches can view own sessions"
  ON public.sessions FOR SELECT
  USING (coach_id = auth.uid());

-- Los coaches pueden crear sesiones para sí mismos
CREATE POLICY "Coaches can create own sessions"
  ON public.sessions FOR INSERT
  WITH CHECK (coach_id = auth.uid() AND public.is_coach());

-- Los coaches pueden actualizar sus propias sesiones
CREATE POLICY "Coaches can update own sessions"
  ON public.sessions FOR UPDATE
  USING (coach_id = auth.uid());

-- Los padres pueden ver todas las sesiones aprobadas
CREATE POLICY "Parents can view approved sessions"
  ON public.sessions FOR SELECT
  USING (status = 'approved' AND public.is_parent());

-- Los admins pueden ver todas las sesiones
CREATE POLICY "Admins can view all sessions"
  ON public.sessions FOR SELECT
  USING (public.is_admin());

-- Los admins pueden gestionar todas las sesiones
CREATE POLICY "Admins can manage all sessions"
  ON public.sessions FOR ALL
  USING (public.is_admin());

-- =============================================================================
-- 10. POLÍTICAS RLS PARA BOOKINGS
-- =============================================================================

-- Los padres pueden ver reservas de sus jugadores
CREATE POLICY "Parents can view own players bookings"
  ON public.bookings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.players
      WHERE id = bookings.player_id AND parent_id = auth.uid()
    )
  );

-- Los padres pueden crear reservas para sus jugadores
CREATE POLICY "Parents can create bookings for own players"
  ON public.bookings FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.players
      WHERE id = bookings.player_id AND parent_id = auth.uid()
    )
  );

-- Los padres pueden actualizar reservas de sus jugadores
CREATE POLICY "Parents can update own players bookings"
  ON public.bookings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.players
      WHERE id = bookings.player_id AND parent_id = auth.uid()
    )
  );

-- Los coaches pueden ver reservas de sus sesiones
CREATE POLICY "Coaches can view own sessions bookings"
  ON public.bookings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.sessions
      WHERE id = bookings.session_id AND coach_id = auth.uid()
    )
  );

-- Los coaches pueden actualizar reservas de sus sesiones
CREATE POLICY "Coaches can update own sessions bookings"
  ON public.bookings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.sessions
      WHERE id = bookings.session_id AND coach_id = auth.uid()
    )
  );

-- Los admins pueden ver todas las reservas
CREATE POLICY "Admins can view all bookings"
  ON public.bookings FOR SELECT
  USING (public.is_admin());

-- Los admins pueden gestionar todas las reservas
CREATE POLICY "Admins can manage all bookings"
  ON public.bookings FOR ALL
  USING (public.is_admin());

-- =============================================================================
-- 11. POLÍTICAS RLS PARA WALLETS
-- =============================================================================

-- Los padres pueden ver solo su propia billetera
CREATE POLICY "Parents can view own wallet"
  ON public.wallets FOR SELECT
  USING (parent_id = auth.uid());

-- Los admins pueden ver todas las billeteras
CREATE POLICY "Admins can view all wallets"
  ON public.wallets FOR SELECT
  USING (public.is_admin());

-- Solo los admins pueden actualizar billeteras (los créditos se descuentan automáticamente)
CREATE POLICY "Admins can update wallets"
  ON public.wallets FOR UPDATE
  USING (public.is_admin());

-- Solo los admins pueden insertar billeteras (se crean automáticamente)
CREATE POLICY "Admins can insert wallets"
  ON public.wallets FOR INSERT
  WITH CHECK (public.is_admin());

-- =============================================================================
-- 12. POLÍTICAS RLS PARA STATS
-- =============================================================================

-- Los padres pueden ver estadísticas de sus jugadores
CREATE POLICY "Parents can view own players stats"
  ON public.stats FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.players
      WHERE id = stats.player_id AND parent_id = auth.uid()
    )
  );

-- Los coaches pueden ver todas las estadísticas
CREATE POLICY "Coaches can view all stats"
  ON public.stats FOR SELECT
  USING (public.is_coach());

-- Los coaches pueden crear/actualizar estadísticas
CREATE POLICY "Coaches can manage stats"
  ON public.stats FOR ALL
  USING (public.is_coach())
  WITH CHECK (public.is_coach() AND updated_by_coach_id = auth.uid());

-- Los admins pueden gestionar todas las estadísticas
CREATE POLICY "Admins can manage all stats"
  ON public.stats FOR ALL
  USING (public.is_admin());

-- =============================================================================
-- 13. FUNCIÓN PARA CREAR PERFIL AL REGISTRARSE
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    'parent'::public.user_role,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$;

-- Trigger para crear perfil automáticamente al registrarse
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 14. COMENTARIOS FINALES
-- =============================================================================

COMMENT ON FUNCTION public.validate_session_capacity() IS 'Valida que no haya más de 10 inscritos por sesión; si llega a 11, marca status como waitlist';
COMMENT ON FUNCTION public.handle_attendance_credit_deduction() IS 'Al marcar attended = TRUE en bookings, descuenta automáticamente 1 crédito en wallets';
COMMENT ON FUNCTION public.is_admin() IS 'Verifica si un usuario es admin';
COMMENT ON FUNCTION public.is_coach() IS 'Verifica si un usuario es coach';
COMMENT ON FUNCTION public.is_parent() IS 'Verifica si un usuario es parent';
COMMENT ON FUNCTION public.count_confirmed_bookings() IS 'Cuenta las reservas confirmadas de una sesión';

-- =============================================================================
-- FIN DEL SCRIPT
-- =============================================================================
