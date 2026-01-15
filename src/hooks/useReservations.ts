import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import type { Database } from '@/integrations/supabase/types';

type ReservationStatus = Database['public']['Enums']['reservation_status'];

export interface Reservation {
  id: string;
  user_id: string;
  player_id: string | null;
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

export const useReservations = () => {
  const { user } = useAuth();
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchReservations = async () => {
    if (!user) return;

    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('reservations')
        .select('*')
        .eq('user_id', user.id)
        .order('start_time', { ascending: false });

      if (error) throw error;
      setReservations(data || []);
    } catch (err) {
      console.error('Error fetching reservations:', err);
    } finally {
      setLoading(false);
    }
  };

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
      await fetchReservations();
      return data;
    } catch (err) {
      console.error('Error creating reservation:', err);
      return null;
    }
  };

  useEffect(() => {
    fetchReservations();
  }, [user]);

  return { reservations, loading, createReservation, refetch: fetchReservations };
};

export const useAllReservations = () => {
  const { isAdmin } = useAuth();
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAllReservations = async () => {
    if (!isAdmin) return;

    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('reservations')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;

      const reservationsWithDetails = await Promise.all(
        (data || []).map(async (res) => {
          const { data: profile } = await supabase
            .from('profiles')
            .select('full_name, email')
            .eq('id', res.user_id)
            .single();

          let player = null;
          if (res.player_id) {
            const { data: playerData } = await supabase
              .from('players')
              .select('name')
              .eq('id', res.player_id)
              .single();
            player = playerData;
          }

          return {
            ...res,
            user: profile || undefined,
            player: player || undefined,
          };
        })
      );

      setReservations(reservationsWithDetails);
    } catch (err) {
      console.error('Error fetching all reservations:', err);
    } finally {
      setLoading(false);
    }
  };

  const updateReservationStatus = async (id: string, status: ReservationStatus, sendEmail: boolean = true) => {
    try {
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
          // Don't fail the status update if email fails
        }
      }
      
      await fetchAllReservations();
      return true;
    } catch (err) {
      console.error('Error updating reservation:', err);
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
      
      await fetchAllReservations();
      return true;
    } catch (err) {
      console.error('Error updating reservation:', err);
      return false;
    }
  };

  useEffect(() => {
    fetchAllReservations();
  }, [isAdmin]);

  return { reservations, loading, updateReservationStatus, updateReservation, refetch: fetchAllReservations };
};
