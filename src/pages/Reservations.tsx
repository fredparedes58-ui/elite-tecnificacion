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
import NewReservationWithCalendar from '@/components/reservations/NewReservationWithCalendar';
import ReservationNegotiationCard from '@/components/reservations/ReservationNegotiationCard';
import CancelReservationModal from '@/components/reservations/CancelReservationModal';
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
import { Calendar, Clock, Plus, Coins, User, Users, X, MessageSquare } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';

const Reservations: React.FC = () => {
  const { user, isApproved, isAdmin, isLoading } = useAuth();
  const { credits } = useCredits();
  const { players } = useMyPlayers();
  const { reservations, createReservation, cancelReservation, refetch } = useReservations();
  const { toast } = useToast();
  
  const [reservationDialogOpen, setReservationDialogOpen] = React.useState(false);
  const [submitting, setSubmitting] = React.useState(false);
  const [cancelModalOpen, setCancelModalOpen] = React.useState(false);
  const [reservationToCancel, setReservationToCancel] = React.useState<typeof reservations[0] | null>(null);
  const [cancelling, setCancelling] = React.useState(false);

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

  const handleCreateReservation = async (data: {
    title: string;
    description?: string;
    start_time: string;
    end_time: string;
    player_id?: string;
    trainer_id?: string;
  }) => {
    setSubmitting(true);
    const result = await createReservation(data);
    setSubmitting(false);
    if (result) {
      toast({
        title: '📩 Solicitud enviada',
        description: 'Pedro recibirá tu solicitud y te responderá pronto.',
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

  const handleAcceptProposal = async (reservationId: string) => {
    setSubmitting(true);
    try {
      const { error } = await supabase
        .from('reservations')
        .update({ 
          status: 'approved',
          proposal_message: null,
          proposed_start_time: null,
          proposed_end_time: null,
          proposed_by: null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', reservationId)
        .eq('user_id', user.id);

      if (error) throw error;

      toast({
        title: '✅ Reserva confirmada',
        description: 'Tu sesión ha sido programada.',
      });
      refetch();
    } catch (err) {
      console.error('Error accepting proposal:', err);
      toast({
        title: 'Error',
        description: 'No se pudo aceptar la propuesta.',
        variant: 'destructive',
      });
    }
    setSubmitting(false);
  };

  const handleRejectProposal = async (reservationId: string) => {
    setSubmitting(true);
    try {
      const { error } = await supabase
        .from('reservations')
        .update({ 
          status: 'rejected',
          updated_at: new Date().toISOString(),
        })
        .eq('id', reservationId)
        .eq('user_id', user.id);

      if (error) throw error;

      toast({
        title: '❌ Propuesta rechazada',
        description: 'La reserva ha sido cancelada.',
      });
      refetch();
    } catch (err) {
      console.error('Error rejecting proposal:', err);
      toast({
        title: 'Error',
        description: 'No se pudo rechazar la propuesta.',
        variant: 'destructive',
      });
    }
    setSubmitting(false);
  };

  const handleCounterPropose = async (reservationId: string, message: string) => {
    setSubmitting(true);
    try {
      const { error } = await supabase
        .from('reservations')
        .update({ 
          status: 'pending',
          proposal_message: message,
          proposed_by: user.id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', reservationId)
        .eq('user_id', user.id);

      if (error) throw error;

      toast({
        title: '📨 Mensaje enviado',
        description: 'Pedro recibirá tu respuesta.',
      });
      refetch();
    } catch (err) {
      console.error('Error sending counter proposal:', err);
      toast({
        title: 'Error',
        description: 'No se pudo enviar el mensaje.',
        variant: 'destructive',
      });
    }
    setSubmitting(false);
  };

  const handleCancelClick = (reservation: typeof reservations[0]) => {
    setReservationToCancel(reservation);
    setCancelModalOpen(true);
  };

  const handleConfirmCancel = async () => {
    if (!reservationToCancel) return;
    
    setCancelling(true);
    const result = await cancelReservation(reservationToCancel.id);
    setCancelling(false);
    
    if (result) {
      toast({
        title: '✅ Reserva cancelada',
        description: reservationToCancel.status === 'approved' 
          ? 'Se te han reembolsado los créditos'
          : 'La reserva ha sido cancelada',
      });
      setCancelModalOpen(false);
      setReservationToCancel(null);
    } else {
      toast({
        title: 'Error',
        description: 'No se pudo cancelar la reserva',
        variant: 'destructive',
      });
    }
  };

  const getPlayerName = (playerId: string | null) => {
    if (!playerId) return null;
    const player = players.find(p => p.id === playerId);
    return player?.name || null;
  };

  // Separate reservations by type
  const pendingNegotiations = reservations.filter(r => 
    r.status === 'pending' || r.status === 'parent_review' || r.status === 'counter_proposal'
  );
  
  const confirmedReservations = reservations.filter(r => 
    r.status === 'approved' && new Date(r.start_time) > new Date()
  );

  const pastReservations = reservations.filter(r => 
    r.status === 'approved' && new Date(r.start_time) <= new Date() ||
    r.status === 'completed' || r.status === 'rejected' || r.status === 'no_show'
  );

  // Get next upcoming session
  const nextSession = confirmedReservations.length > 0 
    ? confirmedReservations.sort((a, b) => 
        new Date(a.start_time).getTime() - new Date(b.start_time).getTime()
      )[0]
    : null;

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
              Gestiona tus entrenamientos con Pedro
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
              <DialogContent className="bg-background border-neon-cyan/30 max-w-2xl max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                  <DialogTitle className="font-orbitron gradient-text">
                    Nueva Reserva
                  </DialogTitle>
                </DialogHeader>
                <NewReservationWithCalendar
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

        {/* Pending Negotiations */}
        {pendingNegotiations.length > 0 && (
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-neon-cyan" />
              <h3 className="font-orbitron font-semibold text-lg">En Negociación</h3>
              <StatusBadge variant="warning">{pendingNegotiations.length}</StatusBadge>
            </div>
            <div className="grid md:grid-cols-2 gap-4">
              {pendingNegotiations.map((reservation) => (
                <ReservationNegotiationCard
                  key={reservation.id}
                  reservation={reservation as any}
                  currentUserId={user.id}
                  isAdmin={false}
                  playerName={getPlayerName(reservation.player_id)}
                  onAccept={() => handleAcceptProposal(reservation.id)}
                  onReject={() => handleRejectProposal(reservation.id)}
                  onCounterPropose={(msg) => handleCounterPropose(reservation.id, msg)}
                  loading={submitting}
                />
              ))}
            </div>
          </div>
        )}

        {/* Confirmed Reservations */}
        {confirmedReservations.length > 0 && (
          <div className="space-y-4">
            <h3 className="font-orbitron font-semibold text-lg">Sesiones Confirmadas</h3>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
              {confirmedReservations.map((reservation) => (
                <EliteCard key={reservation.id} className="p-5">
                  <div className="flex items-start justify-between mb-3">
                    <h3 className="font-orbitron font-semibold truncate pr-2">
                      {reservation.title}
                    </h3>
                    <StatusBadge variant="success">✅ Confirmada</StatusBadge>
                  </div>

                  {getPlayerName(reservation.player_id) && (
                    <div className="flex items-center gap-2 text-sm text-neon-purple mb-2">
                      <Users className="w-4 h-4" />
                      <span className="font-medium">{getPlayerName(reservation.player_id)}</span>
                    </div>
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
                  </div>

                  <NeonButton
                    variant="outline"
                    size="sm"
                    onClick={() => handleCancelClick(reservation)}
                    className="w-full mt-4 border-destructive/50 text-destructive hover:bg-destructive/10"
                  >
                    <X className="w-4 h-4 mr-2" />
                    Cancelar
                  </NeonButton>
                </EliteCard>
              ))}
            </div>
          </div>
        )}

        {/* Empty State */}
        {reservations.length === 0 && (
          <EliteCard className="p-12 text-center">
            <Calendar className="w-16 h-16 text-neon-purple/30 mx-auto mb-4" />
            <h3 className="font-orbitron font-semibold text-lg mb-2">
              No tienes reservas
            </h3>
            <p className="text-muted-foreground mb-6">
              Selecciona un horario disponible para solicitar una sesión con Pedro
            </p>
            <NeonButton variant="gradient" onClick={() => setReservationDialogOpen(true)}>
              <Plus className="w-4 h-4 mr-2" />
              Crear tu primera reserva
            </NeonButton>
          </EliteCard>
        )}

        {/* Past Reservations */}
        {pastReservations.length > 0 && (
          <div className="space-y-4">
            <h3 className="font-orbitron font-semibold text-lg text-muted-foreground">Historial</h3>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4 opacity-70">
              {pastReservations.slice(0, 6).map((reservation) => (
                <EliteCard key={reservation.id} className="p-4">
                  <div className="flex items-start justify-between mb-2">
                    <h4 className="font-semibold truncate pr-2 text-sm">{reservation.title}</h4>
                    <StatusBadge 
                      variant={reservation.status === 'completed' ? 'success' : 
                               reservation.status === 'rejected' ? 'error' : 'warning'}
                    >
                      {reservation.status === 'completed' ? '✔️' :
                       reservation.status === 'rejected' ? '❌' : 
                       reservation.status === 'no_show' ? '⚠️' : reservation.status}
                    </StatusBadge>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    {format(new Date(reservation.start_time), "dd MMM yyyy - HH:mm", { locale: es })}
                  </p>
                </EliteCard>
              ))}
            </div>
          </div>
        )}

        {/* Cancel Modal */}
        <CancelReservationModal
          isOpen={cancelModalOpen}
          onClose={() => {
            setCancelModalOpen(false);
            setReservationToCancel(null);
          }}
          onConfirm={handleConfirmCancel}
          loading={cancelling}
          reservation={reservationToCancel}
        />
      </div>
    </Layout>
  );
};

export default Reservations;
