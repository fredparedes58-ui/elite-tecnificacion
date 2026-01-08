-- ============================================================
-- SCRIPT DE INSTALACIÓN: SISTEMA DE GESTIÓN DE CAMPOS Y RESERVAS
-- ============================================================
-- Ejecutar este script completo en el SQL Editor de Supabase
-- ============================================================

-- ============================================================
-- 1. TABLA: fields (Campos deportivos)
-- ============================================================
CREATE TABLE IF NOT EXISTS fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  type VARCHAR(10) NOT NULL CHECK (type IN ('F7', 'F11')),
  location VARCHAR(200),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_fields_active ON fields(is_active);
CREATE INDEX idx_fields_type ON fields(type);

-- Comentarios descriptivos
COMMENT ON TABLE fields IS 'Almacena los campos deportivos disponibles';
COMMENT ON COLUMN fields.type IS 'Tipo de campo: F7 (Fútbol 7) o F11 (Fútbol 11)';
COMMENT ON COLUMN fields.is_active IS 'Indica si el campo está disponible para reservas';

-- ============================================================
-- 2. TABLA: bookings (Reservas de campos)
-- ============================================================
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  field_id UUID NOT NULL REFERENCES fields(id) ON DELETE CASCADE,
  team_id UUID NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  purpose VARCHAR(50) NOT NULL CHECK (purpose IN ('training', 'match', 'tactical', 'other')),
  title VARCHAR(200) NOT NULL,
  description TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Validación: La hora de fin debe ser posterior a la de inicio
  CONSTRAINT booking_time_check CHECK (end_time > start_time)
);

-- Índices para consultas de disponibilidad (CRÍTICO para rendimiento)
CREATE INDEX idx_bookings_field_time ON bookings(field_id, start_time, end_time);
CREATE INDEX idx_bookings_team ON bookings(team_id);
CREATE INDEX idx_bookings_start_time ON bookings(start_time);
CREATE INDEX idx_bookings_purpose ON bookings(purpose);

-- Comentarios descriptivos
COMMENT ON TABLE bookings IS 'Reservas de campos con detección automática de conflictos';
COMMENT ON COLUMN bookings.purpose IS 'Propósito: training (entrenamiento), match (partido), tactical (sesión táctica), other (otro)';

-- ============================================================
-- 3. TABLA: booking_requests (Solicitudes de cambio/reserva)
-- ============================================================
CREATE TABLE IF NOT EXISTS booking_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  requester_name VARCHAR(200),
  desired_field_id UUID NOT NULL REFERENCES fields(id) ON DELETE CASCADE,
  desired_start_time TIMESTAMPTZ NOT NULL,
  desired_end_time TIMESTAMPTZ NOT NULL,
  purpose VARCHAR(50) NOT NULL CHECK (purpose IN ('training', 'match', 'tactical', 'other')),
  title VARCHAR(200) NOT NULL,
  reason TEXT,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Validación: La hora de fin debe ser posterior a la de inicio
  CONSTRAINT request_time_check CHECK (desired_end_time > desired_start_time)
);

-- Índices
CREATE INDEX idx_booking_requests_status ON booking_requests(status);
CREATE INDEX idx_booking_requests_requester ON booking_requests(requester_id);
CREATE INDEX idx_booking_requests_field ON booking_requests(desired_field_id);
CREATE INDEX idx_booking_requests_time ON booking_requests(desired_start_time, desired_end_time);

-- Comentarios descriptivos
COMMENT ON TABLE booking_requests IS 'Solicitudes de reserva o cambio de horario pendientes de aprobación';
COMMENT ON COLUMN booking_requests.status IS 'Estado: pending (pendiente), approved (aprobada), rejected (rechazada)';

-- ============================================================
-- 4. FUNCIÓN: Detectar conflictos de horario (CORE LOGIC)
-- ============================================================
CREATE OR REPLACE FUNCTION check_booking_conflict(
  p_field_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ,
  p_exclude_booking_id UUID DEFAULT NULL
)
RETURNS TABLE(
  conflict_exists BOOLEAN,
  conflicting_booking_id UUID,
  conflicting_team_id UUID,
  conflicting_title VARCHAR,
  conflicting_start TIMESTAMPTZ,
  conflicting_end TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    true::BOOLEAN,
    b.id,
    b.team_id,
    b.title,
    b.start_time,
    b.end_time
  FROM bookings b
  WHERE b.field_id = p_field_id
    AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
    AND (
      -- Caso 1: La nueva reserva empieza durante una existente
      (p_start_time >= b.start_time AND p_start_time < b.end_time)
      OR
      -- Caso 2: La nueva reserva termina durante una existente
      (p_end_time > b.start_time AND p_end_time <= b.end_time)
      OR
      -- Caso 3: La nueva reserva engloba completamente una existente
      (p_start_time <= b.start_time AND p_end_time >= b.end_time)
    )
  LIMIT 1;
  
  -- Si no hay conflictos, devolver NULL
  IF NOT FOUND THEN
    RETURN QUERY SELECT false::BOOLEAN, NULL::UUID, NULL::UUID, NULL::VARCHAR, NULL::TIMESTAMPTZ, NULL::TIMESTAMPTZ;
  END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_booking_conflict IS 'Detecta si existe un conflicto de horario en un campo específico';

-- ============================================================
-- 5. FUNCIÓN: Obtener campos disponibles en un horario
-- ============================================================
CREATE OR REPLACE FUNCTION get_available_fields(
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
)
RETURNS TABLE(
  field_id UUID,
  field_name VARCHAR,
  field_type VARCHAR,
  field_location VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    f.id,
    f.name,
    f.type,
    f.location
  FROM fields f
  WHERE f.is_active = true
    AND NOT EXISTS (
      SELECT 1
      FROM bookings b
      WHERE b.field_id = f.id
        AND (
          (p_start_time >= b.start_time AND p_start_time < b.end_time)
          OR (p_end_time > b.start_time AND p_end_time <= b.end_time)
          OR (p_start_time <= b.start_time AND p_end_time >= b.end_time)
        )
    )
  ORDER BY f.name;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_available_fields IS 'Devuelve los campos disponibles (sin conflictos) para un rango de tiempo específico';

-- ============================================================
-- 6. TRIGGER: Validar conflictos antes de insertar/actualizar
-- ============================================================
CREATE OR REPLACE FUNCTION validate_booking_before_save()
RETURNS TRIGGER AS $$
DECLARE
  v_conflict_exists BOOLEAN;
  v_conflicting_title VARCHAR;
BEGIN
  -- Verificar conflictos
  SELECT conflict_exists, conflicting_title
  INTO v_conflict_exists, v_conflicting_title
  FROM check_booking_conflict(
    NEW.field_id,
    NEW.start_time,
    NEW.end_time,
    NEW.id -- Excluir la reserva actual si es UPDATE
  );
  
  -- Si hay conflicto, abortar la operación
  IF v_conflict_exists THEN
    RAISE EXCEPTION 'CONFLICTO DE HORARIO: Ya existe una reserva "%". No se puede guardar.', v_conflicting_title
      USING HINT = 'Verifica la disponibilidad del campo antes de crear la reserva.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar el trigger
DROP TRIGGER IF EXISTS trg_validate_booking ON bookings;
CREATE TRIGGER trg_validate_booking
BEFORE INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION validate_booking_before_save();

COMMENT ON FUNCTION validate_booking_before_save IS 'Valida automáticamente que no existan conflictos antes de guardar una reserva';

-- ============================================================
-- 7. TRIGGER: Actualizar updated_at automáticamente
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a todas las tablas
DROP TRIGGER IF EXISTS trg_update_fields_updated_at ON fields;
CREATE TRIGGER trg_update_fields_updated_at
BEFORE UPDATE ON fields
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_update_bookings_updated_at ON bookings;
CREATE TRIGGER trg_update_bookings_updated_at
BEFORE UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_update_booking_requests_updated_at ON booking_requests;
CREATE TRIGGER trg_update_booking_requests_updated_at
BEFORE UPDATE ON booking_requests
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 8. DATOS DE EJEMPLO (OPCIONAL - Puedes descomentar si quieres datos de prueba)
-- ============================================================

-- Insertar campos de ejemplo
INSERT INTO fields (name, type, location) VALUES
  ('Campo Principal', 'F11', 'Zona Norte'),
  ('Campo Secundario', 'F11', 'Zona Norte'),
  ('Campo 7 - A', 'F7', 'Zona Sur'),
  ('Campo 7 - B', 'F7', 'Zona Sur')
ON CONFLICT DO NOTHING;

-- Insertar reserva de ejemplo (ajusta el team_id y created_by con IDs reales de tu DB)
-- INSERT INTO bookings (field_id, team_id, start_time, end_time, purpose, title, description)
-- SELECT 
--   f.id,
--   'TU_TEAM_ID_AQUI'::UUID,
--   NOW() + INTERVAL '1 day' + INTERVAL '16 hours',
--   NOW() + INTERVAL '1 day' + INTERVAL '18 hours',
--   'training',
--   'Entrenamiento Táctico',
--   'Sesión de presión alta'
-- FROM fields f
-- WHERE f.name = 'Campo Principal'
-- LIMIT 1;

-- ============================================================
-- 9. POLÍTICAS RLS (Row Level Security) - SEGURIDAD
-- ============================================================

-- Habilitar RLS en las tablas
ALTER TABLE fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_requests ENABLE ROW LEVEL SECURITY;

-- Política: Todos pueden ver los campos activos
CREATE POLICY "Los campos son visibles para todos" ON fields
  FOR SELECT USING (is_active = true);

-- Política: Solo admins pueden modificar campos
CREATE POLICY "Solo admins pueden gestionar campos" ON fields
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'admin'
  );

-- Política: Todos pueden ver reservas
CREATE POLICY "Las reservas son visibles para todos" ON bookings
  FOR SELECT USING (true);

-- Política: Solo el creador o admins pueden crear/editar reservas
CREATE POLICY "Usuarios autenticados pueden crear reservas" ON bookings
  FOR INSERT WITH CHECK (
    auth.uid() = created_by OR auth.jwt() ->> 'role' = 'admin'
  );

CREATE POLICY "Solo el creador o admin pueden modificar reservas" ON bookings
  FOR UPDATE USING (
    auth.uid() = created_by OR auth.jwt() ->> 'role' = 'admin'
  );

-- Política: Todos pueden ver solicitudes
CREATE POLICY "Las solicitudes son visibles para todos" ON booking_requests
  FOR SELECT USING (true);

-- Política: Usuarios pueden crear sus propias solicitudes
CREATE POLICY "Usuarios pueden crear solicitudes" ON booking_requests
  FOR INSERT WITH CHECK (auth.uid() = requester_id);

-- Política: Solo admins pueden aprobar/rechazar
CREATE POLICY "Solo admins pueden revisar solicitudes" ON booking_requests
  FOR UPDATE USING (auth.jwt() ->> 'role' = 'admin');

-- ============================================================
-- 10. VERIFICACIÓN FINAL
-- ============================================================

-- Verificar que todo se creó correctamente
DO $$
BEGIN
  RAISE NOTICE '✅ Tablas creadas: fields, bookings, booking_requests';
  RAISE NOTICE '✅ Funciones creadas: check_booking_conflict, get_available_fields';
  RAISE NOTICE '✅ Triggers activados: validación de conflictos y updated_at';
  RAISE NOTICE '✅ Políticas RLS aplicadas';
  RAISE NOTICE '🚀 Sistema de Gestión de Campos listo para usar';
  RAISE NOTICE '📝 No olvides insertar campos en la tabla "fields" si no tienes datos de ejemplo';
END $$;
