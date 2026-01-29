-- Allow parents to update status of their own reservations (for cancellation)
CREATE POLICY "Users can cancel own reservations" 
ON public.reservations 
FOR UPDATE 
USING (
  user_id = auth.uid() 
  AND status IN ('pending', 'approved')
)
WITH CHECK (
  user_id = auth.uid() 
  AND status = 'rejected'
);

-- Add delete policy for admins to delete reservations
CREATE POLICY "Admins can delete reservations" 
ON public.reservations 
FOR DELETE 
USING (is_admin());