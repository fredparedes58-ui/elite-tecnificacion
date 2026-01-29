import React from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { NeonButton } from '@/components/ui/NeonButton';
import PhotoUpload from './PhotoUpload';
import RadarChart from '@/components/players/RadarChart';
import type { Player } from '@/hooks/useMyPlayers';
import { 
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Calendar, Edit, User, Footprints, Building2, Activity, Trash2 } from 'lucide-react';
import { differenceInYears } from 'date-fns';

interface MyPlayerCardProps {
  player: Player;
  onUploadPhoto: (playerId: string, file: File) => Promise<void>;
  onEdit?: (player: Player) => void;
  onDelete?: (player: Player) => void;
  uploading?: boolean;
}

const MyPlayerCard: React.FC<MyPlayerCardProps> = ({ 
  player, 
  onUploadPhoto, 
  onEdit,
  onDelete,
  uploading 
}) => {
  const [photoDialogOpen, setPhotoDialogOpen] = React.useState(false);

  const handleUpload = async (file: File) => {
    await onUploadPhoto(player.id, file);
    setPhotoDialogOpen(false);
  };

  const getLevelVariant = (level: string): 'success' | 'info' | 'warning' | 'default' => {
    switch (level) {
      case 'elite':
        return 'success';
      case 'advanced':
        return 'info';
      case 'intermediate':
        return 'warning';
      default:
        return 'default';
    }
  };

  const getLevelLabel = (level: string) => {
    switch (level) {
      case 'elite': return 'Élite';
      case 'advanced': return 'Avanzado';
      case 'intermediate': return 'Intermedio';
      case 'beginner': return 'Principiante';
      default: return level;
    }
  };

  // Calculate age from birth date
  const getAge = (birthDate: string | null) => {
    if (!birthDate) return null;
    return differenceInYears(new Date(), new Date(birthDate));
  };

  const age = getAge(player.birth_date);

  // Get dominant leg label
  const getDominantLegLabel = (leg: string | null) => {
    switch (leg) {
      case 'right': return 'Derecha';
      case 'left': return 'Izquierda';
      case 'both': return 'Ambidiestro';
      default: return null;
    }
  };

  return (
    <EliteCard className="p-6">
      <div className="flex flex-col md:flex-row gap-6">
        {/* Photo Section */}
        <div className="flex flex-col items-center">
          <Dialog open={photoDialogOpen} onOpenChange={setPhotoDialogOpen}>
            <DialogTrigger asChild>
              <button className="relative group">
                <div className="w-28 h-28 rounded-xl overflow-hidden border-2 border-neon-cyan/30 bg-gradient-to-br from-neon-cyan/10 to-neon-purple/10">
                  {player.photo_url ? (
                    <img
                      src={player.photo_url}
                      alt={player.name}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center">
                      <User className="w-12 h-12 text-neon-cyan/30" />
                    </div>
                  )}
                </div>
                <div className="absolute inset-0 bg-background/80 opacity-0 group-hover:opacity-100 transition-opacity rounded-xl flex items-center justify-center">
                  <Edit className="w-6 h-6 text-neon-cyan" />
                </div>
              </button>
            </DialogTrigger>
            <DialogContent className="bg-background border-neon-cyan/30">
              <DialogHeader>
                <DialogTitle className="font-orbitron gradient-text">
                  Foto de {player.name}
                </DialogTitle>
              </DialogHeader>
              <PhotoUpload
                currentPhoto={player.photo_url}
                onUpload={handleUpload}
                loading={uploading}
              />
            </DialogContent>
          </Dialog>
        </div>

        {/* Info Section */}
        <div className="flex-1 space-y-3">
          <div className="flex items-start justify-between">
            <div>
              <h3 className="font-orbitron font-bold text-xl">{player.name}</h3>
              {player.position && (
                <p className="text-muted-foreground text-sm">{player.position}</p>
              )}
            </div>
            <div className="flex gap-2">
              <StatusBadge variant="info">{player.category}</StatusBadge>
              <StatusBadge variant={getLevelVariant(player.level)}>
                {getLevelLabel(player.level)}
              </StatusBadge>
            </div>
          </div>

          {/* Player Details Grid */}
          <div className="grid grid-cols-2 gap-3">
            {player.birth_date && (
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Calendar className="w-4 h-4 text-neon-cyan" />
                <span>{age} años</span>
              </div>
            )}
            
            {player.current_club && (
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Building2 className="w-4 h-4 text-neon-purple" />
                <span className="truncate">{player.current_club}</span>
              </div>
            )}

            {getDominantLegLabel(player.dominant_leg) && (
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Footprints className="w-4 h-4 text-neon-cyan" />
                <span>Pierna {getDominantLegLabel(player.dominant_leg)}</span>
              </div>
            )}

            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Activity className="w-4 h-4 text-green-400" />
              <span>Activo</span>
            </div>
          </div>

          {/* Notes if any */}
          {player.notes && (
            <div className="p-3 rounded-lg bg-muted/30 border border-neon-cyan/10">
              <p className="text-xs text-muted-foreground italic">{player.notes}</p>
            </div>
          )}

          {/* Action Buttons */}
          {(onEdit || onDelete) && (
            <div className="flex gap-2 pt-2">
              {onEdit && (
                <NeonButton
                  variant="outline"
                  size="sm"
                  onClick={() => onEdit(player)}
                >
                  <Edit className="w-4 h-4 mr-1" />
                  Editar
                </NeonButton>
              )}
              {onDelete && (
                <NeonButton
                  variant="outline"
                  size="sm"
                  onClick={() => onDelete(player)}
                  className="border-destructive/50 text-destructive hover:bg-destructive/10"
                >
                  <Trash2 className="w-4 h-4 mr-1" />
                  Eliminar
                </NeonButton>
              )}
            </div>
          )}
        </div>

        {/* Stats Section */}
        <div className="w-full md:w-48 h-48">
          <RadarChart stats={player.stats} size={150} />
        </div>
      </div>
    </EliteCard>
  );
};

export default MyPlayerCard;
