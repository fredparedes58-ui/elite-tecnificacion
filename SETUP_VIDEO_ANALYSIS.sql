-- ============================================================
-- PASO 3: SISTEMA DE VIDEO ANÁLISIS PARA ENTRENADOR
-- ============================================================
-- Este script configura las tablas y políticas RLS necesarias
-- para el análisis de video privado del entrenador
-- ============================================================

-- ==========================================
-- TABLA 1: VIDEOS DE ANÁLISIS DE JUGADORES
-- ==========================================
-- Videos privados del entrenador para análisis técnico individual

CREATE TABLE IF NOT EXISTS player_analysis_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  
  -- Información del video
  video_url TEXT NOT NULL, -- URL del video en Bunny Stream (HLS playlist)
  thumbnail_url TEXT, -- Miniatura del video
  video_guid TEXT NOT NULL, -- GUID de Bunny Stream para tracking
  
  -- Metadatos
  title VARCHAR(200) NOT NULL,
  comments TEXT, -- Comentarios técnicos del entrenador
  analysis_type VARCHAR(50), -- 'technique', 'positioning', 'decision_making', etc.
  duration_seconds INTEGER, -- Duración del video
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Índices para búsquedas rápidas
  CONSTRAINT player_analysis_videos_pkey PRIMARY KEY (id)
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_player_analysis_player ON player_analysis_videos(player_id);
CREATE INDEX IF NOT EXISTS idx_player_analysis_coach ON player_analysis_videos(coach_id);
CREATE INDEX IF NOT EXISTS idx_player_analysis_team ON player_analysis_videos(team_id);
CREATE INDEX IF NOT EXISTS idx_player_analysis_created ON player_analysis_videos(created_at DESC);

-- ==========================================
-- POLÍTICAS RLS: PRIVACIDAD CRÍTICA
-- ==========================================
-- SOLO el entrenador que subió el video Y el jugador analizado pueden verlo

-- Habilitar RLS
ALTER TABLE player_analysis_videos ENABLE ROW LEVEL SECURITY;

-- Política 1: El entrenador puede insertar videos de análisis
CREATE POLICY "Coaches can upload player analysis videos"
ON player_analysis_videos FOR INSERT
WITH CHECK (
  auth.uid() = coach_id
  AND EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = player_analysis_videos.team_id
    AND user_id = auth.uid()
    AND role IN ('coach', 'admin')
  )
);

-- Política 2: Solo el entrenador que subió el video puede verlo
CREATE POLICY "Coaches can view their own analysis videos"
ON player_analysis_videos FOR SELECT
USING (
  auth.uid() = coach_id
);

-- Política 3: El jugador analizado puede ver SUS videos
CREATE POLICY "Players can view their own analysis videos"
ON player_analysis_videos FOR SELECT
USING (
  auth.uid() = player_id
);

-- Política 4: El entrenador puede actualizar sus videos
CREATE POLICY "Coaches can update their analysis videos"
ON player_analysis_videos FOR UPDATE
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

-- Política 5: El entrenador puede eliminar sus videos
CREATE POLICY "Coaches can delete their analysis videos"
ON player_analysis_videos FOR DELETE
USING (auth.uid() = coach_id);

-- ==========================================
-- TABLA 2: VIDEOS DE REFERENCIA TÁCTICA
-- ==========================================
-- Videos adjuntos a tácticas/jugadas guardadas en la pizarra

CREATE TABLE IF NOT EXISTS tactical_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Relación con táctica o sesión táctica
  tactical_session_id UUID REFERENCES tactical_sessions(id) ON DELETE CASCADE,
  alignment_id UUID REFERENCES alignments(id) ON DELETE CASCADE,
  
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Información del video
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  video_guid TEXT NOT NULL,
  
  -- Metadatos
  title VARCHAR(200) NOT NULL,
  description TEXT, -- Descripción de la jugada de referencia
  video_type VARCHAR(50) DEFAULT 'reference', -- 'reference', 'real_match', 'training'
  duration_seconds INTEGER,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Al menos uno debe estar presente
  CONSTRAINT tactical_videos_relation_check 
    CHECK (tactical_session_id IS NOT NULL OR alignment_id IS NOT NULL)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_tactical_videos_session ON tactical_videos(tactical_session_id);
CREATE INDEX IF NOT EXISTS idx_tactical_videos_alignment ON tactical_videos(alignment_id);
CREATE INDEX IF NOT EXISTS idx_tactical_videos_team ON tactical_videos(team_id);
CREATE INDEX IF NOT EXISTS idx_tactical_videos_coach ON tactical_videos(coach_id);

-- ==========================================
-- POLÍTICAS RLS: VIDEOS TÁCTICOS
-- ==========================================
-- Visible para todo el cuerpo técnico del equipo

ALTER TABLE tactical_videos ENABLE ROW LEVEL SECURITY;

-- Política 1: El cuerpo técnico puede subir videos tácticos
CREATE POLICY "Coaching staff can upload tactical videos"
ON tactical_videos FOR INSERT
WITH CHECK (
  auth.uid() = coach_id
  AND EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = tactical_videos.team_id
    AND user_id = auth.uid()
    AND role IN ('coach', 'admin')
  )
);

-- Política 2: Todo el cuerpo técnico puede ver videos tácticos
CREATE POLICY "Coaching staff can view tactical videos"
ON tactical_videos FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = tactical_videos.team_id
    AND user_id = auth.uid()
    AND role IN ('coach', 'admin')
  )
);

-- Política 3: El creador puede actualizar
CREATE POLICY "Coaches can update their tactical videos"
ON tactical_videos FOR UPDATE
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

-- Política 4: El creador puede eliminar
CREATE POLICY "Coaches can delete their tactical videos"
ON tactical_videos FOR DELETE
USING (auth.uid() = coach_id);

-- ==========================================
-- FUNCIÓN: ACTUALIZAR updated_at AUTOMÁTICAMENTE
-- ==========================================

CREATE OR REPLACE FUNCTION update_video_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar updated_at
CREATE TRIGGER player_analysis_videos_updated_at
  BEFORE UPDATE ON player_analysis_videos
  FOR EACH ROW
  EXECUTE FUNCTION update_video_updated_at();

CREATE TRIGGER tactical_videos_updated_at
  BEFORE UPDATE ON tactical_videos
  FOR EACH ROW
  EXECUTE FUNCTION update_video_updated_at();

-- ==========================================
-- VISTAS ÚTILES
-- ==========================================

-- Vista: Videos de análisis con información del jugador y entrenador
CREATE OR REPLACE VIEW player_analysis_videos_detailed AS
SELECT 
  pav.*,
  player_profile.full_name AS player_name,
  player_profile.avatar_url AS player_avatar,
  coach_profile.full_name AS coach_name,
  coach_profile.avatar_url AS coach_avatar,
  teams.name AS team_name
FROM player_analysis_videos pav
LEFT JOIN profiles player_profile ON pav.player_id = player_profile.id
LEFT JOIN profiles coach_profile ON pav.coach_id = coach_profile.id
LEFT JOIN teams ON pav.team_id = teams.id;

-- Vista: Videos tácticos con información completa
CREATE OR REPLACE VIEW tactical_videos_detailed AS
SELECT 
  tv.*,
  ts.name AS tactical_session_name,
  a.name AS alignment_name,
  coach_profile.full_name AS coach_name,
  teams.name AS team_name
FROM tactical_videos tv
LEFT JOIN tactical_sessions ts ON tv.tactical_session_id = ts.id
LEFT JOIN alignments a ON tv.alignment_id = a.id
LEFT JOIN profiles coach_profile ON tv.coach_id = coach_profile.id
LEFT JOIN teams ON tv.team_id = teams.id;

-- ==========================================
-- NOTIFICACIONES (OPCIONAL)
-- ==========================================
-- Notificar al jugador cuando el entrenador sube un video de análisis

CREATE OR REPLACE FUNCTION notify_player_new_analysis_video()
RETURNS TRIGGER AS $$
BEGIN
  -- Insertar notificación (asumiendo que existe tabla de notificaciones)
  -- Si no existe, esta función puede comentarse
  /*
  INSERT INTO notifications (user_id, type, title, message, related_id)
  VALUES (
    NEW.player_id,
    'video_analysis',
    'Nuevo video de análisis',
    'Tu entrenador ha subido un nuevo video de análisis técnico',
    NEW.id
  );
  */
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notify_player_analysis_video
  AFTER INSERT ON player_analysis_videos
  FOR EACH ROW
  EXECUTE FUNCTION notify_player_new_analysis_video();

-- ==========================================
-- COMENTARIOS DE DOCUMENTACIÓN
-- ==========================================

COMMENT ON TABLE player_analysis_videos IS 
'Videos de análisis técnico del entrenador para jugadores individuales. Máxima privacidad: solo entrenador y jugador analizado.';

COMMENT ON TABLE tactical_videos IS 
'Videos de referencia adjuntos a tácticas y jugadas. Visible para todo el cuerpo técnico.';

COMMENT ON COLUMN player_analysis_videos.analysis_type IS 
'Tipos: technique, positioning, decision_making, fitness, mental, recovery';

COMMENT ON COLUMN tactical_videos.video_type IS 
'Tipos: reference (jugada profesional), real_match (partido real del equipo), training (entrenamiento)';

-- ==========================================
-- DATOS DE EJEMPLO (OPCIONAL - COMENTADO)
-- ==========================================

/*
-- Ejemplo de video de análisis (requiere IDs reales de usuarios y equipos)
INSERT INTO player_analysis_videos 
  (player_id, coach_id, team_id, video_url, thumbnail_url, video_guid, title, comments, analysis_type)
VALUES 
  (
    'uuid-del-jugador',
    'uuid-del-entrenador',
    'uuid-del-equipo',
    'https://vz-xxx.b-cdn.net/guid-123/playlist.m3u8',
    'https://vz-xxx.b-cdn.net/guid-123/thumbnail.jpg',
    'guid-123',
    'Mejora en Pases Largos',
    'Trabajar el seguimiento del balón con la vista y mejorar la precisión en distancias de más de 30m.',
    'technique'
  );
*/

-- ==========================================
-- VERIFICACIÓN FINAL
-- ==========================================

-- Verificar que las tablas existen
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'player_analysis_videos') THEN
    RAISE NOTICE '✅ Tabla player_analysis_videos creada correctamente';
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'tactical_videos') THEN
    RAISE NOTICE '✅ Tabla tactical_videos creada correctamente';
  END IF;
END $$;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
-- Ejecuta este script en tu panel de Supabase SQL Editor
-- Orden de ejecución:
-- 1. Asegúrate de que existen las tablas: teams, team_members, tactical_sessions, alignments
-- 2. Ejecuta este script completo
-- 3. Verifica las políticas RLS en el dashboard de Supabase
-- ============================================================
