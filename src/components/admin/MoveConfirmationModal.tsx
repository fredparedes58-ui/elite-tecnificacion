import React from 'react';
import { format, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  AlertTriangle, 
  ArrowRight, 
  Calendar, 
  Clock, 
  User,
  CheckCircle,
  XCircle
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';

interface MoveConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  isLoading?: boolean;
  moveDetails: {
    playerName: string;
    oldDate: Date;
    oldHour: number;
    newDate: Date;
    newHour: number;
    trainerName?: string;
    conflictWarning?: string;
  } | null;
}

export const MoveConfirmationModal: React.FC<MoveConfirmationModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  isLoading = false,
  moveDetails,
}) => {
  if (!moveDetails) return null;

  const formatTimeSlot = (date: Date, hour: number) => {
    const formatted = format(date, "EEEE d 'de' MMMM", { locale: es });
    return {
      date: formatted.charAt(0).toUpperCase() + formatted.slice(1),
      time: `${hour.toString().padStart(2, '0')}:00 - ${(hour + 1).toString().padStart(2, '0')}:00`,
    };
  };

  const oldSlot = formatTimeSlot(moveDetails.oldDate, moveDetails.oldHour);
  const newSlot = formatTimeSlot(moveDetails.newDate, moveDetails.newHour);
  const hasConflict = !!moveDetails.conflictWarning;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-lg bg-background border-border">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 font-orbitron">
            {hasConflict ? (
              <>
                <AlertTriangle className="w-5 h-5 text-red-400" />
                <span className="text-red-400">Conflicto Detectado</span>
              </>
            ) : (
              <>
                <Calendar className="w-5 h-5 text-neon-cyan" />
                <span>Confirmar Movimiento</span>
              </>
            )}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Player info */}
          <div className="flex items-center gap-2 p-3 rounded-lg bg-neon-cyan/10 border border-neon-cyan/30">
            <User className="w-5 h-5 text-neon-cyan" />
            <span className="font-medium">{moveDetails.playerName}</span>
            {moveDetails.trainerName && (
              <Badge variant="outline" className="ml-auto text-xs">
                con {moveDetails.trainerName}
              </Badge>
            )}
          </div>

          {/* Time change visualization */}
          <div className="grid grid-cols-[1fr,auto,1fr] gap-4 items-center">
            {/* Old slot */}
            <div className="p-4 rounded-lg border border-red-500/30 bg-red-500/5">
              <div className="flex items-center gap-2 mb-2">
                <Calendar className="w-4 h-4 text-red-400" />
                <span className="text-xs text-red-400 font-medium">ANTES</span>
              </div>
              <p className="text-sm font-medium">{oldSlot.date}</p>
              <div className="flex items-center gap-1 mt-1 text-muted-foreground">
                <Clock className="w-3 h-3" />
                <span className="text-sm">{oldSlot.time}</span>
              </div>
            </div>

            {/* Arrow */}
            <div className="flex items-center justify-center">
              <div className="p-2 rounded-full bg-muted">
                <ArrowRight className="w-5 h-5 text-neon-cyan" />
              </div>
            </div>

            {/* New slot */}
            <div className="p-4 rounded-lg border border-green-500/30 bg-green-500/5">
              <div className="flex items-center gap-2 mb-2">
                <Calendar className="w-4 h-4 text-green-400" />
                <span className="text-xs text-green-400 font-medium">DESPUÉS</span>
              </div>
              <p className="text-sm font-medium">{newSlot.date}</p>
              <div className="flex items-center gap-1 mt-1 text-muted-foreground">
                <Clock className="w-3 h-3" />
                <span className="text-sm">{newSlot.time}</span>
              </div>
            </div>
          </div>

          {/* Conflict warning */}
          {hasConflict && (
            <div className="p-4 rounded-lg border border-red-500/50 bg-red-500/10">
              <div className="flex items-start gap-3">
                <AlertTriangle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm font-medium text-red-400 mb-1">
                    ¡Conflicto de horario!
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {moveDetails.conflictWarning}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Info about notifications */}
          {!hasConflict && (
            <div className="p-3 rounded-lg bg-muted/30 border border-border">
              <p className="text-xs text-muted-foreground">
                📧 Se enviará una notificación automática al padre del jugador 
                informando sobre el cambio de horario.
              </p>
            </div>
          )}
        </div>

        <DialogFooter className="gap-2">
          <Button
            variant="outline"
            onClick={onClose}
            disabled={isLoading}
            className="border-border"
          >
            <XCircle className="w-4 h-4 mr-2" />
            Cancelar
          </Button>
          
          {!hasConflict && (
            <Button
              onClick={onConfirm}
              disabled={isLoading}
              className="bg-neon-cyan text-background hover:bg-neon-cyan/80"
            >
              {isLoading ? (
                <div className="w-4 h-4 border-2 border-background/30 border-t-background rounded-full animate-spin mr-2" />
              ) : (
                <CheckCircle className="w-4 h-4 mr-2" />
              )}
              Confirmar Movimiento
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
