import React from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Textarea } from '@/components/ui/textarea';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { Calendar, Clock, MessageSquare, User, Check, X, Edit } from 'lucide-react';
import { cn } from '@/lib/utils';
import type { Reservation } from '@/hooks/useReservations';

interface ReservationNegotiationCardProps {
  reservation: Reservation & {
    proposal_message?: string | null;
    proposed_start_time?: string | null;
    proposed_end_time?: string | null;
    proposed_by?: string | null;
  };
  currentUserId: string;
  isAdmin?: boolean;
  playerName?: string | null;
  onAccept?: () => void;
  onReject?: () => void;
  onCounterPropose?: (message: string, newStart?: Date, newEnd?: Date) => void;
  loading?: boolean;
}

const ReservationNegotiationCard: React.FC<ReservationNegotiationCardProps> = ({
  reservation,
  currentUserId,
  isAdmin,
  playerName,
  onAccept,
  onReject,
  onCounterPropose,
  loading,
}) => {
  const [showCounterForm, setShowCounterForm] = React.useState(false);
  const [counterMessage, setCounterMessage] = React.useState('');

  const isPendingMyAction = 
    (reservation.status === 'pending' && isAdmin) ||
    (reservation.status === 'parent_review' && !isAdmin && reservation.user_id === currentUserId);

  const isWaitingForOther = 
    (reservation.status === 'pending' && !isAdmin && reservation.user_id === currentUserId) ||
    (reservation.status === 'parent_review' && isAdmin);

  const getStatusInfo = () => {
    switch (reservation.status) {
      case 'pending':
        return {
          variant: 'warning' as const,
          label: isAdmin ? '⏳ Esperando tu decisión' : '⏳ Esperando respuesta de Pedro',
          color: 'text-amber-400',
        };
      case 'parent_review':
        return {
          variant: 'info' as const,
          label: isAdmin ? '📩 Esperando respuesta del padre' : '📩 Pedro te ha enviado una propuesta',
          color: 'text-neon-cyan',
        };
      case 'counter_proposal':
        return {
          variant: 'info' as const,
          label: '🔄 Contrapropuesta en revisión',
          color: 'text-neon-purple',
        };
      case 'approved':
        return {
          variant: 'success' as const,
          label: '✅ Confirmada',
          color: 'text-green-400',
        };
      case 'rejected':
        return {
          variant: 'error' as const,
          label: '❌ Rechazada',
          color: 'text-red-400',
        };
      default:
        return {
          variant: 'default' as const,
          label: reservation.status || 'Desconocido',
          color: 'text-muted-foreground',
        };
    }
  };

  const statusInfo = getStatusInfo();

  const handleCounterSubmit = () => {
    if (!counterMessage.trim()) return;
    onCounterPropose?.(counterMessage);
    setShowCounterForm(false);
    setCounterMessage('');
  };

  // Check if there's a proposal with different times
  const hasProposedTimes = reservation.proposed_start_time && reservation.proposed_end_time;
  const proposedByMe = reservation.proposed_by === currentUserId;

  return (
    <EliteCard className={cn(
      'p-5 transition-all',
      isPendingMyAction && 'border-neon-cyan/50 shadow-[0_0_20px_rgba(0,240,255,0.2)]',
    )}>
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div>
          <h3 className="font-orbitron font-semibold text-lg truncate pr-2">
            {reservation.title}
          </h3>
          {playerName && (
            <div className="flex items-center gap-2 text-sm text-neon-purple mt-1">
              <User className="w-4 h-4" />
              <span>{playerName}</span>
            </div>
          )}
        </div>
        <StatusBadge variant={statusInfo.variant}>
          {statusInfo.label}
        </StatusBadge>
      </div>

      {/* Original Request */}
      <div className="space-y-2 mb-4">
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Calendar className="w-4 h-4 text-neon-cyan" />
          <span>
            {format(new Date(reservation.start_time), "EEE, dd MMM yyyy", { locale: es })}
          </span>
        </div>
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Clock className="w-4 h-4 text-neon-purple" />
          <span>
            {format(new Date(reservation.start_time), 'HH:mm')} -{' '}
            {format(new Date(reservation.end_time), 'HH:mm')}
          </span>
        </div>
      </div>

      {/* Proposal Message */}
      {reservation.proposal_message && (
        <div className={cn(
          'p-3 rounded-lg mb-4 border',
          proposedByMe 
            ? 'bg-neon-purple/10 border-neon-purple/30'
            : 'bg-neon-cyan/10 border-neon-cyan/30'
        )}>
          <div className="flex items-center gap-2 mb-2 text-xs font-semibold">
            <MessageSquare className="w-3 h-3" />
            <span>{proposedByMe ? 'Tu mensaje' : isAdmin ? 'Mensaje del padre' : 'Mensaje de Pedro'}:</span>
          </div>
          <p className="text-sm font-rajdhani">{reservation.proposal_message}</p>
          
          {/* Show proposed times if different */}
          {hasProposedTimes && (
            <div className="mt-3 pt-3 border-t border-current/20">
              <p className="text-xs text-muted-foreground mb-1">Nuevo horario propuesto:</p>
              <div className="flex items-center gap-2 text-sm font-semibold">
                <Clock className="w-4 h-4" />
                <span>
                  {format(new Date(reservation.proposed_start_time!), "dd MMM 'a las' HH:mm", { locale: es })}
                </span>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Action Buttons */}
      {isPendingMyAction && (
        <div className="space-y-3">
          {showCounterForm ? (
            <div className="space-y-3">
              <Textarea
                value={counterMessage}
                onChange={(e) => setCounterMessage(e.target.value)}
                placeholder={isAdmin ? 'Escribe tu propuesta alternativa...' : 'Escribe tu respuesta...'}
                className="bg-muted/50 border-neon-cyan/30 resize-none"
                rows={3}
              />
              <div className="flex gap-2">
                <NeonButton
                  variant="outline"
                  size="sm"
                  onClick={() => setShowCounterForm(false)}
                  className="flex-1"
                >
                  Cancelar
                </NeonButton>
                <NeonButton
                  variant="gradient"
                  size="sm"
                  onClick={handleCounterSubmit}
                  disabled={!counterMessage.trim() || loading}
                  className="flex-1"
                >
                  Enviar
                </NeonButton>
              </div>
            </div>
          ) : (
            <div className="flex gap-2">
              <NeonButton
                variant="outline"
                size="sm"
                onClick={onReject}
                disabled={loading}
                className="flex-1 border-destructive/50 text-destructive hover:bg-destructive/10"
              >
                <X className="w-4 h-4 mr-1" />
                Rechazar
              </NeonButton>
              <NeonButton
                variant="outline"
                size="sm"
                onClick={() => setShowCounterForm(true)}
                disabled={loading}
                className="flex-1"
              >
                <Edit className="w-4 h-4 mr-1" />
                {isAdmin ? 'Proponer' : 'Negociar'}
              </NeonButton>
              <NeonButton
                variant="gradient"
                size="sm"
                onClick={onAccept}
                disabled={loading}
                className="flex-1"
              >
                <Check className="w-4 h-4 mr-1" />
                Aceptar
              </NeonButton>
            </div>
          )}
        </div>
      )}

      {/* Waiting State */}
      {isWaitingForOther && (
        <div className="p-3 rounded-lg bg-muted/30 border border-muted/50 text-center">
          <p className="text-sm text-muted-foreground">
            {isAdmin 
              ? 'Esperando respuesta del padre...'
              : 'Tu solicitud está siendo revisada por Pedro...'}
          </p>
        </div>
      )}
    </EliteCard>
  );
};

export default ReservationNegotiationCard;
