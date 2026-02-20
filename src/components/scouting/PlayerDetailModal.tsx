import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { NeonButton } from '@/components/ui/NeonButton';
import { Slider } from '@/components/ui/slider';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import RadarChart from '@/components/players/RadarChart';
import PlayerProgressChart from '@/components/players/PlayerProgressChart';
import PlayerSessionHistoryList from '@/components/players/PlayerSessionHistoryList';
import ElitePlayerCard, { mapStatsToPlayerSkills, playerSkillsToStats, type PlayerSkills } from '@/components/players/ElitePlayerCard';
import AverageRatingLineChart from '@/components/players/AverageRatingLineChart';
import { User, Calendar, MapPin, Save, Edit3, X, TrendingUp, History, CreditCard } from 'lucide-react';
import { Database } from '@/integrations/supabase/types';
import { useAuth } from '@/contexts/AuthContext';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

type PlayerCategory = Database['public']['Enums']['player_category'];
type PlayerLevel = Database['public']['Enums']['player_level'];

interface PlayerStats {
  speed: number;
  technique: number;
  physical: number;
  mental: number;
  tactical: number;
}

interface Player {
  id: string;
  name: string;
  category: PlayerCategory;
  level: PlayerLevel;
  photo_url: string | null;
  position: string | null;
  stats: PlayerStats;
  birth_date?: string | null;
  notes?: string | null;
}

interface PlayerDetailModalProps {
  player: Player | null;
  isOpen: boolean;
  onClose: () => void;
  onStatsUpdated?: () => void;
}

const statLabels: Record<keyof PlayerStats, string> = {
  speed: 'Velocidad',
  technique: 'Técnica',
  physical: 'Físico',
  mental: 'Mental',
  tactical: 'Táctico',
};

const PlayerDetailModal: React.FC<PlayerDetailModalProps> = ({
  player,
  isOpen,
  onClose,
  onStatsUpdated
}) => {
  const { isAdmin, user } = useAuth();
  const { toast } = useToast();
  const [isEditing, setIsEditing] = useState(false);
  const [editedStats, setEditedStats] = useState<PlayerStats | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  // Reset editing state when modal opens/closes or player changes
  useEffect(() => {
    if (player) {
      setEditedStats({ ...player.stats });
    }
    setIsEditing(false);
  }, [player, isOpen]);

  if (!player) return null;

  const calculateAge = (birthDate: string | null | undefined) => {
    if (!birthDate) return null;
    const today = new Date();
    const birth = new Date(birthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  };

  const age = calculateAge(player.birth_date);

  const handleStatChange = (stat: keyof PlayerStats, value: number[]) => {
    if (editedStats) {
      setEditedStats({
        ...editedStats,
        [stat]: value[0],
      });
    }
  };

  const handleSaveStats = async () => {
    if (!editedStats) return;

    setIsSaving(true);
    try {
      const statsJson = editedStats as unknown as Record<string, number>;
      
      const { error } = await supabase
        .from('players')
        .update({ 
          stats: statsJson,
          updated_at: new Date().toISOString()
        })
        .eq('id', player.id);

      if (error) throw error;

      toast({
        title: '✅ Estadísticas Guardadas',
        description: `Las stats de ${player.name} han sido actualizadas.`,
      });

      setIsEditing(false);
      onStatsUpdated?.();
    } catch (error) {
      console.error('Error saving stats:', error);
      toast({
        title: 'Error',
        description: 'No se pudieron guardar las estadísticas.',
        variant: 'destructive',
      });
    } finally {
      setIsSaving(false);
    }
  };

  const handleCancelEdit = () => {
    setEditedStats({ ...player.stats });
    setIsEditing(false);
  };

  const displayStats = isEditing && editedStats ? editedStats : player.stats;
  const overallRating = Math.round(Object.values(displayStats).reduce((a, b) => a + b, 0) / 5);

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="bg-card border-neon-cyan/30 max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <DialogTitle className="font-orbitron gradient-text text-2xl">
              Perfil del Jugador
            </DialogTitle>
            {isAdmin && !isEditing && (
              <NeonButton
                variant="purple"
                size="sm"
                onClick={() => setIsEditing(true)}
                className="mr-8"
              >
                <Edit3 className="w-4 h-4 mr-1" />
                Editar Stats
              </NeonButton>
            )}
          </div>
        </DialogHeader>

        <Tabs defaultValue="carta" className="w-full">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="carta" className="flex items-center gap-1">
              <CreditCard className="w-3 h-3" />
              Carta
            </TabsTrigger>
            <TabsTrigger value="profile">Perfil</TabsTrigger>
            <TabsTrigger value="progress" className="flex items-center gap-1">
              <TrendingUp className="w-3 h-3" />
              Progreso
            </TabsTrigger>
            <TabsTrigger value="sessions" className="flex items-center gap-1">
              <History className="w-3 h-3" />
              Sesiones
            </TabsTrigger>
          </TabsList>

          <TabsContent value="carta" className="mt-4 flex justify-center">
            <ElitePlayerCard
              name={player.name}
              position={player.position}
              photoUrl={player.photo_url}
              skills={mapStatsToPlayerSkills(player.stats as Record<string, unknown>)}
              notes={player.notes}
              isCoach={isAdmin}
              onSkillsChange={async (skills: PlayerSkills) => {
                const statsJson = playerSkillsToStats(skills) as unknown as Record<string, number>;
                const { error } = await supabase
                  .from('players')
                  .update({ stats: statsJson, updated_at: new Date().toISOString() })
                  .eq('id', player.id);
                if (!error) {
                  if (user?.id) {
                    const historyStats = { ...statsJson, ...skills };
                    await supabase.from('player_stats_history').insert({
                      player_id: player.id,
                      reservation_id: null,
                      recorded_by: user.id,
                      stats: historyStats,
                      notes: null,
                      recorded_at: new Date().toISOString(),
                    });
                  }
                  onStatsUpdated?.();
                }
              }}
              onNotesChange={async (notes: string) => {
                const { error } = await supabase
                  .from('players')
                  .update({ notes: notes || null, updated_at: new Date().toISOString() })
                  .eq('id', player.id);
                if (!error) onStatsUpdated?.();
              }}
            />
          </TabsContent>

          <TabsContent value="profile" className="mt-4">
            <div className="grid md:grid-cols-2 gap-6">
              {/* Left Column - Photo & Basic Info */}
              <div className="space-y-4">
                {/* Photo */}
                <div className="relative aspect-square rounded-lg overflow-hidden bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30">
                  {player.photo_url ? (
                    <img
                      src={player.photo_url}
                      alt={player.name}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center">
                      <User className="w-24 h-24 text-muted-foreground" />
                    </div>
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-background/80 via-transparent to-transparent" />
                  <div className="absolute bottom-4 left-4 right-4">
                    <h2 className="font-orbitron font-bold text-2xl text-foreground mb-2">
                      {player.name}
                    </h2>
                    <div className="flex flex-wrap gap-2">
                      <StatusBadge variant="info">{player.category}</StatusBadge>
                      <StatusBadge variant={player.level === 'elite' ? 'success' : player.level === 'advanced' ? 'info' : 'default'}>
                        {player.level}
                      </StatusBadge>
                    </div>
                  </div>
                </div>

                {/* Info Details */}
                <div className="space-y-3">
                  {player.position && (
                    <div className="flex items-center gap-3 text-muted-foreground">
                      <MapPin className="w-4 h-4 text-neon-cyan" />
                      <span className="font-rajdhani">Posición: {player.position}</span>
                    </div>
                  )}
                  {age !== null && (
                    <div className="flex items-center gap-3 text-muted-foreground">
                      <Calendar className="w-4 h-4 text-neon-purple" />
                      <span className="font-rajdhani">{age} años</span>
                    </div>
                  )}
                </div>

                {/* Notes */}
                {player.notes && (
                  <div className="p-4 rounded-lg bg-muted/30 border border-border">
                    <h4 className="font-orbitron text-sm text-neon-cyan mb-2">Notas</h4>
                    <p className="text-sm text-muted-foreground font-rajdhani">{player.notes}</p>
                  </div>
                )}
              </div>

              {/* Right Column - Stats */}
              <div className="space-y-4">
                {/* Radar Chart */}
                <div className="flex justify-center py-4">
                  <RadarChart stats={displayStats} size={240} showLabels={true} />
                </div>

                {/* Stat Bars / Sliders */}
                <div className="space-y-4">
                  {(Object.entries(displayStats) as [keyof PlayerStats, number][]).map(([key, value]) => (
                    <div key={key}>
                      <div className="flex justify-between mb-2">
                        <span className="text-sm font-rajdhani text-muted-foreground">
                          {statLabels[key]}
                        </span>
                        <span className="text-sm font-orbitron text-neon-cyan">{value}</span>
                      </div>
                      
                      {isEditing && editedStats ? (
                        <Slider
                          value={[editedStats[key]]}
                          onValueChange={(val) => handleStatChange(key, val)}
                          min={0}
                          max={100}
                          step={1}
                          className="w-full"
                        />
                      ) : (
                        <div className="h-2 bg-muted rounded-full overflow-hidden">
                          <div 
                            className="h-full rounded-full transition-all duration-500"
                            style={{
                              width: `${value}%`,
                              background: `linear-gradient(90deg, hsl(var(--neon-cyan)), hsl(var(--neon-purple)))`
                            }}
                          />
                        </div>
                      )}
                    </div>
                  ))}
                </div>

                {/* Overall Rating */}
                <div className="p-4 rounded-lg bg-gradient-to-br from-neon-cyan/10 to-neon-purple/10 border border-neon-cyan/30 text-center">
                  <span className="text-sm font-rajdhani text-muted-foreground block mb-1">
                    Puntuación General
                  </span>
                  <span className="font-orbitron font-bold text-4xl gradient-text">
                    {overallRating}
                  </span>
                </div>

                {/* Edit Actions */}
                {isEditing && (
                  <div className="flex gap-3">
                    <NeonButton
                      variant="cyan"
                      size="md"
                      className="flex-1"
                      onClick={handleSaveStats}
                      disabled={isSaving}
                    >
                      {isSaving ? (
                        <div className="w-4 h-4 border-2 border-background/50 border-t-background rounded-full animate-spin mr-2" />
                      ) : (
                        <Save className="w-4 h-4 mr-2" />
                      )}
                      Guardar
                    </NeonButton>
                    <NeonButton
                      variant="outline"
                      size="md"
                      onClick={handleCancelEdit}
                      disabled={isSaving}
                    >
                      <X className="w-4 h-4 mr-2" />
                      Cancelar
                    </NeonButton>
                  </div>
                )}
              </div>
            </div>
          </TabsContent>

          <TabsContent value="progress" className="mt-4 space-y-6">
            <AverageRatingLineChart
              playerId={player.id}
              playerLevel={player.level}
              currentStats={player.stats as Record<string, number>}
            />
            <PlayerProgressChart
              playerId={player.id}
              currentStats={player.stats}
            />
          </TabsContent>

          <TabsContent value="sessions" className="mt-4">
            <PlayerSessionHistoryList playerId={player.id} />
          </TabsContent>
        </Tabs>
      </DialogContent>
    </Dialog>
  );
};

export default PlayerDetailModal;
