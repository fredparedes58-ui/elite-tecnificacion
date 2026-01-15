import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import type { Database } from '@/integrations/supabase/types';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

type ReservationStatus = Database['public']['Enums']['reservation_status'];

export interface Reservation {
  id: string;
  user_id: string;
  player_id: string | null;
  trainer_id: string | null;
  title: string;
  description: string | null;
  start_time: string;
  end_time: string;
  status: ReservationStatus;
  credit_cost: number;
  created_at: string;
  updated_at: string;
  user?: {
    full_name: string | null;
    email: string;
  };
  player?: {
    name: string;
  };
}

// Hook for user's own reservations
export const useReservations = () => {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  const { data: reservations = [], isLoading: loading, refetch } = useQuery({
    queryKey: ['reservations', user?.id],
    queryFn: async () => {
      if (!user) return [];
      
      const { data, error } = await supabase
        .from('reservations')
        .select('*')
        .eq('user_id', user.id)
        .order('start_time', { ascending: false });

      if (error) throw error;
      return data as Reservation[];
    },
    enabled: !!user,
    staleTime: 30 * 1000,
    gcTime: 5 * 60 * 1000,
  });

  // Real-time subscription for user's reservations
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('user-reservations-realtime')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'reservations',
          filter: `user_id=eq.${user.id}`,
        },
        () => {
          queryClient.invalidateQueries({ queryKey: ['reservations', user.id] });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, queryClient]);

  const createReservation = async (reservation: {
    title: string;
    description?: string;
    start_time: string;
    end_time: string;
    player_id?: string;
    trainer_id?: string;
    credit_cost?: number;
  }) => {
    if (!user) return null;

    try {
      const { data, error } = await supabase
        .from('reservations')
        .insert({
          user_id: user.id,
          ...reservation,
        })
        .select()
        .single();

      if (error) throw error;
      refetch();
      return data;
    } catch (err) {
      console.error('Error creating reservation:', err);
      return null;
    }
  };

  return { reservations, loading, createReservation, refetch };
};

// Hook for admin - all reservations with real-time updates
export const useAllReservations = () => {
  const { isAdmin, user } = useAuth();
  const queryClient = useQueryClient();

  const { data: reservations = [], isLoading: loading, refetch } = useQuery({
    queryKey: ['all-reservations'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('reservations')
        .select(`
          *,
          profiles:user_id(full_name, email),
          players:player_id(name)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;

      return (data || []).map(res => ({
        id: res.id,
        user_id: res.user_id,
        player_id: res.player_id,
        trainer_id: res.trainer_id,
        title: res.title,
        description: res.description,
        start_time: res.start_time,
        end_time: res.end_time,
        status: res.status,
        credit_cost: res.credit_cost,
        created_at: res.created_at,
        updated_at: res.updated_at,
        user: res.profiles || undefined,
        player: res.players || undefined,
      })) as Reservation[];
    },
    enabled: isAdmin,
    staleTime: 30 * 1000,
    gcTime: 5 * 60 * 1000,
  });

  // Real-time subscription for all reservations (admin)
  useEffect(() => {
    if (!isAdmin) return;

    const channel = supabase
      .channel('admin-reservations-realtime')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'reservations',
        },
        (payload) => {
          console.log('🔄 Realtime reservation update:', payload.eventType);
          // Invalidate and refetch to get complete data with JOINs
          queryClient.invalidateQueries({ queryKey: ['all-reservations'] });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [isAdmin, queryClient]);

  const createReservation = async (reservation: {
    title: string;
    description?: string;
    start_time: string;
    end_time: string;
    player_id?: string;
    trainer_id?: string;
    credit_cost?: number;
    user_id?: string;
    status?: ReservationStatus;
  }) => {
    try {
      const { data, error } = await supabase
        .from('reservations')
        .insert({
          user_id: reservation.user_id || user?.id,
          ...reservation,
        })
        .select()
        .single();

      if (error) throw error;
      
      // Invalidate cache to refetch
      queryClient.invalidateQueries({ queryKey: ['all-reservations'] });
      return data;
    } catch (err) {
      console.error('Error creating reservation:', err);
      return null;
    }
  };

  const updateReservationStatus = async (id: string, status: ReservationStatus, sendEmail: boolean = true) => {
    try {
      // Optimistic update
      queryClient.setQueryData<Reservation[]>(['all-reservations'], (old) =>
        old?.map(r => r.id === id ? { ...r, status, updated_at: new Date().toISOString() } : r)
      );

      const { error } = await supabase
        .from('reservations')
        .update({ status, updated_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;
      
      // Send email notification
      if (sendEmail && (status === 'approved' || status === 'rejected')) {
        try {
          await supabase.functions.invoke('send-reservation-email', {
            body: { reservation_id: id, type: status },
          });
        } catch (emailError) {
          console.error('Error sending email notification:', emailError);
        }
      }
      
      return true;
    } catch (err) {
      console.error('Error updating reservation:', err);
      // Revert on error
      queryClient.invalidateQueries({ queryKey: ['all-reservations'] });
      return false;
    }
  };

  const updateReservation = async (id: string, updates: {
    trainer_id?: string | null;
    player_id?: string | null;
    start_time?: string;
    end_time?: string;
    status?: ReservationStatus;
  }, sendEmail: boolean = false) => {
    try {
      // Optimistic update
      queryClient.setQueryData<Reservation[]>(['all-reservations'], (old) =>
        old?.map(r => r.id === id ? { ...r, ...updates, updated_at: new Date().toISOString() } : r)
      );

      const { error } = await supabase
        .from('reservations')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;
      
      // Send email notification for important updates
      if (sendEmail) {
        try {
          const emailType = updates.status === 'approved' ? 'approved' 
            : updates.status === 'rejected' ? 'rejected' 
            : 'updated';
          await supabase.functions.invoke('send-reservation-email', {
            body: { reservation_id: id, type: emailType },
          });
        } catch (emailError) {
          console.error('Error sending email notification:', emailError);
        }
      }
      
      // Refetch to get updated player/user names if player_id changed
      if (updates.player_id !== undefined) {
        queryClient.invalidateQueries({ queryKey: ['all-reservations'] });
      }
      
      return true;
    } catch (err) {
      console.error('Error updating reservation:', err);
      // Revert on error
      queryClient.invalidateQueries({ queryKey: ['all-reservations'] });
      return false;
    }
  };

  return { reservations, loading, updateReservationStatus, updateReservation, createReservation, refetch };
};
