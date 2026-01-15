import React, { useRef, useEffect, useState } from 'react';
import { useConversations, useMessages, Conversation } from '@/hooks/useConversations';
import { useAuth } from '@/contexts/AuthContext';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { MessageSquare, Send, User, Search, X } from 'lucide-react';

const ChatConsole: React.FC = () => {
  const { user } = useAuth();
  const { conversations, loading } = useConversations();
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null);
  const { messages, sendMessage } = useMessages(selectedConversation?.id || null);
  const [newMessage, setNewMessage] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Filter conversations by search query
  const filteredConversations = conversations.filter((conv) => {
    if (!searchQuery.trim()) return true;
    const searchLower = searchQuery.toLowerCase();
    return (
      conv.participant?.full_name?.toLowerCase().includes(searchLower) ||
      conv.participant?.email?.toLowerCase().includes(searchLower) ||
      conv.subject?.toLowerCase().includes(searchLower)
    );
  });

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async () => {
    if (!newMessage.trim()) return;
    await sendMessage(newMessage);
    setNewMessage('');
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-12 h-12 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="font-orbitron font-bold text-2xl gradient-text">
          Consola de Chats
        </h2>
        <StatusBadge variant="info">
          {searchQuery ? `${filteredConversations.length} de ${conversations.length}` : `${conversations.length}`} conversaciones
        </StatusBadge>
      </div>

      <div className="grid lg:grid-cols-3 gap-6 h-[600px]">
        {/* Conversations List */}
        <EliteCard className="lg:col-span-1 flex flex-col overflow-hidden">
          <div className="p-4 border-b border-neon-cyan/20 space-y-3">
            <h3 className="font-orbitron font-semibold text-sm text-muted-foreground">
              Conversaciones
            </h3>
            {/* Search Input */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Buscar padre o email..."
                className="pl-9 pr-9 bg-muted/50 border-neon-cyan/30"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>
          <ScrollArea className="flex-1">
            <div className="p-2 space-y-2">
              {filteredConversations.length === 0 ? (
                <p className="text-center text-muted-foreground text-sm py-8">
                  {searchQuery ? 'No se encontraron conversaciones' : 'No hay conversaciones'}
                </p>
              ) : (
                filteredConversations.map((conv) => (
                  <button
                    key={conv.id}
                    onClick={() => setSelectedConversation(conv)}
                    className={cn(
                      'w-full p-3 rounded-lg text-left transition-all duration-200',
                      selectedConversation?.id === conv.id
                        ? 'bg-neon-cyan/10 border border-neon-cyan/30'
                        : 'hover:bg-muted/50 border border-transparent'
                    )}
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center flex-shrink-0">
                        <User className="w-5 h-5 text-neon-cyan" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between">
                          <span className="font-rajdhani font-medium text-sm truncate">
                            {conv.participant?.full_name || 'Usuario'}
                          </span>
                          {(conv.unreadCount || 0) > 0 && (
                            <span className="w-5 h-5 rounded-full bg-neon-purple text-xs flex items-center justify-center">
                              {conv.unreadCount}
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-muted-foreground truncate">
                          {conv.lastMessage?.content || conv.subject || 'Sin mensajes'}
                        </p>
                      </div>
                    </div>
                  </button>
                ))
              )}
            </div>
          </ScrollArea>
        </EliteCard>

        {/* Chat View */}
        <EliteCard className="lg:col-span-2 flex flex-col overflow-hidden">
          {selectedConversation ? (
            <>
              {/* Header */}
              <div className="p-4 border-b border-neon-cyan/20 flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center">
                  <User className="w-5 h-5 text-neon-cyan" />
                </div>
                <div>
                  <h3 className="font-orbitron font-semibold">
                    {selectedConversation.participant?.full_name || 'Usuario'}
                  </h3>
                  <p className="text-xs text-muted-foreground">
                    {selectedConversation.participant?.email}
                  </p>
                </div>
              </div>

              {/* Messages */}
              <ScrollArea className="flex-1 p-4">
                <div className="space-y-4">
                  {messages.map((msg) => {
                    const isMe = msg.sender_id === user?.id;
                    return (
                      <div
                        key={msg.id}
                        className={cn(
                          'flex',
                          isMe ? 'justify-end' : 'justify-start'
                        )}
                      >
                        <div
                          className={cn(
                            'max-w-[70%] rounded-2xl px-4 py-2',
                            isMe
                              ? 'bg-gradient-to-r from-neon-cyan to-neon-purple text-background'
                              : 'bg-muted/50 border border-neon-cyan/20'
                          )}
                        >
                          <p className="font-rajdhani text-sm">{msg.content}</p>
                          <p
                            className={cn(
                              'text-xs mt-1',
                              isMe ? 'text-background/70' : 'text-muted-foreground'
                            )}
                          >
                            {format(new Date(msg.created_at), 'HH:mm', { locale: es })}
                          </p>
                        </div>
                      </div>
                    );
                  })}
                  <div ref={messagesEndRef} />
                </div>
              </ScrollArea>

              {/* Input */}
              <div className="p-4 border-t border-neon-cyan/20">
                <div className="flex gap-3">
                  <Input
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    onKeyPress={handleKeyPress}
                    placeholder="Escribe un mensaje..."
                    className="flex-1 bg-muted/50 border-neon-cyan/30"
                  />
                  <NeonButton variant="gradient" onClick={handleSend}>
                    <Send className="w-4 h-4" />
                  </NeonButton>
                </div>
              </div>
            </>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center text-center p-8">
              <div className="w-20 h-20 rounded-full bg-gradient-to-br from-neon-cyan/10 to-neon-purple/10 border border-neon-cyan/20 flex items-center justify-center mb-4">
                <MessageSquare className="w-10 h-10 text-neon-cyan/50" />
              </div>
              <h3 className="font-orbitron font-semibold text-lg mb-2">
                Selecciona una conversación
              </h3>
              <p className="text-muted-foreground text-sm">
                Elige una conversación de la lista para ver los mensajes
              </p>
            </div>
          )}
        </EliteCard>
      </div>
    </div>
  );
};

export default ChatConsole;
