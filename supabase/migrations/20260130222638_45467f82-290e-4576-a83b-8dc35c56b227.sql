-- Create system_config table for dynamic settings
CREATE TABLE public.system_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  description text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.system_config ENABLE ROW LEVEL SECURITY;

-- Everyone can read config (needed for app functionality)
CREATE POLICY "Anyone can read system config" 
ON public.system_config FOR SELECT 
USING (true);

-- Only admins can manage config
CREATE POLICY "Admins can manage system config" 
ON public.system_config FOR ALL 
USING (is_admin());

-- Insert default configurations
INSERT INTO public.system_config (key, value, description) VALUES
  ('session_hours', '{"start": 8, "end": 21}'::jsonb, 'Horario de sesiones: hora inicio y fin'),
  ('max_capacity', '{"value": 6}'::jsonb, 'Capacidad máxima de jugadores por sesión'),
  ('active_days', '{"days": [1, 2, 3, 4, 5, 6]}'::jsonb, 'Días activos (1=Lunes, 7=Domingo)'),
  ('credit_alert_threshold', '{"value": 3}'::jsonb, 'Umbral de créditos para alertas'),
  ('cancellation_window', '{"hours": 24}'::jsonb, 'Horas mínimas antes de la sesión para cancelar sin penalización');

-- Create trigger for updated_at using existing function
CREATE TRIGGER update_system_config_updated_at
BEFORE UPDATE ON public.system_config
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();