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
import PlayerOnboardingWizard from '@/components/onboarding/PlayerOnboardingWizard';
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
  Clock,
  AlertTriangle,
  UserPlus
} from 'lucide-react';
import { cn } from '@/lib/utils';

const Dashboard: React.FC = () => {
  const { user, isApproved, isAdmin, isLoading } = useAuth();
  const { credits, loading: creditsLoading } = useCredits();
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
    
    const statsMap: Record<string, number> = {
      beginner: 30,
      intermediate: 50,
      advanced: 70,
      elite: 85,
    };
    const statsValue = statsMap[data.level] || 50;
    
    const playerData = {
      ...data,
      stats: {
        speed: statsValue,
        technique: statsValue,
        physical: statsValue,
        mental: statsValue,
        tactical: statsValue,
      },
    };
    
    const result = await createPlayer(playerData);
    setSubmitting(false);
    if (result) {
      toast({
        title: '⚽ ¡Fichaje Completado!',
        description: `${data.name} ha sido añadido al plantel.`,
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

  const hasNoCredits = credits === 0;
  const hasLowCredits = credits > 0 && credits <= 3;

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

        {/* Credits Alert Banner */}
        {hasNoCredits && (
          <EliteCard className="p-4 border-red-500/50 bg-red-500/10">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-red-500/20">
                <AlertTriangle className="w-6 h-6 text-red-400" />
              </div>
              <div className="flex-1">
                <p className="font-orbitron font-bold text-red-400">Sin Créditos Disponibles</p>
                <p className="text-sm text-muted-foreground">
                  No puedes hacer nuevas reservas. Contacta a la academia para recargar.
                </p>
              </div>
            </div>
          </EliteCard>
        )}

        {hasLowCredits && (
          <EliteCard className="p-4 border-yellow-500/50 bg-yellow-500/10">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-yellow-500/20">
                <Coins className="w-6 h-6 text-yellow-400" />
              </div>
              <div className="flex-1">
                <p className="font-orbitron font-bold text-yellow-400">Créditos Bajos</p>
                <p className="text-sm text-muted-foreground">
                  Solo te quedan {credits} créditos. Considera recargar pronto.
                </p>
              </div>
            </div>
          </EliteCard>
        )}

        {/* Stats Cards */}
        <div className="grid md:grid-cols-4 gap-4">
          {/* Dynamic Credits Card */}
          <EliteCard className={cn(
            "p-5 transition-all",
            hasNoCredits 
              ? "border-red-500/50 bg-gradient-to-br from-red-500/10 to-red-500/5" 
              : hasLowCredits
                ? "border-yellow-500/50 bg-gradient-to-br from-yellow-500/10 to-yellow-500/5"
                : ""
          )}>
            <div className="flex items-center gap-4">
              <div className={cn(
                "w-12 h-12 rounded-xl flex items-center justify-center",
                hasNoCredits
                  ? "bg-red-500/20 border border-red-500/30"
                  : hasLowCredits
                    ? "bg-yellow-500/20 border border-yellow-500/30"
                    : "bg-gradient-to-br from-neon-cyan/20 to-neon-cyan/5 border border-neon-cyan/30"
              )}>
                <Coins className={cn(
                  "w-6 h-6",
                  hasNoCredits ? "text-red-400" : hasLowCredits ? "text-yellow-400" : "text-neon-cyan"
                )} />
              </div>
              <div>
                <p className="text-muted-foreground text-sm font-rajdhani">Créditos</p>
                <p className={cn(
                  "font-orbitron font-bold text-2xl",
                  hasNoCredits ? "text-red-400" : hasLowCredits ? "text-yellow-400" : "text-neon-cyan"
                )}>
                  {creditsLoading ? '...' : credits}
                </p>
                {hasNoCredits && (
                  <p className="text-xs text-red-400 mt-0.5">Sin créditos</p>
                )}
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
                  <UserPlus className="w-4 h-4 mr-2" />
                  Fichar Jugador
                </NeonButton>
              </DialogTrigger>
              <DialogContent className="bg-background border-neon-cyan/30 max-w-lg max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                  <DialogTitle className="font-orbitron gradient-text text-xl">
                    ⚽ Fichaje Pro
                  </DialogTitle>
                </DialogHeader>
                <PlayerOnboardingWizard
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
                <UserPlus className="w-4 h-4 mr-2" />
                Fichar tu primer jugador
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
                <NeonButton 
                  variant="purple" 
                  size="sm"
                  disabled={hasNoCredits}
                  className={hasNoCredits ? 'opacity-50 cursor-not-allowed' : ''}
                >
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

          {/* Block message when no credits */}
          {hasNoCredits && (
            <EliteCard className="p-6 text-center border-red-500/30 bg-red-500/5">
              <AlertTriangle className="w-10 h-10 text-red-400 mx-auto mb-3" />
              <p className="font-rajdhani font-bold text-red-400 mb-2">
                Acceso al Calendario Bloqueado
              </p>
              <p className="text-sm text-muted-foreground">
                Necesitas créditos para hacer reservas. Contacta a Elite 380 para recargar tu cartera.
              </p>
            </EliteCard>
          )}

          {!hasNoCredits && reservations.length === 0 ? (
            <EliteCard className="p-8 text-center">
              <Calendar className="w-12 h-12 text-neon-purple/30 mx-auto mb-4" />
              <p className="text-muted-foreground mb-4">No tienes reservas</p>
              <NeonButton variant="gradient" onClick={() => setReservationDialogOpen(true)}>
                <Plus className="w-4 h-4 mr-2" />
                Crear tu primera reserva
              </NeonButton>
            </EliteCard>
          ) : !hasNoCredits && (
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
