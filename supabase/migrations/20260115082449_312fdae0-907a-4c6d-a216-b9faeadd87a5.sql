
-- =============================================
-- FIX SECURITY: Profiles table PII exposure
-- =============================================

-- Drop the overly permissive SELECT policy
DROP POLICY IF EXISTS "Approved users can view all profiles" ON public.profiles;

-- Create policy: Users can only see their own full profile
-- (Policy "Users can view own profile" already exists, keep it)

-- Create policy: Admins can view all profiles with full details
CREATE POLICY "Admins can view all profiles" 
ON public.profiles 
FOR SELECT 
USING (is_admin());

-- Create a public view for approved users to see limited profile info (no email/phone)
CREATE VIEW public.profiles_public
WITH (security_invoker = on) AS
SELECT 
  id, 
  full_name, 
  avatar_url, 
  is_approved, 
  created_at, 
  updated_at
FROM public.profiles;

-- Grant access to the view
GRANT SELECT ON public.profiles_public TO authenticated;

-- =============================================
-- FIX SECURITY: Players table children data exposure  
-- =============================================

-- Drop the overly permissive SELECT policy
DROP POLICY IF EXISTS "Approved users can view all players" ON public.players;

-- Create policy: Parents can only view their own children
CREATE POLICY "Parents can view own players" 
ON public.players 
FOR SELECT 
USING (parent_id = auth.uid());

-- Create policy: Admins can view all players
CREATE POLICY "Admins can view all players" 
ON public.players 
FOR SELECT 
USING (is_admin());
