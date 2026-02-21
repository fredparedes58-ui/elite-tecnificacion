-- ============================================================
-- SETUP PROMATCH ANALYSIS SYSTEM
-- ============================================================
-- Tabla para almacenar eventos de análisis durante partidos
-- con soporte para Voice Tagging y Telestration
-- ============================================================

-- Eliminar tabla si existe (solo para desarrollo/reseteo)
DROP TABLE IF EXISTS analysis_events CASCADE;

-- ============================================================
-- TABLA: analysis_events
-- ============================================================
-- Almacena cada evento marcado durante el análisis de video
-- Incluye: timestamp del video, tipo de evento, jugador implicado,
-- transcripción de voz y URL del dibujo táctico
-- ============================================================

CREATE TABLE analysis_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Referencias
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  player_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  coach_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  
  -- Información del Video
  video_timestamp INTEGER NOT NULL, -- Segundos desde el inicio del video
  video_guid TEXT, -- GUID del video en Bunny Stream (si aplica)
  
  -- Información del Evento
  event_type TEXT NOT NULL, -- 'gol', 'pase', 'error', 'robo', 'voice_note', 'custom'
  event_title TEXT, -- Título o resumen del evento
  
  -- Voice Tagging
  voice_transcript TEXT, -- Transcripción textual de lo dicho por el entrenador
  voice_confidence DECIMAL(3,2), -- Confianza del reconocimiento (0.0 - 1.0)
  
  -- Telestration (Dibujo Táctico)
  drawing_url TEXT, -- URL de la captura del dibujo en R2
  drawing_data JSONB, -- Datos del dibujo (coordenadas, colores, etc.) en formato JSON
  
  -- Metadata adicional
  notes TEXT, -- Notas adicionales del entrenador
  tags TEXT[], -- Tags adicionales para búsqueda (ej: ['ataque', 'contraataque'])
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Restricciones
  CONSTRAINT valid_video_timestamp CHECK (video_timestamp >= 0),
  CONSTRAINT valid_confidence CHECK (voice_confidence IS NULL OR (voice_confidence >= 0 AND voice_confidence <= 1))
);

-- ============================================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================================

CREATE INDEX idx_analysis_events_match_id ON analysis_events(match_id);
CREATE INDEX idx_analysis_events_team_id ON analysis_events(team_id);
CREATE INDEX idx_analysis_events_player_id ON analysis_events(player_id);
CREATE INDEX idx_analysis_events_coach_id ON analysis_events(coach_id);
CREATE INDEX idx_analysis_events_event_type ON analysis_events(event_type);
CREATE INDEX idx_analysis_events_video_timestamp ON analysis_events(video_timestamp);
CREATE INDEX idx_analysis_events_created_at ON analysis_events(created_at);
CREATE INDEX idx_analysis_events_tags ON analysis_events USING GIN(tags); -- Para búsquedas en arrays

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE analysis_events ENABLE ROW LEVEL SECURITY;

-- Policy: Los entrenadores pueden ver todos los eventos de su equipo
CREATE POLICY "Coaches can view team analysis events"
  ON analysis_events FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM team_members 
      WHERE user_id = auth.uid() 
      AND (role = 'coach' OR role = 'admin')
    )
  );

-- Policy: Los entrenadores pueden crear eventos para su equipo
CREATE POLICY "Coaches can create analysis events"
  ON analysis_events FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM team_members 
      WHERE user_id = auth.uid() 
      AND (role = 'coach' OR role = 'admin')
    )
    AND coach_id = auth.uid()
  );

-- Policy: Los entrenadores pueden actualizar sus propios eventos
CREATE POLICY "Coaches can update own analysis events"
  ON analysis_events FOR UPDATE
  USING (coach_id = auth.uid())
  WITH CHECK (coach_id = auth.uid());

-- Policy: Los entrenadores pueden eliminar sus propios eventos
CREATE POLICY "Coaches can delete own analysis events"
  ON analysis_events FOR DELETE
  USING (coach_id = auth.uid());

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_analysis_events_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_analysis_events_updated_at
  BEFORE UPDATE ON analysis_events
  FOR EACH ROW
  EXECUTE FUNCTION update_analysis_events_updated_at();

-- ============================================================
-- VISTA: analysis_events_detailed
-- ============================================================
-- Vista enriquecida con información de jugador, entrenador y equipo
-- ============================================================

CREATE OR REPLACE VIEW analysis_events_detailed AS
SELECT 
  ae.id,
  ae.match_id,
  ae.team_id,
  ae.player_id,
  ae.coach_id,
  ae.video_timestamp,
  ae.video_guid,
  ae.event_type,
  ae.event_title,
  ae.voice_transcript,
  ae.voice_confidence,
  ae.drawing_url,
  ae.drawing_data,
  ae.notes,
  ae.tags,
  ae.created_at,
  ae.updated_at,
  
  -- Información del Jugador
  p_player.full_name AS player_name,
  p_player.avatar_url AS player_avatar,
  p_player.jersey_number AS player_number,
  
  -- Información del Entrenador
  p_coach.full_name AS coach_name,
  p_coach.avatar_url AS coach_avatar,
  
  -- Información del Equipo
  t.name AS team_name,
  t.badge_url AS team_badge
  
FROM analysis_events ae
LEFT JOIN profiles p_player ON ae.player_id = p_player.id
LEFT JOIN profiles p_coach ON ae.coach_id = p_coach.id
LEFT JOIN teams t ON ae.team_id = t.id;

-- Conceder acceso a la vista
GRANT SELECT ON analysis_events_detailed TO authenticated;

-- ============================================================
-- TIPOS DE EVENTOS PREDEFINIDOS
-- ============================================================
-- Tabla de referencia para tipos de eventos comunes
-- ============================================================

DROP TABLE IF EXISTS event_types CASCADE;

CREATE TABLE event_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL, -- 'offensive', 'defensive', 'neutral', 'error'
  icon TEXT, -- Nombre del icono Material
  color TEXT, -- Color hex para UI
  keywords TEXT[], -- Keywords para auto-detección en voice tagging
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar tipos de eventos predefinidos
INSERT INTO event_types (id, name, category, icon, color, keywords) VALUES
  ('gol', 'Gol', 'offensive', 'sports_soccer', '#4CAF50', ARRAY['gol', 'goal', 'tanto', 'anotación']),
  ('tiro', 'Tiro', 'offensive', 'adjust', '#2196F3', ARRAY['tiro', 'disparo', 'remate', 'chut']),
  ('pase', 'Pase Clave', 'offensive', 'swap_calls', '#00BCD4', ARRAY['pase', 'asistencia', 'habilitación']),
  ('perdida', 'Pérdida', 'error', 'warning', '#FF9800', ARRAY['pérdida', 'perdida', 'error', 'fallo']),
  ('robo', 'Recuperación', 'defensive', 'sports_kabaddi', '#9C27B0', ARRAY['robo', 'recuperación', 'intercepción', 'quite']),
  ('falta', 'Falta', 'error', 'block', '#F44336', ARRAY['falta', 'infracción']),
  ('corner', 'Córner', 'offensive', 'flag', '#FFC107', ARRAY['córner', 'corner', 'esquina', 'tiro de esquina']),
  ('tarjeta_amarilla', 'Tarjeta Amarilla', 'error', 'style', '#FFEB3B', ARRAY['amarilla', 'tarjeta amarilla', 'amonestación']),
  ('tarjeta_roja', 'Tarjeta Roja', 'error', 'cancel', '#D32F2F', ARRAY['roja', 'tarjeta roja', 'expulsión']),
  ('cambio', 'Sustitución', 'neutral', 'swap_horiz', '#607D8B', ARRAY['cambio', 'sustitución', 'relevo']),
  ('lesion', 'Lesión', 'neutral', 'local_hospital', '#E91E63', ARRAY['lesión', 'lesion', 'dolor', 'herida']),
  ('voice_note', 'Nota de Voz', 'neutral', 'mic', '#9E9E9E', ARRAY['nota', 'observación', 'comentario']),
  ('custom', 'Personalizado', 'neutral', 'edit', '#757575', ARRAY[]);

-- ============================================================
-- FUNCIONES AUXILIARES
-- ============================================================

-- Función: Obtener eventos de un partido ordenados por timestamp
CREATE OR REPLACE FUNCTION get_match_analysis_timeline(p_match_id UUID)
RETURNS TABLE (
  id UUID,
  video_timestamp INTEGER,
  event_type TEXT,
  event_title TEXT,
  player_name TEXT,
  voice_transcript TEXT,
  drawing_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ae.id,
    ae.video_timestamp,
    ae.event_type,
    ae.event_title,
    p.full_name AS player_name,
    ae.voice_transcript,
    ae.drawing_url,
    ae.created_at
  FROM analysis_events ae
  LEFT JOIN profiles p ON ae.player_id = p.id
  WHERE ae.match_id = p_match_id
  ORDER BY ae.video_timestamp ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- PERMISOS
-- ============================================================

GRANT SELECT ON event_types TO authenticated;
GRANT EXECUTE ON FUNCTION get_match_analysis_timeline(UUID) TO authenticated;

-- ============================================================
-- FINALIZACIÓN
-- ============================================================

COMMENT ON TABLE analysis_events IS 'Eventos de análisis marcados durante videos de partidos con voice tagging y telestration';
COMMENT ON TABLE event_types IS 'Catálogo de tipos de eventos predefinidos para análisis';
COMMENT ON VIEW analysis_events_detailed IS 'Vista enriquecida de eventos con información de jugador, entrenador y equipo';
COMMENT ON FUNCTION get_match_analysis_timeline(UUID) IS 'Obtiene la línea de tiempo de eventos de análisis para un partido';

-- ✅ Setup completado exitosamente
