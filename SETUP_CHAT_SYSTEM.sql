-- ============================================================
-- SCRIPT SQL: SISTEMA DE CHAT INTELIGENTE
-- ============================================================
-- Sistema de mensajería con dos tipos de canales:
-- 1. "Tablón del Entrenador" (announcement) - Solo lectura para padres
-- 2. "Vestuario" (general) - Chat libre para todos
-- ============================================================

-- ============================================================
-- PASO 1: CREAR TABLA chat_channels
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('announcement', 'general')),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, type) -- Un equipo solo puede tener un canal de cada tipo
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_chat_channels_team_id ON chat_channels(team_id);
CREATE INDEX IF NOT EXISTS idx_chat_channels_type ON chat_channels(type);
CREATE INDEX IF NOT EXISTS idx_chat_channels_team_type ON chat_channels(team_id, type);

-- Comentarios descriptivos
COMMENT ON TABLE chat_channels IS 'Canales de chat del equipo';
COMMENT ON COLUMN chat_channels.type IS 'announcement = Tablón del Entrenador (solo coach escribe), general = Vestuario (todos escriben)';
COMMENT ON COLUMN chat_channels.name IS 'Nombre del canal (ej: "Avisos Oficiales", "Vestuario")';

-- ============================================================
-- PASO 2: CREAR TABLA chat_messages
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  media_url TEXT, -- URL de foto o video (opcional)
  media_type TEXT CHECK (media_type IN ('image', 'video')), -- Tipo de media
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_chat_messages_channel_id ON chat_messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_channel_created ON chat_messages(channel_id, created_at DESC);

-- Comentarios descriptivos
COMMENT ON TABLE chat_messages IS 'Mensajes del chat';
COMMENT ON COLUMN chat_messages.media_url IS 'URL de foto o video adjunto (Cloudflare R2 o Bunny Stream)';
COMMENT ON COLUMN chat_messages.media_type IS 'Tipo de archivo adjunto: image o video';

-- ============================================================
-- PASO 3: TRIGGER PARA ACTUALIZAR updated_at
-- ============================================================
-- Usar la función existente update_updated_at_column() si ya existe
-- Si no existe, crearla
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a chat_channels
DROP TRIGGER IF EXISTS update_chat_channels_updated_at ON chat_channels;
CREATE TRIGGER update_chat_channels_updated_at
  BEFORE UPDATE ON chat_channels
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Aplicar trigger a chat_messages
DROP TRIGGER IF EXISTS update_chat_messages_updated_at ON chat_messages;
CREATE TRIGGER update_chat_messages_updated_at
  BEFORE UPDATE ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- PASO 4: VISTA PARA MENSAJES CON INFORMACIÓN DEL USUARIO
-- ============================================================
CREATE OR REPLACE VIEW chat_messages_detailed AS
SELECT 
  cm.id,
  cm.channel_id,
  cm.user_id,
  cm.content,
  cm.media_url,
  cm.media_type,
  cm.created_at,
  cm.updated_at,
  p.full_name AS user_name,
  p.avatar_url AS user_avatar_url,
  tm.role AS user_role,
  cc.team_id,
  cc.type AS channel_type,
  cc.name AS channel_name
FROM chat_messages cm
INNER JOIN profiles p ON cm.user_id = p.id
INNER JOIN chat_channels cc ON cm.channel_id = cc.id
LEFT JOIN team_members tm ON cm.user_id = tm.user_id AND cc.team_id = tm.team_id
ORDER BY cm.created_at DESC;

COMMENT ON VIEW chat_messages_detailed IS 'Vista con información completa de mensajes incluyendo datos del usuario';

-- ============================================================
-- PASO 5: HABILITAR ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE chat_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PASO 6: POLÍTICAS RLS PARA chat_channels
-- ============================================================

-- SELECT: Todos los miembros del equipo pueden ver los canales
CREATE POLICY "Members can view team channels"
  ON chat_channels
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      WHERE tm.team_id = chat_channels.team_id
        AND tm.user_id = auth.uid()
    )
  );

-- INSERT: Solo coaches/admins pueden crear canales
CREATE POLICY "Coaches can create channels"
  ON chat_channels
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM team_members tm
      WHERE tm.team_id = chat_channels.team_id
        AND tm.user_id = auth.uid()
        AND tm.role IN ('coach', 'admin')
    )
  );

-- UPDATE: Solo coaches/admins pueden actualizar canales
CREATE POLICY "Coaches can update channels"
  ON chat_channels
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      WHERE tm.team_id = chat_channels.team_id
        AND tm.user_id = auth.uid()
        AND tm.role IN ('coach', 'admin')
    )
  );

-- DELETE: Solo coaches/admins pueden eliminar canales
CREATE POLICY "Coaches can delete channels"
  ON chat_channels
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      WHERE tm.team_id = chat_channels.team_id
        AND tm.user_id = auth.uid()
        AND tm.role IN ('coach', 'admin')
    )
  );

-- ============================================================
-- PASO 7: POLÍTICAS RLS PARA chat_messages
-- ============================================================

-- SELECT: Todos los miembros del equipo pueden leer mensajes de sus canales
CREATE POLICY "Members can read team messages"
  ON chat_messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_channels cc
      INNER JOIN team_members tm ON cc.team_id = tm.team_id
      WHERE cc.id = chat_messages.channel_id
        AND tm.user_id = auth.uid()
    )
  );

-- INSERT: Política diferenciada por tipo de canal
-- Para 'announcement': Solo coaches/admins pueden escribir
-- Para 'general': Todos los miembros pueden escribir
CREATE POLICY "Members can write messages based on channel type"
  ON chat_messages
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_channels cc
      INNER JOIN team_members tm ON cc.team_id = tm.team_id
      WHERE cc.id = chat_messages.channel_id
        AND tm.user_id = auth.uid()
        AND (
          -- Canal general: todos pueden escribir
          (cc.type = 'general')
          OR
          -- Canal announcement: solo coaches/admins pueden escribir
          (cc.type = 'announcement' AND tm.role IN ('coach', 'admin'))
        )
    )
  );

-- UPDATE: Solo el autor del mensaje puede actualizarlo
CREATE POLICY "Users can update own messages"
  ON chat_messages
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DELETE: El autor o un coach/admin del equipo pueden eliminar mensajes
CREATE POLICY "Users and coaches can delete messages"
  ON chat_messages
  FOR DELETE
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM chat_channels cc
      INNER JOIN team_members tm ON cc.team_id = tm.team_id
      WHERE cc.id = chat_messages.channel_id
        AND tm.user_id = auth.uid()
        AND tm.role IN ('coach', 'admin')
    )
  );

-- ============================================================
-- PASO 8: FUNCIÓN PARA CREAR CANALES POR DEFECTO
-- ============================================================
-- Esta función crea los canales por defecto para un equipo si no existen
CREATE OR REPLACE FUNCTION ensure_default_channels(p_team_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Crear canal "Avisos Oficiales" si no existe
  INSERT INTO chat_channels (team_id, type, name)
  VALUES (p_team_id, 'announcement', 'Avisos Oficiales')
  ON CONFLICT (team_id, type) DO NOTHING;

  -- Crear canal "Vestuario" si no existe
  INSERT INTO chat_channels (team_id, type, name)
  VALUES (p_team_id, 'general', 'Vestuario')
  ON CONFLICT (team_id, type) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION ensure_default_channels IS 'Crea los canales por defecto (Avisos Oficiales y Vestuario) para un equipo';

-- ============================================================
-- PASO 9: TRIGGER PARA CREAR CANALES POR DEFECTO AL CREAR EQUIPO
-- ============================================================
-- Nota: Esto requiere que exista la tabla teams
-- Si no existe un trigger similar, puedes ejecutar manualmente:
-- SELECT ensure_default_channels('team-id-here');

-- ============================================================
-- PASO 10: HABILITAR REALTIME PARA MENSAJES
-- ============================================================
-- En Supabase Dashboard, ve a Database > Replication
-- Habilita la replicación para:
-- - chat_messages (para recibir mensajes en tiempo real)
-- - chat_channels (opcional, si quieres notificar cambios de canal)

-- ============================================================
-- NOTAS IMPORTANTES
-- ============================================================
-- 1. Para usar Realtime, asegúrate de habilitar la replicación
--    en Supabase Dashboard > Database > Replication
--
-- 2. Las notificaciones push se pueden implementar usando:
--    - Supabase Edge Functions (recomendado)
--    - Database Triggers + Webhooks
--    - Un servicio externo como N8N
--
-- 3. Para implementar notificaciones push:
--    - Crear un trigger AFTER INSERT en chat_messages
--    - El trigger puede llamar a una Edge Function o webhook
--    - La función/envío debe verificar los permisos del usuario
--
-- 4. Ejemplo de trigger para notificaciones (comentado):
--    CREATE OR REPLACE FUNCTION notify_new_message()
--    RETURNS TRIGGER AS $$
--    BEGIN
--      -- Aquí iría la lógica para enviar notificación push
--      -- Puede usar pg_notify o llamar a una Edge Function
--      PERFORM pg_notify('new_message', json_build_object(
--        'channel_id', NEW.channel_id,
--        'user_id', NEW.user_id,
--        'content', NEW.content
--      )::text);
--      RETURN NEW;
--    END;
--    $$ LANGUAGE plpgsql;
--
--    CREATE TRIGGER on_new_message
--      AFTER INSERT ON chat_messages
--      FOR EACH ROW
--      EXECUTE FUNCTION notify_new_message();
