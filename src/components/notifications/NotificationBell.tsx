import React from 'react';
import { Link } from 'react-router-dom';
import { Bell } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { useNotificationsCenter } from '@/hooks/useNotificationsCenter';
import { cn } from '@/lib/utils';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';
import NotificationItem from './NotificationItem';

const NotificationBell: React.FC = () => {
  const { user, isAdmin } = useAuth();
  const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotificationsCenter();
  const [isOpen, setIsOpen] = React.useState(false);

  if (!user) return null;

  const recentNotifications = notifications.slice(0, 5);
  const notificationsPath = isAdmin ? '/admin/notifications' : '/notifications';

  return (
    <Popover open={isOpen} onOpenChange={setIsOpen}>
      <PopoverTrigger asChild>
        <button
          className={cn(
            'relative p-2 rounded-lg transition-all duration-200',
            'hover:bg-muted/50',
            unreadCount > 0 && 'text-neon-cyan'
          )}
        >
          <Bell className={cn(
            'w-5 h-5',
            unreadCount > 0 && 'animate-pulse'
          )} />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-destructive text-destructive-foreground text-xs font-bold flex items-center justify-center shadow-lg">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </button>
      </PopoverTrigger>
      <PopoverContent 
        className="w-80 p-0 bg-background/95 backdrop-blur-xl border-neon-cyan/20"
        align="end"
      >
        <div className="flex items-center justify-between p-3 border-b border-border/50">
          <h3 className="font-rajdhani font-bold text-sm">Notificaciones</h3>
          {unreadCount > 0 && (
            <button
              onClick={() => markAllAsRead()}
              className="text-xs text-muted-foreground hover:text-neon-cyan transition-colors"
            >
              Marcar todas como leídas
            </button>
          )}
        </div>

        <ScrollArea className="max-h-80">
          {recentNotifications.length === 0 ? (
            <div className="p-6 text-center text-muted-foreground text-sm">
              No tienes notificaciones
            </div>
          ) : (
            <div className="divide-y divide-border/30">
              {recentNotifications.map((notification) => (
                <NotificationItem
                  key={notification.id}
                  notification={notification}
                  onMarkAsRead={markAsRead}
                  compact
                />
              ))}
            </div>
          )}
        </ScrollArea>

        <div className="p-2 border-t border-border/50">
          <Link to={notificationsPath} onClick={() => setIsOpen(false)}>
            <Button variant="ghost" className="w-full text-sm">
              Ver todas las notificaciones
            </Button>
          </Link>
        </div>
      </PopoverContent>
    </Popover>
  );
};

export default NotificationBell;
