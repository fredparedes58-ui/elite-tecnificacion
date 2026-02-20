import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

interface ConversationUnread {
  conversation_id: string;
  unread_count: number;
}

export const useUnreadCounts = () => {
  const { user } = useAuth();
  const [perConversation, setPerConversation] = useState<ConversationUnread[]>([]);
  const [totalUnread, setTotalUnread] = useState(0);
  const [loading, setLoading] = useState(true);

  const fetchCounts = useCallback(async () => {
    if (!user) {
      setPerConversation([]);
      setTotalUnread(0);
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('conversation_state')
        .select('conversation_id, unread_count')
        .eq('user_id', user.id)
        .gt('unread_count', 0);

      if (error) throw error;

      const items = (data || []) as ConversationUnread[];
      setPerConversation(items);
      setTotalUnread(items.reduce((sum, item) => sum + item.unread_count, 0));
    } catch (err) {
      console.error('Error fetching unread counts:', err);
    } finally {
      setLoading(false);
    }
  }, [user]);

  const markAsRead = useCallback(async (conversationId: string) => {
    if (!user) return;

    // Optimistic update
    setPerConversation(prev => prev.filter(p => p.conversation_id !== conversationId));
    setTotalUnread(prev => {
      const item = perConversation.find(p => p.conversation_id === conversationId);
      return Math.max(0, prev - (item?.unread_count || 0));
    });

    try {
      const { error } = await supabase
        .from('conversation_state')
        .update({ unread_count: 0, last_read_at: new Date().toISOString(), updated_at: new Date().toISOString() })
        .eq('conversation_id', conversationId)
        .eq('user_id', user.id);

      if (error) throw error;
    } catch (err) {
      console.error('Error marking as read:', err);
      fetchCounts(); // Revert on error
    }
  }, [user, perConversation, fetchCounts]);

  const getUnreadForConversation = useCallback((conversationId: string) => {
    return perConversation.find(p => p.conversation_id === conversationId)?.unread_count || 0;
  }, [perConversation]);

  useEffect(() => {
    fetchCounts();
  }, [fetchCounts]);

  // Realtime subscription
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('unread-counts')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'conversation_state',
          filter: `user_id=eq.${user.id}`,
        },
        () => {
          fetchCounts();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, fetchCounts]);

  return {
    totalUnread,
    perConversation,
    loading,
    markAsRead,
    getUnreadForConversation,
    refetch: fetchCounts,
  };
};
