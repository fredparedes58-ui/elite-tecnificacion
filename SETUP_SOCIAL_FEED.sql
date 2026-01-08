-- ============================================================
-- SETUP: SOCIAL FEED - Módulo de Feed Social tipo Instagram
-- ============================================================
-- Fecha: 2026-01-08
-- Descripción: Sistema de posts sociales para compartir momentos del equipo
-- ============================================================

-- 1. CREAR TABLA DE POSTS SOCIALES
-- ============================================================

CREATE TABLE IF NOT EXISTS social_posts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Referencias
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Contenido
    content_text TEXT,
    media_url TEXT NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    thumbnail_url TEXT, -- Para videos
    
    -- Metadata
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    
    -- Índices para mejorar rendimiento
    CONSTRAINT valid_media_type CHECK (media_type IN ('image', 'video'))
);

-- 2. ÍNDICES PARA OPTIMIZACIÓN
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_social_posts_team_id ON social_posts(team_id);
CREATE INDEX IF NOT EXISTS idx_social_posts_user_id ON social_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_social_posts_created_at ON social_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_social_posts_team_created ON social_posts(team_id, created_at DESC);

-- 3. TRIGGER PARA ACTUALIZAR updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_social_posts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_social_posts_updated_at
    BEFORE UPDATE ON social_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_social_posts_updated_at();

-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE social_posts ENABLE ROW LEVEL SECURITY;

-- Política de lectura: Solo miembros del equipo pueden ver los posts
CREATE POLICY "Los miembros del equipo pueden ver posts"
    ON social_posts FOR SELECT
    USING (
        team_id IN (
            SELECT team_id FROM team_members 
            WHERE user_id = auth.uid()
        )
    );

-- Política de inserción: Usuarios autenticados pueden crear posts de su equipo
CREATE POLICY "Los miembros pueden crear posts"
    ON social_posts FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND team_id IN (
            SELECT team_id FROM team_members 
            WHERE user_id = auth.uid()
        )
    );

-- Política de actualización: Solo el autor o admin puede editar
CREATE POLICY "Solo el autor puede actualizar su post"
    ON social_posts FOR UPDATE
    USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM team_members
            WHERE team_members.user_id = auth.uid()
            AND team_members.team_id = social_posts.team_id
            AND team_members.role IN ('admin', 'coach')
        )
    );

-- Política de eliminación: Solo el autor o admin puede eliminar
CREATE POLICY "Solo el autor o admin puede eliminar posts"
    ON social_posts FOR DELETE
    USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM team_members
            WHERE team_members.user_id = auth.uid()
            AND team_members.team_id = social_posts.team_id
            AND team_members.role IN ('admin', 'coach')
        )
    );

-- 5. TABLA DE LIKES (OPCIONAL - PARA FUTURA EXPANSIÓN)
-- ============================================================

CREATE TABLE IF NOT EXISTS social_post_likes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    post_id UUID NOT NULL REFERENCES social_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Un usuario solo puede dar like una vez por post
    UNIQUE(post_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_social_post_likes_post_id ON social_post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_social_post_likes_user_id ON social_post_likes(user_id);

-- RLS para likes
ALTER TABLE social_post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los miembros pueden ver likes"
    ON social_post_likes FOR SELECT
    USING (
        post_id IN (
            SELECT id FROM social_posts
            WHERE team_id IN (
                SELECT team_id FROM team_members 
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Los miembros pueden dar like"
    ON social_post_likes FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND post_id IN (
            SELECT id FROM social_posts
            WHERE team_id IN (
                SELECT team_id FROM team_members 
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Los usuarios pueden quitar su like"
    ON social_post_likes FOR DELETE
    USING (auth.uid() = user_id);

-- 6. FUNCIÓN PARA ACTUALIZAR CONTADOR DE LIKES
-- ============================================================

CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE social_posts
        SET likes_count = likes_count + 1
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE social_posts
        SET likes_count = likes_count - 1
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_likes_count_insert
    AFTER INSERT ON social_post_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_post_likes_count();

CREATE TRIGGER trigger_update_likes_count_delete
    AFTER DELETE ON social_post_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_post_likes_count();

-- 7. VISTA ENRIQUECIDA CON INFORMACIÓN DEL AUTOR
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

-- 8. FUNCIÓN PARA OBTENER FEED DEL EQUIPO
-- ============================================================

CREATE OR REPLACE FUNCTION get_team_social_feed(
    p_team_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    team_id UUID,
    user_id UUID,
    content_text TEXT,
    media_url TEXT,
    media_type TEXT,
    thumbnail_url TEXT,
    likes_count INTEGER,
    author_name TEXT,
    author_role TEXT,
    is_liked_by_me BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sp.id,
        sp.created_at,
        sp.team_id,
        sp.user_id,
        sp.content_text,
        sp.media_url,
        sp.media_type,
        sp.thumbnail_url,
        sp.likes_count,
        tm.user_full_name as author_name,
        tm.role as author_role,
        EXISTS(
            SELECT 1 FROM social_post_likes 
            WHERE post_id = sp.id 
            AND user_id = auth.uid()
        ) as is_liked_by_me
    FROM social_posts sp
    LEFT JOIN team_members tm ON sp.user_id = tm.user_id AND sp.team_id = tm.team_id
    WHERE sp.team_id = p_team_id
    ORDER BY sp.is_pinned DESC, sp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FIN DEL SETUP
-- ============================================================

-- VERIFICACIÓN
SELECT 'Social Feed Setup completado exitosamente!' as status;
