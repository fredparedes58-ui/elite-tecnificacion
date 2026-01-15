
-- =============================================
-- FIX: Deny anonymous access to profiles table
-- =============================================

-- First, revoke all permissions from anon role on profiles
REVOKE ALL ON public.profiles FROM anon;

-- Add explicit deny policy for anonymous users (using RESTRICTIVE)
CREATE POLICY "Deny anonymous access to profiles"
ON public.profiles
AS RESTRICTIVE
FOR SELECT
TO anon
USING (false);

-- =============================================
-- FIX: Deny anonymous access to players table
-- =============================================

-- Revoke all permissions from anon role on players
REVOKE ALL ON public.players FROM anon;

-- Add explicit deny policy for anonymous users
CREATE POLICY "Deny anonymous access to players"
ON public.players
AS RESTRICTIVE
FOR SELECT
TO anon
USING (false);
