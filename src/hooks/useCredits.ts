import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

export interface UserCredit {
  user_id: string;
  balance: number;
  updated_at: string;
  profile?: {
    full_name: string | null;
    email: string;
  };
}

export const useCredits = () => {
  const { user } = useAuth();
  const [credits, setCredits] = useState<number>(0);
  const [loading, setLoading] = useState(true);

  const fetchCredits = async () => {
    if (!user) return;

    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('user_credits')
        .select('balance')
        .eq('user_id', user.id)
        .single();

      if (error) throw error;
      setCredits(data?.balance || 0);
    } catch (err) {
      console.error('Error fetching credits:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCredits();
  }, [user]);

  return { credits, loading, refetch: fetchCredits };
};

export const useAllCredits = () => {
  const { isAdmin } = useAuth();
  const [allCredits, setAllCredits] = useState<UserCredit[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAllCredits = async () => {
    if (!isAdmin) return;

    try {
      setLoading(true);
      const { data: credits, error } = await supabase
        .from('user_credits')
        .select('*');

      if (error) throw error;

      const creditsWithProfiles = await Promise.all(
        (credits || []).map(async (credit) => {
          const { data: profile } = await supabase
            .from('profiles')
            .select('full_name, email')
            .eq('id', credit.user_id)
            .single();

          return {
            ...credit,
            profile: profile || undefined,
          };
        })
      );

      setAllCredits(creditsWithProfiles);
    } catch (err) {
      console.error('Error fetching all credits:', err);
    } finally {
      setLoading(false);
    }
  };

  const updateCredits = async (userId: string, newBalance: number) => {
    try {
      const { error } = await supabase
        .from('user_credits')
        .update({ balance: newBalance, updated_at: new Date().toISOString() })
        .eq('user_id', userId);

      if (error) throw error;
      await fetchAllCredits();
      return true;
    } catch (err) {
      console.error('Error updating credits:', err);
      return false;
    }
  };

  useEffect(() => {
    fetchAllCredits();
  }, [isAdmin]);

  return { allCredits, loading, updateCredits, refetch: fetchAllCredits };
};
