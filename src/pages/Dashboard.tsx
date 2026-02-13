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
import EditPlayerModal from '@/components/players/EditPlayerModal';
import DeletePlayerModal from '@/components/players/DeletePlayerModal';
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
  UserPlus,
  User,
  ArrowRight
} from 'lucide-react';
import { cn } from '@/lib/utils';
import type { Player } from '@/hooks/useMyPlayers';

const Dashboard: React.FC = () => {
  const { user, profile, isApproved, isAdmin, isLoading } = useAuth();
  const { credits, loading: creditsLoading } = useCredits();
  const { players, createPlayer, updatePlayer, deletePlayer, uploadPlayerPhoto } = useMyPlayers();
  const { reservations, createReservation } = useReservations();
  const { toast } = useToast();
  
  const [playerDialogOpen, setPlayerDialogOpen] = React.useState(false);
  const [reservationDialogOpen, setReservationDialogOpen] = React.useState(false);
  const [editModalOpen, setEditModalOpen] = React.useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = React.useState(false);
  const [selectedPlayer, setSelectedPlayer] = React.useState<Player | null>(null);
  const [uploading, setUploading] = React.useState(false);
  const [submitting, setSubmitting] = React.useState(false);
  const [deleting, setDeleting] = React.useState(false);

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

  const handleEditClick = (player: Player) => {
    setSelectedPlayer(player);
    setEditModalOpen(true);
  };

  const handleDeleteClick = (player: Player) => {
    setSelectedPlayer(player);
    setDeleteModalOpen(true);
  };

  const handleSavePlayer = async (id: string, data: Partial<Omit<Player, 'stats'>>) => {
    setSubmitting(true);
    const result = await updatePlayer(id, data);
    setSubmitting(false);
    
    if (result) {
      toast({
        title: '✅ Jugador actualizado',
        description: 'Los datos del jugador han sido guardados.',
      });
      return true;
    } else {
      toast({
        title: 'Error',
        description: 'No se pudieron guardar los cambios.',
        variant: 'destructive',
      });
      return false;
    }
  };

  const handleConfirmDelete = async () => {
    if (!selectedPlayer) return;
    
    setDeleting(true);
    const result = await deletePlayer(selectedPlayer.id);
    setDeleting(false);
    
    if (result) {
      toast({
        title: '🗑️ Jugador eliminado',
        description: `${selectedPlayer.name} ha sido eliminado del plantel.`,
      });
      setDeleteModalOpen(false);
      setSelectedPlayer(null);
    } else {
      toast({
        title: 'Error',
        description: 'No se pudo eliminar el jugador.',
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

  // Get pending reservations count
  const pendingReservations = reservations.filter(r => r.status === 'pending').length;
  const approvedReservations = reservations.filter(r => 
    r.status === 'approved' && new Date(r.start_time) > new Date()
  ).length;

  return (
    <Layout>
      <div className="container mx-auto px-4 py-6 space-y-6">
        {/* Welcome Header - Hero style */}
        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-neon-cyan/10 via-background to-neon-purple/10 border border-neon-cyan/20 p-6 md:p-8">
          <div className="absolute top-0 right-0 w-64 h-64 bg-neon-cyan/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/4" />
          <div className="absolute bottom-0 left-0 w-48 h-48 bg-neon-purple/5 rounded-full blur-3xl translate-y-1/2 -translate-x-1/4" />
          <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <p className="text-neon-cyan font-rajdhani font-semibold text-sm uppercase tracking-wider mb-1">
                Elite 380 Academy
              </p>
              <h1 className="font-orbitron font-bold text-3xl md:text-4xl text-foreground mb-1">
                ¡Hola, {profile?.full_name?.split(' ')[0] || 'Deportista'}!
              </h1>
              <p className="text-muted-foreground font-rajdhani">
                {approvedReservations > 0
                  ? `Tienes ${approvedReservations} sesión${approvedReservations > 1 ? 'es' : ''} próxima${approvedReservations > 1 ? 's' : ''}`
                  : 'No tienes sesiones programadas'}
              </p>
            </div>
            <div className="flex items-center gap-3">
              <Link to="/chat">
                <NeonButton variant="outline" size="sm">
                  <MessageSquare className="w-4 h-4 mr-2" />
                  Chat
                </NeonButton>
              </Link>
              <Link to="/settings">
                <NeonButton variant="outline" size="sm">
                  <User className="w-4 h-4 mr-2" />
                  Ajustes
                </NeonButton>
              </Link>
            </div>
          </div>
        </div>

        {/* Credits Alert Banner */}
        {hasNoCredits && (
          <EliteCard className="p-4 border-destructive/50 bg-destructive/10">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-destructive/20">
                <AlertTriangle className="w-6 h-6 text-destructive" />
              </div>
              <div className="flex-1">
                <p className="font-orbitron font-bold text-destructive">Sin Créditos Disponibles</p>
                <p className="text-sm text-muted-foreground">
                  No puedes hacer nuevas reservas. Contacta a la academia para recargar.
                </p>
              </div>
              <Link to="/chat">
                <NeonButton variant="outline" size="sm">
                  Contactar
                </NeonButton>
              </Link>
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

        {/* Quick Stats Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {/* Credits Card */}
          <Link to="/my-credits" className="contents">
            <EliteCard className={cn(
              "p-5 transition-all hover:border-neon-cyan/50 cursor-pointer",
              hasNoCredits 
                ? "border-destructive/50 bg-gradient-to-br from-destructive/10 to-destructive/5" 
                : hasLowCredits
                  ? "border-yellow-500/50 bg-gradient-to-br from-yellow-500/10 to-yellow-500/5"
                  : ""
            )}>
              <div className="flex items-center gap-4">
                <div className={cn(
                  "w-12 h-12 rounded-xl flex items-center justify-center",
                  hasNoCredits
                    ? "bg-destructive/20 border border-destructive/30"
                    : hasLowCredits
                      ? "bg-yellow-500/20 border border-yellow-500/30"
                      : "bg-gradient-to-br from-neon-cyan/20 to-neon-cyan/5 border border-neon-cyan/30"
                )}>
                  <Coins className={cn(
                    "w-6 h-6",
                    hasNoCredits ? "text-destructive" : hasLowCredits ? "text-yellow-400" : "text-neon-cyan"
                  )} />
                </div>
                <div>
                  <p className="text-muted-foreground text-sm font-rajdhani">Créditos</p>
                  <p className={cn(
                    "font-orbitron font-bold text-2xl",
                    hasNoCredits ? "text-destructive" : hasLowCredits ? "text-yellow-400" : "text-neon-cyan"
                  )}>
                    {creditsLoading ? '...' : credits}
                  </p>
                </div>
              </div>
            </EliteCard>
          </Link>

          {/* Players Card */}
          <Link to="/players" className="contents">
            <EliteCard className="p-5 hover:border-neon-purple/50 cursor-pointer transition-all">
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
          </Link>

          {/* Reservations Card */}
          <Link to="/reservations" className="contents">
            <EliteCard className="p-5 hover:border-neon-cyan/50 cursor-pointer transition-all">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center">
                  <Calendar className="w-6 h-6 text-neon-cyan" />
                </div>
                <div>
                  <p className="text-muted-foreground text-sm font-rajdhani">Reservas</p>
                  <p className="font-orbitron font-bold text-2xl">{reservations.length}</p>
                  {approvedReservations > 0 && (
                    <p className="text-xs text-green-400">{approvedReservations} próximas</p>
                  )}
                </div>
              </div>
            </EliteCard>
          </Link>

        </div>

        {/* My Players Section */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-orbitron font-bold text-xl">Mis Jugadores</h2>
            <div className="flex items-center gap-2">
              <Link to="/players">
                <NeonButton variant="outline" size="sm">
                  Ver todos
                  <ArrowRight className="w-4 h-4 ml-2" />
                </NeonButton>
              </Link>
              <Dialog open={playerDialogOpen} onOpenChange={setPlayerDialogOpen}>
                <DialogTrigger asChild>
                  <NeonButton variant="cyan" size="sm">
                    <UserPlus className="w-4 h-4 mr-2" />
                    Fichar
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
              {players.slice(0, 2).map((player) => (
                <MyPlayerCard
                  key={player.id}
                  player={player}
                  onUploadPhoto={handleUploadPhoto}
                  onEdit={handleEditClick}
                  onDelete={handleDeleteClick}
                  uploading={uploading}
                />
              ))}
              {players.length > 2 && (
                <Link to="/players" className="block">
                  <EliteCard className="p-4 text-center hover:border-neon-cyan/50 transition-colors cursor-pointer">
                    <p className="text-muted-foreground">
                      Ver {players.length - 2} jugador{players.length - 2 > 1 ? 'es' : ''} más
                    </p>
                  </EliteCard>
                </Link>
              )}
            </div>
          )}
        </section>

        {/* Reservations Section */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <h2 className="font-orbitron font-bold text-xl">Mis Reservas</h2>
              {pendingReservations > 0 && (
                <StatusBadge variant="warning">{pendingReservations} pendientes</StatusBadge>
              )}
            </div>
            <div className="flex items-center gap-2">
              <Link to="/reservations">
                <NeonButton variant="outline" size="sm">
                  Ver todas
                  <ArrowRight className="w-4 h-4 ml-2" />
                </NeonButton>
              </Link>
              <Dialog open={reservationDialogOpen} onOpenChange={setReservationDialogOpen}>
                <DialogTrigger asChild>
                  <NeonButton 
                    variant="purple" 
                    size="sm"
                    disabled={hasNoCredits}
                    className={hasNoCredits ? 'opacity-50 cursor-not-allowed' : ''}
                  >
                    <Plus className="w-4 h-4 mr-2" />
                    Nueva
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
          </div>

          {/* Block message when no credits */}
          {hasNoCredits && (
            <EliteCard className="p-6 text-center border-destructive/30 bg-destructive/5">
              <AlertTriangle className="w-10 h-10 text-destructive mx-auto mb-3" />
              <p className="font-rajdhani font-bold text-destructive mb-2">
                Acceso al Calendario Bloqueado
              </p>
              <p className="text-sm text-muted-foreground mb-4">
                Necesitas créditos para hacer reservas. Contacta a Elite 380 para recargar tu cartera.
              </p>
              <Link to="/chat">
                <NeonButton variant="outline" size="sm">
                  <MessageSquare className="w-4 h-4 mr-2" />
                  Contactar a Pedro
                </NeonButton>
              </Link>
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

      {/* Edit Modal */}
      <EditPlayerModal
        isOpen={editModalOpen}
        onClose={() => {
          setEditModalOpen(false);
          setSelectedPlayer(null);
        }}
        player={selectedPlayer}
        onSave={handleSavePlayer}
        loading={submitting}
      />

      {/* Delete Modal */}
      <DeletePlayerModal
        isOpen={deleteModalOpen}
        onClose={() => {
          setDeleteModalOpen(false);
          setSelectedPlayer(null);
        }}
        player={selectedPlayer}
        onConfirm={handleConfirmDelete}
        loading={deleting}
      />
    </Layout>
  );
};

export default Dashboard;
