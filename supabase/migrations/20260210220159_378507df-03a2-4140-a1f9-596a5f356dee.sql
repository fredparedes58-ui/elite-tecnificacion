
-- Fix the handle_reservation_approval function to use 'rejected' instead of non-existent 'cancelled'
CREATE OR REPLACE FUNCTION public.handle_reservation_approval()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- When status changes to approved
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    -- Check if user has enough credits
    IF NOT EXISTS (
      SELECT 1 FROM public.user_credits 
      WHERE user_id = NEW.user_id AND balance >= NEW.credit_cost
    ) THEN
      RAISE EXCEPTION 'Créditos insuficientes';
    END IF;
    
    -- Deduct credits
    UPDATE public.user_credits
    SET balance = balance - NEW.credit_cost,
        updated_at = NOW()
    WHERE user_id = NEW.user_id;
    
    -- Log the transaction
    INSERT INTO public.credit_transactions (user_id, reservation_id, amount, transaction_type, description)
    VALUES (NEW.user_id, NEW.id, -NEW.credit_cost, 'debit', 'Reserva aprobada: ' || NEW.title);
  END IF;
  
  -- When status changes FROM approved to rejected - REFUND
  IF OLD.status = 'approved' AND NEW.status = 'rejected' THEN
    -- Refund credits
    UPDATE public.user_credits
    SET balance = balance + OLD.credit_cost,
        updated_at = NOW()
    WHERE user_id = NEW.user_id;
    
    -- Log the refund
    INSERT INTO public.credit_transactions (user_id, reservation_id, amount, transaction_type, description)
    VALUES (NEW.user_id, NEW.id, OLD.credit_cost, 'refund', 'Reembolso por cancelación: ' || NEW.title);
  END IF;
  
  RETURN NEW;
END;
$function$;
