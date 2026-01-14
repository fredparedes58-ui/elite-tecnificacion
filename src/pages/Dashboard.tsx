import React from 'react';
import { Navigate, Link } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useCredits } from '@/hooks/useCredits';
import { useMyPlayers } from '@/hooks/useMyPlayers';
import { useReservations } from '@/hooks/useReservations';
import Layout from '@/components/layout/Layout';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import MyPlayerCard from '@/components/dashboard/MyPlayerCard';
import PlayerForm from '@/components/dashboard/PlayerForm';
import ReservationForm from '@/components/dashboard/ReservationForm';
import { useToast } from '@/hooks/use-toast';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { 
  Users, 
  Calendar, 
  Coins, 
  Plus, 
  MessageSquare,
  Clock
} from 'lucide-react';

const Dashboard: React.FC = () => {
  const { user, isApproved, isAdmin, isLoading } = useAuth();
  const { credits } = useCredits();
  const { players, createPlayer, uploadPlayerPhoto } = useMyPlayers();
  const { reservations, createReservation } = useReservations();
  const { toast } = useToast();
  
  const [playerDialogOpen, setPlayerDialogOpen] = React.useState(false);
  const [reservationDialogOpen, setReservationDialogOpen] = React.useState(false);
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

  const handleCreateReservation = async (data: any) => {
    setSubmitting(true);
    const result = await createReservation(data);
    setSubmitting(false);
    if (result) {
      toast({
        title: 'Reserva solicitada',
        description: 'Tu reserva está pendiente de aprobación.',
      });
      setReservationDialogOpen(false);
    } else {
      toast({
        title: 'Error',
        description: 'No se pudo crear la reserva.',
        variant: 'destructive',
      });
    }
  };

  const getStatusVariant = (status: string) => {
    switch (status) {
      case 'approved':
        return 'success';
      case 'pending':
        return 'warning';
      case 'cancelled':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'approved':
        return 'Aprobada';
      case 'pending':
        return 'Pendiente';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  };

  const pendingReservations = reservations.filter((r) => r.status === 'pending');

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8 space-y-8">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="font-orbitron font-bold text-3xl md:text-4xl gradient-text mb-2">
            Mi Panel
          </h1>
          <p className="text-muted-foreground font-rajdhani">
            Gestiona tus jugadores y reservas
          </p>
        </div>

        {/* Stats Cards */}
        <div className="grid md:grid-cols-4 gap-4">
          <EliteCard className="p-5">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-neon-cyan/20 to-neon-cyan/5 border border-neon-cyan/30 flex items-center justify-center">
                <Coins className="w-6 h-6 text-neon-cyan" />
              </div>
              <div>
                <p className="text-muted-foreground text-sm font-rajdhani">Créditos</p>
                <p className="font-orbitron font-bold text-2xl text-neon-cyan">{credits}</p>
              </div>
            </div>
          </EliteCard>

          <EliteCard className="p-5">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-neon-purple/20 to-neon-purple/5 border border-neon-purple/30 flex items-center justify-center">
                <Users className="w-6 h-6 text-neon-purple" />
              </div>
              <div>
                <p className="text-muted-foreground text-sm font-rajdhani">Jugadores</p>
                <p className="font-orbitron font-bold text-2xl">{players.length}</p>
              </div>
            </div>
          </EliteCard>

          <EliteCard className="p-5">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center">
                <Calendar className="w-6 h-6 text-neon-cyan" />
              </div>
              <div>
                <p className="text-muted-foreground text-sm font-rajdhani">Reservas</p>
                <p className="font-orbitron font-bold text-2xl">{reservations.length}</p>
              </div>
            </div>
          </EliteCard>

          <Link to="/chat">
            <EliteCard className="p-5 h-full hover:border-neon-purple/50 transition-colors">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-neon-purple/20 to-neon-purple/5 border border-neon-purple/30 flex items-center justify-center">
                  <MessageSquare className="w-6 h-6 text-neon-purple" />
                </div>
                <div>
                  <p className="text-muted-foreground text-sm font-rajdhani">Chat</p>
                  <p className="font-orbitron font-semibold text-sm">Ir al Chat</p>
                </div>
              </div>
            </EliteCard>
          </Link>
        </div>

        {/* My Players Section */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-orbitron font-bold text-xl">Mis Jugadores</h2>
            <Dialog open={playerDialogOpen} onOpenChange={setPlayerDialogOpen}>
              <DialogTrigger asChild>
                <NeonButton variant="cyan" size="sm">
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

          {players.length === 0 ? (
            <EliteCard className="p-8 text-center">
              <Users className="w-12 h-12 text-neon-cyan/30 mx-auto mb-4" />
              <p className="text-muted-foreground mb-4">No tienes jugadores registrados</p>
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
        </section>

        {/* Reservations Section */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-orbitron font-bold text-xl">Mis Reservas</h2>
            <Dialog open={reservationDialogOpen} onOpenChange={setReservationDialogOpen}>
              <DialogTrigger asChild>
                <NeonButton variant="purple" size="sm">
                  <Plus className="w-4 h-4 mr-2" />
                  Nueva Reserva
                </NeonButton>
              </DialogTrigger>
              <DialogContent className="bg-background border-neon-cyan/30 max-w-md">
                <DialogHeader>
                  <DialogTitle className="font-orbitron gradient-text">
                    Nueva Reserva
                  </DialogTitle>
                </DialogHeader>
                <ReservationForm
                  players={players}
                  credits={credits}
                  onSubmit={handleCreateReservation}
                  onCancel={() => setReservationDialogOpen(false)}
                  loading={submitting}
                />
              </DialogContent>
            </Dialog>
          </div>

          {reservations.length === 0 ? (
            <EliteCard className="p-8 text-center">
              <Calendar className="w-12 h-12 text-neon-purple/30 mx-auto mb-4" />
              <p className="text-muted-foreground mb-4">No tienes reservas</p>
              <NeonButton variant="gradient" onClick={() => setReservationDialogOpen(true)}>
                <Plus className="w-4 h-4 mr-2" />
                Crear tu primera reserva
              </NeonButton>
            </EliteCard>
          ) : (
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
              {reservations.slice(0, 6).map((reservation) => (
                <EliteCard key={reservation.id} className="p-4">
                  <div className="flex items-start justify-between mb-3">
                    <h3 className="font-rajdhani font-semibold truncate">
                      {reservation.title}
                    </h3>
                    <StatusBadge variant={getStatusVariant(reservation.status || 'pending')}>
                      {getStatusLabel(reservation.status || 'pending')}
                    </StatusBadge>
                  </div>
                  <div className="space-y-2 text-sm text-muted-foreground">
                    <div className="flex items-center gap-2">
                      <Calendar className="w-4 h-4" />
                      <span>
                        {format(new Date(reservation.start_time), 'dd MMM yyyy', { locale: es })}
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Clock className="w-4 h-4" />
                      <span>
                        {format(new Date(reservation.start_time), 'HH:mm')} -{' '}
                        {format(new Date(reservation.end_time), 'HH:mm')}
                      </span>
                    </div>
                  </div>
                </EliteCard>
              ))}
            </div>
          )}
        </section>
      </div>
    </Layout>
  );
};

export default Dashboard;
