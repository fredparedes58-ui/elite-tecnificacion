import React from 'react';
import { useAllReservations } from '@/hooks/useReservations';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { useToast } from '@/hooks/use-toast';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table';
import { Check, X, Clock, Calendar } from 'lucide-react';

const ReservationManagement: React.FC = () => {
  const { reservations, loading, updateReservationStatus } = useAllReservations();
  const { toast } = useToast();

  const handleApprove = async (id: string) => {
    const success = await updateReservationStatus(id, 'approved', true);
    if (success) {
      toast({
        title: 'Reserva aprobada',
        description: 'Se descontará 1 crédito del usuario y se enviará un email de confirmación.',
      });
    } else {
      toast({
        title: 'Error',
        description: 'No se pudo aprobar la reserva. Verifica que el usuario tenga créditos suficientes.',
        variant: 'destructive',
      });
    }
  };

  const handleReject = async (id: string) => {
    const success = await updateReservationStatus(id, 'rejected', true);
    if (success) {
      toast({
        title: 'Reserva rechazada',
        description: 'La reserva ha sido rechazada y se enviará un email de notificación.',
      });
    }
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'default' => {
    switch (status) {
      case 'approved':
        return 'success';
      case 'pending':
        return 'warning';
      case 'rejected':
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
      case 'rejected':
        return 'Rechazada';
      default:
        return status;
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-12 h-12 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  const pendingCount = reservations.filter((r) => r.status === 'pending').length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="font-orbitron font-bold text-2xl gradient-text">
          Gestión de Reservas
        </h2>
        <div className="flex gap-3">
          <StatusBadge variant="warning">{pendingCount} pendientes</StatusBadge>
          <StatusBadge variant="info">{reservations.length} total</StatusBadge>
        </div>
      </div>

      <EliteCard className="overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="border-neon-cyan/20">
              <TableHead className="font-orbitron">Usuario</TableHead>
              <TableHead className="font-orbitron">Jugador</TableHead>
              <TableHead className="font-orbitron">Título</TableHead>
              <TableHead className="font-orbitron">Fecha/Hora</TableHead>
              <TableHead className="font-orbitron">Créditos</TableHead>
              <TableHead className="font-orbitron">Estado</TableHead>
              <TableHead className="font-orbitron text-right">Acciones</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {reservations.map((reservation) => (
              <TableRow key={reservation.id} className="border-neon-cyan/10">
                <TableCell>
                  <span className="font-rajdhani font-medium">
                    {reservation.user?.full_name || 'Usuario'}
                  </span>
                </TableCell>
                <TableCell className="text-muted-foreground">
                  {reservation.player?.name || '-'}
                </TableCell>
                <TableCell className="font-rajdhani">{reservation.title}</TableCell>
                <TableCell>
                  <div className="flex flex-col gap-1">
                    <div className="flex items-center gap-1 text-sm text-neon-cyan">
                      <Calendar className="w-3 h-3" />
                      {format(new Date(reservation.start_time), 'dd MMM yyyy', { locale: es })}
                    </div>
                    <div className="flex items-center gap-1 text-xs text-muted-foreground">
                      <Clock className="w-3 h-3" />
                      {format(new Date(reservation.start_time), 'HH:mm')} - {format(new Date(reservation.end_time), 'HH:mm')}
                    </div>
                  </div>
                </TableCell>
                <TableCell>
                  <span className="text-neon-purple font-rajdhani font-semibold">
                    {reservation.credit_cost}
                  </span>
                </TableCell>
                <TableCell>
                  <StatusBadge variant={getStatusVariant(reservation.status || 'pending')}>
                    {getStatusLabel(reservation.status || 'pending')}
                  </StatusBadge>
                </TableCell>
                <TableCell className="text-right">
                  {reservation.status === 'pending' && (
                    <div className="flex justify-end gap-2">
                      <NeonButton
                        variant="cyan"
                        size="sm"
                        onClick={() => handleApprove(reservation.id)}
                      >
                        <Check className="w-4 h-4" />
                      </NeonButton>
                      <NeonButton
                        variant="outline"
                        size="sm"
                        onClick={() => handleReject(reservation.id)}
                      >
                        <X className="w-4 h-4" />
                      </NeonButton>
                    </div>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </EliteCard>
    </div>
  );
};

export default ReservationManagement;
