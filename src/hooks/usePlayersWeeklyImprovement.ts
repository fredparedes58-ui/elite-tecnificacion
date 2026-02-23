import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export interface WeeklyImprovementRow {
  player_id: string;
  current_avg: number;
  past_avg: number | null;
  points_gain: number;
}

export interface PlayerWeeklyImprovement extends WeeklyImprovementRow {
  player_name: string;
  player_level: string | null;
  player_category: string | null;
  photo_url: string | null;
}

export function usePlayersWeeklyImprovement() {
  return useQuery({
    queryKey: ['players-weekly-improvement'],
    queryFn: async (): Promise<PlayerWeeklyImprovement[]> => {
      const { data: rows, error } = await (supabase.rpc as any)('get_players_weekly_improvement');

      if (error) return [];
      if (!rows || (rows as unknown[]).length === 0) return [];

      const playerIds = (rows as WeeklyImprovementRow[]).map((r) => r.player_id);
      const { data: players } = await supabase
        .from('players')
        .select('id, name, level, category, photo_url')
        .in('id', playerIds);

      const playerMap = new Map(
        (players || []).map((p: { id: string; name: string; level?: string; category?: string; photo_url?: string | null }) => [
          p.id,
          { name: p.name, level: p.level, category: p.category, photo_url: p.photo_url },
        ])
      );

      return (rows as WeeklyImprovementRow[]).map((r) => ({
        ...r,
        current_avg: Number(r.current_avg),
        past_avg: r.past_avg != null ? Number(r.past_avg) : null,
        points_gain: Number(r.points_gain),
        player_name: playerMap.get(r.player_id)?.name ?? 'Jugador',
        player_level: playerMap.get(r.player_id)?.level ?? null,
        player_category: playerMap.get(r.player_id)?.category ?? null,
        photo_url: playerMap.get(r.player_id)?.photo_url ?? null,
      }));
    },
    staleTime: 60 * 1000,
  });
}
