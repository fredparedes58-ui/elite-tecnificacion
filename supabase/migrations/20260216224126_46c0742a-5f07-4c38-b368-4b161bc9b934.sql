
-- Add attachments column to messages (JSONB array of attachment metadata)
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS attachments jsonb DEFAULT NULL;

-- Create storage bucket for chat attachments
INSERT INTO storage.buckets (id, name, public) VALUES ('chat-attachments', 'chat-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: participants can upload attachments
CREATE POLICY "Chat participants can upload attachments"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat-attachments'
  AND auth.uid() IS NOT NULL
  AND (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = ((storage.foldername(name))[1])::uuid
      AND (conversations.participant_id = auth.uid() OR is_admin())
    )
  )
);

-- Storage RLS: participants can view attachments in their conversations
CREATE POLICY "Chat participants can view attachments"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'chat-attachments'
  AND auth.uid() IS NOT NULL
  AND (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = ((storage.foldername(name))[1])::uuid
      AND (conversations.participant_id = auth.uid() OR is_admin())
    )
  )
);

-- Storage RLS: participants can delete their own attachments
CREATE POLICY "Chat participants can delete own attachments"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'chat-attachments'
  AND auth.uid() IS NOT NULL
  AND (owner)::uuid = auth.uid()
);
