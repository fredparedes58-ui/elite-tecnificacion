import React from 'react';
import { Link } from 'react-router-dom';
import { EliteCard } from '@/components/ui/EliteCard';
import { usePlayersWeeklyImprovement } from '@/hooks/usePlayersWeeklyImprovement';
import { getLevelColor } from '@/lib/constants/playerLevelColors';
import { TrendingUp, Target } from 'lucide-react';
import type { Database } from '@/integrations/supabase/types';

type PlayerLevel = Database['public']['Enums']['player_level'];

const PerformanceSummaryCard: React.FC = () => {
  const { data: players, isLoading } = usePlayersWeeklyImprovement();

  if (isLoading) {
    return (
      <EliteCard className="p-6 backdrop-blur-sm border-neon-cyan/20">
        <div className="flex items-center gap-2 mb-4">
          <TrendingUp className="w-5 h-5 text-neon-cyan" />
          <h3 className="font-orbitron font-semibold text-lg">Resumen de Rendimiento</h3>
        </div>
        <div className="h-24 flex items-center justify-center">
          <div className="w-8 h-8 border-2 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
        </div>
      </EliteCard>
    );
  }

  const list = players ?? [];

  return (
    <EliteCard className="p-6 backdrop-blur-sm border-neon-cyan/20">
      <div className="flex items-center justify-between gap-2 mb-4">
        <div className="flex items-center gap-2">
          <TrendingUp className="w-5 h-5 text-neon-cyan" />
          <h3 className="font-orbitron font-semibold text-lg">Resumen de Rendimiento</h3>
        </div>
        <Link
          to="/scouting"
          className="text-xs font-rajdhani text-neon-cyan hover:underline"
        >
          Ir a Scouting
        </Link>
      </div>
      <p className="text-sm text-muted-foreground mb-4">
        Jugadores que han subido +5 puntos de media esta semana
      </p>
      {list.length === 0 ? (
        <div className="py-6 text-center text-muted-foreground text-sm">
          Ningún jugador con mejora ≥5 puntos esta semana.
        </div>
      ) : (
        <ul className="space-y-2 max-h-48 overflow-y-auto">
          {list.map((p) => (
            <li
              key={p.player_id}
              className="flex items-center justify-between gap-2 p-2 rounded-lg bg-muted/30 border border-muted/50"
            >
              <div className="flex items-center gap-2 min-w-0">
                {p.photo_url ? (
                  <img
                    src={p.photo_url}
                    alt=""
                    className="w-8 h-8 rounded-full object-cover shrink-0"
                  />
                ) : (
                  <div
                    className="w-8 h-8 rounded-full shrink-0 flex items-center justify-center text-xs font-bold"
                    style={{
                      backgroundColor: `${getLevelColor(p.player_level as PlayerLevel)}33`,
                      color: getLevelColor(p.player_level as PlayerLevel),
                    }}
                  >
                    {p.player_name.charAt(0)}
                  </div>
                )}
                <span className="font-rajdhani font-medium truncate">{p.player_name}</span>
              </div>
              <span
                className="font-orbitron font-bold shrink-0"
                style={{ color: getLevelColor(p.player_level as PlayerLevel) }}
              >
                +{p.points_gain.toFixed(1)}
              </span>
            </li>
          ))}
        </ul>
      )}
    </EliteCard>
  );
};

export default PerformanceSummaryCard;
