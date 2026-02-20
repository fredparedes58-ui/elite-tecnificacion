import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { useQueryClient } from '@tanstack/react-query';

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

  const fetchCredits = useCallback(async () => {
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
  }, [user]);

  useEffect(() => {
    fetchCredits();
  }, [fetchCredits]);

  // Real-time subscription for own credits
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('user-credits-realtime')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'user_credits',
          filter: `user_id=eq.${user.id}`,
        },
        (payload) => {
          if (payload.new && 'balance' in payload.new) {
            setCredits(payload.new.balance as number);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  return { credits, loading, refetch: fetchCredits };
};

export const useAllCredits = () => {
  const { isAdmin } = useAuth();
  const [allCredits, setAllCredits] = useState<UserCredit[]>([]);
  const [loading, setLoading] = useState(true);
  const queryClient = useQueryClient();

  const fetchAllCredits = useCallback(async () => {
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
  }, [isAdmin]);

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
  }, [fetchAllCredits]);

  // Real-time subscription for all credits (admin)
  useEffect(() => {
    if (!isAdmin) return;

    const channel = supabase
      .channel('all-credits-realtime')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'user_credits',
        },
        () => {
          // Refetch all credits when any change occurs
          fetchAllCredits();
          // Also invalidate related queries
          queryClient.invalidateQueries({ queryKey: ['players-credits-directory'] });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [isAdmin, fetchAllCredits, queryClient]);

  return { allCredits, loading, updateCredits, refetch: fetchAllCredits };
};
