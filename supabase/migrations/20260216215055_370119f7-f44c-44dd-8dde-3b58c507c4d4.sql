
-- Add approval columns to players table
ALTER TABLE public.players
  ADD COLUMN approval_status text NOT NULL DEFAULT 'pending'
    CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  ADD COLUMN rejection_reason text;

-- Set all existing players as approved (they were already active)
UPDATE public.players SET approval_status = 'approved';

-- Create trigger to notify parent on player approval/rejection
CREATE OR REPLACE FUNCTION public.notify_player_approval()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  player_name TEXT;
  parent_id_val UUID;
  notif_title TEXT;
  notif_message TEXT;
  notif_type TEXT;
BEGIN
  -- Only fire when approval_status actually changes
  IF OLD.approval_status IS NOT DISTINCT FROM NEW.approval_status THEN
    RETURN NEW;
  END IF;

  player_name := NEW.name;
  parent_id_val := NEW.parent_id;

  IF NEW.approval_status = 'approved' THEN
    notif_type := 'player_approved';
    notif_title := '✅ Jugador Aprobado';
    notif_message := '¡' || player_name || ' ha sido aprobado y ya está activo en el sistema!';
  ELSIF NEW.approval_status = 'rejected' THEN
    notif_type := 'player_rejected';
    notif_title := '❌ Jugador Rechazado';
    notif_message := player_name || ' no fue aprobado.';
    IF NEW.rejection_reason IS NOT NULL AND char_length(trim(NEW.rejection_reason)) > 0 THEN
      notif_message := notif_message || ' Motivo: ' || NEW.rejection_reason;
    END IF;
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO notifications (user_id, type, title, message, metadata)
  VALUES (
    parent_id_val,
    notif_type,
    notif_title,
    notif_message,
    jsonb_build_object('player_id', NEW.id, 'player_name', player_name, 'approval_status', NEW.approval_status)
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_player_approval
AFTER UPDATE ON public.players
FOR EACH ROW
EXECUTE FUNCTION public.notify_player_approval();
