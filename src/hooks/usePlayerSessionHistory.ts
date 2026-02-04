import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export interface PlayerSession {
  id: string;
  title: string;
  description: string | null;
  start_time: string;
  end_time: string;
  status: string;
  trainer_comments: string | null;
  trainer_id: string | null;
  trainer_name: string | null;
  credit_cost: number;
}

export function usePlayerSessionHistory(playerId?: string) {
  return useQuery({
    queryKey: ['player-session-history', playerId],
    queryFn: async (): Promise<PlayerSession[]> => {
      if (!playerId) return [];

      const { data, error } = await supabase
        .from('reservations')
        .select(`
          id,
          title,
          description,
          start_time,
          end_time,
          status,
          trainer_comments,
          trainer_id,
          credit_cost,
          trainers!reservations_trainer_id_fkey(name)
        `)
        .eq('player_id', playerId)
        .in('status', ['completed', 'approved', 'no_show'])
        .order('start_time', { ascending: false });

      if (error) {
        console.error('Error fetching player sessions:', error);
        return [];
      }

      return (data || []).map((item: any) => ({
        id: item.id,
        title: item.title,
        description: item.description,
        start_time: item.start_time,
        end_time: item.end_time,
        status: item.status,
        trainer_comments: item.trainer_comments,
        trainer_id: item.trainer_id,
        trainer_name: item.trainers?.name || null,
        credit_cost: item.credit_cost || 1,
      }));
    },
    enabled: !!playerId,
  });
}
