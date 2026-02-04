import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

export interface PlayerStatsRecord {
  id: string;
  player_id: string;
  reservation_id: string | null;
  recorded_by: string;
  stats: {
    speed: number;
    technique: number;
    physical: number;
    mental: number;
    tactical: number;
  };
  notes: string | null;
  recorded_at: string;
  created_at: string;
  recorder_name?: string;
}

export function usePlayerStatsHistory(playerId?: string) {
  return useQuery({
    queryKey: ['player-stats-history', playerId],
    queryFn: async (): Promise<PlayerStatsRecord[]> => {
      if (!playerId) return [];

      // First get the stats history
      const { data, error } = await supabase
        .from('player_stats_history')
        .select('*')
        .eq('player_id', playerId)
        .order('recorded_at', { ascending: true });

      if (error) {
        console.error('Error fetching player stats history:', error);
        return [];
      }

      if (!data || data.length === 0) return [];

      // Get unique recorder IDs
      const recorderIds = [...new Set(data.map(d => d.recorded_by))];
      
      // Fetch recorder names
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, full_name')
        .in('id', recorderIds);
      
      const profileMap = new Map(profiles?.map(p => [p.id, p.full_name]) || []);

      return data.map((item: any) => ({
        id: item.id,
        player_id: item.player_id,
        reservation_id: item.reservation_id,
        recorded_by: item.recorded_by,
        stats: item.stats as PlayerStatsRecord['stats'],
        notes: item.notes,
        recorded_at: item.recorded_at,
        created_at: item.created_at,
        recorder_name: profileMap.get(item.recorded_by) || 'Entrenador',
      }));
    },
    enabled: !!playerId,
  });
}

export function useAddStatsRecord() {
  const queryClient = useQueryClient();
  const { user } = useAuth();

  return useMutation({
    mutationFn: async ({
      playerId,
      reservationId,
      stats,
      notes,
    }: {
      playerId: string;
      reservationId?: string;
      stats: PlayerStatsRecord['stats'];
      notes?: string;
    }) => {
      if (!user) throw new Error('No user authenticated');

      const { data, error } = await supabase
        .from('player_stats_history')
        .insert({
          player_id: playerId,
          reservation_id: reservationId || null,
          recorded_by: user.id,
          stats,
          notes: notes || null,
          recorded_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['player-stats-history', variables.playerId] });
    },
  });
}
