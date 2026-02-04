import React, { useState } from 'react';
import { format, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Slider } from '@/components/ui/slider';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { NeonButton } from '@/components/ui/NeonButton';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';
import { useQueryClient } from '@tanstack/react-query';
import { 
  CheckCircle, 
  XCircle, 
  MessageSquare, 
  TrendingUp,
  Zap,
  Target,
  Heart,
  Brain,
  Shield
} from 'lucide-react';

interface CompleteSessionModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  reservation: {
    id: string;
    title: string;
    player_id: string | null;
    player_name?: string;
    start_time: string;
    current_stats?: {
      speed: number;
      technique: number;
      physical: number;
      mental: number;
      tactical: number;
    };
  } | null;
  onComplete?: () => void;
}

const STAT_CONFIG = [
  { key: 'speed', label: 'Velocidad', icon: Zap, color: 'text-cyan-400' },
  { key: 'technique', label: 'Técnica', icon: Target, color: 'text-purple-400' },
  { key: 'physical', label: 'Físico', icon: Heart, color: 'text-green-400' },
  { key: 'mental', label: 'Mental', icon: Brain, color: 'text-amber-400' },
  { key: 'tactical', label: 'Táctico', icon: Shield, color: 'text-pink-400' },
];

const CompleteSessionModal: React.FC<CompleteSessionModalProps> = ({
  open,
  onOpenChange,
  reservation,
  onComplete,
}) => {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [status, setStatus] = useState<'completed' | 'no_show'>('completed');
  const [trainerComments, setTrainerComments] = useState('');
  const [updateStats, setUpdateStats] = useState(false);
  const [stats, setStats] = useState({
    speed: reservation?.current_stats?.speed || 50,
    technique: reservation?.current_stats?.technique || 50,
    physical: reservation?.current_stats?.physical || 50,
    mental: reservation?.current_stats?.mental || 50,
    tactical: reservation?.current_stats?.tactical || 50,
  });
  const [submitting, setSubmitting] = useState(false);

  // Reset form when modal opens with new reservation
  React.useEffect(() => {
    if (reservation && open) {
      setStatus('completed');
      setTrainerComments('');
      setUpdateStats(false);
      setStats({
        speed: reservation.current_stats?.speed || 50,
        technique: reservation.current_stats?.technique || 50,
        physical: reservation.current_stats?.physical || 50,
        mental: reservation.current_stats?.mental || 50,
        tactical: reservation.current_stats?.tactical || 50,
      });
    }
  }, [reservation, open]);

  const handleSubmit = async () => {
    if (!reservation || !user) return;

    setSubmitting(true);
    try {
      // Update reservation status and comments
      const { error: reservationError } = await supabase
        .from('reservations')
        .update({
          status,
          trainer_comments: trainerComments.trim() || null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', reservation.id);

      if (reservationError) throw reservationError;

      // If updating stats and we have a player
      if (updateStats && reservation.player_id) {
        // Update player's current stats
        const { error: playerError } = await supabase
          .from('players')
          .update({
            stats,
            updated_at: new Date().toISOString(),
          })
          .eq('id', reservation.player_id);

        if (playerError) throw playerError;

        // Record stats in history
        const { error: historyError } = await supabase
          .from('player_stats_history')
          .insert({
            player_id: reservation.player_id,
            reservation_id: reservation.id,
            recorded_by: user.id,
            stats,
            notes: trainerComments.trim() || null,
            recorded_at: new Date().toISOString(),
          });

        if (historyError) {
          console.error('Error recording stats history:', historyError);
          // Don't throw - this is not critical
        }
      }

      toast({
        title: status === 'completed' ? '✅ Sesión completada' : '❌ Ausencia registrada',
        description: status === 'no_show' 
          ? 'Se ha descontado el crédito por no asistir.'
          : 'La sesión ha sido marcada como completada.',
      });

      // Invalidate queries
      queryClient.invalidateQueries({ queryKey: ['reservations'] });
      queryClient.invalidateQueries({ queryKey: ['player-session-history'] });
      queryClient.invalidateQueries({ queryKey: ['player-stats-history'] });
      queryClient.invalidateQueries({ queryKey: ['players'] });

      onComplete?.();
      onOpenChange(false);
    } catch (error) {
      console.error('Error completing session:', error);
      toast({
        title: 'Error',
        description: 'No se pudo completar la sesión.',
        variant: 'destructive',
      });
    } finally {
      setSubmitting(false);
    }
  };

  if (!reservation) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="bg-background border-neon-cyan/30 max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="font-orbitron gradient-text">
            Finalizar Sesión
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6">
          {/* Session Info */}
          <div className="p-3 rounded-lg bg-muted/30 border border-muted/50">
            <p className="font-semibold">{reservation.title}</p>
            <p className="text-sm text-muted-foreground">
              {reservation.player_name && `${reservation.player_name} • `}
              {format(parseISO(reservation.start_time), "EEEE dd MMM, HH:mm", { locale: es })}
            </p>
          </div>

          {/* Status Selection */}
          <div className="space-y-3">
            <Label className="font-rajdhani font-medium">Estado de la sesión</Label>
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setStatus('completed')}
                className={`p-4 rounded-lg border-2 transition-all flex flex-col items-center gap-2 ${
                  status === 'completed'
                    ? 'border-green-500 bg-green-500/10'
                    : 'border-muted/50 hover:border-green-500/50'
                }`}
              >
                <CheckCircle className={`w-8 h-8 ${
                  status === 'completed' ? 'text-green-400' : 'text-muted-foreground'
                }`} />
                <span className={`font-rajdhani font-medium ${
                  status === 'completed' ? 'text-green-400' : 'text-muted-foreground'
                }`}>
                  Completada
                </span>
              </button>
              <button
                type="button"
                onClick={() => setStatus('no_show')}
                className={`p-4 rounded-lg border-2 transition-all flex flex-col items-center gap-2 ${
                  status === 'no_show'
                    ? 'border-red-500 bg-red-500/10'
                    : 'border-muted/50 hover:border-red-500/50'
                }`}
              >
                <XCircle className={`w-8 h-8 ${
                  status === 'no_show' ? 'text-red-400' : 'text-muted-foreground'
                }`} />
                <span className={`font-rajdhani font-medium ${
                  status === 'no_show' ? 'text-red-400' : 'text-muted-foreground'
                }`}>
                  No Asistió
                </span>
              </button>
            </div>
          </div>

          {/* Trainer Comments */}
          <div className="space-y-2">
            <Label className="font-rajdhani font-medium flex items-center gap-2">
              <MessageSquare className="w-4 h-4 text-neon-purple" />
              Comentarios del Entrenador
            </Label>
            <Textarea
              value={trainerComments}
              onChange={(e) => setTrainerComments(e.target.value)}
              placeholder="Observaciones sobre el rendimiento, progreso, áreas de mejora..."
              className="bg-muted/50 border-neon-cyan/30 resize-none"
              rows={3}
            />
          </div>

          {/* Update Stats Toggle */}
          {reservation.player_id && status === 'completed' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label className="font-rajdhani font-medium flex items-center gap-2">
                  <TrendingUp className="w-4 h-4 text-neon-cyan" />
                  Actualizar estadísticas del jugador
                </Label>
                <Switch
                  checked={updateStats}
                  onCheckedChange={setUpdateStats}
                />
              </div>

              {updateStats && (
                <div className="space-y-4 p-4 rounded-lg bg-muted/20 border border-muted/30">
                  {STAT_CONFIG.map(({ key, label, icon: Icon, color }) => (
                    <div key={key} className="space-y-2">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <Icon className={`w-4 h-4 ${color}`} />
                          <span className="text-sm font-rajdhani">{label}</span>
                        </div>
                        <span className="font-orbitron font-bold text-neon-cyan">
                          {stats[key as keyof typeof stats]}
                        </span>
                      </div>
                      <Slider
                        value={[stats[key as keyof typeof stats]]}
                        onValueChange={([value]) => setStats(prev => ({ ...prev, [key]: value }))}
                        min={0}
                        max={100}
                        step={1}
                        className="w-full"
                      />
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Actions */}
          <div className="flex gap-3 pt-2">
            <NeonButton
              variant="outline"
              onClick={() => onOpenChange(false)}
              className="flex-1"
            >
              Cancelar
            </NeonButton>
            <NeonButton
              variant={status === 'completed' ? 'cyan' : 'purple'}
              onClick={handleSubmit}
              disabled={submitting}
              className="flex-1"
            >
              {submitting ? 'Guardando...' : (
                status === 'completed' ? 'Marcar Completada' : 'Registrar Ausencia'
              )}
            </NeonButton>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default CompleteSessionModal;
