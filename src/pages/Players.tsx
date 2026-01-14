import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useMyPlayers } from '@/hooks/useMyPlayers';
import Layout from '@/components/layout/Layout';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import MyPlayerCard from '@/components/dashboard/MyPlayerCard';
import PlayerForm from '@/components/dashboard/PlayerForm';
import { useToast } from '@/hooks/use-toast';
import { 
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Users, Plus } from 'lucide-react';

const Players: React.FC = () => {
  const { user, isApproved, isAdmin, isLoading } = useAuth();
  const { players, createPlayer, uploadPlayerPhoto } = useMyPlayers();
  const { toast } = useToast();
  
  const [playerDialogOpen, setPlayerDialogOpen] = React.useState(false);
  const [uploading, setUploading] = React.useState(false);
  const [submitting, setSubmitting] = React.useState(false);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  if (!user || isAdmin) {
    return <Navigate to="/" replace />;
  }

  if (!isApproved) {
    return <Navigate to="/" replace />;
  }

  const handleCreatePlayer = async (data: any) => {
    setSubmitting(true);
    const result = await createPlayer(data);
    setSubmitting(false);
    if (result) {
      toast({
        title: 'Jugador registrado',
        description: 'El jugador ha sido añadido exitosamente.',
      });
      setPlayerDialogOpen(false);
    } else {
      toast({
        title: 'Error',
        description: 'No se pudo registrar el jugador.',
        variant: 'destructive',
      });
    }
  };

  const handleUploadPhoto = async (playerId: string, file: File) => {
    setUploading(true);
    const url = await uploadPlayerPhoto(playerId, file);
    setUploading(false);
    if (url) {
      toast({
        title: 'Foto actualizada',
        description: 'La foto del jugador ha sido actualizada.',
      });
    } else {
      toast({
        title: 'Error',
        description: 'No se pudo subir la foto.',
        variant: 'destructive',
      });
    }
  };

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8 space-y-8">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="font-orbitron font-bold text-3xl md:text-4xl gradient-text mb-2">
              Mis Jugadores
            </h1>
            <p className="text-muted-foreground font-rajdhani">
              Gestiona los perfiles de tus hijos
            </p>
          </div>
          <Dialog open={playerDialogOpen} onOpenChange={setPlayerDialogOpen}>
            <DialogTrigger asChild>
              <NeonButton variant="gradient">
                <Plus className="w-4 h-4 mr-2" />
                Agregar Jugador
              </NeonButton>
            </DialogTrigger>
            <DialogContent className="bg-background border-neon-cyan/30 max-w-md">
              <DialogHeader>
                <DialogTitle className="font-orbitron gradient-text">
                  Nuevo Jugador
                </DialogTitle>
              </DialogHeader>
              <PlayerForm
                onSubmit={handleCreatePlayer}
                onCancel={() => setPlayerDialogOpen(false)}
                loading={submitting}
              />
            </DialogContent>
          </Dialog>
        </div>

        {/* Players List */}
        {players.length === 0 ? (
          <EliteCard className="p-12 text-center">
            <Users className="w-16 h-16 text-neon-cyan/30 mx-auto mb-4" />
            <h3 className="font-orbitron font-semibold text-lg mb-2">
              No tienes jugadores registrados
            </h3>
            <p className="text-muted-foreground mb-6">
              Agrega a tus hijos para comenzar a gestionar sus entrenamientos
            </p>
            <NeonButton variant="gradient" onClick={() => setPlayerDialogOpen(true)}>
              <Plus className="w-4 h-4 mr-2" />
              Agregar tu primer jugador
            </NeonButton>
          </EliteCard>
        ) : (
          <div className="space-y-4">
            {players.map((player) => (
              <MyPlayerCard
                key={player.id}
                player={player}
                onUploadPhoto={handleUploadPhoto}
                uploading={uploading}
              />
            ))}
          </div>
        )}
      </div>
    </Layout>
  );
};

export default Players;
