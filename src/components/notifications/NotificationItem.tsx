import React from 'react';
import { useNavigate } from 'react-router-dom';
import { formatDistanceToNow } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  CheckCircle, 
  XCircle, 
  MessageSquare, 
  Wallet, 
  AlertTriangle, 
  UserPlus, 
  Calendar,
  Trash2,
  Circle
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { Notification } from '@/hooks/useNotificationsCenter';
import { Button } from '@/components/ui/button';

interface NotificationItemProps {
  notification: Notification;
  onMarkAsRead: (id: string) => void;
  onDelete?: (id: string) => void;
  compact?: boolean;
}

const getNotificationConfig = (type: string) => {
  switch (type) {
    case 'reservation_approved':
      return { 
        icon: CheckCircle, 
        color: 'text-green-500',
        bgColor: 'bg-green-500/10'
      };
    case 'reservation_rejected':
      return { 
        icon: XCircle, 
        color: 'text-destructive',
        bgColor: 'bg-destructive/10'
      };
    case 'new_message':
      return { 
        icon: MessageSquare, 
        color: 'text-neon-cyan',
        bgColor: 'bg-neon-cyan/10'
      };
    case 'credit_low':
      return { 
        icon: Wallet, 
        color: 'text-yellow-500',
        bgColor: 'bg-yellow-500/10'
      };
    case 'credit_exhausted':
      return { 
        icon: AlertTriangle, 
        color: 'text-destructive',
        bgColor: 'bg-destructive/10'
      };
    case 'new_user':
      return { 
        icon: UserPlus, 
        color: 'text-neon-purple',
        bgColor: 'bg-neon-purple/10'
      };
    case 'new_reservation_request':
      return { 
        icon: Calendar, 
        color: 'text-neon-cyan',
        bgColor: 'bg-neon-cyan/10'
      };
    case 'player_updated':
      return { 
        icon: UserPlus, 
        color: 'text-yellow-500',
        bgColor: 'bg-yellow-500/10'
      };
    case 'scouting_updated':
      return { 
        icon: CheckCircle, 
        color: 'text-green-500',
        bgColor: 'bg-green-500/10'
      };
    case 'session_updated':
    case 'session_player_removed':
      return { 
        icon: Calendar, 
        color: 'text-blue-500',
        bgColor: 'bg-blue-500/10'
      };
    case 'player_approved':
      return { 
        icon: CheckCircle, 
        color: 'text-green-500',
        bgColor: 'bg-green-500/10'
      };
    case 'player_rejected':
      return { 
        icon: XCircle, 
        color: 'text-destructive',
        bgColor: 'bg-destructive/10'
      };
    case 'new_player_pending':
      return { 
        icon: UserPlus, 
        color: 'text-yellow-500',
        bgColor: 'bg-yellow-500/10'
      };
    case 'reservation_proposal':
      return { 
        icon: MessageSquare, 
        color: 'text-neon-purple',
        bgColor: 'bg-neon-purple/10'
      };
    default:
      return { 
        icon: Circle, 
        color: 'text-muted-foreground',
        bgColor: 'bg-muted/10'
      };
  }
};

const getNavigationPath = (notification: Notification, isAdmin: boolean): string | null => {
  const metadata = notification.metadata as Record<string, string>;
  
  switch (notification.type) {
    case 'reservation_approved':
    case 'reservation_rejected':
      return isAdmin ? '/admin/reservations' : '/reservations';
    case 'new_reservation_request':
      return '/admin/reservations';
    case 'new_message':
      return isAdmin ? '/admin/chat' : '/chat';
    case 'new_user':
      return '/admin/users';
    case 'credit_low':
    case 'credit_exhausted':
      return isAdmin ? '/admin/reservations' : '/reservations';
    case 'player_updated':
    case 'scouting_updated':
      return isAdmin ? '/scouting' : '/players';
    case 'player_approved':
    case 'player_rejected':
      return '/players';
    case 'new_player_pending':
      return '/admin/player-approval';
    case 'session_updated':
    case 'session_player_removed':
      return isAdmin ? '/admin/reservations' : '/reservations';
    case 'reservation_proposal':
      return isAdmin ? '/admin/reservations' : '/reservations';
    default:
      return null;
  }
};

const NotificationItem: React.FC<NotificationItemProps> = ({
  notification,
  onMarkAsRead,
  onDelete,
  compact = false
}) => {
  const navigate = useNavigate();
  const config = getNotificationConfig(notification.type);
  const Icon = config.icon;

  const handleClick = () => {
    if (!notification.is_read) {
      onMarkAsRead(notification.id);
    }
    
    // Navigate based on notification type
    const path = getNavigationPath(notification, notification.type.includes('new_user') || notification.type.includes('new_reservation_request'));
    if (path) {
      navigate(path);
    }
  };

  const timeAgo = formatDistanceToNow(new Date(notification.created_at), {
    addSuffix: true,
    locale: es
  });

  return (
    <div
      className={cn(
        'relative flex items-start gap-3 p-3 cursor-pointer transition-all duration-200 hover:bg-muted/30',
        !notification.is_read && 'bg-neon-cyan/5',
        compact ? 'py-2' : 'py-4'
      )}
      onClick={handleClick}
    >
      {/* Unread indicator */}
      {!notification.is_read && (
        <div className="absolute left-1 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-neon-cyan shadow-[0_0_6px_rgba(0,240,255,0.8)]" />
      )}

      {/* Icon */}
      <div className={cn(
        'flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center',
        config.bgColor
      )}>
        <Icon className={cn('w-4 h-4', config.color)} />
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <p className={cn(
          'font-rajdhani font-semibold text-sm leading-tight',
          !notification.is_read ? 'text-foreground' : 'text-muted-foreground'
        )}>
          {notification.title}
        </p>
        <p className="text-xs text-muted-foreground mt-0.5 line-clamp-2">
          {notification.message}
        </p>
        <p className="text-[10px] text-muted-foreground/70 mt-1">
          {timeAgo}
        </p>
      </div>

      {/* Delete button (only in full view) */}
      {!compact && onDelete && (
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8 text-muted-foreground hover:text-destructive"
          onClick={(e) => {
            e.stopPropagation();
            onDelete(notification.id);
          }}
        >
          <Trash2 className="w-4 h-4" />
        </Button>
      )}
    </div>
  );
};

export default NotificationItem;
