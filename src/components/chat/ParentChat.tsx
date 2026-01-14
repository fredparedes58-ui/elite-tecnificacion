import React, { useRef, useEffect } from 'react';
import { useConversations, useMessages } from '@/hooks/useConversations';
import { useAuth } from '@/contexts/AuthContext';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { MessageSquare, Send, Plus, Shield } from 'lucide-react';

const ParentChat: React.FC = () => {
  const { user } = useAuth();
  const { conversations, loading, createConversation } = useConversations();
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
    if (conversations.length > 0 && !selectedConversationId) {
      setSelectedConversationId(conversations[0].id);
    }
  }, [conversations, selectedConversationId]);

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

  const selectedConversation = conversations.find((c) => c.id === selectedConversationId);

  return (
    <div className="h-[600px]">
      <EliteCard className="h-full flex flex-col overflow-hidden">
        {/* Header */}
        <div className="p-4 border-b border-neon-cyan/20 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-neon-cyan to-neon-purple flex items-center justify-center">
              <Shield className="w-5 h-5 text-background" />
            </div>
            <div>
              <h3 className="font-orbitron font-semibold">Elite 380 Staff</h3>
              <p className="text-xs text-muted-foreground">
                {selectedConversation?.subject || 'Chat con el equipo'}
              </p>
            </div>
          </div>
          <NeonButton variant="outline" size="sm" onClick={handleNewConversation}>
            <Plus className="w-4 h-4 mr-1" />
            Nueva
          </NeonButton>
        </div>

        {conversations.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center text-center p-8">
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-neon-cyan/10 to-neon-purple/10 border border-neon-cyan/20 flex items-center justify-center mb-4">
              <MessageSquare className="w-10 h-10 text-neon-cyan/50" />
            </div>
            <h3 className="font-orbitron font-semibold text-lg mb-2">
              Inicia una conversación
            </h3>
            <p className="text-muted-foreground text-sm mb-4">
              Comunícate directamente con el staff de Elite 380
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
                            'max-w-[80%] rounded-2xl px-4 py-2',
                            isMe
                              ? 'bg-gradient-to-r from-neon-cyan to-neon-purple text-background'
                              : 'bg-muted/50 border border-neon-cyan/20'
                          )}
                        >
                          {!isMe && (
                            <p className="text-xs text-neon-purple font-semibold mb-1">
                              Staff Elite 380
                            </p>
                          )}
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
