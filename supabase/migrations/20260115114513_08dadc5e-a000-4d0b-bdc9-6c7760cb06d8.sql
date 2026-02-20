-- Function to notify parent on reservation status change
CREATE OR REPLACE FUNCTION public.notify_parent_reservation_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only notify if status changed to approved or rejected
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    INSERT INTO notifications (user_id, type, title, message, metadata)
    VALUES (
      NEW.user_id,
      'reservation_approved',
      '✅ Reserva Aprobada',
      'Tu reserva "' || NEW.title || '" ha sido aprobada',
      jsonb_build_object('reservation_id', NEW.id)
    );
  ELSIF NEW.status = 'rejected' AND (OLD.status IS NULL OR OLD.status != 'rejected') THEN
    INSERT INTO notifications (user_id, type, title, message, metadata)
    VALUES (
      NEW.user_id,
      'reservation_rejected',
      '❌ Reserva Rechazada',
      'Tu reserva "' || NEW.title || '" ha sido rechazada',
      jsonb_build_object('reservation_id', NEW.id)
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger and recreate
DROP TRIGGER IF EXISTS on_reservation_status_change ON public.reservations;

-- Create notification trigger for reservation status
CREATE TRIGGER on_reservation_status_notify
  AFTER UPDATE OF status ON public.reservations
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_parent_reservation_status();