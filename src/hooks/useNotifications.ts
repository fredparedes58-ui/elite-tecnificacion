import { useEffect, useRef } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';

/**
 * Hook that listens to realtime events and shows push-style notifications
 * - Reservation approval/rejection for parents
 * - New messages for the current user
 */
export const useNotifications = () => {
  const { user, isAdmin } = useAuth();
  const { toast } = useToast();
  const initialLoadRef = useRef(true);

  useEffect(() => {
    if (!user) return;

    // Small delay to avoid showing notifications on initial load
    const timeout = setTimeout(() => {
      initialLoadRef.current = false;
    }, 2000);

    return () => clearTimeout(timeout);
  }, [user]);

  // Listen to reservation status changes
  useEffect(() => {
    if (!user || isAdmin) return; // Only parents need these notifications

    const channel = supabase
      .channel('reservation-notifications')
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'reservations',
          filter: `user_id=eq.${user.id}`,
        },
        (payload) => {
          if (initialLoadRef.current) return;

          const newStatus = payload.new.status;
          const title = payload.new.title;

          if (newStatus === 'approved') {
            toast({
              title: '🎉 ¡Reserva Aprobada!',
              description: `Tu reserva "${title}" ha sido aprobada por el administrador.`,
            });

            // Browser notification if permitted
            showBrowserNotification('Reserva Aprobada', `Tu reserva "${title}" ha sido aprobada.`);
          } else if (newStatus === 'rejected') {
            toast({
              title: '❌ Reserva Rechazada',
              description: `Tu reserva "${title}" ha sido rechazada.`,
              variant: 'destructive',
            });

            showBrowserNotification('Reserva Rechazada', `Tu reserva "${title}" ha sido rechazada.`);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, isAdmin, toast]);

  // Listen to new messages
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('message-notifications')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
        },
        async (payload) => {
          if (initialLoadRef.current) return;
          
          const newMessage = payload.new;
          
          // Don't notify for own messages
          if (newMessage.sender_id === user.id) return;

          // Check if user is part of this conversation
          const { data: conversation } = await supabase
            .from('conversations')
            .select('participant_id, subject')
            .eq('id', newMessage.conversation_id)
            .single();

          if (!conversation) return;

          // Check if user should receive this notification
          const shouldNotify = isAdmin || conversation.participant_id === user.id;

          if (shouldNotify) {
            // Get sender name
            const { data: sender } = await supabase
              .from('profiles')
              .select('full_name, email')
              .eq('id', newMessage.sender_id)
              .single();

            const senderName = sender?.full_name || sender?.email || 'Alguien';

            toast({
              title: '💬 Nuevo Mensaje',
              description: `${senderName}: ${newMessage.content.slice(0, 50)}${newMessage.content.length > 50 ? '...' : ''}`,
            });

            showBrowserNotification(
              'Nuevo Mensaje',
              `${senderName}: ${newMessage.content.slice(0, 100)}`
            );
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, isAdmin, toast]);

  // Request notification permission on mount
  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      // We'll request permission when user interacts with the page
      const requestPermission = () => {
        Notification.requestPermission();
        document.removeEventListener('click', requestPermission);
      };
      document.addEventListener('click', requestPermission, { once: true });
    }
  }, []);

  return null;
};

/**
 * Show a browser notification if permission is granted
 */
function showBrowserNotification(title: string, body: string) {
  if ('Notification' in window && Notification.permission === 'granted') {
    try {
      new Notification(`Elite 380 - ${title}`, {
        body,
        icon: '/favicon.ico',
        badge: '/favicon.ico',
        tag: Date.now().toString(),
      });
    } catch (error) {
      // Silent fail for browsers that don't support notifications
      console.log('Browser notifications not supported');
    }
  }
}

export default useNotifications;
