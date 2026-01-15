
-- =============================================
-- FIX ERROR: Add explicit authenticated-only policy for profiles
-- =============================================
CREATE POLICY "Authenticated users only" 
ON public.profiles 
FOR SELECT 
TO authenticated
USING (true);

-- Drop the existing restrictive policies and recreate as permissive with proper conditions
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

-- Recreate as permissive policies
CREATE POLICY "Users can view own profile" 
ON public.profiles 
FOR SELECT 
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" 
ON public.profiles 
FOR SELECT 
TO authenticated
USING (is_admin());

-- Drop the redundant authenticated policy (the specific ones handle it)
DROP POLICY IF EXISTS "Authenticated users only" ON public.profiles;

-- =============================================
-- FIX WARNING: profiles_public view needs RLS-like protection
-- Add policy to ensure only authenticated users can access the view
-- =============================================
-- Views inherit RLS from base tables when security_invoker=on (which we set)
-- But let's add an explicit grant restriction
REVOKE ALL ON public.profiles_public FROM anon;
GRANT SELECT ON public.profiles_public TO authenticated;

-- =============================================
-- FIX WARNING: Add UPDATE and DELETE policies for conversations
-- =============================================
CREATE POLICY "Users can update own conversations" 
ON public.conversations 
FOR UPDATE 
USING (participant_id = auth.uid());

CREATE POLICY "Admins can update conversations" 
ON public.conversations 
FOR UPDATE 
USING (is_admin());

CREATE POLICY "Users can delete own conversations" 
ON public.conversations 
FOR DELETE 
USING (participant_id = auth.uid());

CREATE POLICY "Admins can delete conversations" 
ON public.conversations 
FOR DELETE 
USING (is_admin());

-- =============================================
-- FIX WARNING: Add message content length validation trigger
-- =============================================
CREATE OR REPLACE FUNCTION public.validate_message_content()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF char_length(NEW.content) > 5000 THEN
    RAISE EXCEPTION 'Message content exceeds maximum length of 5000 characters';
  END IF;
  IF char_length(trim(NEW.content)) = 0 THEN
    RAISE EXCEPTION 'Message content cannot be empty';
  END IF;
  NEW.content := trim(NEW.content);
  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_message_content_trigger
BEFORE INSERT OR UPDATE ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.validate_message_content();
