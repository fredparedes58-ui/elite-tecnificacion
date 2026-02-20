import React, { useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel,
  AlertDialogContent, AlertDialogDescription, AlertDialogFooter,
  AlertDialogHeader, AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { toast } from 'sonner';
import { Check, X, User, Search, Clock, Shield } from 'lucide-react';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { usePendingPlayers } from '@/hooks/usePendingPlayers';

const PendingPlayersPanel: React.FC = () => {
  const { players, loading, refetch } = usePendingPlayers();
  const [searchQuery, setSearchQuery] = useState('');
  const [rejectTarget, setRejectTarget] = useState<{ id: string; name: string } | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [processing, setProcessing] = useState<string | null>(null);

  const filteredPlayers = players.filter((p) => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    return (
      p.name.toLowerCase().includes(q) ||
      p.parent_name?.toLowerCase().includes(q) ||
      p.category.toLowerCase().includes(q)
    );
  });

  const handleApprove = async (playerId: string, playerName: string) => {
    setProcessing(playerId);
    try {
      const { error } = await supabase
        .from('players')
        .update({ approval_status: 'approved' } as any)
        .eq('id', playerId);

      if (error) throw error;
      toast.success(`${playerName} aprobado correctamente`);
      refetch();
    } catch (err) {
      console.error(err);
      toast.error('Error al aprobar jugador');
    } finally {
      setProcessing(null);
    }
  };

  const handleReject = async () => {
    if (!rejectTarget) return;
    setProcessing(rejectTarget.id);
    try {
      const { error } = await supabase
        .from('players')
        .update({
          approval_status: 'rejected',
          rejection_reason: rejectionReason.trim() || null,
        } as any)
        .eq('id', rejectTarget.id);

      if (error) throw error;
      toast.success(`${rejectTarget.name} rechazado`);
      setRejectTarget(null);
      setRejectionReason('');
      refetch();
    } catch (err) {
      console.error(err);
      toast.error('Error al rechazar jugador');
    } finally {
      setProcessing(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-12 h-12 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Shield className="w-6 h-6 text-neon-cyan" />
          <h2 className="font-orbitron font-bold text-2xl gradient-text">
            Aprobación de Jugadores
          </h2>
        </div>
        <StatusBadge variant={players.length > 0 ? 'warning' : 'success'}>
          {players.length} pendientes
        </StatusBadge>
      </div>

      {players.length > 0 && (
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Buscar jugador o padre..."
            className="pl-9 bg-muted/50 border-neon-cyan/30"
          />
        </div>
      )}

      {filteredPlayers.length === 0 ? (
        <EliteCard className="p-8 text-center">
          <Check className="w-12 h-12 text-green-500/30 mx-auto mb-4" />
          <p className="text-muted-foreground font-rajdhani">
            {searchQuery ? 'No se encontraron jugadores' : 'No hay jugadores pendientes de aprobación'}
          </p>
        </EliteCard>
      ) : (
        <ScrollArea className="max-h-[600px]">
          <div className="space-y-3">
            {filteredPlayers.map((player) => (
              <EliteCard key={player.id} className="p-4">
                <div className="flex flex-col sm:flex-row sm:items-center gap-4">
                  {/* Player info */}
                  <div className="flex items-center gap-3 flex-1 min-w-0">
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center flex-shrink-0">
                      {player.photo_url ? (
                        <img src={player.photo_url} alt={player.name} className="w-full h-full object-cover rounded-xl" />
                      ) : (
                        <User className="w-6 h-6 text-neon-cyan" />
                      )}
                    </div>
                    <div className="min-w-0">
                      <h4 className="font-orbitron font-semibold truncate">{player.name}</h4>
                      <div className="flex items-center gap-2 text-xs text-muted-foreground">
                        <span>{player.category}</span>
                        <span>•</span>
                        <span>{player.position || 'Sin posición'}</span>
                        {player.current_club && (
                          <>
                            <span>•</span>
                            <span>{player.current_club}</span>
                          </>
                        )}
                      </div>
                      <div className="flex items-center gap-1 text-xs text-muted-foreground mt-0.5">
                        <Clock className="w-3 h-3" />
                        <span>
                          Registrado {format(new Date(player.created_at), "dd MMM yyyy 'a las' HH:mm", { locale: es })}
                        </span>
                      </div>
                      {player.parent_name && (
                        <p className="text-xs text-neon-cyan/70 mt-0.5">
                          Padre: {player.parent_name}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex gap-2 flex-shrink-0">
                    <NeonButton
                      variant="gradient"
                      size="sm"
                      onClick={() => handleApprove(player.id, player.name)}
                      disabled={processing === player.id}
                    >
                      <Check className="w-4 h-4 mr-1" />
                      Aprobar
                    </NeonButton>
                    <NeonButton
                      variant="outline"
                      size="sm"
                      onClick={() => setRejectTarget({ id: player.id, name: player.name })}
                      disabled={processing === player.id}
                      className="border-destructive/50 text-destructive hover:bg-destructive/10"
                    >
                      <X className="w-4 h-4 mr-1" />
                      Rechazar
                    </NeonButton>
                  </div>
                </div>
              </EliteCard>
            ))}
          </div>
        </ScrollArea>
      )}

      {/* Reject Dialog */}
      <AlertDialog open={!!rejectTarget} onOpenChange={(open) => !open && setRejectTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Rechazar jugador?</AlertDialogTitle>
            <AlertDialogDescription>
              Vas a rechazar a <strong>{rejectTarget?.name}</strong>. El padre será notificado.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <div className="py-2">
            <Textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="Motivo del rechazo (opcional)..."
              className="bg-muted/50 border-neon-cyan/30"
              rows={3}
            />
          </div>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => { setRejectTarget(null); setRejectionReason(''); }}>
              Cancelar
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={handleReject}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Rechazar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
};

export default PendingPlayersPanel;
