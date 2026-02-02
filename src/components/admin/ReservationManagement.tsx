import React, { useState } from 'react';
import { Reservation, useAllReservations } from '@/hooks/useReservations';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Textarea } from '@/components/ui/textarea';
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
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Check, X, Clock, Calendar, Edit, MessageSquare, Send, User } from 'lucide-react';
import type { Database } from '@/integrations/supabase/types';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

type ReservationStatus = Database['public']['Enums']['reservation_status'];

interface ReservationManagementProps {
  reservations: Reservation[];
  loading: boolean;
  updateReservationStatus: (id: string, status: ReservationStatus, sendEmail?: boolean) => Promise<boolean>;
  refetch?: () => void;
}

const ReservationManagement: React.FC<ReservationManagementProps> = ({
  reservations,
  loading,
  updateReservationStatus,
  refetch
}) => {
  const { toast } = useToast();
  const { user } = useAuth();
  const [proposalModalOpen, setProposalModalOpen] = useState(false);
  const [selectedReservation, setSelectedReservation] = useState<Reservation | null>(null);
  const [proposalMessage, setProposalMessage] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleApprove = async (id: string) => {
    const success = await updateReservationStatus(id, 'approved', true);
    if (success) {
      toast({
        title: '✅ Reserva aprobada',
        description: 'Se descontará 1 crédito del usuario y se enviará notificación.',
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
        title: '❌ Reserva rechazada',
        description: 'La reserva ha sido rechazada y se enviará notificación.',
      });
    }
  };

  const handleOpenProposal = (reservation: Reservation) => {
    setSelectedReservation(reservation);
    setProposalMessage('');
    setProposalModalOpen(true);
  };

  const handleSendProposal = async () => {
    if (!selectedReservation || !proposalMessage.trim() || !user) return;
    
    setSubmitting(true);
    try {
      const { error } = await supabase
        .from('reservations')
        .update({
          status: 'parent_review' as ReservationStatus,
          proposal_message: proposalMessage.trim(),
          proposed_by: user.id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', selectedReservation.id);

      if (error) throw error;

      // Send notification to parent
      await supabase.from('notifications').insert({
        user_id: selectedReservation.user_id,
        type: 'reservation_proposal',
        title: '📩 Pedro te ha enviado una propuesta',
        message: `Revisa la propuesta para tu reserva "${selectedReservation.title}"`,
        metadata: { reservation_id: selectedReservation.id },
      });

      toast({
        title: '📨 Propuesta enviada',
        description: 'El padre recibirá una notificación.',
      });

      setProposalModalOpen(false);
      setSelectedReservation(null);
      setProposalMessage('');
      refetch?.();
    } catch (err) {
      console.error('Error sending proposal:', err);
      toast({
        title: 'Error',
        description: 'No se pudo enviar la propuesta.',
        variant: 'destructive',
      });
    }
    setSubmitting(false);
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
    switch (status) {
      case 'approved':
        return 'success';
      case 'pending':
        return 'warning';
      case 'rejected':
        return 'error';
      case 'parent_review':
      case 'counter_proposal':
        return 'info';
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
      case 'parent_review':
        return 'Esperando padre';
      case 'counter_proposal':
        return 'Contrapropuesta';
      case 'completed':
        return 'Completada';
      case 'no_show':
        return 'No asistió';
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
  const waitingParentCount = reservations.filter((r) => r.status === 'parent_review').length;

  // Sort: pending first, then parent_review, then approved, then others
  const sortedReservations = [...reservations].sort((a, b) => {
    const order: Record<string, number> = {
      pending: 0,
      parent_review: 1,
      counter_proposal: 2,
      approved: 3,
      rejected: 4,
      completed: 5,
      no_show: 6,
    };
    return (order[a.status || ''] ?? 7) - (order[b.status || ''] ?? 7);
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <h2 className="font-orbitron font-bold text-2xl gradient-text">
          Gestión de Reservas
        </h2>
        <div className="flex gap-3">
          {pendingCount > 0 && (
            <StatusBadge variant="warning">{pendingCount} pendientes</StatusBadge>
          )}
          {waitingParentCount > 0 && (
            <StatusBadge variant="info">{waitingParentCount} esperando respuesta</StatusBadge>
          )}
          <StatusBadge variant="default">{reservations.length} total</StatusBadge>
        </div>
      </div>

      <EliteCard className="overflow-hidden">
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow className="border-neon-cyan/20">
                <TableHead className="font-orbitron">Padre</TableHead>
                <TableHead className="font-orbitron">Jugador</TableHead>
                <TableHead className="font-orbitron">Título</TableHead>
                <TableHead className="font-orbitron">Fecha/Hora</TableHead>
                <TableHead className="font-orbitron">Mensaje</TableHead>
                <TableHead className="font-orbitron">Estado</TableHead>
                <TableHead className="font-orbitron text-right">Acciones</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sortedReservations.map((reservation) => {
                const resWithProposal = reservation as Reservation & {
                  proposal_message?: string | null;
                };
                return (
                  <TableRow key={reservation.id} className="border-neon-cyan/10">
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <User className="w-4 h-4 text-neon-purple" />
                        <span className="font-rajdhani font-medium">
                          {reservation.user?.full_name || reservation.user?.email || 'Usuario'}
                        </span>
                      </div>
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
                      {resWithProposal.proposal_message ? (
                        <div className="max-w-[200px]">
                          <p className="text-xs text-muted-foreground truncate">
                            {resWithProposal.proposal_message}
                          </p>
                        </div>
                      ) : (
                        <span className="text-muted-foreground text-xs">-</span>
                      )}
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
                            title="Aprobar"
                          >
                            <Check className="w-4 h-4" />
                          </NeonButton>
                          <NeonButton
                            variant="purple"
                            size="sm"
                            onClick={() => handleOpenProposal(reservation)}
                            title="Proponer cambios"
                          >
                            <Edit className="w-4 h-4" />
                          </NeonButton>
                          <NeonButton
                            variant="outline"
                            size="sm"
                            onClick={() => handleReject(reservation.id)}
                            title="Rechazar"
                          >
                            <X className="w-4 h-4" />
                          </NeonButton>
                        </div>
                      )}
                      {reservation.status === 'parent_review' && (
                        <StatusBadge variant="info">
                          <MessageSquare className="w-3 h-3 mr-1" />
                          Esperando...
                        </StatusBadge>
                      )}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>
      </EliteCard>

      {/* Proposal Modal */}
      <Dialog open={proposalModalOpen} onOpenChange={setProposalModalOpen}>
        <DialogContent className="bg-background border-neon-cyan/30">
          <DialogHeader>
            <DialogTitle className="font-orbitron gradient-text">
              Enviar Propuesta
            </DialogTitle>
          </DialogHeader>
          {selectedReservation && (
            <div className="space-y-4">
              <div className="p-3 rounded-lg bg-muted/30 border border-muted/50">
                <p className="text-sm font-semibold">{selectedReservation.title}</p>
                <p className="text-xs text-muted-foreground">
                  {selectedReservation.user?.full_name} • {format(new Date(selectedReservation.start_time), "dd MMM HH:mm", { locale: es })}
                </p>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-rajdhani font-medium">
                  Tu propuesta o mensaje al padre:
                </label>
                <Textarea
                  value={proposalMessage}
                  onChange={(e) => setProposalMessage(e.target.value)}
                  placeholder="Ej: Te propongo mover la sesión al jueves a las 18:00..."
                  className="bg-muted/50 border-neon-cyan/30 resize-none"
                  rows={4}
                />
              </div>

              <div className="flex gap-3">
                <NeonButton
                  variant="outline"
                  onClick={() => setProposalModalOpen(false)}
                  className="flex-1"
                >
                  Cancelar
                </NeonButton>
                <NeonButton
                  variant="gradient"
                  onClick={handleSendProposal}
                  disabled={!proposalMessage.trim() || submitting}
                  className="flex-1"
                >
                  {submitting ? 'Enviando...' : (
                    <>
                      <Send className="w-4 h-4 mr-2" />
                      Enviar al Padre
                    </>
                  )}
                </NeonButton>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default ReservationManagement;
