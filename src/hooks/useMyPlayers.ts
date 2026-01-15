import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import type { Database } from '@/integrations/supabase/types';

type PlayerCategory = Database['public']['Enums']['player_category'];
type PlayerLevel = Database['public']['Enums']['player_level'];

export interface PlayerStats {
  technique: number;
  speed: number;
  physical: number;
  mental: number;
  tactical: number;
}

export interface Player {
  id: string;
  parent_id: string;
  name: string;
  birth_date: string | null;
  category: PlayerCategory;
  level: PlayerLevel;
  position: string | null;
  photo_url: string | null;
  stats: PlayerStats;
  notes: string | null;
  current_club: string | null;
  dominant_leg: string | null;
  created_at: string;
  updated_at: string;
}

const defaultStats: PlayerStats = {
  technique: 50,
  speed: 50,
  physical: 50,
  mental: 50,
  tactical: 50,
};

export const useMyPlayers = () => {
  const { user } = useAuth();
  const [players, setPlayers] = useState<Player[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchPlayers = async () => {
    if (!user) return;

    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('players')
        .select('*')
        .eq('parent_id', user.id)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const playersWithStats = (data || []).map((player) => ({
        ...player,
        stats: typeof player.stats === 'object' && player.stats !== null
          ? { ...defaultStats, ...(player.stats as Record<string, number>) }
          : defaultStats,
      }));

      setPlayers(playersWithStats);
    } catch (err) {
      console.error('Error fetching players:', err);
    } finally {
      setLoading(false);
    }
  };

  const createPlayer = async (playerData: {
    name: string;
    birth_date?: string;
    category: PlayerCategory;
    level?: PlayerLevel;
    position?: string;
  }) => {
    if (!user) return null;

    try {
      const { data, error } = await supabase
        .from('players')
        .insert({
          parent_id: user.id,
          name: playerData.name,
          birth_date: playerData.birth_date || null,
          category: playerData.category,
          level: playerData.level || 'beginner',
          position: playerData.position || null,
        })
        .select()
        .single();

      if (error) throw error;
      await fetchPlayers();
      return data;
    } catch (err) {
      console.error('Error creating player:', err);
      return null;
    }
  };

  const updatePlayer = async (id: string, updates: Partial<Omit<Player, 'stats'>> & { stats?: Record<string, number> }) => {
    try {
      const { stats, ...otherUpdates } = updates;
      const updateData: Record<string, unknown> = {
        ...otherUpdates,
        updated_at: new Date().toISOString(),
      };
      
      if (stats) {
        updateData.stats = stats;
      }

      const { error } = await supabase
        .from('players')
        .update(updateData)
        .eq('id', id);

      if (error) throw error;
      await fetchPlayers();
      return true;
    } catch (err) {
      console.error('Error updating player:', err);
      return false;
    }
  };

  const uploadPlayerPhoto = async (playerId: string, file: File) => {
    if (!user) return null;

    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `${playerId}-${Date.now()}.${fileExt}`;
      const filePath = `${user.id}/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('player-photos')
        .upload(filePath, file, { upsert: true });

      if (uploadError) throw uploadError;

      const { data: urlData } = supabase.storage
        .from('player-photos')
        .getPublicUrl(filePath);

      const photoUrl = urlData.publicUrl;

      const { error: updateError } = await supabase
        .from('players')
        .update({ photo_url: photoUrl, updated_at: new Date().toISOString() })
        .eq('id', playerId);

      if (updateError) throw updateError;

      await fetchPlayers();
      return photoUrl;
    } catch (err) {
      console.error('Error uploading photo:', err);
      return null;
    }
  };

  const deletePlayer = async (id: string) => {
    try {
      const { error } = await supabase
        .from('players')
        .delete()
        .eq('id', id);

      if (error) throw error;
      await fetchPlayers();
      return true;
    } catch (err) {
      console.error('Error deleting player:', err);
      return false;
    }
  };

  useEffect(() => {
    fetchPlayers();
  }, [user]);

  return {
    players,
    loading,
    createPlayer,
    updatePlayer,
    uploadPlayerPhoto,
    deletePlayer,
    refetch: fetchPlayers,
  };
};
