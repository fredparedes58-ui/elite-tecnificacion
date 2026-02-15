
-- Create conversation_state table to track per-user unread counts
CREATE TABLE public.conversation_state (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  unread_count integer NOT NULL DEFAULT 0,
  last_read_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  UNIQUE(conversation_id, user_id)
);

-- Enable RLS
ALTER TABLE public.conversation_state ENABLE ROW LEVEL SECURITY;

-- Users can view their own state
CREATE POLICY "Users can view own conversation state"
ON public.conversation_state FOR SELECT
USING (user_id = auth.uid());

-- Admins can view all conversation states
CREATE POLICY "Admins can view all conversation states"
ON public.conversation_state FOR SELECT
USING (public.is_admin());

-- Users can update their own state (for marking as read)
CREATE POLICY "Users can update own conversation state"
ON public.conversation_state FOR UPDATE
USING (user_id = auth.uid());

-- Admins can update any state
CREATE POLICY "Admins can update any conversation state"
ON public.conversation_state FOR UPDATE
USING (public.is_admin());

-- System can insert conversation states
CREATE POLICY "System can insert conversation state"
ON public.conversation_state FOR INSERT
WITH CHECK (true);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_state;

-- Trigger function: when a new message is inserted, increment unread for the OTHER participant
CREATE OR REPLACE FUNCTION public.increment_unread_on_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  conv_participant_id uuid;
  admin_ids uuid[];
BEGIN
  -- Get the conversation participant (parent)
  SELECT participant_id INTO conv_participant_id
  FROM conversations WHERE id = NEW.conversation_id;

  -- If sender is the participant (parent), increment for all admins
  IF NEW.sender_id = conv_participant_id THEN
    -- Get all admin user IDs
    SELECT array_agg(user_id) INTO admin_ids
    FROM user_roles WHERE role = 'admin';

    IF admin_ids IS NOT NULL THEN
      FOR i IN 1..array_length(admin_ids, 1) LOOP
        INSERT INTO conversation_state (conversation_id, user_id, unread_count, last_read_at)
        VALUES (NEW.conversation_id, admin_ids[i], 1, NULL)
        ON CONFLICT (conversation_id, user_id)
        DO UPDATE SET unread_count = conversation_state.unread_count + 1,
                      updated_at = now();
      END LOOP;
    END IF;
  ELSE
    -- Sender is admin, increment for the participant
    INSERT INTO conversation_state (conversation_id, user_id, unread_count, last_read_at)
    VALUES (NEW.conversation_id, conv_participant_id, 1, NULL)
    ON CONFLICT (conversation_id, user_id)
    DO UPDATE SET unread_count = conversation_state.unread_count + 1,
                  updated_at = now();
  END IF;

  RETURN NEW;
END;
$$;

-- Attach trigger to messages table
CREATE TRIGGER on_message_insert_increment_unread
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.increment_unread_on_message();
