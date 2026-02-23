import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import type { Database } from '@/integrations/supabase/types';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState, useCallback } from 'react';

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
      try {
        await supabase.functions.invoke('notify-session-events', {
          body: { event: 'reservation_requested', reservation_id: data.id },
        });
      } catch (notifyErr) {
        console.warn('notify-session-events (reservation_requested):', notifyErr);
      }
      return data;
    } catch (err) {
      console.error('Error creating reservation:', err);
      return null;
    }
  };

  const cancelReservation = async (id: string) => {
    if (!user) return false;

    try {
      const reservation = reservations.find(r => r.id === id);
      if (!reservation) return false;

      // Only allow cancelling pending or approved reservations
      if (!['pending', 'approved'].includes(reservation.status || '')) {
        console.error('Cannot cancel reservation with status:', reservation.status);
        return false;
      }

      // Update status to rejected (cancelled)
      // The database trigger will handle refunding credits if it was approved
      const { error } = await supabase
        .from('reservations')
        .update({ 
          status: 'rejected',
          updated_at: new Date().toISOString() 
        })
        .eq('id', id)
        .eq('user_id', user.id);

      if (error) throw error;

      refetch();
      return true;
    } catch (err) {
      console.error('Error cancelling reservation:', err);
      return false;
    }
  };

  return { reservations, loading, createReservation, cancelReservation, refetch };
};

// Hook for admin - all reservations with real-time updates
export const useAllReservations = () => {
  const { isAdmin, user } = useAuth();
  const queryClient = useQueryClient();
  const [isRealtimeConnected, setIsRealtimeConnected] = useState(false);
  const [lastRealtimeUpdate, setLastRealtimeUpdate] = useState<Date | null>(null);

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
          setLastRealtimeUpdate(new Date());
          // Invalidate and refetch to get complete data with JOINs
          queryClient.invalidateQueries({ queryKey: ['all-reservations'] });
        }
      )
      .subscribe((status) => {
        setIsRealtimeConnected(status === 'SUBSCRIBED');
        console.log('📡 Realtime reservations status:', status);
      });

    return () => {
      supabase.removeChannel(channel);
      setIsRealtimeConnected(false);
    };
  }, [isAdmin, queryClient]);

  // Delete reservation
  const deleteReservation = useCallback(async (id: string) => {
    try {
      // Optimistic update - remove from cache
      queryClient.setQueryData<Reservation[]>(['all-reservations'], (old) =>
        old?.filter(r => r.id !== id)
      );

      const { error } = await supabase
        .from('reservations')
        .delete()
        .eq('id', id);

      if (error) throw error;
      return true;
    } catch (err) {
      console.error('Error deleting reservation:', err);
      // Revert on error
      queryClient.invalidateQueries({ queryKey: ['all-reservations'] });
      return false;
    }
  }, [queryClient]);

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
        if (status === 'approved') {
          try {
            await supabase.functions.invoke('notify-session-events', {
              body: { event: 'reservation_accepted', reservation_id: id },
            });
          } catch (notifyErr) {
            console.warn('notify-session-events (reservation_accepted):', notifyErr);
          }
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
    title?: string;
  }, sendEmail: boolean = true) => {
    try {
      // Get current reservation for comparison
      const currentReservation = reservations.find(r => r.id === id);
      
      // Optimistic update
      queryClient.setQueryData<Reservation[]>(['all-reservations'], (old) =>
        old?.map(r => r.id === id ? { ...r, ...updates, updated_at: new Date().toISOString() } : r)
      );

      const { error } = await supabase
        .from('reservations')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;
      
      // Determine email type based on changes and send email
      if (sendEmail && currentReservation) {
        let emailType = 'updated';
        try {
          let oldStartTime: string | undefined;
          let oldTrainerName: string | undefined;
          
          // Determine the most specific email type based on what changed
          if (updates.start_time || updates.end_time) {
            emailType = 'moved';
            oldStartTime = currentReservation.start_time;
          } else if (updates.trainer_id !== undefined && updates.trainer_id !== currentReservation.trainer_id) {
            emailType = 'trainer_changed';
            // We'd need to look up old trainer name - for now just send the type
          } else if (updates.player_id !== undefined) {
            if (updates.player_id && !currentReservation.player_id) {
              emailType = 'player_assigned';
            } else if (!updates.player_id && currentReservation.player_id) {
              emailType = 'player_removed';
            }
          } else if (updates.status) {
            emailType = updates.status === 'approved' ? 'approved' 
              : updates.status === 'rejected' ? 'rejected' 
              : 'updated';
          }
          
          await supabase.functions.invoke('send-reservation-email', {
            body: { 
              reservation_id: id, 
              type: emailType,
              old_start_time: oldStartTime,
              old_trainer_name: oldTrainerName,
            },
          });
        } catch (emailError) {
          console.error('Error sending email notification:', emailError);
        }
        if (emailType === 'moved') {
          try {
            await supabase.functions.invoke('notify-session-events', {
              body: {
                event: 'reservation_moved',
                reservation_id: id,
                old_start_time: currentReservation.start_time,
              },
            });
          } catch (notifyErr) {
            console.warn('notify-session-events (reservation_moved):', notifyErr);
          }
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

  return { 
    reservations, 
    loading, 
    updateReservationStatus, 
    updateReservation, 
    createReservation, 
    deleteReservation,
    refetch,
    isRealtimeConnected,
    lastRealtimeUpdate,
  };
};
