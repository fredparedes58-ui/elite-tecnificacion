
-- =============================================
-- FIX ERROR 1: profiles - remove overly permissive policies
-- Only allow users to see their OWN profile, admins see all
-- =============================================

-- Drop existing permissive policies that could allow access to others' data
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

-- Recreate with explicit PERMISSIVE type and proper restrictions
CREATE POLICY "Users can view own profile only"
ON public.profiles
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
ON public.profiles
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (is_admin());

-- =============================================
-- FIX ERROR 2: trainers - hide contact info from non-admins
-- Create a public view without sensitive fields
-- =============================================

-- Create view for non-admin users (no email/phone)
CREATE VIEW public.trainers_public
WITH (security_invoker = on) AS
SELECT 
  id,
  name,
  specialty,
  bio,
  photo_url,
  is_active,
  created_at,
  updated_at
FROM public.trainers;

-- Grant access to authenticated users only
GRANT SELECT ON public.trainers_public TO authenticated;
REVOKE ALL ON public.trainers_public FROM anon;

-- Drop the overly permissive policy
DROP POLICY IF EXISTS "Anyone approved can view trainers" ON public.trainers;

-- Now only admins can see full trainer details (including contact info)
-- The existing "Only admins can manage trainers" ALL policy covers SELECT for admins

-- =============================================
-- FIX WARNING: profiles_public view - restrict to authenticated
-- =============================================

-- Already created with security_invoker=on, just ensure anon is revoked
REVOKE ALL ON public.profiles_public FROM anon;
REVOKE ALL ON public.profiles_public FROM public;
GRANT SELECT ON public.profiles_public TO authenticated;
