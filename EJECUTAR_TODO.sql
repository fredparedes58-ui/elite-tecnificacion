-- ============================================================
-- 🚀 SCRIPT CONSOLIDADO - SISTEMA DE GOLEADORES COMPLETO
-- ============================================================
-- Ejecuta TODO en un solo paso en Supabase SQL Editor
-- Fecha: 2026-01-08
-- Categorías: Prebenjamín → Juvenil
-- ============================================================

-- ============================================================
-- PASO 1: AGREGAR CAMPO CATEGORY A LA TABLA TEAMS
-- ============================================================
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'teams' AND column_name = 'category'
    ) THEN
        ALTER TABLE teams ADD COLUMN category VARCHAR(50);
        RAISE NOTICE '✅ Campo category agregado a tabla teams';
    ELSE
        RAISE NOTICE '✓ Campo category ya existe en tabla teams';
    END IF;
END $$;

-- Agregar comentario con categorías oficiales
COMMENT ON COLUMN teams.category IS 'Categoría del equipo: Prebenjamín (Sub-7), Benjamín (Sub-9), Alevín (Sub-11), Infantil (Sub-13), Cadete (Sub-15), Juvenil (Sub-18)';

-- ============================================================
-- PASO 2: CREAR TABLA MATCH_STATS
-- ============================================================
CREATE TABLE IF NOT EXISTS match_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    
    -- Estadísticas principales
    goals INTEGER DEFAULT 0 CHECK (goals >= 0),
    assists INTEGER DEFAULT 0 CHECK (assists >= 0),
    minutes_played INTEGER DEFAULT 0 CHECK (minutes_played >= 0 AND minutes_played <= 120),
    
    -- Estadísticas adicionales
    yellow_cards INTEGER DEFAULT 0 CHECK (yellow_cards >= 0),
    red_cards INTEGER DEFAULT 0 CHECK (red_cards >= 0),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Un jugador solo puede tener una entrada por partido
    UNIQUE(match_id, player_id)
);

-- Mensaje de confirmación
DO $$ 
BEGIN
    RAISE NOTICE '✅ Tabla match_stats creada correctamente';
END $$;

-- ============================================================
-- PASO 3: CREAR ÍNDICES PARA OPTIMIZACIÓN
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_match_stats_match_id ON match_stats(match_id);
CREATE INDEX IF NOT EXISTS idx_match_stats_player_id ON match_stats(player_id);
CREATE INDEX IF NOT EXISTS idx_match_stats_team_id ON match_stats(team_id);
CREATE INDEX IF NOT EXISTS idx_match_stats_goals ON match_stats(goals) WHERE goals > 0;
CREATE INDEX IF NOT EXISTS idx_teams_category ON teams(category);

DO $$ 
BEGIN
    RAISE NOTICE '✅ Índices creados para optimización';
END $$;

-- ============================================================
-- PASO 4: HABILITAR ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE match_stats ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can view match stats of their teams" ON match_stats;
DROP POLICY IF EXISTS "Users can insert match stats for their teams" ON match_stats;
DROP POLICY IF EXISTS "Users can update match stats for their teams" ON match_stats;
DROP POLICY IF EXISTS "Users can delete match stats for their teams" ON match_stats;

-- Crear políticas de seguridad
CREATE POLICY "Users can view match stats of their teams"
ON match_stats FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM teams
        WHERE teams.id = match_stats.team_id
        AND teams.club_id = auth.uid()
    )
);

CREATE POLICY "Users can insert match stats for their teams"
ON match_stats FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM teams
        WHERE teams.id = match_stats.team_id
        AND teams.club_id = auth.uid()
    )
);

CREATE POLICY "Users can update match stats for their teams"
ON match_stats FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM teams
        WHERE teams.id = match_stats.team_id
        AND teams.club_id = auth.uid()
    )
);

CREATE POLICY "Users can delete match stats for their teams"
ON match_stats FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM teams
        WHERE teams.id = match_stats.team_id
        AND teams.club_id = auth.uid()
    )
);

DO $$ 
BEGIN
    RAISE NOTICE '✅ Políticas de seguridad RLS configuradas';
END $$;

-- ============================================================
-- PASO 5: FUNCIÓN PARA ACTUALIZAR UPDATED_AT AUTOMÁTICAMENTE
-- ============================================================
CREATE OR REPLACE FUNCTION update_match_stats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_match_stats_updated_at ON match_stats;

CREATE TRIGGER trigger_update_match_stats_updated_at
    BEFORE UPDATE ON match_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_match_stats_updated_at();

DO $$ 
BEGIN
    RAISE NOTICE '✅ Trigger de updated_at configurado';
END $$;

-- ============================================================
-- PASO 6: CREAR VISTA TOP_SCORERS (RANKING DE GOLEADORES)
-- ============================================================
CREATE OR REPLACE VIEW top_scorers AS
SELECT 
    p.id as player_id,
    p.name as player_name,
    p.photo_url,
    p.position,
    p.jersey_number,
    t.id as team_id,
    t.name as team_name,
    t.category,
    t.club_id,
    SUM(ms.goals) as total_goals,
    SUM(ms.assists) as total_assists,
    COUNT(DISTINCT ms.match_id) as matches_played,
    SUM(ms.minutes_played) as total_minutes,
    ROUND(CAST(SUM(ms.goals) AS NUMERIC) / NULLIF(COUNT(DISTINCT ms.match_id), 0), 2) as goals_per_match
FROM match_stats ms
JOIN players p ON ms.player_id = p.id
JOIN teams t ON ms.team_id = t.id
WHERE ms.goals > 0
GROUP BY p.id, p.name, p.photo_url, p.position, p.jersey_number, t.id, t.name, t.category, t.club_id
ORDER BY total_goals DESC, goals_per_match DESC;

DO $$ 
BEGIN
    RAISE NOTICE '✅ Vista top_scorers creada';
END $$;

-- ============================================================
-- PASO 7: FUNCIÓN - TOP SCORERS DE UN EQUIPO
-- ============================================================
CREATE OR REPLACE FUNCTION get_team_top_scorers(
    p_team_id UUID,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    player_id UUID,
    player_name TEXT,
    photo_url TEXT,
    position TEXT,
    jersey_number INTEGER,
    total_goals BIGINT,
    total_assists BIGINT,
    matches_played BIGINT,
    goals_per_match NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ts.player_id,
        ts.player_name,
        ts.photo_url,
        ts.position,
        ts.jersey_number,
        ts.total_goals,
        ts.total_assists,
        ts.matches_played,
        ts.goals_per_match
    FROM top_scorers ts
    WHERE ts.team_id = p_team_id
    ORDER BY ts.total_goals DESC, ts.goals_per_match DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
    RAISE NOTICE '✅ Función get_team_top_scorers creada';
END $$;

-- ============================================================
-- PASO 8: FUNCIÓN - TOP SCORERS POR CATEGORÍA
-- ============================================================
CREATE OR REPLACE FUNCTION get_category_top_scorers(
    p_category VARCHAR(50),
    p_club_id UUID,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    player_id UUID,
    player_name TEXT,
    photo_url TEXT,
    position TEXT,
    jersey_number INTEGER,
    team_name TEXT,
    total_goals BIGINT,
    total_assists BIGINT,
    matches_played BIGINT,
    goals_per_match NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ts.player_id,
        ts.player_name,
        ts.photo_url,
        ts.position,
        ts.jersey_number,
        ts.team_name,
        ts.total_goals,
        ts.total_assists,
        ts.matches_played,
        ts.goals_per_match
    FROM top_scorers ts
    WHERE ts.category = p_category
    AND ts.club_id = p_club_id
    ORDER BY ts.total_goals DESC, ts.goals_per_match DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
    RAISE NOTICE '✅ Función get_category_top_scorers creada';
END $$;

-- ============================================================
-- PASO 9: FUNCIÓN - TOP SCORERS GLOBALES DEL CLUB
-- ============================================================
CREATE OR REPLACE FUNCTION get_club_top_scorers(
    p_club_id UUID,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    player_id UUID,
    player_name TEXT,
    photo_url TEXT,
    position TEXT,
    jersey_number INTEGER,
    team_name TEXT,
    category TEXT,
    total_goals BIGINT,
    total_assists BIGINT,
    matches_played BIGINT,
    goals_per_match NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ts.player_id,
        ts.player_name,
        ts.photo_url,
        ts.position,
        ts.jersey_number,
        ts.team_name,
        ts.category,
        ts.total_goals,
        ts.total_assists,
        ts.matches_played,
        ts.goals_per_match
    FROM top_scorers ts
    WHERE ts.club_id = p_club_id
    ORDER BY ts.total_goals DESC, ts.goals_per_match DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
    RAISE NOTICE '✅ Función get_club_top_scorers creada';
END $$;

-- ============================================================
-- PASO 10: ASIGNAR CATEGORÍAS AUTOMÁTICAMENTE
-- ============================================================
-- Asignación automática por nombre de equipo

-- Prebenjamín (Sub-7)
UPDATE teams SET category = 'Prebenjamín' 
WHERE category IS NULL 
AND (
    name ILIKE '%prebenjam%' OR 
    name ILIKE '%sub-7%' OR 
    name ILIKE '%sub 7%'
);

-- Benjamín (Sub-9)
UPDATE teams SET category = 'Benjamín' 
WHERE category IS NULL 
AND (
    name ILIKE '%benjam%' OR 
    name ILIKE '%sub-9%' OR 
    name ILIKE '%sub 9%'
);

-- Alevín (Sub-11)
UPDATE teams SET category = 'Alevín' 
WHERE category IS NULL 
AND (
    name ILIKE '%alev%' OR 
    name ILIKE '%sub-11%' OR 
    name ILIKE '%sub 11%'
);

-- Infantil (Sub-13)
UPDATE teams SET category = 'Infantil' 
WHERE category IS NULL 
AND (
    name ILIKE '%infantil%' OR 
    name ILIKE '%sub-13%' OR 
    name ILIKE '%sub 13%'
);

-- Cadete (Sub-15)
UPDATE teams SET category = 'Cadete' 
WHERE category IS NULL 
AND (
    name ILIKE '%cadete%' OR 
    name ILIKE '%sub-15%' OR 
    name ILIKE '%sub 15%'
);

-- Juvenil (Sub-18)
UPDATE teams SET category = 'Juvenil' 
WHERE category IS NULL 
AND (
    name ILIKE '%juvenil%' OR 
    name ILIKE '%sub-18%' OR 
    name ILIKE '%sub 18%'
);

DO $$ 
BEGIN
    RAISE NOTICE '✅ Categorías asignadas automáticamente';
END $$;

-- ============================================================
-- VERIFICACIONES FINALES
-- ============================================================

-- Ver resumen de categorías asignadas
DO $$ 
DECLARE
    rec RECORD;
    total_teams INTEGER;
    teams_with_category INTEGER;
    teams_without_category INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_teams FROM teams;
    SELECT COUNT(*) INTO teams_with_category FROM teams WHERE category IS NOT NULL;
    SELECT COUNT(*) INTO teams_without_category FROM teams WHERE category IS NULL;
    
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════════════';
    RAISE NOTICE '🎉 INSTALACIÓN COMPLETADA EXITOSAMENTE';
    RAISE NOTICE '════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE '📊 RESUMEN:';
    RAISE NOTICE '   • Total de equipos: %', total_teams;
    RAISE NOTICE '   • Con categoría: %', teams_with_category;
    RAISE NOTICE '   • Sin categoría: %', teams_without_category;
    RAISE NOTICE '';
    
    IF teams_with_category > 0 THEN
        RAISE NOTICE '📋 DISTRIBUCIÓN POR CATEGORÍA:';
        FOR rec IN 
            SELECT 
                category,
                COUNT(*) as cantidad
            FROM teams
            WHERE category IS NOT NULL
            GROUP BY category
            ORDER BY 
                CASE category
                    WHEN 'Prebenjamín' THEN 1
                    WHEN 'Benjamín' THEN 2
                    WHEN 'Alevín' THEN 3
                    WHEN 'Infantil' THEN 4
                    WHEN 'Cadete' THEN 5
                    WHEN 'Juvenil' THEN 6
                    ELSE 7
                END
        LOOP
            RAISE NOTICE '   • %: % equipo(s)', rec.category, rec.cantidad;
        END LOOP;
    END IF;
    
    RAISE NOTICE '';
    
    IF teams_without_category > 0 THEN
        RAISE NOTICE '⚠️  EQUIPOS SIN CATEGORÍA:';
        FOR rec IN SELECT name FROM teams WHERE category IS NULL LOOP
            RAISE NOTICE '   • %', rec.name;
        END LOOP;
        RAISE NOTICE '';
        RAISE NOTICE '💡 Para asignar manualmente:';
        RAISE NOTICE '   UPDATE teams SET category = ''Alevín'' WHERE name = ''Nombre del Equipo'';';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ TABLAS CREADAS:';
    RAISE NOTICE '   • match_stats (con RLS habilitado)';
    RAISE NOTICE '   • Vista: top_scorers';
    RAISE NOTICE '';
    RAISE NOTICE '✅ FUNCIONES RPC CREADAS:';
    RAISE NOTICE '   • get_team_top_scorers()';
    RAISE NOTICE '   • get_category_top_scorers()';
    RAISE NOTICE '   • get_club_top_scorers()';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 PRÓXIMOS PASOS:';
    RAISE NOTICE '   1. Si hay equipos sin categoría, asígnalas manualmente';
    RAISE NOTICE '   2. Ejecuta la app de Flutter';
    RAISE NOTICE '   3. Registra estadísticas de partidos';
    RAISE NOTICE '   4. ¡Disfruta del sistema de goleadores!';
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════════════';
END $$;

-- Consulta final para verificar todo
SELECT 
    '✅ SISTEMA LISTO' as status,
    (SELECT COUNT(*) FROM teams WHERE category IS NOT NULL) as equipos_con_categoria,
    (SELECT COUNT(*) FROM teams WHERE category IS NULL) as equipos_sin_categoria,
    (SELECT COUNT(*) FROM match_stats) as estadisticas_registradas;

-- ============================================================
-- 🎉 INSTALACIÓN COMPLETA
-- ============================================================
-- Si llegaste hasta aquí sin errores, el sistema está listo.
-- Abre tu app de Flutter y comienza a registrar goles!
-- ============================================================
