import React from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { StatusBadge } from '@/components/ui/StatusBadge';
import RadarChart from '@/components/players/RadarChart';
import { User, Calendar, MapPin } from 'lucide-react';
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
  birth_date?: string | null;
  notes?: string | null;
}

interface PlayerDetailModalProps {
  player: Player | null;
  isOpen: boolean;
  onClose: () => void;
}

const statLabels: Record<keyof PlayerStats, string> = {
  speed: 'Velocidad',
  technique: 'Técnica',
  physical: 'Físico',
  mental: 'Mental',
  tactical: 'Táctico',
};

const PlayerDetailModal: React.FC<PlayerDetailModalProps> = ({ player, isOpen, onClose }) => {
  if (!player) return null;

  const calculateAge = (birthDate: string | null | undefined) => {
    if (!birthDate) return null;
    const today = new Date();
    const birth = new Date(birthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  };

  const age = calculateAge(player.birth_date);

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="bg-card border-neon-cyan/30 max-w-2xl">
        <DialogHeader>
          <DialogTitle className="font-orbitron gradient-text text-2xl">
            Perfil del Jugador
          </DialogTitle>
        </DialogHeader>

        <div className="grid md:grid-cols-2 gap-6">
          {/* Left Column - Photo & Basic Info */}
          <div className="space-y-4">
            {/* Photo */}
            <div className="relative aspect-square rounded-lg overflow-hidden bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30">
              {player.photo_url ? (
                <img
                  src={player.photo_url}
                  alt={player.name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <User className="w-24 h-24 text-muted-foreground" />
                </div>
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-background/80 via-transparent to-transparent" />
              <div className="absolute bottom-4 left-4 right-4">
                <h2 className="font-orbitron font-bold text-2xl text-foreground mb-2">
                  {player.name}
                </h2>
                <div className="flex flex-wrap gap-2">
                  <StatusBadge variant="info">{player.category}</StatusBadge>
                  <StatusBadge variant={player.level === 'elite' ? 'success' : player.level === 'advanced' ? 'info' : 'default'}>
                    {player.level}
                  </StatusBadge>
                </div>
              </div>
            </div>

            {/* Info Details */}
            <div className="space-y-3">
              {player.position && (
                <div className="flex items-center gap-3 text-muted-foreground">
                  <MapPin className="w-4 h-4 text-neon-cyan" />
                  <span className="font-rajdhani">Posición: {player.position}</span>
                </div>
              )}
              {age !== null && (
                <div className="flex items-center gap-3 text-muted-foreground">
                  <Calendar className="w-4 h-4 text-neon-purple" />
                  <span className="font-rajdhani">{age} años</span>
                </div>
              )}
            </div>

            {/* Notes */}
            {player.notes && (
              <div className="p-4 rounded-lg bg-muted/30 border border-border">
                <h4 className="font-orbitron text-sm text-neon-cyan mb-2">Notas</h4>
                <p className="text-sm text-muted-foreground font-rajdhani">{player.notes}</p>
              </div>
            )}
          </div>

          {/* Right Column - Stats */}
          <div className="space-y-4">
            {/* Radar Chart */}
            <div className="flex justify-center py-4">
              <RadarChart stats={player.stats} size={240} showLabels={true} />
            </div>

            {/* Stat Bars */}
            <div className="space-y-3">
              {(Object.entries(player.stats) as [keyof PlayerStats, number][]).map(([key, value]) => (
                <div key={key}>
                  <div className="flex justify-between mb-1">
                    <span className="text-sm font-rajdhani text-muted-foreground">
                      {statLabels[key]}
                    </span>
                    <span className="text-sm font-orbitron text-neon-cyan">{value}</span>
                  </div>
                  <div className="h-2 bg-muted rounded-full overflow-hidden">
                    <div 
                      className="h-full rounded-full transition-all duration-500"
                      style={{
                        width: `${value}%`,
                        background: `linear-gradient(90deg, hsl(var(--neon-cyan)), hsl(var(--neon-purple)))`
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>

            {/* Overall Rating */}
            <div className="p-4 rounded-lg bg-gradient-to-br from-neon-cyan/10 to-neon-purple/10 border border-neon-cyan/30 text-center">
              <span className="text-sm font-rajdhani text-muted-foreground block mb-1">
                Puntuación General
              </span>
              <span className="font-orbitron font-bold text-4xl gradient-text">
                {Math.round(Object.values(player.stats).reduce((a, b) => a + b, 0) / 5)}
              </span>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default PlayerDetailModal;
