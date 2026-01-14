import React from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import RadarChart from './RadarChart';
import { User } from 'lucide-react';

interface PlayerStats {
  speed: number;
  technique: number;
  physical: number;
  mental: number;
  tactical: number;
}

interface Player {
  id: string;
  name: string;
  category: 'U8' | 'U10' | 'U12' | 'U14' | 'U16' | 'U18';
  level: 'beginner' | 'intermediate' | 'advanced' | 'elite';
  photo_url: string | null;
  stats: PlayerStats;
  position?: string;
}

interface PlayerCardProps {
  player: Player;
  onClick?: () => void;
}

const PlayerCard: React.FC<PlayerCardProps> = ({ player, onClick }) => {
  return (
    <EliteCard 
      className="p-4 cursor-pointer group"
      onClick={onClick}
    >
      {/* Header */}
      <div className="flex items-start gap-4 mb-4">
        {/* Photo */}
        <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex-shrink-0">
          {player.photo_url ? (
            <img
              src={player.photo_url}
              alt={player.name}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center">
              <User className="w-8 h-8 text-muted-foreground" />
            </div>
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-background/60 to-transparent" />
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <h3 className="font-orbitron font-semibold text-foreground truncate group-hover:text-neon-cyan transition-colors">
            {player.name}
          </h3>
          <p className="text-sm text-muted-foreground font-rajdhani">
            {player.position || 'Sin posición'}
          </p>
          <div className="flex flex-wrap gap-2 mt-2">
            <StatusBadge type="category" value={player.category} />
            <StatusBadge type="level" value={player.level} />
          </div>
        </div>
      </div>

      {/* Radar Chart */}
      <div className="flex justify-center">
        <RadarChart stats={player.stats} size={180} showLabels={true} />
      </div>

      {/* Stats Summary */}
      <div className="mt-4 grid grid-cols-5 gap-2 text-center">
        {Object.entries(player.stats).map(([key, value]) => (
          <div key={key} className="flex flex-col">
            <span className="text-lg font-orbitron font-bold text-neon-cyan">{value}</span>
            <span className="text-[9px] text-muted-foreground uppercase">
              {key.substring(0, 3)}
            </span>
          </div>
        ))}
      </div>

      {/* Hover effect line */}
      <div className="absolute bottom-0 left-0 right-0 h-[2px] bg-gradient-to-r from-neon-cyan via-neon-purple to-neon-cyan opacity-0 group-hover:opacity-100 transition-opacity" />
    </EliteCard>
  );
};

export default PlayerCard;
