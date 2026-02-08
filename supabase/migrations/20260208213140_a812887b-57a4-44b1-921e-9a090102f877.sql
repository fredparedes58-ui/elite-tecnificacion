
-- Tabla cash_payments para registro contable de pagos en efectivo
CREATE TABLE public.cash_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  transaction_id UUID REFERENCES public.credit_transactions(id),
  cash_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'efectivo',
  notes TEXT,
  received_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.cash_payments ENABLE ROW LEVEL SECURITY;

-- Solo admins pueden gestionar pagos en efectivo
CREATE POLICY "Admins manage cash payments"
  ON public.cash_payments FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Agregar columna color a trainers para identificación visual
ALTER TABLE public.trainers 
  ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#06b6d4';

-- Inicializar colores para entrenadores existentes
UPDATE public.trainers SET color = '#06b6d4' WHERE name = 'Pedro';
UPDATE public.trainers SET color = '#a855f7' WHERE name LIKE 'Saul%';
UPDATE public.trainers SET color = '#f59e0b' WHERE name LIKE 'Sebast%';
