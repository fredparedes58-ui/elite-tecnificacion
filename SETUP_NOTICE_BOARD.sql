-- ============================================================
-- SCRIPT SQL: TABLÓN DE ANUNCIOS OFICIALES
-- ============================================================
-- Sistema unidireccional de comunicados (Club -> Padres)
-- con confirmación de lectura (Acuse de Recibo)
-- ============================================================

-- ============================================================
-- PASO 1: CREAR TABLA notice_board_posts
-- ============================================================
CREATE TABLE IF NOT EXISTS notice_board_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE, -- NULL = para toda la escuela
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL, -- Soporta markdown
  attachment_url TEXT, -- URL del PDF o imagen adjunta
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('normal', 'urgent')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_notice_board_posts_team_id ON notice_board_posts(team_id);
CREATE INDEX IF NOT EXISTS idx_notice_board_posts_author_id ON notice_board_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_notice_board_posts_created_at ON notice_board_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notice_board_posts_priority ON notice_board_posts(priority);

-- Comentarios descriptivos
COMMENT ON TABLE notice_board_posts IS 'Comunicados oficiales del club/equipo';
COMMENT ON COLUMN notice_board_posts.team_id IS 'NULL = comunicado para toda la escuela, UUID = comunicado para equipo específico';
COMMENT ON COLUMN notice_board_posts.content IS 'Contenido del comunicado (soporta markdown)';
COMMENT ON COLUMN notice_board_posts.attachment_url IS 'URL del archivo adjunto (PDF, imagen de horario, etc.)';
COMMENT ON COLUMN notice_board_posts.priority IS 'normal o urgent (urgent muestra borde rojo y alerta)';

-- ============================================================
-- PASO 2: CREAR TABLA notice_read_receipts
-- ============================================================
CREATE TABLE IF NOT EXISTS notice_read_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notice_id UUID NOT NULL REFERENCES notice_board_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(notice_id, user_id) -- Un usuario solo puede tener un registro por comunicado
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_notice_read_receipts_notice_id ON notice_read_receipts(notice_id);
CREATE INDEX IF NOT EXISTS idx_notice_read_receipts_user_id ON notice_read_receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_notice_read_receipts_read_at ON notice_read_receipts(read_at DESC);

-- Comentarios descriptivos
COMMENT ON TABLE notice_read_receipts IS 'Registro de lectura de comunicados (Acuse de Recibo)';
COMMENT ON COLUMN notice_read_receipts.read_at IS 'Timestamp de cuándo el usuario leyó el comunicado';

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

-- Aplicar trigger a notice_board_posts
DROP TRIGGER IF EXISTS update_notice_board_posts_updated_at ON notice_board_posts;
CREATE TRIGGER update_notice_board_posts_updated_at
  BEFORE UPDATE ON notice_board_posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- PASO 4: FUNCIONES ÚTILES
-- ============================================================

-- Función para obtener estadísticas de lectura de un comunicado
CREATE OR REPLACE FUNCTION get_notice_read_stats(p_notice_id UUID)
RETURNS TABLE(
  total_users BIGINT,
  read_count BIGINT,
  unread_count BIGINT,
  read_percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH notice_info AS (
    SELECT 
      nbp.team_id,
      nbp.author_id
    FROM notice_board_posts nbp
    WHERE nbp.id = p_notice_id
  ),
  affected_users AS (
    SELECT DISTINCT tm.user_id
    FROM team_members tm
    CROSS JOIN notice_info ni
    WHERE (ni.team_id IS NULL OR tm.team_id = ni.team_id)
      AND tm.user_id != ni.author_id -- Excluir al autor
  ),
  read_users AS (
    SELECT user_id
    FROM notice_read_receipts
    WHERE notice_id = p_notice_id
  )
  SELECT 
    (SELECT COUNT(*) FROM affected_users)::BIGINT as total_users,
    (SELECT COUNT(*) FROM read_users)::BIGINT as read_count,
    ((SELECT COUNT(*) FROM affected_users) - (SELECT COUNT(*) FROM read_users))::BIGINT as unread_count,
    CASE 
      WHEN (SELECT COUNT(*) FROM affected_users) > 0 THEN
        ROUND(
          ((SELECT COUNT(*) FROM read_users)::NUMERIC / 
           (SELECT COUNT(*) FROM affected_users)::NUMERIC) * 100, 
          1
        )
      ELSE 0
    END as read_percentage;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener lista de usuarios que NO han leído un comunicado
CREATE OR REPLACE FUNCTION get_unread_users(p_notice_id UUID)
RETURNS TABLE(
  user_id UUID,
  full_name TEXT,
  email TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH notice_info AS (
    SELECT 
      nbp.team_id,
      nbp.author_id
    FROM notice_board_posts nbp
    WHERE nbp.id = p_notice_id
  ),
  affected_users AS (
    SELECT DISTINCT tm.user_id
    FROM team_members tm
    CROSS JOIN notice_info ni
    WHERE (ni.team_id IS NULL OR tm.team_id = ni.team_id)
      AND tm.user_id != ni.author_id
  ),
  read_users AS (
    SELECT user_id
    FROM notice_read_receipts
    WHERE notice_id = p_notice_id
  )
  SELECT 
    au.user_id,
    p.full_name,
    p.email
  FROM affected_users au
  JOIN profiles p ON p.id = au.user_id
  WHERE au.user_id NOT IN (SELECT user_id FROM read_users)
  ORDER BY p.full_name;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- PASO 5: VISTA PARA COMUNICADOS CON ESTADÍSTICAS
-- ============================================================
CREATE OR REPLACE VIEW notice_board_posts_with_stats AS
SELECT 
  nbp.*,
  COALESCE(
    (SELECT COUNT(*)::BIGINT 
     FROM notice_read_receipts nrr 
     WHERE nrr.notice_id = nbp.id),
    0
  ) as read_count,
  COALESCE(
    (SELECT COUNT(DISTINCT tm.user_id)::BIGINT
     FROM team_members tm
     WHERE (nbp.team_id IS NULL OR tm.team_id = nbp.team_id)
       AND tm.user_id != nbp.author_id),
    0
  ) as total_users
FROM notice_board_posts nbp;

-- ============================================================
-- PASO 6: POLÍTICAS RLS (ROW LEVEL SECURITY)
-- ============================================================
-- Habilitar RLS en las tablas
ALTER TABLE notice_board_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notice_read_receipts ENABLE ROW LEVEL SECURITY;

-- Política: Todos los miembros del equipo pueden ver los comunicados
CREATE POLICY "Team members can view notices"
ON notice_board_posts
FOR SELECT
USING (
  team_id IS NULL -- Comunicado para toda la escuela
  OR EXISTS (
    SELECT 1 FROM team_members tm
    WHERE tm.team_id = notice_board_posts.team_id
    AND tm.user_id = auth.uid()
  )
);

-- Política: Solo coaches y admins pueden crear comunicados
CREATE POLICY "Coaches can create notices"
ON notice_board_posts
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM team_members tm
    WHERE (notice_board_posts.team_id IS NULL OR tm.team_id = notice_board_posts.team_id)
    AND tm.user_id = auth.uid()
    AND tm.role IN ('coach', 'admin')
  )
);

-- Política: Solo el autor puede actualizar sus comunicados
CREATE POLICY "Authors can update their notices"
ON notice_board_posts
FOR UPDATE
USING (author_id = auth.uid())
WITH CHECK (author_id = auth.uid());

-- Política: Solo coaches y admins pueden eliminar comunicados
CREATE POLICY "Coaches can delete notices"
ON notice_board_posts
FOR DELETE
USING (
  author_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM team_members tm
    WHERE (team_id IS NULL OR tm.team_id = notice_board_posts.team_id)
    AND tm.user_id = auth.uid()
    AND tm.role IN ('coach', 'admin')
  )
);

-- Política: Los usuarios pueden ver sus propios acuses de recibo
CREATE POLICY "Users can view their receipts"
ON notice_read_receipts
FOR SELECT
USING (user_id = auth.uid());

-- Política: Los usuarios pueden crear sus propios acuses de recibo
CREATE POLICY "Users can create receipts"
ON notice_read_receipts
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Política: Los coaches pueden ver todos los acuses de recibo de sus comunicados
CREATE POLICY "Coaches can view all receipts"
ON notice_read_receipts
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM notice_board_posts nbp
    JOIN team_members tm ON (nbp.team_id IS NULL OR tm.team_id = nbp.team_id)
    WHERE nbp.id = notice_read_receipts.notice_id
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
WHERE table_name IN ('notice_board_posts', 'notice_read_receipts')
ORDER BY table_name, ordinal_position;

-- Verificar funciones creadas
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_notice_read_stats', 'get_unread_users');

-- Verificar vista creada
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public' 
AND table_name = 'notice_board_posts_with_stats';

-- ============================================================
-- NOTAS IMPORTANTES
-- ============================================================
-- 1. Este script es idempotente (se puede ejecutar múltiples veces sin problemas)
-- 2. Los comunicados pueden ser para un equipo específico (team_id) o para toda la escuela (team_id = NULL)
-- 3. El sistema de acuse de recibo registra automáticamente cuando un usuario abre un comunicado
-- 4. Las funciones get_notice_read_stats y get_unread_users ayudan a los entrenadores a ver quién ha leído
-- 5. Las políticas RLS aseguran que solo coaches/admins puedan crear comunicados
-- 6. Los usuarios solo pueden crear acuses de recibo para sí mismos
-- ============================================================
