-- 1. Create credit_transactions table for audit trail
CREATE TABLE public.credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reservation_id UUID REFERENCES public.reservations(id) ON DELETE SET NULL,
  amount INTEGER NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('debit', 'credit', 'refund', 'manual_adjustment')),
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own transactions"
ON public.credit_transactions FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Admins can view all transactions"
ON public.credit_transactions FOR SELECT
USING (is_admin());

CREATE POLICY "Only system can insert transactions"
ON public.credit_transactions FOR INSERT
WITH CHECK (is_admin());

-- 2. Update the reservation approval trigger to log transactions
CREATE OR REPLACE FUNCTION public.handle_reservation_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
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
  
  -- When status changes FROM approved to cancelled/rejected - REFUND
  IF OLD.status = 'approved' AND NEW.status IN ('cancelled', 'rejected') THEN
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
$$;

-- Ensure trigger exists
DROP TRIGGER IF EXISTS on_reservation_status_change ON public.reservations;
CREATE TRIGGER on_reservation_status_change
  BEFORE UPDATE ON public.reservations
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_reservation_approval();