import React, { useRef, useEffect } from 'react';
import { useConversations, useMessages } from '@/hooks/useConversations';
import { useUnreadCounts } from '@/hooks/useUnreadCounts';
import { useAuth } from '@/contexts/AuthContext';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { MessageSquare, Send, Plus, User } from 'lucide-react';

const ParentChat: React.FC = () => {
  const { user } = useAuth();
  const { conversations, loading, createConversation } = useConversations();
  const { markAsRead, getUnreadForConversation } = useUnreadCounts();
  const hasAutoSelected = useRef(false);
  const [selectedConversationId, setSelectedConversationId] = React.useState<string | null>(null);
  const { messages, sendMessage } = useMessages(selectedConversationId);
  const [newMessage, setNewMessage] = React.useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  useEffect(() => {
    if (!hasAutoSelected.current && conversations.length > 0 && !selectedConversationId) {
      hasAutoSelected.current = true;
      const firstConv = conversations[0];
      setSelectedConversationId(firstConv.id);
      markAsRead(firstConv.id);
    }
  }, [conversations]);

  const handleSelectConversation = (convId: string) => {
    setSelectedConversationId(convId);
    markAsRead(convId);
  };

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

  const handleNewConversation = async () => {
    const conv = await createConversation('Consulta general');
    if (conv) {
      setSelectedConversationId(conv.id);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-12 h-12 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  const hasMultipleConversations = conversations.length > 1;

  return (
    <div className="h-[600px]">
      <EliteCard className="h-full flex flex-col overflow-hidden">
        {/* Header */}
        <div className="p-4 border-b border-neon-cyan/20 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="relative">
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-neon-cyan to-neon-purple flex items-center justify-center">
                <User className="w-6 h-6 text-background" />
              </div>
              <div className="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-green-500 border-2 border-background" />
            </div>
            <div>
              <h3 className="font-orbitron font-semibold">Pedro</h3>
              <p className="text-xs text-muted-foreground">Director de Elite 380</p>
              <p className="text-xs text-green-400 flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-green-400" />
                En línea
              </p>
            </div>
          </div>
          <NeonButton variant="outline" size="sm" onClick={handleNewConversation}>
            <Plus className="w-4 h-4 mr-1" />
            Nueva
          </NeonButton>
        </div>

        {/* Conversation tabs if multiple */}
        {hasMultipleConversations && (
          <div className="flex gap-1 p-2 border-b border-neon-cyan/10 overflow-x-auto">
            {conversations.map((conv) => {
              const unread = getUnreadForConversation(conv.id);
              return (
                <button
                  key={conv.id}
                  onClick={() => handleSelectConversation(conv.id)}
                  className={cn(
                    'px-3 py-1.5 rounded-full text-xs font-rajdhani font-medium whitespace-nowrap transition-all relative',
                    selectedConversationId === conv.id
                      ? 'bg-neon-cyan/20 text-neon-cyan border border-neon-cyan/30'
                      : 'bg-muted/30 text-muted-foreground hover:bg-muted/50'
                  )}
                >
                  {conv.subject || 'Chat'}
                  {unread > 0 && (
                    <span className="ml-1.5 inline-flex items-center justify-center min-w-[16px] h-[16px] rounded-full bg-destructive text-destructive-foreground text-[9px] font-bold px-1">
                      {unread}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        )}

        {conversations.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center text-center p-8">
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-neon-cyan/10 to-neon-purple/10 border border-neon-cyan/20 flex items-center justify-center mb-4">
              <MessageSquare className="w-10 h-10 text-neon-cyan/50" />
            </div>
            <h3 className="font-orbitron font-semibold text-lg mb-2">
              Inicia una conversación con Pedro
            </h3>
            <p className="text-muted-foreground text-sm mb-4">
              Comunícate directamente con el director de Elite 380
            </p>
            <NeonButton variant="gradient" onClick={handleNewConversation}>
              <Plus className="w-4 h-4 mr-2" />
              Nueva Conversación
            </NeonButton>
          </div>
        ) : (
          <>
            {/* Messages */}
            <ScrollArea className="flex-1 p-4">
              <div className="space-y-4">
                {messages.length === 0 ? (
                  <div className="text-center py-8">
                    <p className="text-muted-foreground text-sm">
                      Envía un mensaje para iniciar la conversación
                    </p>
                  </div>
                ) : (
                  messages.map((msg) => {
                    const isMe = msg.sender_id === user?.id;
                    const isOptimistic = msg.id.startsWith('temp-');
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
                            'max-w-[80%] rounded-2xl px-4 py-2 transition-opacity',
                            isMe
                              ? 'bg-gradient-to-r from-neon-cyan to-neon-purple text-background'
                              : 'bg-muted/50 border border-neon-cyan/20',
                            isOptimistic && 'opacity-70'
                          )}
                        >
                          {!isMe && (
                            <p className="text-xs text-neon-purple font-semibold mb-1">
                              Pedro
                            </p>
                          )}
                          <p className="font-rajdhani text-sm">{msg.content}</p>
                          <p
                            className={cn(
                              'text-xs mt-1',
                              isMe ? 'text-background/70' : 'text-muted-foreground'
                            )}
                          >
                            {isOptimistic ? 'Enviando...' : format(new Date(msg.created_at), 'HH:mm', { locale: es })}
                          </p>
                        </div>
                      </div>
                    );
                  })
                )}
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
        )}
      </EliteCard>
    </div>
  );
};

export default ParentChat;
