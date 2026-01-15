import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

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
  const [trainers, setTrainers] = useState<Trainer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTrainers = async () => {
    try {
      setLoading(true);
      setError(null);
      
      if (isAdmin) {
        // Admins get full trainer data from trainers table
        const { data, error: fetchError } = await supabase
          .from('trainers')
          .select('*')
          .eq('is_active', true)
          .order('name');

        if (fetchError) throw fetchError;
        setTrainers((data || []) as Trainer[]);
      } else {
        // Non-admins get public trainer data (no email/phone)
        const { data, error: fetchError } = await supabase
          .from('trainers_public')
          .select('*')
          .eq('is_active', true)
          .order('name');

        if (fetchError) throw fetchError;
        // Map to Trainer type with null contact fields
        setTrainers((data || []).map(t => ({
          ...t,
          email: null,
          phone: null,
        })) as Trainer[]);
      }
    } catch (err) {
      console.error('Error fetching trainers:', err);
      setError('Error al cargar entrenadores');
    } finally {
      setLoading(false);
    }
  };

  const createTrainer = async (trainer: Omit<Trainer, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      const { data, error } = await supabase
        .from('trainers')
        .insert(trainer)
        .select()
        .single();

      if (error) throw error;
      await fetchTrainers();
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
      await fetchTrainers();
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
      await fetchTrainers();
      return true;
    } catch (err) {
      console.error('Error deleting trainer:', err);
      return false;
    }
  };

  useEffect(() => {
    if (user) {
      fetchTrainers();
    }
  }, [user, isAdmin]);

  return {
    trainers,
    loading,
    error,
    createTrainer,
    updateTrainer,
    deleteTrainer,
    refetch: fetchTrainers,
  };
};
