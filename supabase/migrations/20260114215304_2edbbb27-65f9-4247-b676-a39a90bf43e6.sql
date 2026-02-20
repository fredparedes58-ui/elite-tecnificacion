-- Create app_role enum
CREATE TYPE public.app_role AS ENUM ('admin', 'parent', 'player');

-- Create player_category enum
CREATE TYPE public.player_category AS ENUM ('U8', 'U10', 'U12', 'U14', 'U16', 'U18');

-- Create player_level enum
CREATE TYPE public.player_level AS ENUM ('beginner', 'intermediate', 'advanced', 'elite');

-- Create reservation_status enum
CREATE TYPE public.reservation_status AS ENUM ('pending', 'approved', 'rejected');

-- Profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  is_approved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User roles table (separate for security)
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role app_role NOT NULL DEFAULT 'parent',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);

-- User credits table
CREATE TABLE public.user_credits (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  balance INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Players table (children of parents)
CREATE TABLE public.players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category player_category NOT NULL DEFAULT 'U10',
  level player_level NOT NULL DEFAULT 'beginner',
  photo_url TEXT,
  stats JSONB DEFAULT '{"speed": 50, "technique": 50, "physical": 50, "mental": 50, "tactical": 50}'::jsonb,
  birth_date DATE,
  position TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reservations table
CREATE TABLE public.reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  player_id UUID REFERENCES public.players(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  status reservation_status DEFAULT 'pending',
  credit_cost INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations table (for chat)
CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Helper function: Check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  );
$$;

-- Helper function: Check if user is approved
CREATE OR REPLACE FUNCTION public.is_approved()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_approved = true
  );
$$;

-- Helper function: Check role
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  );
$$;

-- Trigger function: Handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  is_admin_user BOOLEAN;
BEGIN
  -- Check if this is the admin email
  is_admin_user := (NEW.email = 'fredparedes58@gmail.com');
  
  -- Create profile
  INSERT INTO public.profiles (id, email, full_name, is_approved)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    is_admin_user -- Auto-approve admin
  );
  
  -- Assign role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (
    NEW.id,
    CASE WHEN is_admin_user THEN 'admin'::app_role ELSE 'parent'::app_role END
  );
  
  -- Initialize credits
  INSERT INTO public.user_credits (user_id, balance)
  VALUES (NEW.id, CASE WHEN is_admin_user THEN 999 ELSE 0 END);
  
  RETURN NEW;
END;
$$;

-- Create trigger for new users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger function: Deduct credits when reservation approved
CREATE OR REPLACE FUNCTION public.handle_reservation_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only run when status changes to approved
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    -- Deduct credits
    UPDATE public.user_credits
    SET balance = balance - NEW.credit_cost,
        updated_at = NOW()
    WHERE user_id = NEW.user_id
      AND balance >= NEW.credit_cost;
    
    -- If no rows updated, insufficient credits
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Insufficient credits';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for reservation approval
CREATE TRIGGER on_reservation_approval
  BEFORE UPDATE ON public.reservations
  FOR EACH ROW EXECUTE FUNCTION public.handle_reservation_approval();

-- Update timestamp function
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Update triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_players_updated_at BEFORE UPDATE ON public.players FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_reservations_updated_at BEFORE UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Approved users can view all profiles" ON public.profiles FOR SELECT USING (public.is_approved() OR public.is_admin());
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can update any profile" ON public.profiles FOR UPDATE USING (public.is_admin());

-- RLS Policies for user_roles
CREATE POLICY "Users can view own roles" ON public.user_roles FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can view all roles" ON public.user_roles FOR SELECT USING (public.is_admin());
CREATE POLICY "Only admins can manage roles" ON public.user_roles FOR ALL USING (public.is_admin());

-- RLS Policies for user_credits
CREATE POLICY "Users can view own credits" ON public.user_credits FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can view all credits" ON public.user_credits FOR SELECT USING (public.is_admin());
CREATE POLICY "Only admins can update credits" ON public.user_credits FOR UPDATE USING (public.is_admin());

-- RLS Policies for players
CREATE POLICY "Approved users can view all players" ON public.players FOR SELECT USING (public.is_approved() OR public.is_admin());
CREATE POLICY "Parents can create players" ON public.players FOR INSERT WITH CHECK (parent_id = auth.uid() AND public.is_approved());
CREATE POLICY "Parents can update own players" ON public.players FOR UPDATE USING (parent_id = auth.uid());
CREATE POLICY "Admins can update any player" ON public.players FOR UPDATE USING (public.is_admin());
CREATE POLICY "Parents can delete own players" ON public.players FOR DELETE USING (parent_id = auth.uid());
CREATE POLICY "Admins can delete any player" ON public.players FOR DELETE USING (public.is_admin());

-- RLS Policies for reservations
CREATE POLICY "Users can view own reservations" ON public.reservations FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can view all reservations" ON public.reservations FOR SELECT USING (public.is_admin());
CREATE POLICY "Approved users can create reservations" ON public.reservations FOR INSERT WITH CHECK (user_id = auth.uid() AND public.is_approved());
CREATE POLICY "Admins can update reservations" ON public.reservations FOR UPDATE USING (public.is_admin());

-- RLS Policies for conversations
CREATE POLICY "Users can view own conversations" ON public.conversations FOR SELECT USING (participant_id = auth.uid());
CREATE POLICY "Admins can view all conversations" ON public.conversations FOR SELECT USING (public.is_admin());
CREATE POLICY "Approved users can create conversations" ON public.conversations FOR INSERT WITH CHECK (participant_id = auth.uid() AND public.is_approved());

-- RLS Policies for messages
CREATE POLICY "Users can view messages in their conversations" ON public.messages FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations 
      WHERE id = conversation_id 
      AND (participant_id = auth.uid() OR public.is_admin())
    )
  );
CREATE POLICY "Users can send messages in their conversations" ON public.messages FOR INSERT 
  WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.conversations 
      WHERE id = conversation_id 
      AND (participant_id = auth.uid() OR public.is_admin())
    )
  );
CREATE POLICY "Admins can send messages anywhere" ON public.messages FOR INSERT WITH CHECK (public.is_admin());

-- Enable realtime for messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('player-photos', 'player-photos', true);

-- Storage policies for avatars
CREATE POLICY "Anyone can view avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload own avatar" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can update own avatar" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can delete own avatar" ON storage.objects FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for player-photos
CREATE POLICY "Anyone can view player photos" ON storage.objects FOR SELECT USING (bucket_id = 'player-photos');
CREATE POLICY "Parents can upload player photos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'player-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Parents can update player photos" ON storage.objects FOR UPDATE USING (bucket_id = 'player-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Parents can delete player photos" ON storage.objects FOR DELETE USING (bucket_id = 'player-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Admins can manage all storage" ON storage.objects FOR ALL USING (public.is_admin());