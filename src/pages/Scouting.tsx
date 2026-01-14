import React, { useState, useMemo, useCallback } from 'react';
import { Navigate } from 'react-router-dom';
import Layout from '@/components/layout/Layout';
import ScoutingFilters from '@/components/scouting/ScoutingFilters';
import PlayerGrid from '@/components/scouting/PlayerGrid';
import PlayerDetailModal from '@/components/scouting/PlayerDetailModal';
import { usePlayers } from '@/hooks/usePlayers';
import { useAuth } from '@/contexts/AuthContext';
import { Target } from 'lucide-react';
import { Database } from '@/integrations/supabase/types';

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

const Scouting: React.FC = () => {
  const { user, isApproved, isAdmin, isLoading: authLoading } = useAuth();
  const [category, setCategory] = useState<string>('all');
  const [level, setLevel] = useState<string>('all');
  const [search, setSearch] = useState<string>('');
  const [selectedPlayer, setSelectedPlayer] = useState<Player | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const filters = useMemo(() => ({
    category: category as PlayerCategory | 'all',
    level: level as PlayerLevel | 'all',
    search: search.trim() || undefined,
  }), [category, level, search]);

  const { players, isLoading, error } = usePlayers(filters);

  const handlePlayerClick = useCallback((player: Player) => {
    setSelectedPlayer(player);
    setIsModalOpen(true);
  }, []);

  const handleCloseModal = useCallback(() => {
    setIsModalOpen(false);
    setSelectedPlayer(null);
  }, []);

  // Redirect if not authenticated or not approved
  if (authLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/auth" replace />;
  }

  if (!isApproved && !isAdmin) {
    return <Navigate to="/" replace />;
  }

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="flex items-center gap-4 mb-8">
          <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-neon-cyan to-neon-purple flex items-center justify-center">
            <Target className="w-6 h-6 text-background" />
          </div>
          <div>
            <h1 className="font-orbitron font-bold text-3xl gradient-text">
              SCOUTING
            </h1>
            <p className="text-muted-foreground font-rajdhani">
              Explora el talento de Elite 380
            </p>
          </div>
        </div>

        {/* Filters */}
        <ScoutingFilters
          category={category}
          level={level}
          search={search}
          onCategoryChange={setCategory}
          onLevelChange={setLevel}
          onSearchChange={setSearch}
        />

        {/* Stats Summary */}
        <div className="flex items-center justify-between mb-6">
          <p className="text-muted-foreground font-rajdhani">
            {isLoading ? 'Cargando...' : `${players.length} jugadores encontrados`}
          </p>
          <div className="flex gap-2">
            {category !== 'all' && (
              <span className="px-3 py-1 rounded-full bg-neon-cyan/10 text-neon-cyan text-sm font-rajdhani border border-neon-cyan/30">
                {category}
              </span>
            )}
            {level !== 'all' && (
              <span className="px-3 py-1 rounded-full bg-neon-purple/10 text-neon-purple text-sm font-rajdhani border border-neon-purple/30">
                {level}
              </span>
            )}
          </div>
        </div>

        {/* Error State */}
        {error && (
          <div className="p-4 rounded-lg bg-destructive/10 border border-destructive/30 text-destructive mb-6">
            <p className="font-rajdhani">{error}</p>
          </div>
        )}

        {/* Loading State */}
        {isLoading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {[...Array(8)].map((_, i) => (
              <div 
                key={i} 
                className="h-80 rounded-lg bg-card border border-neon-cyan/20 animate-pulse"
              />
            ))}
          </div>
        ) : (
          <PlayerGrid 
            players={players} 
            onPlayerClick={handlePlayerClick}
          />
        )}

        {/* Player Detail Modal */}
        <PlayerDetailModal
          player={selectedPlayer}
          isOpen={isModalOpen}
          onClose={handleCloseModal}
        />
      </div>
    </Layout>
  );
};

export default Scouting;
