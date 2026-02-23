import React, { useState, useMemo } from 'react';
import { Navigate } from 'react-router-dom';
import Layout from '@/components/layout/Layout';
import { useAuth } from '@/contexts/AuthContext';
import { usePlayers } from '@/hooks/usePlayers';
import ElitePlayerCard, { mapStatsToPlayerSkills } from '@/components/players/ElitePlayerCard';
import { EliteCard } from '@/components/ui/EliteCard';
import BackButton from '@/components/layout/BackButton';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { GitCompare } from 'lucide-react';
import type { Database } from '@/integrations/supabase/types';

type PlayerCategory = Database['public']['Enums']['player_category'];
type PlayerLevel = Database['public']['Enums']['player_level'];

interface Player {
  id: string;
  name: string;
  category: PlayerCategory;
  level: PlayerLevel;
  photo_url: string | null;
  position: string | null;
  stats: Record<string, number> | null;
  notes: string | null;
}

const ComparePlayers: React.FC = () => {
  const { isAdmin, isLoading: authLoading } = useAuth();
  const { players = [], isLoading } = usePlayers({});
  const [playerAId, setPlayerAId] = useState<string>('');
  const [playerBId, setPlayerBId] = useState<string>('');

  const playerA = useMemo(() => players.find((p) => p.id === playerAId) as unknown as Player | undefined, [players, playerAId]);
  const playerB = useMemo(() => players.find((p) => p.id === playerBId) as unknown as Player | undefined, [players, playerBId]);

  if (authLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAdmin) return <Navigate to="/" replace />;

  return (
    <Layout>
      <div className="container mx-auto px-4 py-6">
        <BackButton />
        <div className="flex items-center gap-3 mb-6">
          <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-neon-cyan to-neon-purple flex items-center justify-center">
            <GitCompare className="w-6 h-6 text-background" />
          </div>
          <div>
            <h1 className="font-orbitron font-bold text-2xl md:text-3xl gradient-text">
              Comparativa de Jugadores
            </h1>
            <p className="text-muted-foreground font-rajdhani text-sm">
              Estilo FIFA: elige dos jugadores para comparar
            </p>
          </div>
        </div>

        <EliteCard className="p-4 mb-6 flex flex-col sm:flex-row gap-4">
          <div className="flex-1 space-y-2">
            <label className="text-sm font-rajdhani text-muted-foreground">Jugador A</label>
            <Select value={playerAId} onValueChange={setPlayerAId}>
              <SelectTrigger className="bg-background border-neon-cyan/30">
                <SelectValue placeholder="Seleccionar jugador..." />
              </SelectTrigger>
              <SelectContent>
                {players.map((p) => (
                  <SelectItem key={p.id} value={p.id}>
                    {p.name} ({p.category})
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex-1 space-y-2">
            <label className="text-sm font-rajdhani text-muted-foreground">Jugador B</label>
            <Select value={playerBId} onValueChange={setPlayerBId}>
              <SelectTrigger className="bg-background border-neon-cyan/30">
                <SelectValue placeholder="Seleccionar jugador..." />
              </SelectTrigger>
              <SelectContent>
                {players.map((p) => (
                  <SelectItem key={p.id} value={p.id}>
                    {p.name} ({p.category})
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </EliteCard>

        {isLoading ? (
          <div className="flex justify-center py-12">
            <div className="w-10 h-10 border-2 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
          </div>
        ) : (
          <div className="grid md:grid-cols-2 gap-6 justify-items-center">
            {playerA ? (
              <div className="w-full max-w-[320px]">
                <ElitePlayerCard
                  name={playerA.name}
                  position={playerA.position}
                  photoUrl={playerA.photo_url}
                  skills={mapStatsToPlayerSkills(playerA.stats as Record<string, unknown>)}
                  notes={playerA.notes}
                  isCoach={false}
                />
              </div>
            ) : (
              <EliteCard className="w-full max-w-[320px] min-h-[420px] flex items-center justify-center border-dashed">
                <p className="text-muted-foreground text-sm">Selecciona jugador A</p>
              </EliteCard>
            )}
            {playerB ? (
              <div className="w-full max-w-[320px]">
                <ElitePlayerCard
                  name={playerB.name}
                  position={playerB.position}
                  photoUrl={playerB.photo_url}
                  skills={mapStatsToPlayerSkills(playerB.stats as Record<string, unknown>)}
                  notes={playerB.notes}
                  isCoach={false}
                />
              </div>
            ) : (
              <EliteCard className="w-full max-w-[320px] min-h-[420px] flex items-center justify-center border-dashed">
                <p className="text-muted-foreground text-sm">Selecciona jugador B</p>
              </EliteCard>
            )}
          </div>
        )}
      </div>
    </Layout>
  );
};

export default ComparePlayers;
