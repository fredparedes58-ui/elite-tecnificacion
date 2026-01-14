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
import { Calendar, Edit, User } from 'lucide-react';

interface MyPlayerCardProps {
  player: Player;
  onUploadPhoto: (playerId: string, file: File) => Promise<void>;
  uploading?: boolean;
}

const MyPlayerCard: React.FC<MyPlayerCardProps> = ({ player, onUploadPhoto, uploading }) => {
  const [photoDialogOpen, setPhotoDialogOpen] = React.useState(false);

  const handleUpload = async (file: File) => {
    await onUploadPhoto(player.id, file);
    setPhotoDialogOpen(false);
  };

  const getLevelVariant = (level: string) => {
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
                {player.level}
              </StatusBadge>
            </div>
          </div>

          {player.birth_date && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Calendar className="w-4 h-4" />
              <span>Nacimiento: {new Date(player.birth_date).toLocaleDateString('es-ES')}</span>
            </div>
          )}
        </div>

        {/* Stats Section */}
        <div className="w-full md:w-48 h-48">
          <RadarChart stats={player.stats} size="sm" />
        </div>
      </div>
    </EliteCard>
  );
};

export default MyPlayerCard;
