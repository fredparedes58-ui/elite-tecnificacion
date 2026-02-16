import { useState, useEffect, useCallback, useRef } from 'react';
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
  const initialFetchDone = useRef(false);

  const fetchConversations = useCallback(async () => {
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
  }, [user?.id, isAdmin]);

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

  // Initial fetch - only once
  useEffect(() => {
    if (!user || initialFetchDone.current) return;
    initialFetchDone.current = true;
    fetchConversations();
  }, [user?.id]);

  // Realtime: update state locally instead of full refetch
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('conversations-and-state')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'conversations' },
        () => fetchConversations() // New conversation needs full data
      )
      .on(
        'postgres_changes',
        { event: 'DELETE', schema: 'public', table: 'conversations' },
        (payload) => {
          const deletedId = (payload.old as any)?.id;
          if (deletedId) {
            setConversations(prev => prev.filter(c => c.id !== deletedId));
          }
        }
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'conversation_state', filter: `user_id=eq.${user.id}` },
        (payload) => {
          // Update unread count locally
          if (payload.eventType === 'UPDATE' || payload.eventType === 'INSERT') {
            const updated = payload.new as any;
            setConversations(prev => prev.map(c =>
              c.id === updated.conversation_id
                ? { ...c, unreadCount: updated.unread_count || 0 }
                : c
            ));
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user?.id, fetchConversations]);

  const deleteConversation = async (conversationId: string) => {
    if (!user) return false;

    try {
      await supabase.from('messages').delete().eq('conversation_id', conversationId);
      await supabase.from('conversation_state').delete().eq('conversation_id', conversationId);

      const { error } = await supabase
        .from('conversations')
        .delete()
        .eq('id', conversationId);

      if (error) throw error;

      // Optimistic removal (realtime will also fire)
      setConversations(prev => prev.filter(c => c.id !== conversationId));
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
  const [loading, setLoading] = useState(false);
  const hasFetched = useRef<string | null>(null);
  const userIdRef = useRef(user?.id);
  userIdRef.current = user?.id;

  const fetchMessages = useCallback(async () => {
    if (!conversationId) {
      setMessages([]);
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

      // Mark as read
      if (userIdRef.current) {
        supabase
          .from('conversation_state')
          .update({ unread_count: 0, last_read_at: new Date().toISOString(), updated_at: new Date().toISOString() })
          .eq('conversation_id', conversationId)
          .eq('user_id', userIdRef.current)
          .then();
      }
    } catch (err) {
      console.error('Error fetching messages:', err);
    } finally {
      setLoading(false);
    }
  }, [conversationId]);

  // Fetch only once per conversation change
  useEffect(() => {
    if (hasFetched.current === conversationId) return;
    hasFetched.current = conversationId;
    fetchMessages();
  }, [conversationId, fetchMessages]);

  const sendMessage = useCallback(async (content: string) => {
    if (!conversationId || !userIdRef.current || !content.trim()) return null;

    const optimisticMsg: Message = {
      id: `temp-${Date.now()}`,
      conversation_id: conversationId,
      sender_id: userIdRef.current,
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
          sender_id: userIdRef.current,
          content: content.trim(),
        })
        .select()
        .single();

      if (error) throw error;

      // Replace optimistic message with real one
      setMessages(prev => prev.map(m => m.id === optimisticMsg.id ? data : m));

      // Update conversation timestamp
      supabase
        .from('conversations')
        .update({ updated_at: new Date().toISOString() })
        .eq('id', conversationId)
        .then();

      return data;
    } catch (err) {
      console.error('Error sending message:', err);
      setMessages(prev => prev.filter(m => m.id !== optimisticMsg.id));
      return null;
    }
  }, [conversationId]);

  // Realtime: append only, no refetch
  useEffect(() => {
    if (!conversationId || !userIdRef.current) return;

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
          // Only append if not from current user (already handled optimistically)
          if (newMsg.sender_id !== userIdRef.current) {
            setMessages(prev => {
              // Deduplicate check
              if (prev.some(m => m.id === newMsg.id)) return prev;
              return [...prev, newMsg];
            });
            // Auto-mark as read
            supabase
              .from('conversation_state')
              .update({ unread_count: 0, last_read_at: new Date().toISOString(), updated_at: new Date().toISOString() })
              .eq('conversation_id', conversationId)
              .eq('user_id', userIdRef.current!)
              .then();
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversationId]);

  return {
    messages,
    loading,
    sendMessage,
    refetch: fetchMessages,
  };
};
