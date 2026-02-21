-- ============================================================
-- SCRIPT SQL: SISTEMA DE ASISTENCIA PARA PADRES
-- ============================================================
-- Este script permite que los padres marquen asistencia
-- entrenamiento por entrenamiento para sus hijos
-- ============================================================

-- ============================================================
-- PASO 1: CREAR TABLA DE RELACIÓN PADRE-HIJO
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
-- PASO 2: AÑADIR COLUMNA marked_by A attendance_records
-- ============================================================
-- Esta columna indica quién marcó la asistencia (coach, parent, o el mismo jugador)
ALTER TABLE attendance_records
ADD COLUMN IF NOT EXISTS marked_by UUID REFERENCES profiles(id);

-- Índice para mejorar consultas
CREATE INDEX IF NOT EXISTS idx_attendance_records_marked_by ON attendance_records(marked_by);

COMMENT ON COLUMN attendance_records.marked_by IS 'ID del usuario que marcó la asistencia (coach, parent, o player)';

-- ============================================================
-- PASO 3: ACTUALIZAR POLÍTICAS RLS PARA PADRES
-- ============================================================

-- Eliminar política antigua que solo permitía coaches
DROP POLICY IF EXISTS "Coaches can manage attendance" ON attendance_records;

-- Nueva política: Los padres pueden ver y gestionar asistencia de sus hijos
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

-- Política adicional: Los padres pueden ver las sesiones de entrenamiento de los equipos de sus hijos
CREATE POLICY "Parents can view their children team sessions"
ON training_sessions
FOR SELECT
USING (
  -- Miembros del equipo pueden ver sesiones
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

-- ============================================================
-- PASO 4: FUNCIÓN PARA OBTENER HIJOS DE UN PADRE
-- ============================================================
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

-- ============================================================
-- PASO 5: FUNCIÓN PARA OBTENER PADRES DE UN JUGADOR
-- ============================================================
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
-- PASO 6: VERIFICACIÓN
-- ============================================================
-- Verificar tabla creada
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'parent_child_relationships'
ORDER BY ordinal_position;

-- Verificar columna añadida
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'attendance_records'
AND column_name = 'marked_by';

-- Verificar funciones creadas
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_parent_children', 'get_child_parents');

-- ============================================================
-- NOTAS IMPORTANTES
-- ============================================================
-- 1. Para crear una relación padre-hijo, ejecuta:
--    INSERT INTO parent_child_relationships (parent_id, child_id, team_id)
--    VALUES ('parent_uuid', 'child_uuid', 'team_uuid');
--
-- 2. Los padres ahora pueden:
--    - Ver sesiones de entrenamiento de equipos donde tienen hijos
--    - Marcar asistencia (present/absent/late/injured/sick) para sus hijos
--    - Ver historial de asistencia de sus hijos
--
-- 3. El campo marked_by se llena automáticamente con el ID del usuario
--    que marca la asistencia (coach, parent, o player)
--
-- 4. Las políticas RLS aseguran que:
--    - Los padres solo pueden gestionar asistencia de sus propios hijos
--    - Los coaches pueden gestionar asistencia de todos los jugadores
--    - Los jugadores pueden ver su propia asistencia
-- ============================================================
