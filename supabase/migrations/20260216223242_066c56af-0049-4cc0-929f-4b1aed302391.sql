
-- Enforce one conversation per participant (one-to-one)
ALTER TABLE public.conversations ADD CONSTRAINT conversations_participant_id_unique UNIQUE (participant_id);
