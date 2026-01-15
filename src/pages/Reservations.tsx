import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useCredits } from '@/hooks/useCredits';
import { useMyPlayers } from '@/hooks/useMyPlayers';
import { useReservations } from '@/hooks/useReservations';
import Layout from '@/components/layout/Layout';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
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
import { Calendar, Clock, Plus, Coins, User, Users } from 'lucide-react';

const Reservations: React.FC = () => {
  const { user, isApproved, isAdmin, isLoading } = useAuth();
  const { credits } = useCredits();
  const { players } = useMyPlayers();
  const { reservations, createReservation } = useReservations();
  const { toast } = useToast();
  
  const [reservationDialogOpen, setReservationDialogOpen] = React.useState(false);
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
      case 'rejected':
      case 'cancelled':
        return 'error';
      case 'completed':
        return 'info';
      case 'no_show':
        return 'warning';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'approved':
        return '✅ Aprobada';
      case 'pending':
        return '⏳ Pendiente';
      case 'rejected':
        return '❌ Rechazada';
      case 'cancelled':
        return '🚫 Cancelada';
      case 'completed':
        return '✔️ Completada';
      case 'no_show':
        return '⚠️ No Asistió';
      default:
        return status;
    }
  };

  // Get player name by ID
  const getPlayerName = (playerId: string | null) => {
    if (!playerId) return null;
    const player = players.find(p => p.id === playerId);
    return player?.name || null;
  };

  // Sort reservations: upcoming first, then by date
  const sortedReservations = [...reservations].sort((a, b) => {
    const dateA = new Date(a.start_time).getTime();
    const dateB = new Date(b.start_time).getTime();
    const now = Date.now();
    
    // Upcoming reservations first
    const aIsUpcoming = dateA > now && (a.status === 'approved' || a.status === 'pending');
    const bIsUpcoming = dateB > now && (b.status === 'approved' || b.status === 'pending');
    
    if (aIsUpcoming && !bIsUpcoming) return -1;
    if (!aIsUpcoming && bIsUpcoming) return 1;
    
    return dateB - dateA;
  });

  // Get next upcoming session
  const nextSession = sortedReservations.find(r => 
    new Date(r.start_time) > new Date() && r.status === 'approved'
  );

  // Calculate days until next session
  const getDaysUntil = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diffTime = date.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    if (diffDays === 0) return 'Hoy';
    if (diffDays === 1) return 'Mañana';
    return `Faltan ${diffDays} días`;
  };

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8 space-y-8">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="font-orbitron font-bold text-3xl md:text-4xl gradient-text mb-2">
              Mis Reservas
            </h1>
            <p className="text-muted-foreground font-rajdhani">
              Gestiona tus entrenamientos y sesiones
            </p>
          </div>
          <div className="flex items-center gap-4">
            <EliteCard className="px-4 py-2 flex items-center gap-2">
              <Coins className="w-5 h-5 text-neon-cyan" />
              <span className="font-orbitron font-bold text-neon-cyan">{credits}</span>
              <span className="text-muted-foreground text-sm">créditos</span>
            </EliteCard>
            <Dialog open={reservationDialogOpen} onOpenChange={setReservationDialogOpen}>
              <DialogTrigger asChild>
                <NeonButton variant="gradient">
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
        </div>

        {/* Next Session Highlight */}
        {nextSession && (
          <EliteCard className="p-6 border-neon-cyan/50 bg-gradient-to-r from-neon-cyan/5 to-neon-purple/5">
            <div className="flex items-center gap-2 mb-4">
              <Calendar className="w-5 h-5 text-neon-cyan" />
              <h3 className="font-orbitron font-semibold text-lg">Próxima Sesión</h3>
              <StatusBadge variant="success">{getDaysUntil(nextSession.start_time)}</StatusBadge>
            </div>
            <div className="grid md:grid-cols-2 gap-4">
              <div>
                <h4 className="font-orbitron font-bold text-xl mb-2">{nextSession.title}</h4>
                {getPlayerName(nextSession.player_id) && (
                  <div className="flex items-center gap-2 text-muted-foreground mb-1">
                    <User className="w-4 h-4 text-neon-purple" />
                    <span>{getPlayerName(nextSession.player_id)}</span>
                  </div>
                )}
                <div className="flex items-center gap-2 text-muted-foreground">
                  <Calendar className="w-4 h-4 text-neon-cyan" />
                  <span>{format(new Date(nextSession.start_time), "EEEE dd 'de' MMMM", { locale: es })}</span>
                </div>
                <div className="flex items-center gap-2 text-muted-foreground">
                  <Clock className="w-4 h-4 text-neon-purple" />
                  <span>{format(new Date(nextSession.start_time), 'HH:mm')} - {format(new Date(nextSession.end_time), 'HH:mm')}</span>
                </div>
              </div>
            </div>
          </EliteCard>
        )}

        {/* Reservations List */}
        {sortedReservations.length === 0 ? (
          <EliteCard className="p-12 text-center">
            <Calendar className="w-16 h-16 text-neon-purple/30 mx-auto mb-4" />
            <h3 className="font-orbitron font-semibold text-lg mb-2">
              No tienes reservas
            </h3>
            <p className="text-muted-foreground mb-6">
              Crea una reserva para agendar entrenamientos y sesiones
            </p>
            <NeonButton variant="gradient" onClick={() => setReservationDialogOpen(true)}>
              <Plus className="w-4 h-4 mr-2" />
              Crear tu primera reserva
            </NeonButton>
          </EliteCard>
        ) : (
          <div className="space-y-4">
            <h3 className="font-orbitron font-semibold text-lg">Historial de Reservas</h3>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
              {sortedReservations.map((reservation) => (
                <EliteCard key={reservation.id} className="p-5">
                  <div className="flex items-start justify-between mb-3">
                    <h3 className="font-orbitron font-semibold truncate pr-2">
                      {reservation.title}
                    </h3>
                    <StatusBadge variant={getStatusVariant(reservation.status || 'pending')}>
                      {getStatusLabel(reservation.status || 'pending')}
                    </StatusBadge>
                  </div>

                  {/* Player Info */}
                  {getPlayerName(reservation.player_id) && (
                    <div className="flex items-center gap-2 text-sm text-neon-purple mb-2">
                      <Users className="w-4 h-4" />
                      <span className="font-medium">{getPlayerName(reservation.player_id)}</span>
                    </div>
                  )}

                  {reservation.description && (
                    <p className="text-sm text-muted-foreground mb-3 line-clamp-2">
                      {reservation.description}
                    </p>
                  )}

                  <div className="space-y-2 text-sm">
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Calendar className="w-4 h-4 text-neon-cyan" />
                      <span>
                        {format(new Date(reservation.start_time), "EEE, dd MMM yyyy", { locale: es })}
                      </span>
                    </div>
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Clock className="w-4 h-4 text-neon-purple" />
                      <span>
                        {format(new Date(reservation.start_time), 'HH:mm')} -{' '}
                        {format(new Date(reservation.end_time), 'HH:mm')}
                      </span>
                    </div>
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Coins className="w-4 h-4 text-neon-cyan" />
                      <span>{reservation.credit_cost} crédito{reservation.credit_cost !== 1 ? 's' : ''}</span>
                    </div>
                  </div>
                </EliteCard>
              ))}
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
};

export default Reservations;
