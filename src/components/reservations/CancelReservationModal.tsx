import React from 'react';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { format, differenceInHours } from 'date-fns';
import { es } from 'date-fns/locale';
import { AlertTriangle, Calendar, Clock, Coins, Loader2 } from 'lucide-react';

interface CancelReservationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  loading: boolean;
  reservation: {
    title: string;
    start_time: string;
    end_time: string;
    credit_cost: number;
    status: string | null;
  } | null;
}

const CancelReservationModal: React.FC<CancelReservationModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  loading,
  reservation,
}) => {
  if (!reservation) return null;

  const hoursUntilSession = differenceInHours(new Date(reservation.start_time), new Date());
  const isLessThan24Hours = hoursUntilSession < 24 && hoursUntilSession > 0;
  const isApproved = reservation.status === 'approved';
  const isPast = hoursUntilSession <= 0;

  return (
    <AlertDialog open={isOpen} onOpenChange={onClose}>
      <AlertDialogContent className="bg-background border-neon-cyan/30">
        <AlertDialogHeader>
          <AlertDialogTitle className="font-orbitron flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 text-destructive" />
            Cancelar Reserva
          </AlertDialogTitle>
          <AlertDialogDescription asChild>
            <div className="space-y-4 text-muted-foreground">
              <p>¿Estás seguro de que deseas cancelar esta reserva?</p>
              
              <div className="p-4 rounded-lg bg-muted/50 space-y-2">
                <p className="font-semibold text-foreground">{reservation.title}</p>
                <div className="flex items-center gap-2 text-sm">
                  <Calendar className="w-4 h-4 text-neon-cyan" />
                  <span>
                    {format(new Date(reservation.start_time), "EEEE dd 'de' MMMM", { locale: es })}
                  </span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Clock className="w-4 h-4 text-neon-purple" />
                  <span>
                    {format(new Date(reservation.start_time), 'HH:mm')} - {format(new Date(reservation.end_time), 'HH:mm')}
                  </span>
                </div>
              </div>

              {isApproved && (
                <div className="p-3 rounded-lg bg-green-500/10 border border-green-500/30 flex items-center gap-2">
                  <Coins className="w-4 h-4 text-green-400" />
                  <span className="text-green-400 text-sm">
                    Se te reembolsarán <strong>{reservation.credit_cost} crédito{reservation.credit_cost !== 1 ? 's' : ''}</strong>
                  </span>
                </div>
              )}

              {isLessThan24Hours && (
                <div className="p-3 rounded-lg bg-amber-500/10 border border-amber-500/30">
                  <p className="text-amber-400 text-sm font-medium">
                    No se puede cancelar ni editar cuando la sesión empieza en menos de 24 horas.
                  </p>
                </div>
              )}

              {isPast && (
                <div className="p-3 rounded-lg bg-red-500/10 border border-red-500/30">
                  <p className="text-red-400 text-sm">
                    ❌ Esta sesión ya ha pasado y no puede ser cancelada.
                  </p>
                </div>
              )}
            </div>
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel 
            className="border-muted-foreground/30 hover:bg-muted"
            disabled={loading}
          >
            Volver
          </AlertDialogCancel>
          <AlertDialogAction
            onClick={(e) => {
              e.preventDefault();
              onConfirm();
            }}
            disabled={loading || isPast || isLessThan24Hours}
            className="bg-destructive text-destructive-foreground hover:bg-destructive/90 disabled:opacity-50"
          >
            {loading ? (
              <Loader2 className="w-4 h-4 animate-spin mr-2" />
            ) : null}
            Sí, Cancelar Reserva
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
};

export default CancelReservationModal;
