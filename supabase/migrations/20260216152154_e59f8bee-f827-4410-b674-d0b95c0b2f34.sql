
-- Enable pg_net extension for async HTTP calls from triggers
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- =============================================
-- 1. TRIGGER: Player attribute changes → notify parent
-- =============================================
CREATE OR REPLACE FUNCTION public.notify_player_data_changed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  changes TEXT[] := '{}';
  notification_message TEXT;
  is_caller_admin BOOLEAN;
BEGIN
  -- Only fire when an admin makes the change
  SELECT EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  INTO is_caller_admin;
  IF NOT is_caller_admin THEN RETURN NEW; END IF;

  -- Detect which fields changed
  IF OLD.name IS DISTINCT FROM NEW.name THEN changes := array_append(changes, 'nombre'); END IF;
  IF OLD.position IS DISTINCT FROM NEW.position THEN changes := array_append(changes, 'posición'); END IF;
  IF OLD.category IS DISTINCT FROM NEW.category THEN changes := array_append(changes, 'categoría'); END IF;
  IF OLD.level IS DISTINCT FROM NEW.level THEN changes := array_append(changes, 'nivel'); END IF;
  IF OLD.stats IS DISTINCT FROM NEW.stats THEN changes := array_append(changes, 'estadísticas'); END IF;
  IF OLD.current_club IS DISTINCT FROM NEW.current_club THEN changes := array_append(changes, 'club'); END IF;
  IF OLD.dominant_leg IS DISTINCT FROM NEW.dominant_leg THEN changes := array_append(changes, 'pierna dominante'); END IF;
  IF OLD.notes IS DISTINCT FROM NEW.notes THEN changes := array_append(changes, 'notas'); END IF;
  IF OLD.photo_url IS DISTINCT FROM NEW.photo_url THEN changes := array_append(changes, 'foto'); END IF;
  IF OLD.birth_date IS DISTINCT FROM NEW.birth_date THEN changes := array_append(changes, 'fecha de nacimiento'); END IF;

  IF array_length(changes, 1) IS NULL OR array_length(changes, 1) = 0 THEN
    RETURN NEW;
  END IF;

  notification_message := 'Se actualizó ' || array_to_string(changes, ', ') || ' de ' || NEW.name;

  INSERT INTO notifications (user_id, type, title, message, metadata)
  VALUES (
    NEW.parent_id,
    'player_updated',
    '📝 Datos del Jugador Actualizados',
    notification_message,
    jsonb_build_object('player_id', NEW.id, 'player_name', NEW.name, 'changes', to_jsonb(changes))
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_player_data_changed
AFTER UPDATE ON public.players
FOR EACH ROW
EXECUTE FUNCTION public.notify_player_data_changed();

-- =============================================
-- 2. TRIGGER: Scouting / stats evaluation recorded → notify parent
-- =============================================
CREATE OR REPLACE FUNCTION public.notify_scouting_recorded()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  player_parent_id UUID;
  player_name_val TEXT;
BEGIN
  SELECT parent_id, name INTO player_parent_id, player_name_val
  FROM players WHERE id = NEW.player_id;

  IF player_parent_id IS NULL THEN RETURN NEW; END IF;

  INSERT INTO notifications (user_id, type, title, message, metadata)
  VALUES (
    player_parent_id,
    'scouting_updated',
    '⚽ Nueva Evaluación de Scouting',
    'Se registró una nueva evaluación para ' || player_name_val || COALESCE('. Notas: ' || LEFT(NEW.notes, 80), ''),
    jsonb_build_object('player_id', NEW.player_id, 'stats_history_id', NEW.id, 'player_name', player_name_val)
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_scouting_recorded
AFTER INSERT ON public.player_stats_history
FOR EACH ROW
EXECUTE FUNCTION public.notify_scouting_recorded();

-- =============================================
-- 3. TRIGGER: Admin sends message → create notification record for parent
-- =============================================
CREATE OR REPLACE FUNCTION public.notify_admin_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  conv_participant_id UUID;
  sender_name TEXT;
  is_sender_admin BOOLEAN;
BEGIN
  SELECT EXISTS (SELECT 1 FROM user_roles WHERE user_id = NEW.sender_id AND role = 'admin')
  INTO is_sender_admin;

  IF NOT is_sender_admin THEN RETURN NEW; END IF;

  SELECT participant_id INTO conv_participant_id
  FROM conversations WHERE id = NEW.conversation_id;

  IF conv_participant_id IS NULL THEN RETURN NEW; END IF;

  SELECT full_name INTO sender_name FROM profiles WHERE id = NEW.sender_id;

  INSERT INTO notifications (user_id, type, title, message, metadata)
  VALUES (
    conv_participant_id,
    'new_message',
    '💬 Nuevo Mensaje del Admin',
    COALESCE(sender_name, 'Admin') || ': ' || LEFT(NEW.content, 100),
    jsonb_build_object('conversation_id', NEW.conversation_id, 'message_id', NEW.id)
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_admin_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.notify_admin_message();

-- =============================================
-- 4. TRIGGER: On notification INSERT → send email via pg_net
-- =============================================
CREATE OR REPLACE FUNCTION public.dispatch_notification_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  user_email TEXT;
  user_name TEXT;
  supabase_url TEXT;
  anon_key TEXT;
BEGIN
  -- Get user email
  SELECT email, full_name INTO user_email, user_name
  FROM profiles WHERE id = NEW.user_id;

  IF user_email IS NULL THEN RETURN NEW; END IF;

  -- Build Supabase URL
  supabase_url := 'https://hquoczkfumtpolyomrlg.supabase.co';
  anon_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxdW9jemtmdW10cG9seW9tcmxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MjY3NDQsImV4cCI6MjA4NDAwMjc0NH0.M-u1yVs4jQjIy5ncoOyc9bgGwZtZGycUZSGyn4d3elo';

  -- Call edge function asynchronously via pg_net
  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/send-notification-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || anon_key
    ),
    body := jsonb_build_object(
      'to_email', user_email,
      'to_name', COALESCE(user_name, ''),
      'title', NEW.title,
      'message', NEW.message,
      'type', NEW.type,
      'metadata', COALESCE(NEW.metadata, '{}'::jsonb)
    )
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_dispatch_notification_email
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.dispatch_notification_email();
