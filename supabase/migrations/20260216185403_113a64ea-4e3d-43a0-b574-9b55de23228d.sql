-- Allow admins to delete messages
CREATE POLICY "Admins can delete messages"
ON public.messages
FOR DELETE
USING (is_admin());

-- Allow admins to delete conversation_state
CREATE POLICY "Admins can delete conversation state"
ON public.conversation_state
FOR DELETE
USING (is_admin());