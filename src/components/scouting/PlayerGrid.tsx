import React from 'react';
import PlayerCard from '@/components/players/PlayerCard';
import { Database } from '@/integrations/supabase/types';

type PlayerCategory = Database['public']['Enums']['player_category'];
type PlayerLevel = Database['public']['Enums']['player_level'];

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
  category: PlayerCategory;
  level: PlayerLevel;
  photo_url: string | null;
  position: string | null;
  stats: PlayerStats;
}

interface PlayerGridProps {
  players: Player[];
  onPlayerClick?: (player: Player) => void;
}

const PlayerGrid: React.FC<PlayerGridProps> = ({ players, onPlayerClick }) => {
  if (players.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <div className="w-24 h-24 rounded-full bg-muted/50 flex items-center justify-center mb-4">
          <svg 
            className="w-12 h-12 text-muted-foreground" 
            fill="none" 
            viewBox="0 0 24 24" 
            stroke="currentColor"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <h3 className="font-orbitron font-semibold text-lg mb-2">No se encontraron jugadores</h3>
        <p className="text-muted-foreground font-rajdhani">
          Intenta ajustar los filtros de búsqueda
        </p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {players.map((player) => (
        <PlayerCard 
          key={player.id} 
          player={player}
          onClick={() => onPlayerClick?.(player)}
        />
      ))}
    </div>
  );
};

export default PlayerGrid;
