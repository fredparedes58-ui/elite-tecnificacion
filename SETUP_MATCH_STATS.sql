-- ============================================================
-- SETUP: SISTEMA DE ESTADÍSTICAS DE PARTIDOS Y GOLEADORES
-- ============================================================
-- Ejecutar en Supabase SQL Editor
-- Fecha: 2026-01-08
-- ============================================================

-- PASO 1: Asegurar que la tabla teams tiene el campo category
-- ============================================================
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'teams' AND column_name = 'category'
    ) THEN
        ALTER TABLE teams ADD COLUMN category VARCHAR(50);
        
        -- Valores por defecto para categorías comunes
        COMMENT ON COLUMN teams.category IS 'Categoría del equipo: Prebenjamín, Benjamín, Alevín, Infantil, Cadete, Juvenil, Senior';
    END IF;
END $$;

-- PASO 2: Crear tabla match_stats (Estadísticas individuales por partido)
-- ============================================================
CREATE TABLE IF NOT EXISTS match_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    
    -- Estadísticas de goles y asistencias
    goals INTEGER DEFAULT 0 CHECK (goals >= 0),
    assists INTEGER DEFAULT 0 CHECK (assists >= 0),
    
    -- Tiempo de juego
    minutes_played INTEGER DEFAULT 0 CHECK (minutes_played >= 0 AND minutes_played <= 120),
    
    -- Otras estadísticas opcionales (para futuro)
    yellow_cards INTEGER DEFAULT 0 CHECK (yellow_cards >= 0),
    red_cards INTEGER DEFAULT 0 CHECK (red_cards >= 0),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint: Un jugador solo puede tener una entrada por partido
    UNIQUE(match_id, player_id)
);

-- PASO 3: Crear índices para optimizar las consultas
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_match_stats_match_id ON match_stats(match_id);
CREATE INDEX IF NOT EXISTS idx_match_stats_player_id ON match_stats(player_id);
CREATE INDEX IF NOT EXISTS idx_match_stats_team_id ON match_stats(team_id);
CREATE INDEX IF NOT EXISTS idx_match_stats_goals ON match_stats(goals) WHERE goals > 0;

-- Índice para búsqueda por categoría de equipo
CREATE INDEX IF NOT EXISTS idx_teams_category ON teams(category);

-- PASO 4: Habilitar RLS (Row Level Security)
-- ============================================================
ALTER TABLE match_stats ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios pueden ver stats de partidos de sus equipos
CREATE POLICY "Users can view match stats of their teams"
ON match_stats
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM teams
        WHERE teams.id = match_stats.team_id
        AND teams.club_id = auth.uid()
    )
);

-- Política: Los usuarios pueden insertar/actualizar stats de sus equipos
CREATE POLICY "Users can insert match stats for their teams"
ON match_stats
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM teams
        WHERE teams.id = match_stats.team_id
        AND teams.club_id = auth.uid()
    )
);

CREATE POLICY "Users can update match stats for their teams"
ON match_stats
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM teams
        WHERE teams.id = match_stats.team_id
        AND teams.club_id = auth.uid()
    )
);

-- Política: Los usuarios pueden eliminar stats de sus equipos
CREATE POLICY "Users can delete match stats for their teams"
ON match_stats
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM teams
        WHERE teams.id = match_stats.team_id
        AND teams.club_id = auth.uid()
    )
);

-- PASO 5: Función para actualizar updated_at automáticamente
-- ============================================================
CREATE OR REPLACE FUNCTION update_match_stats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_match_stats_updated_at
    BEFORE UPDATE ON match_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_match_stats_updated_at();

-- PASO 6: Vista para Top Scorers (Ranking de Goleadores)
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
    -- Calcular promedio de goles por partido
    ROUND(CAST(SUM(ms.goals) AS NUMERIC) / NULLIF(COUNT(DISTINCT ms.match_id), 0), 2) as goals_per_match
FROM match_stats ms
JOIN players p ON ms.player_id = p.id
JOIN teams t ON ms.team_id = t.id
WHERE ms.goals > 0  -- Solo incluir jugadores con al menos un gol
GROUP BY p.id, p.name, p.photo_url, p.position, p.jersey_number, t.id, t.name, t.category, t.club_id
ORDER BY total_goals DESC, goals_per_match DESC;

-- PASO 7: Función para obtener goleadores por equipo
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

-- PASO 8: Función para obtener goleadores por categoría
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

-- PASO 9: Función para obtener goleadores globales del club
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

-- PASO 10: Datos de ejemplo para testing (OPCIONAL - Comentado)
-- ============================================================
/*
-- Ejemplo: Insertar estadísticas de prueba
INSERT INTO match_stats (match_id, player_id, team_id, goals, assists, minutes_played)
VALUES 
    ('match-uuid-1', 'player-uuid-1', 'team-uuid-1', 2, 1, 90),
    ('match-uuid-1', 'player-uuid-2', 'team-uuid-1', 1, 0, 75),
    ('match-uuid-2', 'player-uuid-1', 'team-uuid-1', 3, 2, 90);
*/

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
-- VERIFICACIÓN:
-- SELECT * FROM match_stats;
-- SELECT * FROM top_scorers;
-- SELECT * FROM get_team_top_scorers('your-team-id');
-- ============================================================
