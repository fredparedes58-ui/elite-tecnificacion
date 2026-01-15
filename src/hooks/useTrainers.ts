import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { useQuery, useQueryClient } from '@tanstack/react-query';

export interface Trainer {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  photo_url: string | null;
  specialty: string | null;
  bio: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Public trainer info (without contact details)
export interface TrainerPublic {
  id: string;
  name: string;
  photo_url: string | null;
  specialty: string | null;
  bio: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export const useTrainers = () => {
  const { user, isAdmin } = useAuth();
  const queryClient = useQueryClient();

  const { data: trainers = [], isLoading: loading, error: queryError, refetch } = useQuery({
    queryKey: ['trainers', isAdmin],
    queryFn: async () => {
      if (isAdmin) {
        // Admins get full trainer data from trainers table
        const { data, error } = await supabase
          .from('trainers')
          .select('*')
          .eq('is_active', true)
          .order('name');

        if (error) throw error;
        return (data || []) as Trainer[];
      } else {
        // Non-admins get public trainer data (no email/phone)
        const { data, error } = await supabase
          .from('trainers_public')
          .select('*')
          .eq('is_active', true)
          .order('name');

        if (error) throw error;
        // Map to Trainer type with null contact fields
        return (data || []).map(t => ({
          ...t,
          email: null,
          phone: null,
        })) as Trainer[];
      }
    },
    enabled: !!user,
    staleTime: 60 * 1000, // 1 minute - trainers don't change often
    gcTime: 10 * 60 * 1000, // 10 minutes
  });

  const error = queryError ? 'Error al cargar entrenadores' : null;

  const createTrainer = async (trainer: Omit<Trainer, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      const { data, error } = await supabase
        .from('trainers')
        .insert(trainer)
        .select()
        .single();

      if (error) throw error;
      queryClient.invalidateQueries({ queryKey: ['trainers'] });
      return data as Trainer;
    } catch (err) {
      console.error('Error creating trainer:', err);
      return null;
    }
  };

  const updateTrainer = async (id: string, updates: Partial<Trainer>) => {
    try {
      const { error } = await supabase
        .from('trainers')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;
      queryClient.invalidateQueries({ queryKey: ['trainers'] });
      return true;
    } catch (err) {
      console.error('Error updating trainer:', err);
      return false;
    }
  };

  const deleteTrainer = async (id: string) => {
    try {
      // Soft delete by setting is_active to false
      const { error } = await supabase
        .from('trainers')
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;
      queryClient.invalidateQueries({ queryKey: ['trainers'] });
      return true;
    } catch (err) {
      console.error('Error deleting trainer:', err);
      return false;
    }
  };

  return {
    trainers,
    loading,
    error,
    createTrainer,
    updateTrainer,
    deleteTrainer,
    refetch,
  };
};
