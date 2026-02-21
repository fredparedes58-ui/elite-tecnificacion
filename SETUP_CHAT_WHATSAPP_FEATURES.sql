-- ============================================================
-- ACTUALIZACIÓN: CHAT CON FUNCIONES WHATSAPP
-- ============================================================
-- Agrega soporte para:
-- - Mensajes privados (uno a uno)
-- - Audio, documentos, ubicación
-- - Representantes de jugadores
-- ============================================================
-- NOTA: Este script asume que las tablas chat_channels y chat_messages ya existen.
-- Si no existen, ejecuta primero SETUP_CHAT_SYSTEM.sql
-- ============================================================

-- ============================================================
-- VERIFICACIÓN: Asegurar que las tablas existan
-- ============================================================

-- Crear tabla chat_channels si no existe
CREATE TABLE IF NOT EXISTS chat_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('announcement', 'general', 'private')),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  participant1_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  participant2_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  UNIQUE(team_id, type) -- Un equipo solo puede tener un canal de cada tipo
);

-- Crear tabla chat_messages si no existe
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  media_url TEXT,
  media_type TEXT CHECK (media_type IS NULL OR media_type IN ('image', 'video', 'audio', 'document', 'location')),
  recipient_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  is_private BOOLEAN DEFAULT FALSE,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  player_represented_id UUID REFERENCES team_members(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crear índices básicos si no existen
CREATE INDEX IF NOT EXISTS idx_chat_channels_team_id ON chat_channels(team_id);
CREATE INDEX IF NOT EXISTS idx_chat_channels_type ON chat_channels(type);
CREATE INDEX IF NOT EXISTS idx_chat_messages_channel_id ON chat_messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- ============================================================
-- PASO 1: ACTUALIZAR chat_messages con nuevos campos
-- ============================================================

-- Agregar campos para mensajes privados
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS recipient_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT FALSE;

-- Agregar campos para ubicaciones
ALTER TABLE chat_messages
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Agregar campo para representante de jugador
ALTER TABLE chat_messages
ADD COLUMN IF NOT EXISTS player_represented_id UUID REFERENCES team_members(id) ON DELETE SET NULL;

-- Actualizar CHECK constraint para incluir nuevos tipos de media
ALTER TABLE chat_messages 
DROP CONSTRAINT IF EXISTS chat_messages_media_type_check;

ALTER TABLE chat_messages
ADD CONSTRAINT chat_messages_media_type_check 
CHECK (media_type IS NULL OR media_type IN ('image', 'video', 'audio', 'document', 'location'));

-- Índices para mensajes privados
CREATE INDEX IF NOT EXISTS idx_chat_messages_recipient_id ON chat_messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_is_private ON chat_messages(is_private);
CREATE INDEX IF NOT EXISTS idx_chat_messages_private_chat ON chat_messages(user_id, recipient_id, created_at DESC);

-- Comentarios descriptivos
COMMENT ON COLUMN chat_messages.recipient_id IS 'ID del destinatario en mensajes privados (uno a uno)';
COMMENT ON COLUMN chat_messages.is_private IS 'Si es TRUE, el mensaje es privado entre user_id y recipient_id';
COMMENT ON COLUMN chat_messages.latitude IS 'Latitud para mensajes de ubicación';
COMMENT ON COLUMN chat_messages.longitude IS 'Longitud para mensajes de ubicación';
COMMENT ON COLUMN chat_messages.player_represented_id IS 'ID del jugador si el usuario es representante';

-- ============================================================
-- PASO 2: ACTUALIZAR team_members para representantes
-- ============================================================

-- Agregar campo para identificar representantes
ALTER TABLE team_members
ADD COLUMN IF NOT EXISTS is_representative BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS represented_player_id UUID REFERENCES team_members(id) ON DELETE SET NULL;

-- Comentarios
COMMENT ON COLUMN team_members.is_representative IS 'Si es TRUE, este usuario es representante de un jugador';
COMMENT ON COLUMN team_members.represented_player_id IS 'ID del jugador que representa (si es representante)';

-- Índice para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_team_members_representative ON team_members(is_representative, represented_player_id);

-- ============================================================
-- PASO 3: ACTUALIZAR chat_channels para chats privados
-- ============================================================

-- Actualizar CHECK constraint para incluir tipo 'private'
DO $$ 
BEGIN
  -- Intentar eliminar el constraint si existe
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'chat_channels_type_check' 
    AND table_name = 'chat_channels'
  ) THEN
    ALTER TABLE chat_channels DROP CONSTRAINT chat_channels_type_check;
  END IF;
  
  -- Agregar el nuevo constraint
  ALTER TABLE chat_channels
  ADD CONSTRAINT chat_channels_type_check 
  CHECK (type IN ('announcement', 'general', 'private'));
EXCEPTION
  WHEN others THEN
    -- Si ya existe el constraint correcto, no hacer nada
    NULL;
END $$;

-- Agregar campos para chats privados
ALTER TABLE chat_channels
ADD COLUMN IF NOT EXISTS participant1_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS participant2_id UUID REFERENCES profiles(id) ON DELETE CASCADE;

-- Comentarios
COMMENT ON COLUMN chat_channels.participant1_id IS 'Primer participante en chats privados';
COMMENT ON COLUMN chat_channels.participant2_id IS 'Segundo participante en chats privados';

-- Índice para búsquedas de chats privados
CREATE INDEX IF NOT EXISTS idx_chat_channels_private ON chat_channels(type, participant1_id, participant2_id);

-- ============================================================
-- PASO 4: ACTUALIZAR VISTA chat_messages_detailed
-- ============================================================

DROP VIEW IF EXISTS chat_messages_detailed;

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
  cm.recipient_id,
  cm.is_private,
  cm.latitude,
  cm.longitude,
  cm.player_represented_id,
  p.full_name AS user_name,
  p.avatar_url AS user_avatar_url,
  tm.role AS user_role,
  tm.is_representative AS user_is_representative,
  tm.represented_player_id AS user_represented_player_id,
  cc.team_id,
  cc.type AS channel_type,
  cc.name AS channel_name,
  cc.participant1_id,
  cc.participant2_id,
  -- Información del destinatario (si es mensaje privado)
  recipient_p.full_name AS recipient_name,
  recipient_p.avatar_url AS recipient_avatar_url,
  -- Información del jugador representado
  player_p.full_name AS player_represented_name,
  player_p.avatar_url AS player_represented_avatar_url
FROM chat_messages cm
INNER JOIN profiles p ON cm.user_id = p.id
INNER JOIN chat_channels cc ON cm.channel_id = cc.id
LEFT JOIN team_members tm ON cm.user_id = tm.user_id AND cc.team_id = tm.team_id
LEFT JOIN profiles recipient_p ON cm.recipient_id = recipient_p.id
LEFT JOIN team_members player_tm ON cm.player_represented_id = player_tm.id
LEFT JOIN profiles player_p ON player_tm.user_id = player_p.id
ORDER BY cm.created_at DESC;

COMMENT ON VIEW chat_messages_detailed IS 'Vista con información completa de mensajes incluyendo datos del usuario, destinatario y jugador representado';

-- ============================================================
-- PASO 5: ACTUALIZAR POLÍTICAS RLS PARA MENSAJES PRIVADOS
-- ============================================================

-- Actualizar política de SELECT para incluir mensajes privados
-- Solo intentar si RLS está habilitado
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chat_messages') THEN
    DROP POLICY IF EXISTS "Members can read team messages" ON chat_messages;
  END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

CREATE POLICY "Members can read team messages"
  ON chat_messages
  FOR SELECT
  USING (
    -- Mensajes en canales del equipo
    EXISTS (
      SELECT 1 FROM chat_channels cc
      INNER JOIN team_members tm ON cc.team_id = tm.team_id
      WHERE cc.id = chat_messages.channel_id
        AND tm.user_id = auth.uid()
        AND (cc.type = 'announcement' OR cc.type = 'general')
    )
    OR
    -- Mensajes privados donde el usuario es el remitente o destinatario
    (
      chat_messages.is_private = TRUE
      AND (
        chat_messages.user_id = auth.uid()
        OR chat_messages.recipient_id = auth.uid()
      )
    )
  );

-- Actualizar política de INSERT para incluir mensajes privados
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chat_messages') THEN
    DROP POLICY IF EXISTS "Members can write messages based on channel type" ON chat_messages;
  END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

CREATE POLICY "Members can write messages based on channel type"
  ON chat_messages
  FOR INSERT
  WITH CHECK (
    -- Mensajes en canales del equipo
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
    OR
    -- Mensajes privados: el remitente debe ser el usuario autenticado
    (
      chat_messages.is_private = TRUE
      AND chat_messages.user_id = auth.uid()
      AND chat_messages.recipient_id IS NOT NULL
      -- Verificar que el destinatario sea del mismo equipo
      AND EXISTS (
        SELECT 1 FROM team_members tm1, team_members tm2
        WHERE tm1.user_id = chat_messages.user_id
          AND tm2.user_id = chat_messages.recipient_id
          AND tm1.team_id = tm2.team_id
      )
    )
  );

-- ============================================================
-- PASO 6: FUNCIÓN PARA CREAR O OBTENER CHAT PRIVADO
-- ============================================================

CREATE OR REPLACE FUNCTION get_or_create_private_chat(
  p_user1_id UUID,
  p_user2_id UUID,
  p_team_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_channel_id UUID;
BEGIN
  -- Buscar chat privado existente
  SELECT id INTO v_channel_id
  FROM chat_channels
  WHERE type = 'private'
    AND (
      (participant1_id = p_user1_id AND participant2_id = p_user2_id)
      OR
      (participant1_id = p_user2_id AND participant2_id = p_user1_id)
    )
    AND team_id = p_team_id
  LIMIT 1;

  -- Si no existe, crear uno nuevo
  IF v_channel_id IS NULL THEN
    INSERT INTO chat_channels (team_id, type, name, participant1_id, participant2_id)
    VALUES (
      p_team_id,
      'private',
      'Chat Privado',
      p_user1_id,
      p_user2_id
    )
    RETURNING id INTO v_channel_id;
  END IF;

  RETURN v_channel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_or_create_private_chat IS 'Crea o obtiene un chat privado entre dos usuarios del mismo equipo';

-- ============================================================
-- PASO 7: POLÍTICAS RLS PARA CHATS PRIVADOS
-- ============================================================

-- SELECT: Los participantes pueden ver su chat privado
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chat_channels') THEN
    DROP POLICY IF EXISTS "Users can view their private chats" ON chat_channels;
  END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

CREATE POLICY "Users can view their private chats"
  ON chat_channels
  FOR SELECT
  USING (
    type != 'private'
    OR
    participant1_id = auth.uid()
    OR
    participant2_id = auth.uid()
  );

-- INSERT: Cualquier miembro del equipo puede crear un chat privado
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chat_channels') THEN
    DROP POLICY IF EXISTS "Members can create private chats" ON chat_channels;
  END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

CREATE POLICY "Members can create private chats"
  ON chat_channels
  FOR INSERT
  WITH CHECK (
    type != 'private'
    OR
    (
      participant1_id = auth.uid()
      AND participant2_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM team_members tm1, team_members tm2
        WHERE tm1.user_id = participant1_id
          AND tm2.user_id = participant2_id
          AND tm1.team_id = chat_channels.team_id
          AND tm2.team_id = chat_channels.team_id
      )
    )
  );
