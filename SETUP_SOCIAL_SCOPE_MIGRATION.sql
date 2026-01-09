-- ============================================================
-- MIGRACIÓN: SISTEMA DE SCOPE PARA SOCIAL FEED
-- ============================================================
-- Agrega soporte para dos niveles de privacidad:
-- - 'team': Posts privados del equipo
-- - 'school': Posts públicos para todo el club/escuela
-- ============================================================

-- ============================================================
-- PASO 1: AGREGAR COLUMNA scope A social_posts
-- ============================================================

-- Agregar columna scope con valor por defecto 'team' (para mantener compatibilidad)
ALTER TABLE social_posts
ADD COLUMN IF NOT EXISTS scope TEXT NOT NULL DEFAULT 'team'
CHECK (scope IN ('team', 'school'));

-- Crear índice para mejorar rendimiento de consultas por scope
CREATE INDEX IF NOT EXISTS idx_social_posts_scope ON social_posts(scope);
CREATE INDEX IF NOT EXISTS idx_social_posts_team_scope ON social_posts(team_id, scope);
CREATE INDEX IF NOT EXISTS idx_social_posts_scope_created ON social_posts(scope, created_at DESC);

-- Comentario descriptivo
COMMENT ON COLUMN social_posts.scope IS 'Nivel de privacidad: team = solo equipo, school = todo el club';

-- ============================================================
-- PASO 2: ELIMINAR POLÍTICAS RLS ANTIGUAS
-- ============================================================

DROP POLICY IF EXISTS "Los miembros del equipo pueden ver posts" ON social_posts;
DROP POLICY IF EXISTS "Los miembros pueden crear posts" ON social_posts;
DROP POLICY IF EXISTS "Los miembros pueden ver likes" ON social_post_likes;
DROP POLICY IF EXISTS "Los miembros pueden dar like" ON social_post_likes;

-- ============================================================
-- PASO 3: CREAR NUEVAS POLÍTICAS RLS CON SCOPE
-- ============================================================

-- Política de lectura: 
-- - Posts 'team': Solo miembros del equipo pueden ver
-- - Posts 'school': Todos los miembros de cualquier equipo pueden ver
CREATE POLICY "Ver posts según scope"
    ON social_posts FOR SELECT
    USING (
        -- Posts del equipo del usuario (scope team)
        (
            scope = 'team'
            AND team_id IN (
                SELECT team_id FROM team_members 
                WHERE user_id = auth.uid()
            )
        )
        OR
        -- Posts públicos del club (scope school)
        (
            scope = 'school'
            AND EXISTS (
                SELECT 1 FROM team_members 
                WHERE user_id = auth.uid()
            )
        )
    );

-- Política de inserción:
-- - Padres/Jugadores: Solo pueden crear posts con scope 'team' de su equipo
-- - Coaches/Admins: Pueden crear posts con scope 'team' o 'school'
CREATE POLICY "Crear posts según rol"
    ON social_posts FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND (
            -- Scope 'team': Usuario debe ser miembro del equipo
            (
                scope = 'team'
                AND team_id IN (
                    SELECT team_id FROM team_members 
                    WHERE user_id = auth.uid()
                )
            )
            OR
            -- Scope 'school': Solo coaches/admins pueden crear posts públicos
            (
                scope = 'school'
                AND EXISTS (
                    SELECT 1 FROM team_members
                    WHERE user_id = auth.uid()
                    AND role IN ('coach', 'admin')
                )
            )
        )
    );

-- Política de actualización: Sin cambios (solo autor o admin)
-- (Ya existe, no necesita cambios)

-- Política de eliminación: Sin cambios (solo autor o admin)
-- (Ya existe, no necesita cambios)

-- ============================================================
-- PASO 4: ACTUALIZAR POLÍTICAS DE LIKES
-- ============================================================

-- Ver likes: Usuarios pueden ver likes de posts que pueden ver
CREATE POLICY "Ver likes según scope"
    ON social_post_likes FOR SELECT
    USING (
        post_id IN (
            SELECT id FROM social_posts
            WHERE (
                -- Posts del equipo del usuario (scope team)
                (
                    scope = 'team'
                    AND team_id IN (
                        SELECT team_id FROM team_members 
                        WHERE user_id = auth.uid()
                    )
                )
                OR
                -- Posts públicos del club (scope school)
                (
                    scope = 'school'
                    AND EXISTS (
                        SELECT 1 FROM team_members 
                        WHERE user_id = auth.uid()
                    )
                )
            )
        )
    );

-- Dar like: Usuarios pueden dar like a posts que pueden ver
CREATE POLICY "Dar like según scope"
    ON social_post_likes FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND post_id IN (
            SELECT id FROM social_posts
            WHERE (
                -- Posts del equipo del usuario (scope team)
                (
                    scope = 'team'
                    AND team_id IN (
                        SELECT team_id FROM team_members 
                        WHERE user_id = auth.uid()
                    )
                )
                OR
                -- Posts públicos del club (scope school)
                (
                    scope = 'school'
                    AND EXISTS (
                        SELECT 1 FROM team_members 
                        WHERE user_id = auth.uid()
                    )
                )
            )
        )
    );

-- ============================================================
-- PASO 5: ACTUALIZAR VISTA CON SCOPE
-- ============================================================

CREATE OR REPLACE VIEW social_posts_with_author AS
SELECT 
    sp.*,
    tm.user_full_name as author_name,
    tm.role as author_role,
    COALESCE(
        (SELECT COUNT(*) FROM social_post_likes WHERE post_id = sp.id),
        0
    ) as actual_likes_count
FROM social_posts sp
LEFT JOIN team_members tm ON sp.user_id = tm.user_id AND sp.team_id = tm.team_id
ORDER BY sp.created_at DESC;

-- ============================================================
-- PASO 6: ACTUALIZAR FUNCIÓN get_team_social_feed
-- ============================================================

-- Nueva función que filtra por scope
CREATE OR REPLACE FUNCTION get_team_social_feed(
    p_team_id UUID,
    p_scope TEXT DEFAULT 'team', -- 'team' o 'school'
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    team_id UUID,
    user_id UUID,
    content_text TEXT,
    media_url TEXT,
    media_type TEXT,
    thumbnail_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    is_pinned BOOLEAN,
    scope TEXT,
    author_name TEXT,
    author_role TEXT,
    is_liked_by_me BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sp.id,
        sp.created_at,
        sp.updated_at,
        sp.team_id,
        sp.user_id,
        sp.content_text,
        sp.media_url,
        sp.media_type,
        sp.thumbnail_url,
        sp.likes_count,
        sp.comments_count,
        sp.is_pinned,
        sp.scope,
        tm.user_full_name as author_name,
        tm.role as author_role,
        EXISTS(
            SELECT 1 FROM social_post_likes 
            WHERE post_id = sp.id 
            AND user_id = auth.uid()
        ) as is_liked_by_me
    FROM social_posts sp
    LEFT JOIN team_members tm ON sp.user_id = tm.user_id AND sp.team_id = tm.team_id
    WHERE 
        -- Si scope es 'team': filtrar por team_id específico
        (p_scope = 'team' AND sp.team_id = p_team_id AND sp.scope = 'team')
        OR
        -- Si scope es 'school': mostrar todos los posts públicos
        (p_scope = 'school' AND sp.scope = 'school')
    ORDER BY sp.is_pinned DESC, sp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- PASO 7: NUEVA FUNCIÓN PARA OBTENER FEED DEL CLUB (SCOPE SCHOOL)
-- ============================================================

CREATE OR REPLACE FUNCTION get_school_social_feed(
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    team_id UUID,
    user_id UUID,
    content_text TEXT,
    media_url TEXT,
    media_type TEXT,
    thumbnail_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    is_pinned BOOLEAN,
    scope TEXT,
    author_name TEXT,
    author_role TEXT,
    team_name TEXT,
    is_liked_by_me BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sp.id,
        sp.created_at,
        sp.updated_at,
        sp.team_id,
        sp.user_id,
        sp.content_text,
        sp.media_url,
        sp.media_type,
        sp.thumbnail_url,
        sp.likes_count,
        sp.comments_count,
        sp.is_pinned,
        sp.scope,
        tm.user_full_name as author_name,
        tm.role as author_role,
        t.name as team_name,
        EXISTS(
            SELECT 1 FROM social_post_likes 
            WHERE post_id = sp.id 
            AND user_id = auth.uid()
        ) as is_liked_by_me
    FROM social_posts sp
    LEFT JOIN team_members tm ON sp.user_id = tm.user_id AND sp.team_id = tm.team_id
    LEFT JOIN teams t ON sp.team_id = t.id
    WHERE sp.scope = 'school'
    ORDER BY sp.is_pinned DESC, sp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- VERIFICACIÓN
-- ============================================================

SELECT 'Migración de scope completada exitosamente!' as status;

-- Verificar que la columna existe
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'social_posts' AND column_name = 'scope';
