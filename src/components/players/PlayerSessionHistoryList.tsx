import React from 'react';
import { format, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  Calendar, 
  Clock, 
  MessageSquare, 
  User, 
  CheckCircle, 
  XCircle,
  AlertCircle,
  History
} from 'lucide-react';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Badge } from '@/components/ui/badge';
import { EliteCard } from '@/components/ui/EliteCard';
import { usePlayerSessionHistory, PlayerSession } from '@/hooks/usePlayerSessionHistory';

interface PlayerSessionHistoryListProps {
  playerId: string;
}

const getStatusConfig = (status: string) => {
  switch (status) {
    case 'completed':
      return {
        icon: CheckCircle,
        label: 'Completada',
        color: 'text-green-400 bg-green-500/10 border-green-500/30',
      };
    case 'no_show':
      return {
        icon: XCircle,
        label: 'No asistió',
        color: 'text-red-400 bg-red-500/10 border-red-500/30',
      };
    case 'approved':
      return {
        icon: AlertCircle,
        label: 'Programada',
        color: 'text-blue-400 bg-blue-500/10 border-blue-500/30',
      };
    default:
      return {
        icon: History,
        label: status,
        color: 'text-muted-foreground bg-muted/10 border-muted/30',
      };
  }
};

const PlayerSessionHistoryList: React.FC<PlayerSessionHistoryListProps> = ({ playerId }) => {
  const { data: sessions, isLoading } = usePlayerSessionHistory(playerId);

  if (isLoading) {
    return (
      <EliteCard className="p-6">
        <div className="flex items-center justify-center h-48">
          <div className="w-8 h-8 border-2 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
        </div>
      </EliteCard>
    );
  }

  if (!sessions || sessions.length === 0) {
    return (
      <EliteCard className="p-6">
        <div className="flex items-center gap-3 mb-4">
          <History className="w-5 h-5 text-neon-purple" />
          <h3 className="font-orbitron font-semibold text-lg">Historial de Sesiones</h3>
        </div>
        <div className="flex flex-col items-center justify-center h-32 text-muted-foreground">
          <Calendar className="w-10 h-10 mb-2 opacity-50" />
          <p className="text-sm">No hay sesiones registradas</p>
        </div>
      </EliteCard>
    );
  }

  const completedCount = sessions.filter(s => s.status === 'completed').length;
  const noShowCount = sessions.filter(s => s.status === 'no_show').length;

  return (
    <EliteCard className="p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <History className="w-5 h-5 text-neon-purple" />
          <h3 className="font-orbitron font-semibold text-lg">Historial de Sesiones</h3>
        </div>
        <div className="flex gap-2">
          <Badge variant="outline" className="text-green-400 bg-green-500/10 border-green-500/30">
            {completedCount} completadas
          </Badge>
          {noShowCount > 0 && (
            <Badge variant="outline" className="text-red-400 bg-red-500/10 border-red-500/30">
              {noShowCount} ausencias
            </Badge>
          )}
        </div>
      </div>

      <ScrollArea className="h-[350px]">
        <div className="space-y-3 pr-4">
          {sessions.map((session) => {
            const config = getStatusConfig(session.status);
            const Icon = config.icon;
            const sessionDate = parseISO(session.start_time);
            const endTime = parseISO(session.end_time);

            return (
              <div 
                key={session.id}
                className="p-4 rounded-lg border border-border bg-muted/20 hover:bg-muted/30 transition-colors"
              >
                {/* Header */}
                <div className="flex items-start justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <div className={`p-1.5 rounded-lg ${config.color}`}>
                      <Icon className="w-4 h-4" />
                    </div>
                    <div>
                      <h4 className="font-rajdhani font-semibold text-foreground">
                        {session.title}
                      </h4>
                      <Badge 
                        variant="outline" 
                        className={`text-xs mt-1 ${config.color}`}
                      >
                        {config.label}
                      </Badge>
                    </div>
                  </div>
                  <div className="text-right text-xs text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      {format(sessionDate, "dd MMM yyyy", { locale: es })}
                    </div>
                    <div className="flex items-center gap-1 mt-1">
                      <Clock className="w-3 h-3" />
                      {format(sessionDate, "HH:mm")} - {format(endTime, "HH:mm")}
                    </div>
                  </div>
                </div>

                {/* Trainer */}
                {session.trainer_name && (
                  <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
                    <User className="w-3 h-3" />
                    <span>Entrenador: {session.trainer_name}</span>
                  </div>
                )}

                {/* Trainer Comments */}
                {session.trainer_comments && (
                  <div className="mt-3 p-3 rounded-lg bg-neon-purple/5 border border-neon-purple/20">
                    <div className="flex items-center gap-2 mb-2">
                      <MessageSquare className="w-4 h-4 text-neon-purple" />
                      <span className="text-xs font-semibold text-neon-purple">
                        Comentarios del Entrenador
                      </span>
                    </div>
                    <p className="text-sm text-foreground/90 leading-relaxed">
                      {session.trainer_comments}
                    </p>
                  </div>
                )}

                {/* Description if no comments */}
                {!session.trainer_comments && session.description && (
                  <p className="text-sm text-muted-foreground mt-2">
                    {session.description}
                  </p>
                )}
              </div>
            );
          })}
        </div>
      </ScrollArea>
    </EliteCard>
  );
};

export default PlayerSessionHistoryList;
