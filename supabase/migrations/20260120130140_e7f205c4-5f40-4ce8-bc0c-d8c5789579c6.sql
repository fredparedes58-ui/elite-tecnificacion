-- Create session_changes_history table for tracking all modifications
CREATE TABLE public.session_changes_history (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  reservation_id UUID NOT NULL REFERENCES public.reservations(id) ON DELETE CASCADE,
  changed_by UUID NOT NULL,
  change_type TEXT NOT NULL, -- 'time_changed', 'trainer_changed', 'player_assigned', 'player_removed', 'status_changed', 'created', 'deleted'
  old_value JSONB,
  new_value JSONB,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.session_changes_history ENABLE ROW LEVEL SECURITY;

-- Admins can view all history
CREATE POLICY "Admins can view session history"
ON public.session_changes_history
FOR SELECT
USING (is_admin());

-- Admins can insert history entries
CREATE POLICY "Admins can insert session history"
ON public.session_changes_history
FOR INSERT
WITH CHECK (is_admin());

-- Create index for faster lookups
CREATE INDEX idx_session_changes_reservation_id ON public.session_changes_history(reservation_id);
CREATE INDEX idx_session_changes_created_at ON public.session_changes_history(created_at DESC);

-- Create function to automatically log changes
CREATE OR REPLACE FUNCTION public.log_session_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  change_description TEXT;
  admin_id UUID;
  player_name_old TEXT;
  player_name_new TEXT;
  trainer_name_old TEXT;
  trainer_name_new TEXT;
BEGIN
  -- Get current user ID
  admin_id := auth.uid();
  
  -- Get player names
  IF OLD.player_id IS NOT NULL THEN
    SELECT name INTO player_name_old FROM players WHERE id = OLD.player_id;
  END IF;
  IF NEW.player_id IS NOT NULL THEN
    SELECT name INTO player_name_new FROM players WHERE id = NEW.player_id;
  END IF;
  
  -- Get trainer names
  IF OLD.trainer_id IS NOT NULL THEN
    SELECT name INTO trainer_name_old FROM trainers WHERE id = OLD.trainer_id;
  END IF;
  IF NEW.trainer_id IS NOT NULL THEN
    SELECT name INTO trainer_name_new FROM trainers WHERE id = NEW.trainer_id;
  END IF;
  
  -- Log time changes
  IF (OLD.start_time IS DISTINCT FROM NEW.start_time OR OLD.end_time IS DISTINCT FROM NEW.end_time) THEN
    change_description := 'Horario cambiado de ' || 
      to_char(OLD.start_time AT TIME ZONE 'UTC', 'DD/MM HH24:MI') || ' a ' ||
      to_char(NEW.start_time AT TIME ZONE 'UTC', 'DD/MM HH24:MI');
    
    INSERT INTO session_changes_history (reservation_id, changed_by, change_type, old_value, new_value, description)
    VALUES (
      NEW.id,
      admin_id,
      'time_changed',
      jsonb_build_object('start_time', OLD.start_time, 'end_time', OLD.end_time),
      jsonb_build_object('start_time', NEW.start_time, 'end_time', NEW.end_time),
      change_description
    );
  END IF;
  
  -- Log trainer changes
  IF (OLD.trainer_id IS DISTINCT FROM NEW.trainer_id) THEN
    change_description := 'Entrenador cambiado de ' || 
      COALESCE(trainer_name_old, 'Sin asignar') || ' a ' ||
      COALESCE(trainer_name_new, 'Sin asignar');
    
    INSERT INTO session_changes_history (reservation_id, changed_by, change_type, old_value, new_value, description)
    VALUES (
      NEW.id,
      admin_id,
      'trainer_changed',
      jsonb_build_object('trainer_id', OLD.trainer_id, 'trainer_name', trainer_name_old),
      jsonb_build_object('trainer_id', NEW.trainer_id, 'trainer_name', trainer_name_new),
      change_description
    );
  END IF;
  
  -- Log player changes
  IF (OLD.player_id IS DISTINCT FROM NEW.player_id) THEN
    IF OLD.player_id IS NULL THEN
      change_description := 'Jugador asignado: ' || COALESCE(player_name_new, 'Desconocido');
      INSERT INTO session_changes_history (reservation_id, changed_by, change_type, old_value, new_value, description)
      VALUES (
        NEW.id,
        admin_id,
        'player_assigned',
        NULL,
        jsonb_build_object('player_id', NEW.player_id, 'player_name', player_name_new),
        change_description
      );
    ELSIF NEW.player_id IS NULL THEN
      change_description := 'Jugador removido: ' || COALESCE(player_name_old, 'Desconocido');
      INSERT INTO session_changes_history (reservation_id, changed_by, change_type, old_value, new_value, description)
      VALUES (
        NEW.id,
        admin_id,
        'player_removed',
        jsonb_build_object('player_id', OLD.player_id, 'player_name', player_name_old),
        NULL,
        change_description
      );
    ELSE
      change_description := 'Jugador cambiado de ' || COALESCE(player_name_old, 'Sin asignar') || ' a ' || COALESCE(player_name_new, 'Sin asignar');
      INSERT INTO session_changes_history (reservation_id, changed_by, change_type, old_value, new_value, description)
      VALUES (
        NEW.id,
        admin_id,
        'player_changed',
        jsonb_build_object('player_id', OLD.player_id, 'player_name', player_name_old),
        jsonb_build_object('player_id', NEW.player_id, 'player_name', player_name_new),
        change_description
      );
    END IF;
  END IF;
  
  -- Log status changes
  IF (OLD.status IS DISTINCT FROM NEW.status) THEN
    change_description := 'Estado cambiado de ' || OLD.status || ' a ' || NEW.status;
    
    INSERT INTO session_changes_history (reservation_id, changed_by, change_type, old_value, new_value, description)
    VALUES (
      NEW.id,
      admin_id,
      'status_changed',
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status),
      change_description
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for logging changes
CREATE TRIGGER on_session_change_log
  AFTER UPDATE ON public.reservations
  FOR EACH ROW
  EXECUTE FUNCTION public.log_session_changes();