-- ============================================================
-- ACTUALIZACIÓN: SISTEMA HÍBRIDO (LIVE + VIDEO SYNC)
-- ============================================================
-- Actualiza las tablas existentes para soportar el modo Live
-- y la sincronización posterior con video
-- ============================================================

-- ============================================================
-- 1. ACTUALIZAR TABLA: analysis_events
-- ============================================================
-- Añadir el campo match_timestamp (tiempo real del partido)
-- y hacer video_timestamp nullable

ALTER TABLE analysis_events
ADD COLUMN IF NOT EXISTS match_timestamp INTEGER NOT NULL DEFAULT 0;

-- Hacer video_timestamp nullable (puede ser NULL si es evento Live)
ALTER TABLE analysis_events
ALTER COLUMN video_timestamp DROP NOT NULL;

-- Migrar datos existentes: si solo tienen video_timestamp, copiarlo a match_timestamp
UPDATE analysis_events
SET match_timestamp = video_timestamp
WHERE match_timestamp = 0 AND video_timestamp IS NOT NULL;

-- Comentarios
COMMENT ON COLUMN analysis_events.match_timestamp IS 'Tiempo real del partido en segundos desde el pitido inicial';
COMMENT ON COLUMN analysis_events.video_timestamp IS 'Tiempo del video en segundos (NULL si fue creado en modo Live sin sincronizar)';

-- ============================================================
-- 2. ACTUALIZAR/CREAR TABLA: matches
-- ============================================================
-- Añadir campo para el offset de sincronización

ALTER TABLE matches
ADD COLUMN IF NOT EXISTS video_offset INTEGER DEFAULT 0;

ALTER TABLE matches
ADD COLUMN IF NOT EXISTS video_duration INTEGER;

ALTER TABLE matches
ADD COLUMN IF NOT EXISTS is_synced BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN matches.video_offset IS 'Diferencia en segundos entre el inicio del video y el pitido inicial del árbitro';
COMMENT ON COLUMN matches.video_duration IS 'Duración total del video en segundos';
COMMENT ON COLUMN matches.is_synced IS 'Indica si los eventos Live ya fueron sincronizados con el video';

-- ============================================================
-- 3. ACTUALIZAR VISTA: analysis_events_detailed
-- ============================================================
-- Recrear la vista para incluir los nuevos campos

DROP VIEW IF EXISTS analysis_events_detailed CASCADE;

CREATE OR REPLACE VIEW analysis_events_detailed AS
SELECT 
  ae.id,
  ae.match_id,
  ae.team_id,
  ae.player_id,
  ae.coach_id,
  
  -- Campos de tiempo
  ae.match_timestamp,
  ae.video_timestamp,
  ae.video_guid,
  
  -- Información del evento
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
  t.badge_url AS team_badge,
  
  -- Información del Partido (para sync)
  m.video_offset AS match_video_offset,
  m.is_synced AS match_is_synced
  
FROM analysis_events ae
LEFT JOIN profiles p_player ON ae.player_id = p_player.id
LEFT JOIN profiles p_coach ON ae.coach_id = p_coach.id
LEFT JOIN teams t ON ae.team_id = t.id
LEFT JOIN matches m ON ae.match_id = m.id;

-- Conceder acceso
GRANT SELECT ON analysis_events_detailed TO authenticated;

-- ============================================================
-- 4. FUNCIÓN: SINCRONIZAR EVENTOS CON VIDEO
-- ============================================================
-- Actualiza todos los eventos Live de un partido con el video_offset

CREATE OR REPLACE FUNCTION sync_live_events_with_video(
  p_match_id UUID,
  p_video_offset INTEGER
)
RETURNS TABLE (
  events_synced INTEGER,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  v_events_count INTEGER;
BEGIN
  -- Contar eventos que se van a sincronizar
  SELECT COUNT(*) INTO v_events_count
  FROM analysis_events
  WHERE match_id = p_match_id
    AND video_timestamp IS NULL;
  
  -- Si no hay eventos para sincronizar
  IF v_events_count = 0 THEN
    RETURN QUERY SELECT 0, TRUE, 'No hay eventos Live para sincronizar'::TEXT;
    RETURN;
  END IF;
  
  -- Actualizar video_timestamp = match_timestamp + offset
  UPDATE analysis_events
  SET 
    video_timestamp = match_timestamp + p_video_offset,
    updated_at = NOW()
  WHERE match_id = p_match_id
    AND video_timestamp IS NULL;
  
  -- Actualizar el partido como sincronizado
  UPDATE matches
  SET 
    video_offset = p_video_offset,
    is_synced = TRUE,
    updated_at = NOW()
  WHERE id = p_match_id;
  
  -- Retornar resultado
  RETURN QUERY SELECT 
    v_events_count,
    TRUE,
    format('Se sincronizaron %s eventos correctamente', v_events_count)::TEXT;
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT 
      0,
      FALSE,
      format('Error: %s', SQLERRM)::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Conceder acceso
GRANT EXECUTE ON FUNCTION sync_live_events_with_video(UUID, INTEGER) TO authenticated;

-- ============================================================
-- 5. FUNCIÓN: VERIFICAR SI HAY EVENTOS LIVE SIN SINCRONIZAR
-- ============================================================

CREATE OR REPLACE FUNCTION has_unsynced_live_events(p_match_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM analysis_events
    WHERE match_id = p_match_id
      AND video_timestamp IS NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION has_unsynced_live_events(UUID) TO authenticated;

-- ============================================================
-- 6. FUNCIÓN: OBTENER ESTADÍSTICAS DE EVENTOS LIVE
-- ============================================================

CREATE OR REPLACE FUNCTION get_live_events_stats(p_match_id UUID)
RETURNS TABLE (
  total_events INTEGER,
  synced_events INTEGER,
  unsynced_events INTEGER,
  events_by_type JSONB
) AS $$
BEGIN
  RETURN QUERY
  WITH stats AS (
    SELECT
      COUNT(*)::INTEGER AS total,
      COUNT(video_timestamp)::INTEGER AS synced,
      COUNT(*) FILTER (WHERE video_timestamp IS NULL)::INTEGER AS unsynced,
      jsonb_object_agg(
        event_type,
        COUNT(*)
      ) AS by_type
    FROM analysis_events
    WHERE match_id = p_match_id
  )
  SELECT 
    total,
    synced,
    unsynced,
    by_type
  FROM stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_live_events_stats(UUID) TO authenticated;

-- ============================================================
-- 7. ÍNDICES ADICIONALES PARA PERFORMANCE
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_analysis_events_match_timestamp 
  ON analysis_events(match_timestamp);

CREATE INDEX IF NOT EXISTS idx_analysis_events_video_timestamp_null 
  ON analysis_events(match_id) 
  WHERE video_timestamp IS NULL;

CREATE INDEX IF NOT EXISTS idx_matches_is_synced 
  ON matches(is_synced);

-- ============================================================
-- 8. ACTUALIZAR FUNCIÓN TIMELINE (SI EXISTE)
-- ============================================================

DROP FUNCTION IF EXISTS get_match_analysis_timeline(UUID);

CREATE OR REPLACE FUNCTION get_match_analysis_timeline(p_match_id UUID)
RETURNS TABLE (
  id UUID,
  match_timestamp INTEGER,
  video_timestamp INTEGER,
  event_type TEXT,
  event_title TEXT,
  player_name TEXT,
  voice_transcript TEXT,
  drawing_url TEXT,
  is_live_event BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ae.id,
    ae.match_timestamp,
    ae.video_timestamp,
    ae.event_type,
    ae.event_title,
    p.full_name AS player_name,
    ae.voice_transcript,
    ae.drawing_url,
    (ae.video_timestamp IS NULL) AS is_live_event,
    ae.created_at
  FROM analysis_events ae
  LEFT JOIN profiles p ON ae.player_id = p.id
  WHERE ae.match_id = p_match_id
  ORDER BY ae.match_timestamp ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_match_analysis_timeline(UUID) TO authenticated;

-- ============================================================
-- 9. TRIGGER: VALIDAR TIMESTAMPS
-- ============================================================

CREATE OR REPLACE FUNCTION validate_event_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  -- match_timestamp siempre debe ser >= 0
  IF NEW.match_timestamp < 0 THEN
    RAISE EXCEPTION 'match_timestamp no puede ser negativo';
  END IF;
  
  -- Si hay video_timestamp, debe ser >= 0
  IF NEW.video_timestamp IS NOT NULL AND NEW.video_timestamp < 0 THEN
    RAISE EXCEPTION 'video_timestamp no puede ser negativo';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_event_timestamps ON analysis_events;

CREATE TRIGGER trigger_validate_event_timestamps
  BEFORE INSERT OR UPDATE ON analysis_events
  FOR EACH ROW
  EXECUTE FUNCTION validate_event_timestamps();

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================

DO $$
BEGIN
  -- Verificar que la columna match_timestamp existe
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'analysis_events'
      AND column_name = 'match_timestamp'
  ) THEN
    RAISE EXCEPTION 'Error: No se pudo crear la columna match_timestamp';
  END IF;
  
  -- Verificar que video_timestamp es nullable
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'analysis_events'
      AND column_name = 'video_timestamp'
      AND is_nullable = 'NO'
  ) THEN
    RAISE EXCEPTION 'Error: video_timestamp debe ser nullable';
  END IF;
  
  RAISE NOTICE '✅ Sistema Híbrido configurado correctamente';
END $$;

-- ============================================================
-- FINALIZACIÓN
-- ============================================================

COMMENT ON FUNCTION sync_live_events_with_video(UUID, INTEGER) IS 
  'Sincroniza eventos Live con el video aplicando el offset temporal';

COMMENT ON FUNCTION has_unsynced_live_events(UUID) IS 
  'Verifica si un partido tiene eventos Live sin sincronizar';

COMMENT ON FUNCTION get_live_events_stats(UUID) IS 
  'Obtiene estadísticas de eventos Live y sincronizados de un partido';

-- ✅ Actualización completada exitosamente
