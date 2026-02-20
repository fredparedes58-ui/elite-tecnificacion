-- ============================================================
-- SCRIPT SQL: CATEGORÍAS DE ENTRENAMIENTOS
-- ============================================================
-- Crea la tabla para almacenar contenidos de entrenamientos
-- por categorías (Ataque, Defensa, Uno contra uno, etc.)
-- ============================================================

-- PASO 1: Crear tabla training_contents
CREATE TABLE IF NOT EXISTS training_contents (
  id TEXT PRIMARY KEY,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  category TEXT NOT NULL, -- 'ataque', 'defensa', 'unoContraUno', etc.
  text TEXT, -- Descripción/instrucciones del entrenamiento
  file_urls TEXT[] DEFAULT '{}', -- Array de URLs de archivos (imágenes, PDFs, videos)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  UNIQUE(team_id, category) -- Un solo contenido por categoría por equipo
);

-- PASO 2: Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_training_contents_team_id 
ON training_contents(team_id);

CREATE INDEX IF NOT EXISTS idx_training_contents_category 
ON training_contents(category);

-- PASO 3: Habilitar Row Level Security (RLS)
ALTER TABLE training_contents ENABLE ROW LEVEL SECURITY;

-- PASO 4: Política para que los miembros del equipo puedan leer
CREATE POLICY "Team members can view training contents"
ON training_contents
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM team_members
    WHERE team_members.team_id = training_contents.team_id
    AND team_members.user_id = auth.uid()
  )
);

-- PASO 5: Política para que entrenadores/admins puedan modificar
CREATE POLICY "Coaches and admins can manage training contents"
ON training_contents
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM team_members
    WHERE team_members.team_id = training_contents.team_id
    AND team_members.user_id = auth.uid()
    AND team_members.role IN ('coach', 'admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM team_members
    WHERE team_members.team_id = training_contents.team_id
    AND team_members.user_id = auth.uid()
    AND team_members.role IN ('coach', 'admin')
  )
);

-- ============================================================
-- NOTAS:
-- ============================================================
-- 1. Cada equipo tiene un contenido por categoría
-- 2. Las categorías disponibles son:
--    - ataque
--    - defensa
--    - unoContraUno
--    - duelos
--    - resistencia
--    - fuerza
--    - pliometria
-- 3. Los archivos se almacenan en Supabase Storage (bucket: app-files, folder: training-files)
-- 4. Solo entrenadores y admins pueden crear/modificar contenidos
-- 5. Todos los miembros del equipo pueden ver los contenidos
