-- Create credit_packages table
CREATE TABLE public.credit_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  credits INTEGER NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.credit_packages ENABLE ROW LEVEL SECURITY;

-- Everyone can view active packages
CREATE POLICY "Anyone can view active packages"
ON public.credit_packages
FOR SELECT
USING (is_active = true);

-- Only admins can manage packages
CREATE POLICY "Admins can manage packages"
ON public.credit_packages
FOR ALL
USING (is_admin());

-- Add package_id to credit_transactions for tracking which package was purchased
ALTER TABLE public.credit_transactions 
ADD COLUMN IF NOT EXISTS package_id UUID REFERENCES public.credit_packages(id);

-- Insert initial packages
INSERT INTO public.credit_packages (name, credits, price, description) VALUES
  ('Bono Básico', 4, 60.00, '4 sesiones individuales'),
  ('Bono Mensual', 8, 100.00, '8 sesiones - Ahorra 20€'),
  ('Bono Trimestral', 24, 250.00, '24 sesiones - El mejor valor');

-- Add trigger for updated_at
CREATE TRIGGER update_credit_packages_updated_at
BEFORE UPDATE ON public.credit_packages
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();