-- Migración: Tabla device_tokens para almacenar tokens de push notifications
-- Fecha: 2026-02-20

-- Crear tabla device_tokens
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Un usuario puede tener múltiples dispositivos, pero no duplicados del mismo token
  UNIQUE(user_id, device_token)
);

-- Índices para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_device_token ON device_tokens(device_token);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_device_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_device_tokens_updated_at();

-- RLS (Row Level Security)
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios solo pueden ver/editar sus propios tokens
CREATE POLICY "Users can view their own device tokens"
  ON device_tokens FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own device tokens"
  ON device_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own device tokens"
  ON device_tokens FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own device tokens"
  ON device_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- Política: Los admins pueden ver todos los tokens (para debugging)
CREATE POLICY "Admins can view all device tokens"
  ON device_tokens FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );

-- Comentarios
COMMENT ON TABLE device_tokens IS 'Almacena los tokens de dispositivos para enviar push notifications';
COMMENT ON COLUMN device_tokens.user_id IS 'ID del usuario propietario del dispositivo';
COMMENT ON COLUMN device_tokens.device_token IS 'Token único del dispositivo (OneSignal User ID)';
COMMENT ON COLUMN device_tokens.platform IS 'Plataforma del dispositivo: ios, android o web';
