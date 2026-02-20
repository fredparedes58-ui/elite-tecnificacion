import React, { useState } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import PlayerProgressChart from './PlayerProgressChart';
import { usePlayerStatsHistory } from '@/hooks/usePlayerStatsHistory';
import { format, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import { TrendingUp, ChevronDown, ChevronUp, ClipboardList } from 'lucide-react';
import type { Player } from '@/hooks/useMyPlayers';

interface PlayerEvolutionPanelProps {
  player: Player;
}

const PlayerEvolutionPanel: React.FC<PlayerEvolutionPanelProps> = ({ player }) => {
  const [expanded, setExpanded] = useState(false);
  const { data: history = [] } = usePlayerStatsHistory(player.id);

  return (
    <div className="space-y-4">
      {/* Toggle Button */}
      <NeonButton
        variant="outline"
        size="sm"
        onClick={() => setExpanded(!expanded)}
        className="w-full justify-between"
      >
        <span className="flex items-center gap-2">
          <TrendingUp className="w-4 h-4" />
          Evolución de Stats ({history.length} registros)
        </span>
        {expanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
      </NeonButton>

      {expanded && (
        <>
          {/* Progress Chart */}
          <PlayerProgressChart playerId={player.id} currentStats={player.stats} />

          {/* History Timeline */}
          {history.length > 0 && (
            <EliteCard className="p-4">
              <div className="flex items-center gap-2 mb-3">
                <ClipboardList className="w-4 h-4 text-neon-cyan" />
                <h4 className="font-orbitron text-sm font-semibold">Historial de Evaluaciones</h4>
              </div>
              <div className="space-y-3 max-h-60 overflow-y-auto pr-2">
                {[...history].reverse().map((record) => (
                  <div
                    key={record.id}
                    className="p-3 rounded-lg bg-muted/20 border border-muted/30 text-sm"
                  >
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-semibold text-foreground">
                        {format(parseISO(record.recorded_at), "d MMM yyyy", { locale: es })}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        por {record.recorder_name}
                      </span>
                    </div>
                    <div className="flex gap-3 text-xs text-muted-foreground">
                      <span>VEL: {record.stats.speed}</span>
                      <span>TÉC: {record.stats.technique}</span>
                      <span>FÍS: {record.stats.physical}</span>
                      <span>MEN: {record.stats.mental}</span>
                      <span>TÁC: {record.stats.tactical}</span>
                    </div>
                    {record.notes && (
                      <p className="text-xs text-muted-foreground mt-1 italic">"{record.notes}"</p>
                    )}
                  </div>
                ))}
              </div>
            </EliteCard>
          )}
        </>
      )}
    </div>
  );
};

export default PlayerEvolutionPanel;
