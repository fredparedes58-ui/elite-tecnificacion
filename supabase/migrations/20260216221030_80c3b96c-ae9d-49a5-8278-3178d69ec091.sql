
-- Trigger function: notify all admins when a new player is created with pending status
CREATE OR REPLACE FUNCTION public.notify_admins_new_pending_player()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  admin_record RECORD;
  parent_name TEXT;
BEGIN
  -- Only fire on INSERT with pending status
  IF NEW.approval_status != 'pending' THEN
    RETURN NEW;
  END IF;

  -- Get parent name
  SELECT full_name INTO parent_name
  FROM profiles WHERE id = NEW.parent_id;

  -- Notify all admins
  FOR admin_record IN
    SELECT user_id FROM user_roles WHERE role = 'admin'
  LOOP
    INSERT INTO notifications (user_id, type, title, message, metadata)
    VALUES (
      admin_record.user_id,
      'new_player_pending',
      '🆕 Nuevo Jugador Pendiente',
      COALESCE(parent_name, 'Un padre') || ' ha registrado a ' || NEW.name || ' y requiere aprobación.',
      jsonb_build_object(
        'player_id', NEW.id,
        'player_name', NEW.name,
        'parent_id', NEW.parent_id,
        'parent_name', COALESCE(parent_name, ''),
        'category', NEW.category,
        'level', NEW.level
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$;

-- Create trigger on players INSERT
DROP TRIGGER IF EXISTS trg_notify_admins_new_pending_player ON public.players;
CREATE TRIGGER trg_notify_admins_new_pending_player
  AFTER INSERT ON public.players
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_admins_new_pending_player();
