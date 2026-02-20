-- =============================================================================
-- Elite Performance - Core Schema: enrollments, trigger attendance → credit,
-- RLS (parents / coaches / admin), índices y lógica de waitlist
-- =============================================================================
-- Las tablas profiles, players (con stats JSONB), reservations (sesiones),
-- user_credits ya existen. Añadimos enrollments y credit_wallets (vista/alias)
-- para alinear con el diseño "Elite Performance".
-- Capacidad: 10 jugadores por sesión; el 11º entra en waitlist.
-- =============================================================================

-- Vista para compatibilidad con "credit_wallets" (balance por usuario)
CREATE OR REPLACE VIEW public.credit_wallets AS
SELECT
  user_id AS parent_id,
  balance,
  updated_at
FROM public.user_credits;

-- Tabla de inscripciones a sesiones (1 sesión = 1 reservation, N enrollments)
-- slot_position 1-10 = plaza confirmada; 11+ = waitlist
CREATE TABLE IF NOT EXISTS public.enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.reservations(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  attended BOOLEAN NOT NULL DEFAULT FALSE,
  slot_position INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(session_id, player_id)
);

COMMENT ON TABLE public.enrollments IS 'Inscripciones a sesiones. slot_position 1-10 = plaza; 11+ = waitlist.';
COMMENT ON COLUMN public.enrollments.attended IS 'Al pasar a TRUE se descuenta 1 crédito del padre (trigger).';

-- Índices para velocidad
CREATE INDEX IF NOT EXISTS idx_enrollments_session_id ON public.enrollments(session_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_player_id ON public.enrollments(player_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_attended ON public.enrollments(attended) WHERE attended = TRUE;
CREATE INDEX IF NOT EXISTS idx_players_parent_id ON public.players(parent_id);
CREATE INDEX IF NOT EXISTS idx_reservations_trainer_id ON public.reservations(trainer_id);
CREATE INDEX IF NOT EXISTS idx_user_credits_user_id ON public.user_credits(user_id);

-- Trigger: al marcar attended = TRUE, restar 1 crédito y validar balance >= 0
CREATE OR REPLACE FUNCTION public.handle_session_attendance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_parent_id UUID;
  v_balance INT;
  v_credit_cost INT := 1;
BEGIN
  -- Solo actuar cuando attended pasa a TRUE
  IF (TG_OP = 'UPDATE' AND OLD.attended = FALSE AND NEW.attended = TRUE)
     OR (TG_OP = 'INSERT' AND NEW.attended = TRUE) THEN

    SELECT parent_id INTO v_parent_id
    FROM players
    WHERE id = NEW.player_id;

    IF v_parent_id IS NULL THEN
      RAISE EXCEPTION 'Player has no parent_id';
    END IF;

    -- Obtener balance actual (con lock para evitar race)
    SELECT balance INTO v_balance
    FROM user_credits
    WHERE user_id = v_parent_id
    FOR UPDATE;

    IF v_balance IS NULL THEN
      RAISE EXCEPTION 'No credit wallet for parent %', v_parent_id;
    END IF;

    IF v_balance < v_credit_cost THEN
      RAISE EXCEPTION 'Insufficient credits: balance=% required=%', v_balance, v_credit_cost;
    END IF;

    -- Descontar 1 crédito
    UPDATE user_credits
    SET balance = balance - v_credit_cost,
        updated_at = now()
    WHERE user_id = v_parent_id;

    -- Opcional: registrar en credit_transactions si existe la tabla
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'credit_transactions') THEN
      INSERT INTO credit_transactions (user_id, amount, transaction_type, reservation_id, description)
      VALUES (v_parent_id, -v_credit_cost, 'debit', NEW.session_id,
              'Sesión - asistencia registrada (enrollment ' || NEW.id || ')');
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_handle_session_attendance ON public.enrollments;
CREATE TRIGGER trg_handle_session_attendance
  AFTER INSERT OR UPDATE OF attended
  ON public.enrollments
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_session_attendance();

-- Actualizar updated_at en enrollments
CREATE OR REPLACE FUNCTION public.set_enrollments_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_enrollments_updated_at ON public.enrollments;
CREATE TRIGGER trg_enrollments_updated_at
  BEFORE UPDATE ON public.enrollments
  FOR EACH ROW EXECUTE FUNCTION public.set_enrollments_updated_at();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================

ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;

-- Políticas para enrollments
-- Admin: bypass vía app_metadata.role = 'admin' en JWT (Supabase)
CREATE POLICY "Admin full access enrollments"
  ON public.enrollments
  FOR ALL
  USING (
    (auth.jwt()->'app_metadata'->>'role') = 'admin'
  );

-- Parents: solo leer/editar enrollments de sus hijos (players.parent_id = auth.uid())
CREATE POLICY "Parents own players enrollments"
  ON public.enrollments
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.players pl
      WHERE pl.id = enrollments.player_id AND pl.parent_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.players pl
      WHERE pl.id = enrollments.player_id AND pl.parent_id = auth.uid()
    )
  );

-- Coaches: solo ver enrollments de sesiones donde son trainer (trainer identificado por email = auth.uid())
DROP POLICY IF EXISTS "Coaches see own sessions enrollments" ON public.enrollments;
CREATE POLICY "Coaches see sessions where they are trainer"
  ON public.enrollments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.reservations r
      INNER JOIN public.trainers t ON t.id = r.trainer_id
      WHERE r.id = enrollments.session_id
        AND (t.email = (SELECT email FROM auth.users WHERE id = auth.uid()) OR t.id::text = auth.uid()::text)
    )
  );

-- Vista credit_wallets: RLS por parent (solo ver su wallet)
-- La vista lee de user_credits; si user_credits ya tiene RLS, no hace falta policy en la vista.
-- En muchos proyectos user_credits tiene policy "Users see own row" (user_id = auth.uid()).

-- =============================================================================
-- LÓGICA DE WAITLIST (breve explicación)
-- =============================================================================
-- Regla de negocio: máximo 10 jugadores por sesión (bloque). Los que ocupan
-- slot_position 1..10 están "confirmados". El 11º en adelante (slot_position >= 11)
-- están en waitlist: no se les descuenta crédito hasta que pasen a una plaza 1-10
-- (p. ej. al mover un enrollment o cancelar uno).
--
-- Cómo usar en la app:
-- 1) Al inscribir un jugador: contar enrollments con slot_position <= 10 para esa session_id.
--    Si count < 10, insertar con slot_position = count+1; si count >= 10, insertar con
--    slot_position = count+1 (waitlist).
-- 2) Solo marcar attended = TRUE para enrollments con slot_position <= 10 (o permitir
--    y dejar que el trigger falle si no hay crédito).
-- 3) Si un confirmado cancela: actualizar slot_position de los waitlist (11->10, 12->11...)
--    y opcionalmente notificar al primero de la waitlist.
-- =============================================================================
