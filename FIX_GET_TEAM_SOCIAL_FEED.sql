-- ============================================================
-- FIX: Actualizar función get_team_social_feed con parámetro p_scope
-- ============================================================
-- Script completo para crear tablas y función actualizada
-- Ejecutado exitosamente en Supabase
-- ============================================================

-- ============================================================
-- 1. CREACIÓN DE TABLAS (SI NO EXISTEN)
-- ============================================================

-- Crear la tabla social_posts si no existe
CREATE TABLE IF NOT EXISTS social_posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    team_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    content_text TEXT,
    media_url TEXT,
    media_type TEXT,
    thumbnail_url TEXT,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT false,
    scope TEXT NOT NULL DEFAULT 'team' CHECK (scope IN ('team', 'school'))
);

-- Crear la tabla de likes si no existe (necesaria para la función)
CREATE TABLE IF NOT EXISTS social_post_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES social_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ============================================================
-- 2. ASEGURAR COLUMNAS Y RESTRICCIONES
-- ============================================================

-- Por seguridad, si la tabla ya existía pero le faltaba la columna scope:
ALTER TABLE social_posts 
ADD COLUMN IF NOT EXISTS scope TEXT NOT NULL DEFAULT 'team';

-- Asegurar que el CHECK constraint exista (se elimina y recrea para evitar duplicados)
ALTER TABLE social_posts DROP CONSTRAINT IF EXISTS social_posts_scope_check;
ALTER TABLE social_posts ADD CONSTRAINT social_posts_scope_check CHECK (scope IN ('team', 'school'));

-- ============================================================
-- 3. ÍNDICES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_social_posts_scope ON social_posts(scope);
CREATE INDEX IF NOT EXISTS idx_social_posts_team_scope ON social_posts(team_id, scope);
CREATE INDEX IF NOT EXISTS idx_social_posts_user_id ON social_posts(user_id);

-- ============================================================
-- 4. FUNCIÓN ACTUALIZADA
-- ============================================================

CREATE OR REPLACE FUNCTION get_team_social_feed(
    p_team_id UUID,
    p_scope TEXT DEFAULT 'team',
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
        -- Si scope es 'school': mostrar todos los posts públicos de tipo school
        -- Nota: Asumimos que 'school' es global. Si school depende del team_id, agrega esa condición aquí.
        (p_scope = 'school' AND sp.scope = 'school')
    ORDER BY sp.is_pinned DESC, sp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT 'Tablas creadas y función get_team_social_feed actualizada correctamente!' as status;
