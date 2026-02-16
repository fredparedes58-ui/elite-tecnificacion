import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

export interface PendingPlayer {
  id: string;
  name: string;
  category: string;
  level: string;
  position: string | null;
  photo_url: string | null;
  current_club: string | null;
  birth_date: string | null;
  created_at: string;
  parent_id: string;
  parent_name: string | null;
}

export const usePendingPlayers = () => {
  const { user, isAdmin } = useAuth();
  const [players, setPlayers] = useState<PendingPlayer[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchPending = async () => {
    if (!user || !isAdmin) {
      setPlayers([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const { data, error } = await (supabase
        .from('players')
        .select('*') as any)
        .eq('approval_status', 'pending')
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Fetch parent names
      const parentIds = Array.from(new Set((data || []).map((p: any) => String(p.parent_id))));
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, full_name')
        .in('id', parentIds as any);

      const profileMap = new Map(
        (profiles || []).map((p) => [p.id, p.full_name])
      );

      const result: PendingPlayer[] = (data || []).map((p: any) => ({
        id: p.id,
        name: p.name,
        category: p.category,
        level: p.level,
        position: p.position,
        photo_url: p.photo_url,
        current_club: p.current_club,
        birth_date: p.birth_date,
        created_at: p.created_at,
        parent_id: p.parent_id,
        parent_name: profileMap.get(p.parent_id) || null,
      }));

      setPlayers(result);
    } catch (err) {
      console.error('Error fetching pending players:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPending();
  }, [user, isAdmin]);

  // Realtime subscription for player changes
  useEffect(() => {
    if (!user || !isAdmin) return;

    const channel = supabase
      .channel('pending-players')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'players' },
        () => fetchPending()
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, isAdmin]);

  return { players, loading, refetch: fetchPending };
};
