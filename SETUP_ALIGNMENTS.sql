-- ============================================================
-- SETUP: Tabla de Alineaciones Personalizadas
-- ============================================================
-- Script para crear la tabla de alineaciones con jugadores asignados
-- ============================================================

-- 1. Crear tabla de alineaciones
CREATE TABLE IF NOT EXISTS alignments (
  id TEXT PRIMARY KEY,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  formation TEXT NOT NULL DEFAULT '4-4-2',
  player_positions JSONB, -- Map de player_id -> {x, y, role}
  is_custom BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Crear índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_alignments_team_id ON alignments(team_id);
CREATE INDEX IF NOT EXISTS idx_alignments_user_id ON alignments(user_id);
CREATE INDEX IF NOT EXISTS idx_alignments_created_at ON alignments(created_at DESC);

-- 3. Habilitar Row Level Security (RLS)
ALTER TABLE alignments ENABLE ROW LEVEL SECURITY;

-- 4. Políticas de seguridad

-- Política de lectura: Los usuarios pueden ver las alineaciones de sus equipos
CREATE POLICY "Users can view team alignments"
ON alignments FOR SELECT
USING (
  team_id IN (
    SELECT team_id FROM team_members WHERE user_id = auth.uid()
  )
);

-- Política de inserción: Los usuarios pueden crear alineaciones para sus equipos
CREATE POLICY "Users can create team alignments"
ON alignments FOR INSERT
WITH CHECK (
  team_id IN (
    SELECT team_id FROM team_members WHERE user_id = auth.uid()
  )
  AND user_id = auth.uid()
);

-- Política de actualización: Los usuarios pueden actualizar sus propias alineaciones
CREATE POLICY "Users can update own alignments"
ON alignments FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Política de eliminación: Los usuarios pueden eliminar sus propias alineaciones
CREATE POLICY "Users can delete own alignments"
ON alignments FOR DELETE
USING (user_id = auth.uid());

-- 5. Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_alignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER alignments_updated_at
BEFORE UPDATE ON alignments
FOR EACH ROW
EXECUTE FUNCTION update_alignments_updated_at();

-- 6. Insertar alineaciones predeterminadas (4-4-2, 4-3-3, 3-5-2)
-- Estas son plantillas sin jugadores asignados

-- Nota: Necesitas reemplazar 'YOUR_TEAM_ID' y 'YOUR_USER_ID' con IDs reales
-- O ejecutar esto manualmente desde el dashboard de Supabase

/*
-- Ejemplo de inserción (ajusta los IDs):
INSERT INTO alignments (id, team_id, user_id, name, formation, player_positions, is_custom)
VALUES 
  ('default-442', 'YOUR_TEAM_ID', 'YOUR_USER_ID', 'Formación 4-4-2', '4-4-2', NULL, false),
  ('default-433', 'YOUR_TEAM_ID', 'YOUR_USER_ID', 'Formación 4-3-3', '4-3-3', NULL, false),
  ('default-352', 'YOUR_TEAM_ID', 'YOUR_USER_ID', 'Formación 3-5-2', '3-5-2', NULL, false)
ON CONFLICT (id) DO NOTHING;
*/

-- ============================================================
-- VERIFICACIÓN
-- ============================================================

-- Ejecuta esto para verificar que todo se creó correctamente:
-- SELECT * FROM alignments;

-- ============================================================
-- NOTAS
-- ============================================================
-- 
-- Estructura de player_positions (JSONB):
-- {
--   "player_id_1": {"x": 180, "y": 600, "role": "Portero"},
--   "player_id_2": {"x": 80, "y": 480, "role": "Defensa"},
--   ...
-- }
--
-- Ejemplo de uso desde Flutter:
-- 1. Crear alineación personalizada con asignación de jugadores
-- 2. Guardar usando SupabaseService.saveAlignment()
-- 3. Cargar usando SupabaseService.getAlignments()
-- 4. Seleccionar alineación y cargar jugadores en posiciones específicas
--
-- ============================================================
