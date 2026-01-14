import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Database } from '@/integrations/supabase/types';

type Player = Database['public']['Tables']['players']['Row'];
type PlayerCategory = Database['public']['Enums']['player_category'];
type PlayerLevel = Database['public']['Enums']['player_level'];

interface PlayerStats {
  speed: number;
  technique: number;
  physical: number;
  mental: number;
  tactical: number;
}

interface PlayerWithStats extends Omit<Player, 'stats'> {
  stats: PlayerStats;
}

interface UsePlayersFilters {
  category?: PlayerCategory | 'all';
  level?: PlayerLevel | 'all';
  search?: string;
}

export function usePlayers(filters?: UsePlayersFilters) {
  const [players, setPlayers] = useState<PlayerWithStats[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchPlayers() {
      setIsLoading(true);
      setError(null);

      try {
        let query = supabase.from('players').select('*');

        if (filters?.category && filters.category !== 'all') {
          query = query.eq('category', filters.category);
        }

        if (filters?.level && filters.level !== 'all') {
          query = query.eq('level', filters.level);
        }

        if (filters?.search) {
          query = query.ilike('name', `%${filters.search}%`);
        }

        const { data, error: fetchError } = await query.order('name');

        if (fetchError) throw fetchError;

        // Transform the data to ensure stats is properly typed
        const transformedData: PlayerWithStats[] = (data || []).map(player => {
          const rawStats = player.stats as unknown;
          const defaultStats: PlayerStats = {
            speed: 50,
            technique: 50,
            physical: 50,
            mental: 50,
            tactical: 50
          };

          let stats: PlayerStats = defaultStats;
          if (rawStats && typeof rawStats === 'object' && !Array.isArray(rawStats)) {
            const obj = rawStats as Record<string, unknown>;
            stats = {
              speed: typeof obj.speed === 'number' ? obj.speed : defaultStats.speed,
              technique: typeof obj.technique === 'number' ? obj.technique : defaultStats.technique,
              physical: typeof obj.physical === 'number' ? obj.physical : defaultStats.physical,
              mental: typeof obj.mental === 'number' ? obj.mental : defaultStats.mental,
              tactical: typeof obj.tactical === 'number' ? obj.tactical : defaultStats.tactical,
            };
          }

          return {
            ...player,
            stats
          };
        });

        setPlayers(transformedData);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Error al cargar jugadores');
      } finally {
        setIsLoading(false);
      }
    }

    fetchPlayers();
  }, [filters?.category, filters?.level, filters?.search]);

  return { players, isLoading, error, refetch: () => {} };
}
