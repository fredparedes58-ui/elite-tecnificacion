-- Create function to notify session changes (time, trainer, player)
CREATE OR REPLACE FUNCTION public.notify_session_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  player_parent_id UUID;
  player_name TEXT;
  old_player_parent_id UUID;
  old_player_name TEXT;
  notification_title TEXT;
  notification_message TEXT;
  new_time_formatted TEXT;
  trainer_name TEXT;
BEGIN
  -- Skip if no meaningful changes
  IF (OLD.start_time = NEW.start_time 
      AND OLD.end_time = NEW.end_time 
      AND OLD.trainer_id IS NOT DISTINCT FROM NEW.trainer_id 
      AND OLD.player_id IS NOT DISTINCT FROM NEW.player_id) THEN
    RETURN NEW;
  END IF;

  -- Get new player info
  IF NEW.player_id IS NOT NULL THEN
    SELECT parent_id, name INTO player_parent_id, player_name
    FROM players WHERE id = NEW.player_id;
  END IF;
  
  -- Get old player info if player changed
  IF OLD.player_id IS NOT NULL AND OLD.player_id IS DISTINCT FROM NEW.player_id THEN
    SELECT parent_id, name INTO old_player_parent_id, old_player_name
    FROM players WHERE id = OLD.player_id;
    
    -- Notify old player's parent that they were removed
    INSERT INTO notifications (user_id, type, title, message, metadata)
    VALUES (
      old_player_parent_id,
      'session_player_removed',
      '🔄 Sesión Modificada',
      old_player_name || ' ha sido removido de la sesión del ' || to_char(OLD.start_time AT TIME ZONE 'Europe/Madrid', 'DD/MM a las HH24:MI'),
      jsonb_build_object('reservation_id', NEW.id, 'player_id', OLD.player_id)
    );
  END IF;
  
  -- Skip if no new player to notify
  IF player_parent_id IS NULL THEN RETURN NEW; END IF;
  
  -- Format new time
  new_time_formatted := to_char(NEW.start_time AT TIME ZONE 'Europe/Madrid', 'EEEE DD/MM a las HH24:MI');
  
  -- Get trainer name if exists
  IF NEW.trainer_id IS NOT NULL THEN
    SELECT name INTO trainer_name FROM trainers WHERE id = NEW.trainer_id;
  END IF;
  
  -- Determine notification type based on what changed
  IF OLD.player_id IS DISTINCT FROM NEW.player_id AND OLD.player_id IS NULL THEN
    -- New player assigned
    notification_title := '➕ Nueva Sesión Asignada';
    notification_message := player_name || ' ha sido asignado a una sesión el ' || new_time_formatted;
    IF trainer_name IS NOT NULL THEN
      notification_message := notification_message || ' con ' || trainer_name;
    END IF;
  ELSIF (OLD.start_time != NEW.start_time OR OLD.end_time != NEW.end_time) THEN
    -- Session time changed
    notification_title := '📅 Sesión Reprogramada';
    notification_message := 'La sesión de ' || player_name || ' ha sido movida al ' || new_time_formatted;
  ELSIF OLD.trainer_id IS DISTINCT FROM NEW.trainer_id THEN
    -- Trainer changed
    notification_title := '👨‍🏫 Cambio de Entrenador';
    IF trainer_name IS NOT NULL THEN
      notification_message := 'El entrenador de la sesión de ' || player_name || ' ahora es ' || trainer_name;
    ELSE
      notification_message := 'El entrenador de la sesión de ' || player_name || ' ha sido removido';
    END IF;
  ELSE
    RETURN NEW;
  END IF;
  
  -- Insert notification for the player's parent
  INSERT INTO notifications (user_id, type, title, message, metadata)
  VALUES (
    player_parent_id,
    'session_updated',
    notification_title,
    notification_message,
    jsonb_build_object(
      'reservation_id', NEW.id, 
      'player_id', NEW.player_id,
      'start_time', NEW.start_time,
      'trainer_id', NEW.trainer_id
    )
  );
  
  RETURN NEW;
END;
$$;

-- Create trigger for session changes
DROP TRIGGER IF EXISTS on_session_changes ON public.reservations;
CREATE TRIGGER on_session_changes
  AFTER UPDATE ON public.reservations
  FOR EACH ROW
  WHEN (
    OLD.start_time IS DISTINCT FROM NEW.start_time OR
    OLD.end_time IS DISTINCT FROM NEW.end_time OR
    OLD.trainer_id IS DISTINCT FROM NEW.trainer_id OR
    OLD.player_id IS DISTINCT FROM NEW.player_id
  )
  EXECUTE FUNCTION public.notify_session_changes();