import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

export interface Message {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  is_read: boolean;
  created_at: string;
}

export interface Conversation {
  id: string;
  participant_id: string;
  subject: string | null;
  created_at: string;
  updated_at: string;
  participant?: {
    full_name: string | null;
    email: string;
  };
  lastMessage?: Message;
  unreadCount?: number;
}

export const useConversations = () => {
  const { user, isAdmin } = useAuth();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchConversations = async () => {
    if (!user) return;

    try {
      setLoading(true);
      
      let query = supabase
        .from('conversations')
        .select('*')
        .order('updated_at', { ascending: false });

      if (!isAdmin) {
        query = query.eq('participant_id', user.id);
      }

      const { data: convos, error: convosError } = await query;
      if (convosError) throw convosError;

      // Fetch unread counts from conversation_state
      const { data: unreadData } = await supabase
        .from('conversation_state')
        .select('conversation_id, unread_count')
        .eq('user_id', user.id);

      const unreadMap = new Map<string, number>();
      (unreadData || []).forEach((item: any) => {
        unreadMap.set(item.conversation_id, item.unread_count || 0);
      });

      const conversationsWithDetails = await Promise.all(
        (convos || []).map(async (conv) => {
          const { data: profile } = await supabase
            .from('profiles')
            .select('full_name, email')
            .eq('id', conv.participant_id)
            .single();

          const { data: lastMsg } = await supabase
            .from('messages')
            .select('*')
            .eq('conversation_id', conv.id)
            .order('created_at', { ascending: false })
            .limit(1)
            .single();

          return {
            ...conv,
            participant: profile || undefined,
            lastMessage: lastMsg || undefined,
            unreadCount: unreadMap.get(conv.id) || 0,
          };
        })
      );

      // Sort: unread first, then by updated_at
      conversationsWithDetails.sort((a, b) => {
        const aUnread = a.unreadCount || 0;
        const bUnread = b.unreadCount || 0;
        if (aUnread > 0 && bUnread === 0) return -1;
        if (aUnread === 0 && bUnread > 0) return 1;
        return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime();
      });

      setConversations(conversationsWithDetails);
    } catch (err) {
      console.error('Error fetching conversations:', err);
      setError('Error al cargar conversaciones');
    } finally {
      setLoading(false);
    }
  };

  const createConversation = async (subject?: string) => {
    if (!user) return null;

    try {
      const { data, error } = await supabase
        .from('conversations')
        .insert({
          participant_id: user.id,
          subject: subject || 'Nueva conversación',
        })
        .select()
        .single();

      if (error) throw error;

      await fetchConversations();
      return data;
    } catch (err) {
      console.error('Error creating conversation:', err);
      return null;
    }
  };

  useEffect(() => {
    fetchConversations();
  }, [user, isAdmin]);

  // Subscribe to realtime updates on both conversations and conversation_state
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('conversations-and-state')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'conversations' },
        () => fetchConversations()
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'conversation_state', filter: `user_id=eq.${user.id}` },
        () => fetchConversations()
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, isAdmin]);

  const deleteConversation = async (conversationId: string) => {
    if (!user) return false;

    try {
      // Delete messages first (foreign key constraint)
      await supabase
        .from('messages')
        .delete()
        .eq('conversation_id', conversationId);

      // Delete conversation_state
      await supabase
        .from('conversation_state')
        .delete()
        .eq('conversation_id', conversationId);

      // Delete conversation
      const { error } = await supabase
        .from('conversations')
        .delete()
        .eq('id', conversationId);

      if (error) throw error;

      await fetchConversations();
      return true;
    } catch (err) {
      console.error('Error deleting conversation:', err);
      return false;
    }
  };

  return {
    conversations,
    loading,
    error,
    createConversation,
    deleteConversation,
    refetch: fetchConversations,
  };
};

export const useMessages = (conversationId: string | null) => {
  const { user } = useAuth();
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchMessages = async () => {
    if (!conversationId) {
      setMessages([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true });

      if (error) throw error;
      setMessages(data || []);

      // Mark as read via conversation_state
      if (user) {
        await supabase
          .from('conversation_state')
          .update({ unread_count: 0, last_read_at: new Date().toISOString(), updated_at: new Date().toISOString() })
          .eq('conversation_id', conversationId)
          .eq('user_id', user.id);
      }
    } catch (err) {
      console.error('Error fetching messages:', err);
    } finally {
      setLoading(false);
    }
  };

  const sendMessage = async (content: string) => {
    if (!conversationId || !user || !content.trim()) return null;

    // Optimistic update
    const optimisticMsg: Message = {
      id: `temp-${Date.now()}`,
      conversation_id: conversationId,
      sender_id: user.id,
      content: content.trim(),
      is_read: false,
      created_at: new Date().toISOString(),
    };
    setMessages(prev => [...prev, optimisticMsg]);

    try {
      const { data, error } = await supabase
        .from('messages')
        .insert({
          conversation_id: conversationId,
          sender_id: user.id,
          content: content.trim(),
        })
        .select()
        .single();

      if (error) throw error;

      // Replace optimistic message with real one
      setMessages(prev => prev.map(m => m.id === optimisticMsg.id ? data : m));

      // Update conversation timestamp
      await supabase
        .from('conversations')
        .update({ updated_at: new Date().toISOString() })
        .eq('id', conversationId);

      return data;
    } catch (err) {
      console.error('Error sending message:', err);
      // Remove optimistic message on error
      setMessages(prev => prev.filter(m => m.id !== optimisticMsg.id));
      return null;
    }
  };

  useEffect(() => {
    fetchMessages();
  }, [conversationId, user]);

  // Subscribe to realtime messages
  useEffect(() => {
    if (!conversationId || !user) return;

    const channel = supabase
      .channel(`messages-${conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `conversation_id=eq.${conversationId}`,
        },
        (payload) => {
          const newMsg = payload.new as Message;
          // Only add if not from current user (we already have optimistic)
          if (newMsg.sender_id !== user.id) {
            setMessages(prev => [...prev, newMsg]);
            // Auto-mark as read since chat is open
            supabase
              .from('conversation_state')
              .update({ unread_count: 0, last_read_at: new Date().toISOString(), updated_at: new Date().toISOString() })
              .eq('conversation_id', conversationId)
              .eq('user_id', user.id)
              .then();
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversationId, user]);

  return {
    messages,
    loading,
    sendMessage,
    refetch: fetchMessages,
  };
};
