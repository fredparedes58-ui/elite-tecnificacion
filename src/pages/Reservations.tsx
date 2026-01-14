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
import { Calendar, Clock, Plus, Coins } from 'lucide-react';

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

        {/* Reservations List */}
        {reservations.length === 0 ? (
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
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {reservations.map((reservation) => (
              <EliteCard key={reservation.id} className="p-5">
                <div className="flex items-start justify-between mb-4">
                  <h3 className="font-orbitron font-semibold truncate pr-2">
                    {reservation.title}
                  </h3>
                  <StatusBadge variant={getStatusVariant(reservation.status || 'pending')}>
                    {getStatusLabel(reservation.status || 'pending')}
                  </StatusBadge>
                </div>

                {reservation.description && (
                  <p className="text-sm text-muted-foreground mb-4 line-clamp-2">
                    {reservation.description}
                  </p>
                )}

                <div className="space-y-2 text-sm">
                  <div className="flex items-center gap-2 text-muted-foreground">
                    <Calendar className="w-4 h-4 text-neon-cyan" />
                    <span>
                      {format(new Date(reservation.start_time), "EEEE, dd 'de' MMMM yyyy", { locale: es })}
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
        )}
      </div>
    </Layout>
  );
};

export default Reservations;
