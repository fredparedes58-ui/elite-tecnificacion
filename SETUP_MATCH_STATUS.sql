-- ============================================================
-- SCRIPT SQL: GESTIÓN DE CONVOCATORIA Y ESTADOS DE JUGADORES
-- ============================================================
-- Este script añade las columnas necesarias para el sistema
-- de gestión de plantilla y táctica dinámica
-- ============================================================

-- PASO 1: Añadir columna match_status a team_members
-- Esta columna almacena el estado del jugador: 'starter', 'sub', o 'unselected'
ALTER TABLE team_members
ADD COLUMN IF NOT EXISTS match_status TEXT DEFAULT 'sub';

-- PASO 2: Añadir columna status_note a team_members
-- Esta columna almacena la razón de desconvocatoria (opcional)
ALTER TABLE team_members
ADD COLUMN IF NOT EXISTS status_note TEXT;

-- PASO 3: Añadir constraint para validar los valores de match_status
-- Solo permite los valores: 'starter', 'sub', 'unselected'
ALTER TABLE team_members
DROP CONSTRAINT IF EXISTS match_status_check;

ALTER TABLE team_members
ADD CONSTRAINT match_status_check 
CHECK (match_status IN ('starter', 'sub', 'unselected'));

-- PASO 4: Crear índice para mejorar el rendimiento de las consultas
-- Esto acelera las búsquedas por estado de jugador
CREATE INDEX IF NOT EXISTS idx_team_members_match_status 
ON team_members(match_status);

-- PASO 5: (Opcional) Inicializar datos de ejemplo
-- Esto establece los primeros 11 jugadores como titulares
-- y el resto como suplentes

-- Comentario: Descomenta las siguientes líneas si quieres inicializar datos automáticamente
/*
DO $$
DECLARE
  v_team_id UUID;
  v_player_ids UUID[];
BEGIN
  -- Obtener el primer equipo
  SELECT id INTO v_team_id FROM teams LIMIT 1;
  
  IF v_team_id IS NOT NULL THEN
    -- Obtener los IDs de los primeros 11 jugadores
    SELECT ARRAY_AGG(user_id) INTO v_player_ids
    FROM (
      SELECT user_id 
      FROM team_members 
      WHERE team_id = v_team_id 
      LIMIT 11
    ) AS starters;
    
    -- Marcar los primeros 11 como titulares
    UPDATE team_members
    SET match_status = 'starter'
    WHERE team_id = v_team_id
    AND user_id = ANY(v_player_ids);
    
    -- Marcar el resto como suplentes
    UPDATE team_members
    SET match_status = 'sub'
    WHERE team_id = v_team_id
    AND user_id != ALL(v_player_ids);
  END IF;
END $$;
*/

-- ============================================================
-- FUNCIONES ÚTILES PARA LA GESTIÓN DE CONVOCATORIA
-- ============================================================

-- Función para obtener el conteo de jugadores por estado
CREATE OR REPLACE FUNCTION get_players_count_by_status(p_team_id UUID)
RETURNS TABLE(status TEXT, count BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    match_status as status,
    COUNT(*) as count
  FROM team_members
  WHERE team_id = p_team_id
  GROUP BY match_status;
END;
$$ LANGUAGE plpgsql;

-- Función para intercambiar el estado de dos jugadores
CREATE OR REPLACE FUNCTION swap_player_status(
  p_team_id UUID,
  p_player1_id UUID,
  p_player2_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_status1 TEXT;
  v_status2 TEXT;
BEGIN
  -- Obtener estados actuales
  SELECT match_status INTO v_status1
  FROM team_members
  WHERE team_id = p_team_id AND user_id = p_player1_id;
  
  SELECT match_status INTO v_status2
  FROM team_members
  WHERE team_id = p_team_id AND user_id = p_player2_id;
  
  -- Intercambiar estados
  UPDATE team_members
  SET match_status = v_status2
  WHERE team_id = p_team_id AND user_id = p_player1_id;
  
  UPDATE team_members
  SET match_status = v_status1
  WHERE team_id = p_team_id AND user_id = p_player2_id;
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- POLÍTICAS RLS (ROW LEVEL SECURITY) - OPCIONAL
-- ============================================================
-- Si tienes RLS habilitado, asegúrate de que las políticas
-- permitan actualizar las columnas match_status y status_note

-- Ejemplo de política para permitir a los coaches actualizar estados:
/*
CREATE POLICY "Coaches can update match status"
ON team_members
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM team_members tm
    WHERE tm.team_id = team_members.team_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'coach'
  )
);
*/

-- ============================================================
-- VERIFICACIÓN
-- ============================================================
-- Ejecuta esta consulta para verificar que todo se configuró correctamente

SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'team_members'
AND column_name IN ('match_status', 'status_note')
ORDER BY column_name;

-- ============================================================
-- NOTAS IMPORTANTES
-- ============================================================
-- 1. Este script es idempotente (se puede ejecutar múltiples veces sin problemas)
-- 2. Los valores por defecto están configurados para que todos los jugadores
--    nuevos se añadan como 'sub' (suplentes)
-- 3. La columna status_note solo se llena cuando match_status = 'unselected'
-- 4. Se recomienda hacer un backup de la base de datos antes de ejecutar
-- ============================================================
