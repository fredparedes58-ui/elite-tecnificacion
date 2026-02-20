import React from 'react';
import { format, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  Clock, 
  User, 
  UserCheck, 
  UserMinus, 
  RefreshCw,
  ArrowRight,
  History
} from 'lucide-react';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Badge } from '@/components/ui/badge';
import { useSessionHistory } from '@/hooks/useSessionHistory';

interface SessionHistoryPanelProps {
  reservationId?: string;
}

const changeTypeConfig: Record<string, { 
  icon: React.ElementType; 
  label: string; 
  color: string;
}> = {
  time_changed: {
    icon: Clock,
    label: 'Horario',
    color: 'text-blue-400 bg-blue-500/10 border-blue-500/30',
  },
  trainer_changed: {
    icon: User,
    label: 'Entrenador',
    color: 'text-purple-400 bg-purple-500/10 border-purple-500/30',
  },
  player_assigned: {
    icon: UserCheck,
    label: 'Asignado',
    color: 'text-green-400 bg-green-500/10 border-green-500/30',
  },
  player_removed: {
    icon: UserMinus,
    label: 'Removido',
    color: 'text-red-400 bg-red-500/10 border-red-500/30',
  },
  player_changed: {
    icon: RefreshCw,
    label: 'Cambio',
    color: 'text-orange-400 bg-orange-500/10 border-orange-500/30',
  },
  status_changed: {
    icon: RefreshCw,
    label: 'Estado',
    color: 'text-yellow-400 bg-yellow-500/10 border-yellow-500/30',
  },
};

export const SessionHistoryPanel: React.FC<SessionHistoryPanelProps> = ({ 
  reservationId 
}) => {
  const { data: history, isLoading } = useSessionHistory(reservationId);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="w-6 h-6 border-2 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  if (!history || history.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-muted-foreground">
        <History className="w-8 h-8 mb-2 opacity-50" />
        <p className="text-sm">Sin historial de cambios</p>
      </div>
    );
  }

  return (
    <ScrollArea className="h-[300px]">
      <div className="space-y-3 pr-4">
        {history.map((change) => {
          const config = changeTypeConfig[change.change_type] || {
            icon: RefreshCw,
            label: 'Cambio',
            color: 'text-muted-foreground bg-muted/10 border-muted/30',
          };
          const Icon = config.icon;

          return (
            <div 
              key={change.id}
              className="p-3 rounded-lg border border-border bg-muted/20"
            >
              <div className="flex items-start gap-3">
                <div className={`p-2 rounded-lg ${config.color}`}>
                  <Icon className="w-4 h-4" />
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2 mb-1">
                    <Badge 
                      variant="outline" 
                      className={`text-xs ${config.color}`}
                    >
                      {config.label}
                    </Badge>
                    <span className="text-xs text-muted-foreground">
                      {format(parseISO(change.created_at), "dd MMM HH:mm", { locale: es })}
                    </span>
                  </div>
                  
                  <p className="text-sm text-foreground mb-1">
                    {change.description}
                  </p>
                  
                  <p className="text-xs text-muted-foreground">
                    por {change.admin_name}
                  </p>
                  
                  {/* Show old/new values for time changes */}
                  {change.change_type === 'time_changed' && change.old_value && change.new_value && (
                    <div className="flex items-center gap-2 mt-2 text-xs">
                      <span className="text-red-400/70 line-through">
                        {format(parseISO(change.old_value.start_time), "EEE dd/MM HH:mm", { locale: es })}
                      </span>
                      <ArrowRight className="w-3 h-3 text-muted-foreground" />
                      <span className="text-green-400">
                        {format(parseISO(change.new_value.start_time), "EEE dd/MM HH:mm", { locale: es })}
                      </span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </ScrollArea>
  );
};
