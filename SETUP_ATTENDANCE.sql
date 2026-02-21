-- ============================================================
-- SCRIPT SQL: SISTEMA DE CONTROL DE ASISTENCIA A ENTRENAMIENTOS
-- ============================================================
-- Este script crea las tablas y funciones necesarias para
-- gestionar la asistencia de jugadores a entrenamientos
-- ============================================================

-- ============================================================
-- PASO 1: CREAR TABLA training_sessions
-- ============================================================
CREATE TABLE IF NOT EXISTS training_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  date TIMESTAMPTZ NOT NULL,
  topic TEXT, -- Ej: "Físico", "Táctica", "Técnica"
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_training_sessions_team_id ON training_sessions(team_id);
CREATE INDEX IF NOT EXISTS idx_training_sessions_date ON training_sessions(date DESC);

-- Comentarios descriptivos
COMMENT ON TABLE training_sessions IS 'Sesiones de entrenamiento del equipo';
COMMENT ON COLUMN training_sessions.topic IS 'Tema o tipo de entrenamiento (Físico, Táctica, Técnica, etc.)';

-- ============================================================
-- PASO 2: CREAR TABLA attendance_records
-- ============================================================
CREATE TABLE IF NOT EXISTS attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES training_sessions(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late', 'injured', 'sick')),
  note TEXT, -- Nota opcional del entrenador
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, player_id) -- Un jugador solo puede tener un registro por sesión
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_attendance_records_session_id ON attendance_records(session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_player_id ON attendance_records(player_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_status ON attendance_records(status);

-- Comentarios descriptivos
COMMENT ON TABLE attendance_records IS 'Registros de asistencia de jugadores a entrenamientos';
COMMENT ON COLUMN attendance_records.status IS 'Estado: present (Presente), absent (Ausente), late (Tarde), injured (Lesionado), sick (Enfermo)';

-- ============================================================
-- PASO 3: TRIGGER PARA ACTUALIZAR updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a training_sessions
DROP TRIGGER IF EXISTS update_training_sessions_updated_at ON training_sessions;
CREATE TRIGGER update_training_sessions_updated_at
  BEFORE UPDATE ON training_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Aplicar trigger a attendance_records
DROP TRIGGER IF EXISTS update_attendance_records_updated_at ON attendance_records;
CREATE TRIGGER update_attendance_records_updated_at
  BEFORE UPDATE ON attendance_records
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- PASO 4: FUNCIONES ÚTILES
-- ============================================================

-- Función para obtener el porcentaje de asistencia de un jugador
CREATE OR REPLACE FUNCTION get_attendance_rate(
  p_player_id UUID,
  p_team_id UUID,
  p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE(
  total_sessions BIGINT,
  present_count BIGINT,
  absent_count BIGINT,
  late_count BIGINT,
  injured_count BIGINT,
  sick_count BIGINT,
  attendance_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT ts.id)::BIGINT as total_sessions,
    COUNT(CASE WHEN ar.status = 'present' THEN 1 END)::BIGINT as present_count,
    COUNT(CASE WHEN ar.status = 'absent' THEN 1 END)::BIGINT as absent_count,
    COUNT(CASE WHEN ar.status = 'late' THEN 1 END)::BIGINT as late_count,
    COUNT(CASE WHEN ar.status = 'injured' THEN 1 END)::BIGINT as injured_count,
    COUNT(CASE WHEN ar.status = 'sick' THEN 1 END)::BIGINT as sick_count,
    CASE 
      WHEN COUNT(DISTINCT ts.id) > 0 THEN
        ROUND(
          (COUNT(CASE WHEN ar.status = 'present' THEN 1 END)::NUMERIC / 
           COUNT(DISTINCT ts.id)::NUMERIC) * 100, 
          2
        )
      ELSE 0
    END as attendance_rate
  FROM training_sessions ts
  LEFT JOIN attendance_records ar ON ts.id = ar.session_id AND ar.player_id = p_player_id
  WHERE ts.team_id = p_team_id
    AND ts.date >= NOW() - (p_days_back || ' days')::INTERVAL
  GROUP BY ts.team_id;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener estadísticas de asistencia de un equipo
CREATE OR REPLACE FUNCTION get_team_attendance_stats(
  p_team_id UUID,
  p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE(
  total_sessions BIGINT,
  avg_attendance_rate NUMERIC,
  total_players BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT ts.id)::BIGINT as total_sessions,
    CASE 
      WHEN COUNT(DISTINCT ts.id) > 0 THEN
        ROUND(
          AVG(
            CASE 
              WHEN COUNT(CASE WHEN ar.status = 'present' THEN 1 END) > 0 THEN
                (COUNT(CASE WHEN ar.status = 'present' THEN 1 END)::NUMERIC / 
                 COUNT(DISTINCT ts.id)::NUMERIC) * 100
              ELSE 0
            END
          ), 
          2
        )
      ELSE 0
    END as avg_attendance_rate,
    COUNT(DISTINCT tm.user_id)::BIGINT as total_players
  FROM training_sessions ts
  CROSS JOIN team_members tm
  LEFT JOIN attendance_records ar ON ts.id = ar.session_id AND ar.player_id = tm.user_id
  WHERE ts.team_id = p_team_id
    AND tm.team_id = p_team_id
    AND ts.date >= NOW() - (p_days_back || ' days')::INTERVAL
  GROUP BY ts.team_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- PASO 5: POLÍTICAS RLS (ROW LEVEL SECURITY)
-- ============================================================
-- Nota: Ajusta estas políticas según tu configuración de seguridad

-- Habilitar RLS en las tablas
ALTER TABLE training_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- Política: Los miembros del equipo pueden ver las sesiones de su equipo
CREATE POLICY "Team members can view training sessions"
ON training_sessions
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM team_members tm
    WHERE tm.team_id = training_sessions.team_id
    AND tm.user_id = auth.uid()
  )
);

-- Política: Solo coaches y admins pueden crear sesiones
CREATE POLICY "Coaches can create training sessions"
ON training_sessions
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM team_members tm
    WHERE tm.team_id = training_sessions.team_id
    AND tm.user_id = auth.uid()
    AND tm.role IN ('coach', 'admin')
  )
);

-- Política: Solo coaches y admins pueden actualizar sesiones
CREATE POLICY "Coaches can update training sessions"
ON training_sessions
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM team_members tm
    WHERE tm.team_id = training_sessions.team_id
    AND tm.user_id = auth.uid()
    AND tm.role IN ('coach', 'admin')
  )
);

-- Política: Los miembros del equipo pueden ver sus propios registros de asistencia
CREATE POLICY "Players can view their own attendance"
ON attendance_records
FOR SELECT
USING (
  player_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM team_members tm
    JOIN training_sessions ts ON ts.id = attendance_records.session_id
    WHERE tm.team_id = ts.team_id
    AND tm.user_id = auth.uid()
    AND tm.role IN ('coach', 'admin')
  )
);

-- Política: Solo coaches y admins pueden crear/actualizar registros de asistencia
CREATE POLICY "Coaches can manage attendance"
ON attendance_records
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM team_members tm
    JOIN training_sessions ts ON ts.id = attendance_records.session_id
    WHERE tm.team_id = ts.team_id
    AND tm.user_id = auth.uid()
    AND tm.role IN ('coach', 'admin')
  )
);

-- ============================================================
-- VERIFICACIÓN
-- ============================================================
-- Ejecuta estas consultas para verificar que todo se configuró correctamente

-- Verificar tablas creadas
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name IN ('training_sessions', 'attendance_records')
ORDER BY table_name, ordinal_position;

-- Verificar funciones creadas
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_attendance_rate', 'get_team_attendance_stats');

-- Verificar triggers
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND event_object_table IN ('training_sessions', 'attendance_records');

-- ============================================================
-- NOTAS IMPORTANTES
-- ============================================================
-- 1. Este script es idempotente (se puede ejecutar múltiples veces sin problemas)
-- 2. Los estados de asistencia son: 'present', 'absent', 'late', 'injured', 'sick'
-- 3. Un jugador solo puede tener un registro por sesión (constraint UNIQUE)
-- 4. Las funciones get_attendance_rate y get_team_attendance_stats calculan estadísticas
-- 5. Las políticas RLS aseguran que solo coaches/admins puedan modificar asistencia
-- ============================================================
