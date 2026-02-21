-- =============================================================================
-- SCRIPT 01 COMPLETO — Elite Performance
-- Copiar TODO este archivo y ejecutar en Supabase → SQL Editor → Run
-- Incluye: tipos, tablas (con columna attended en bookings), índices,
-- funciones, triggers, RLS y trigger de registro.
-- =============================================================================

-- 1. TIPOS ENUM (solo si no existen)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN
    CREATE TYPE public.user_role AS ENUM ('admin', 'coach', 'parent');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'session_status' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN
    CREATE TYPE public.session_status AS ENUM ('pending', 'approved', 'cancelled');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN
    CREATE TYPE public.booking_status AS ENUM ('confirmed', 'waitlist');
  END IF;
END $$;

-- 2. TABLAS PRINCIPALES
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  role public.user_role NOT NULL DEFAULT 'parent',
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.players (
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

CREATE TABLE IF NOT EXISTS public.sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  max_capacity INTEGER NOT NULL DEFAULT 10 CHECK (max_capacity > 0),
  status public.session_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  status public.booking_status NOT NULL DEFAULT 'waitlist',
  attended BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, player_id)
);

-- Si bookings ya existía sin "attended", añadir la columna
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS attended BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS public.wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  credit_balance INTEGER NOT NULL DEFAULT 0 CHECK (credit_balance >= 0),
  last_update TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.stats (
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

-- 3. ÍNDICES (solo si no existen)
CREATE INDEX IF NOT EXISTS idx_players_parent_id ON public.players(parent_id);
CREATE INDEX IF NOT EXISTS idx_sessions_coach_id ON public.sessions(coach_id);
CREATE INDEX IF NOT EXISTS idx_sessions_date ON public.sessions(date);
CREATE INDEX IF NOT EXISTS idx_bookings_session_id ON public.bookings(session_id);
CREATE INDEX IF NOT EXISTS idx_bookings_player_id ON public.bookings(player_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_wallets_parent_id ON public.wallets(parent_id);
CREATE INDEX IF NOT EXISTS idx_stats_player_id ON public.stats(player_id);
CREATE INDEX IF NOT EXISTS idx_stats_updated_by_coach ON public.stats(updated_by_coach_id);

-- 4. FUNCIONES AUXILIARES
CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = user_id AND role = 'admin');
$$;

CREATE OR REPLACE FUNCTION public.is_coach(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = user_id AND role = 'coach');
$$;

CREATE OR REPLACE FUNCTION public.is_parent(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = user_id AND role = 'parent');
$$;

CREATE OR REPLACE FUNCTION public.count_confirmed_bookings(session_uuid UUID)
RETURNS INTEGER LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COUNT(*)::INTEGER FROM public.bookings WHERE session_id = session_uuid AND status = 'confirmed';
$$;

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_players_updated_at BEFORE UPDATE ON public.players FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_sessions_updated_at BEFORE UPDATE ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_stats_updated_at BEFORE UPDATE ON public.stats FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.validate_session_capacity()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_max_capacity INTEGER; v_confirmed_count INTEGER;
BEGIN
  SELECT max_capacity INTO v_max_capacity FROM public.sessions WHERE id = NEW.session_id;
  SELECT COUNT(*) INTO v_confirmed_count FROM public.bookings WHERE session_id = NEW.session_id AND status = 'confirmed';
  IF TG_OP = 'INSERT' THEN
    IF v_confirmed_count >= v_max_capacity THEN NEW.status := 'waitlist'; ELSE NEW.status := 'confirmed'; END IF;
  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    IF NEW.status = 'confirmed' AND v_confirmed_count >= v_max_capacity THEN NEW.status := 'waitlist'; END IF;
  END IF;
  RETURN NEW;
END; $$;
CREATE TRIGGER trg_validate_session_capacity BEFORE INSERT OR UPDATE OF status ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.validate_session_capacity();

CREATE OR REPLACE FUNCTION public.handle_attendance_credit_deduction()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_parent_id UUID; v_current_balance INTEGER; v_credit_cost INTEGER := 1;
BEGIN
  IF (TG_OP = 'UPDATE' AND OLD.attended = FALSE AND NEW.attended = TRUE) OR (TG_OP = 'INSERT' AND NEW.attended = TRUE) THEN
    IF NEW.status != 'confirmed' THEN RAISE EXCEPTION 'No se puede marcar asistencia para reservas en waitlist'; END IF;
    SELECT parent_id INTO v_parent_id FROM public.players WHERE id = NEW.player_id;
    IF v_parent_id IS NULL THEN RAISE EXCEPTION 'Jugador no tiene parent_id asignado'; END IF;
    SELECT credit_balance INTO v_current_balance FROM public.wallets WHERE parent_id = v_parent_id FOR UPDATE;
    IF v_current_balance IS NULL THEN
      INSERT INTO public.wallets (parent_id, credit_balance, last_update) VALUES (v_parent_id, 0, NOW()) ON CONFLICT (parent_id) DO NOTHING;
      SELECT credit_balance INTO v_current_balance FROM public.wallets WHERE parent_id = v_parent_id FOR UPDATE;
    END IF;
    IF v_current_balance < v_credit_cost THEN RAISE EXCEPTION 'Créditos insuficientes'; END IF;
    UPDATE public.wallets SET credit_balance = credit_balance - v_credit_cost, last_update = NOW() WHERE parent_id = v_parent_id;
  END IF;
  RETURN NEW;
END; $$;
CREATE TRIGGER trg_handle_attendance_credit_deduction AFTER INSERT OR UPDATE OF attended ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.handle_attendance_credit_deduction();

CREATE OR REPLACE FUNCTION public.create_wallet_for_parent()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.role = 'parent' THEN INSERT INTO public.wallets (parent_id, credit_balance, last_update) VALUES (NEW.id, 0, NOW()) ON CONFLICT (parent_id) DO NOTHING; END IF;
  RETURN NEW;
END; $$;
CREATE TRIGGER trg_create_wallet_for_parent AFTER INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.create_wallet_for_parent();

-- 5. RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON public.profiles FOR SELECT USING (public.is_admin());
CREATE POLICY "Admins can update all profiles" ON public.profiles FOR UPDATE USING (public.is_admin());
CREATE POLICY "Coaches can view parent profiles" ON public.profiles FOR SELECT USING (public.is_coach() AND role IN ('parent', 'coach'));

CREATE POLICY "Parents can view own players" ON public.players FOR SELECT USING (parent_id = auth.uid());
CREATE POLICY "Parents can create own players" ON public.players FOR INSERT WITH CHECK (parent_id = auth.uid());
CREATE POLICY "Parents can update own players" ON public.players FOR UPDATE USING (parent_id = auth.uid());
CREATE POLICY "Admins can view all players" ON public.players FOR SELECT USING (public.is_admin());
CREATE POLICY "Admins can manage all players" ON public.players FOR ALL USING (public.is_admin());
CREATE POLICY "Coaches can view all players" ON public.players FOR SELECT USING (public.is_coach());

CREATE POLICY "Coaches can view own sessions" ON public.sessions FOR SELECT USING (coach_id = auth.uid());
CREATE POLICY "Coaches can create own sessions" ON public.sessions FOR INSERT WITH CHECK (coach_id = auth.uid() AND public.is_coach());
CREATE POLICY "Coaches can update own sessions" ON public.sessions FOR UPDATE USING (coach_id = auth.uid());
CREATE POLICY "Parents can view approved sessions" ON public.sessions FOR SELECT USING (status = 'approved' AND public.is_parent());
CREATE POLICY "Admins can view all sessions" ON public.sessions FOR SELECT USING (public.is_admin());
CREATE POLICY "Admins can manage all sessions" ON public.sessions FOR ALL USING (public.is_admin());

CREATE POLICY "Parents can view own players bookings" ON public.bookings FOR SELECT USING (EXISTS (SELECT 1 FROM public.players WHERE id = bookings.player_id AND parent_id = auth.uid()));
CREATE POLICY "Parents can create bookings for own players" ON public.bookings FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.players WHERE id = bookings.player_id AND parent_id = auth.uid()));
CREATE POLICY "Parents can update own players bookings" ON public.bookings FOR UPDATE USING (EXISTS (SELECT 1 FROM public.players WHERE id = bookings.player_id AND parent_id = auth.uid()));
CREATE POLICY "Coaches can view own sessions bookings" ON public.bookings FOR SELECT USING (EXISTS (SELECT 1 FROM public.sessions WHERE id = bookings.session_id AND coach_id = auth.uid()));
CREATE POLICY "Coaches can update own sessions bookings" ON public.bookings FOR UPDATE USING (EXISTS (SELECT 1 FROM public.sessions WHERE id = bookings.session_id AND coach_id = auth.uid()));
CREATE POLICY "Admins can view all bookings" ON public.bookings FOR SELECT USING (public.is_admin());
CREATE POLICY "Admins can manage all bookings" ON public.bookings FOR ALL USING (public.is_admin());

CREATE POLICY "Parents can view own wallet" ON public.wallets FOR SELECT USING (parent_id = auth.uid());
CREATE POLICY "Admins can view all wallets" ON public.wallets FOR SELECT USING (public.is_admin());
CREATE POLICY "Admins can update wallets" ON public.wallets FOR UPDATE USING (public.is_admin());
CREATE POLICY "Admins can insert wallets" ON public.wallets FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "Parents can view own players stats" ON public.stats FOR SELECT USING (EXISTS (SELECT 1 FROM public.players WHERE id = stats.player_id AND parent_id = auth.uid()));
CREATE POLICY "Coaches can view all stats" ON public.stats FOR SELECT USING (public.is_coach());
CREATE POLICY "Coaches can manage stats" ON public.stats FOR ALL USING (public.is_coach()) WITH CHECK (public.is_coach() AND updated_by_coach_id = auth.uid());
CREATE POLICY "Admins can manage all stats" ON public.stats FOR ALL USING (public.is_admin());

-- 6. Perfil al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name)
  VALUES (NEW.id, NEW.email, 'parent'::public.user_role, COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)));
  RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
