-- ============================================================
-- SCRIPT SQL: TABLA GURU_POSTS (Informes generados por Gemini)
-- ============================================================
-- Tabla para almacenar informes de partidos generados por IA
-- ============================================================

-- ============================================================
-- CREAR TABLA: guru_posts
-- ============================================================
CREATE TABLE IF NOT EXISTS guru_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Referencia al partido
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  
  -- Contenido del informe
  content TEXT NOT NULL,
  
  -- Audiencia: 'coach' (técnico) o 'family' (familias)
  audience TEXT NOT NULL CHECK (audience IN ('coach', 'family')),
  
  -- Estado: 'draft' (borrador) o 'published' (publicado)
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_guru_posts_match_id ON guru_posts(match_id);
CREATE INDEX IF NOT EXISTS idx_guru_posts_audience ON guru_posts(audience);
CREATE INDEX IF NOT EXISTS idx_guru_posts_status ON guru_posts(status);
CREATE INDEX IF NOT EXISTS idx_guru_posts_match_audience ON guru_posts(match_id, audience);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_guru_posts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_guru_posts_updated_at ON guru_posts;
CREATE TRIGGER trigger_update_guru_posts_updated_at
  BEFORE UPDATE ON guru_posts
  FOR EACH ROW
  EXECUTE FUNCTION update_guru_posts_updated_at();

-- Comentarios descriptivos
COMMENT ON TABLE guru_posts IS 'Informes de partidos generados por IA (Gemini)';
COMMENT ON COLUMN guru_posts.audience IS 'Audiencia: coach (técnico) o family (familias)';
COMMENT ON COLUMN guru_posts.status IS 'Estado: draft (borrador) o published (publicado)';

-- ============================================================
-- HABILITAR RLS (Row Level Security)
-- ============================================================
ALTER TABLE guru_posts ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios autenticados pueden ver todos los posts
-- (Se puede refinar más adelante si se necesita restricción por equipo)
CREATE POLICY "Authenticated users can view guru posts"
ON guru_posts
FOR SELECT
TO authenticated
USING (true);

-- Política: Permitir inserción desde Edge Functions (service_role)
-- Las Edge Functions tienen permisos de service_role que bypass RLS
-- Esta política permite inserción autenticada también (por si acaso)
CREATE POLICY "Authenticated users can insert guru posts"
ON guru_posts
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política: Los usuarios autenticados pueden actualizar posts
-- (Se puede refinar más adelante si se necesita restricción por rol)
CREATE POLICY "Authenticated users can update guru posts"
ON guru_posts
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Mensaje de confirmación
DO $$ 
BEGIN
  RAISE NOTICE '✅ Tabla guru_posts creada correctamente';
  RAISE NOTICE '✅ Índices creados';
  RAISE NOTICE '✅ RLS habilitado';
END $$;
