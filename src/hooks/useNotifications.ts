import { useEffect, useRef, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';

// Audio context for notification sounds
let audioContext: AudioContext | null = null;

/**
 * Play a notification sound using Web Audio API
 */
const playNotificationSound = (type: 'message' | 'approval' | 'alert' = 'message') => {
  try {
    if (!audioContext) {
      audioContext = new AudioContext();
    }

    // Resume context if suspended (browser policy)
    if (audioContext.state === 'suspended') {
      audioContext.resume();
    }

    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();

    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);

    // Different sounds for different notification types
    if (type === 'message') {
      // Pleasant chime for messages
      oscillator.frequency.setValueAtTime(880, audioContext.currentTime); // A5
      oscillator.frequency.setValueAtTime(1100, audioContext.currentTime + 0.1); // C#6
      oscillator.type = 'sine';
      gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.3);
    } else if (type === 'approval') {
      // Success sound for approvals
      oscillator.frequency.setValueAtTime(523, audioContext.currentTime); // C5
      oscillator.frequency.setValueAtTime(659, audioContext.currentTime + 0.1); // E5
      oscillator.frequency.setValueAtTime(784, audioContext.currentTime + 0.2); // G5
      oscillator.type = 'sine';
      gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.4);
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.4);
    } else {
      // Alert sound
      oscillator.frequency.setValueAtTime(440, audioContext.currentTime);
      oscillator.type = 'triangle';
      gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2);
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.2);
    }
  } catch (error) {
    console.log('Could not play notification sound:', error);
  }
};

/**
 * Hook that listens to realtime events and shows push-style notifications
 * - Reservation approval/rejection for parents
 * - New messages for the current user
 */
export const useNotifications = () => {
  const { user, isAdmin } = useAuth();
  const { toast } = useToast();
  const initialLoadRef = useRef(true);

  // Initialize audio context on first user interaction
  const initAudio = useCallback(() => {
    if (!audioContext) {
      audioContext = new AudioContext();
    }
    document.removeEventListener('click', initAudio);
  }, []);

  useEffect(() => {
    document.addEventListener('click', initAudio, { once: true });
    return () => document.removeEventListener('click', initAudio);
  }, [initAudio]);

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
            playNotificationSound('approval');
            toast({
              title: '🎉 ¡Reserva Aprobada!',
              description: `Tu reserva "${title}" ha sido aprobada por el administrador.`,
            });

            showBrowserNotification('Reserva Aprobada', `Tu reserva "${title}" ha sido aprobada.`);
          } else if (newStatus === 'rejected') {
            playNotificationSound('alert');
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
            .maybeSingle();

          if (!conversation) return;

          // Check if user should receive this notification
          const shouldNotify = isAdmin || conversation.participant_id === user.id;

          if (shouldNotify) {
            // Get sender name
            const { data: sender } = await supabase
              .from('profiles')
              .select('full_name, email')
              .eq('id', newMessage.sender_id)
              .maybeSingle();

            const senderName = sender?.full_name || sender?.email || 'Alguien';

            playNotificationSound('message');
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
