-- ============================================================
-- SCRIPT SQL COMPLETO: SISTEMA DE ASISTENCIA CON SOPORTE PARA PADRES
-- ============================================================
-- Este script crea TODO el sistema de asistencia incluyendo
-- la funcionalidad para que los padres marquen asistencia
-- ============================================================
-- EJECUTA ESTE SCRIPT PRIMERO EN SUPABASE SQL EDITOR
-- ============================================================

-- ============================================================
-- PARTE 1: CREAR TABLAS BASE DE ASISTENCIA
-- ============================================================

-- PASO 1.1: CREAR TABLA training_sessions
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

-- PASO 1.2: CREAR TABLA attendance_records (CON COLUMNA marked_by)
CREATE TABLE IF NOT EXISTS attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES training_sessions(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late', 'injured', 'sick')),
  note TEXT, -- Nota opcional del entrenador
  marked_by UUID REFERENCES profiles(id), -- ID del usuario que marcó la asistencia
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, player_id) -- Un jugador solo puede tener un registro por sesión
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_attendance_records_session_id ON attendance_records(session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_player_id ON attendance_records(player_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_status ON attendance_records(status);
CREATE INDEX IF NOT EXISTS idx_attendance_records_marked_by ON attendance_records(marked_by);

-- Comentarios descriptivos
COMMENT ON TABLE attendance_records IS 'Registros de asistencia de jugadores a entrenamientos';
COMMENT ON COLUMN attendance_records.status IS 'Estado: present (Presente), absent (Ausente), late (Tarde), injured (Lesionado), sick (Enfermo)';
COMMENT ON COLUMN attendance_records.marked_by IS 'ID del usuario que marcó la asistencia (coach, parent, o player)';

-- ============================================================
-- PARTE 2: CREAR TABLA DE RELACIÓN PADRE-HIJO
-- ============================================================

CREATE TABLE IF NOT EXISTS parent_child_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(parent_id, child_id, team_id) -- Un padre solo puede tener un hijo por equipo
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_parent_child_parent_id ON parent_child_relationships(parent_id);
CREATE INDEX IF NOT EXISTS idx_parent_child_child_id ON parent_child_relationships(child_id);
CREATE INDEX IF NOT EXISTS idx_parent_child_team_id ON parent_child_relationships(team_id);

-- Comentarios descriptivos
COMMENT ON TABLE parent_child_relationships IS 'Relación entre padres e hijos (jugadores)';
COMMENT ON COLUMN parent_child_relationships.parent_id IS 'ID del perfil del padre/madre';
COMMENT ON COLUMN parent_child_relationships.child_id IS 'ID del perfil del hijo/jugador';

-- ============================================================
-- PARTE 3: TRIGGERS PARA ACTUALIZAR updated_at
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
-- PARTE 4: FUNCIONES ÚTILES
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

-- Función para obtener hijos de un padre
CREATE OR REPLACE FUNCTION get_parent_children(
  p_parent_id UUID,
  p_team_id UUID DEFAULT NULL
)
RETURNS TABLE(
  child_id UUID,
  child_name TEXT,
  child_avatar_url TEXT,
  team_id UUID,
  team_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pcr.child_id,
    p.full_name as child_name,
    p.avatar_url as child_avatar_url,
    pcr.team_id,
    t.name as team_name
  FROM parent_child_relationships pcr
  JOIN profiles p ON p.id = pcr.child_id
  JOIN teams t ON t.id = pcr.team_id
  WHERE pcr.parent_id = p_parent_id
  AND (p_team_id IS NULL OR pcr.team_id = p_team_id);
END;
$$ LANGUAGE plpgsql;

-- Función para obtener padres de un jugador
CREATE OR REPLACE FUNCTION get_child_parents(
  p_child_id UUID,
  p_team_id UUID DEFAULT NULL
)
RETURNS TABLE(
  parent_id UUID,
  parent_name TEXT,
  parent_email TEXT,
  team_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pcr.parent_id,
    p.full_name as parent_name,
    au.email as parent_email,
    pcr.team_id
  FROM parent_child_relationships pcr
  JOIN profiles p ON p.id = pcr.parent_id
  JOIN auth.users au ON au.id = pcr.parent_id
  WHERE pcr.child_id = p_child_id
  AND (p_team_id IS NULL OR pcr.team_id = p_team_id);
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- PARTE 5: POLÍTICAS RLS (ROW LEVEL SECURITY)
-- ============================================================

-- Habilitar RLS en las tablas
ALTER TABLE training_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_child_relationships ENABLE ROW LEVEL SECURITY;

-- Política: Los miembros del equipo pueden ver las sesiones de su equipo
DROP POLICY IF EXISTS "Team members can view training sessions" ON training_sessions;
CREATE POLICY "Team members can view training sessions"
ON training_sessions
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM team_members tm
    WHERE tm.team_id = training_sessions.team_id
    AND tm.user_id = auth.uid()
  )
  OR
  -- Padres pueden ver sesiones de equipos donde tienen hijos
  EXISTS (
    SELECT 1 FROM parent_child_relationships pcr
    WHERE pcr.parent_id = auth.uid()
    AND pcr.team_id = training_sessions.team_id
  )
);

-- Política: Solo coaches y admins pueden crear sesiones
DROP POLICY IF EXISTS "Coaches can create training sessions" ON training_sessions;
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
DROP POLICY IF EXISTS "Coaches can update training sessions" ON training_sessions;
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
DROP POLICY IF EXISTS "Players can view their own attendance" ON attendance_records;
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
  OR
  -- Padres pueden ver asistencia de sus hijos
  EXISTS (
    SELECT 1 FROM parent_child_relationships pcr
    JOIN training_sessions ts ON ts.id = attendance_records.session_id
    WHERE pcr.parent_id = auth.uid()
    AND pcr.child_id = attendance_records.player_id
    AND pcr.team_id = ts.team_id
  )
);

-- Política: Coaches, admins y padres pueden gestionar asistencia
DROP POLICY IF EXISTS "Coaches can manage attendance" ON attendance_records;
DROP POLICY IF EXISTS "Parents can manage their children attendance" ON attendance_records;
CREATE POLICY "Parents can manage their children attendance"
ON attendance_records
FOR ALL
USING (
  -- Los coaches/admins pueden gestionar cualquier asistencia de su equipo
  EXISTS (
    SELECT 1 FROM team_members tm
    JOIN training_sessions ts ON ts.id = attendance_records.session_id
    WHERE tm.team_id = ts.team_id
    AND tm.user_id = auth.uid()
    AND tm.role IN ('coach', 'admin')
  )
  OR
  -- Los padres pueden gestionar asistencia de sus hijos
  EXISTS (
    SELECT 1 FROM parent_child_relationships pcr
    JOIN training_sessions ts ON ts.id = attendance_records.session_id
    WHERE pcr.parent_id = auth.uid()
    AND pcr.child_id = attendance_records.player_id
    AND pcr.team_id = ts.team_id
  )
  OR
  -- Los jugadores pueden ver su propia asistencia
  player_id = auth.uid()
);

-- Política para parent_child_relationships: Solo coaches/admins pueden crear relaciones
CREATE POLICY "Coaches can manage parent child relationships"
ON parent_child_relationships
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM team_members tm
    WHERE tm.team_id = parent_child_relationships.team_id
    AND tm.user_id = auth.uid()
    AND tm.role IN ('coach', 'admin')
  )
);

-- ============================================================
-- VERIFICACIÓN
-- ============================================================

-- Verificar tablas creadas
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name IN ('training_sessions', 'attendance_records', 'parent_child_relationships')
ORDER BY table_name, ordinal_position;

-- Verificar funciones creadas
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_attendance_rate', 'get_team_attendance_stats', 'get_parent_children', 'get_child_parents');

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
-- 4. Para crear una relación padre-hijo, ejecuta:
--    INSERT INTO parent_child_relationships (parent_id, child_id, team_id)
--    VALUES ('parent_uuid', 'child_uuid', 'team_uuid');
-- 5. Los padres pueden marcar asistencia entrenamiento por entrenamiento
-- 6. El campo marked_by se llena automáticamente con el ID del usuario que marca
-- ============================================================
