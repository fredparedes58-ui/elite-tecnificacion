import React from 'react';
import BackButton from '@/components/layout/BackButton';
import { Navigate } from 'react-router-dom';
import Layout from '@/components/layout/Layout';
import { useAuth } from '@/contexts/AuthContext';
import { useNotificationsCenter } from '@/hooks/useNotificationsCenter';
import NotificationItem from '@/components/notifications/NotificationItem';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Bell, 
  CheckCheck, 
  Trash2, 
  Calendar, 
  MessageSquare, 
  Wallet,
  Loader2
} from 'lucide-react';
import { cn } from '@/lib/utils';

const Notifications: React.FC = () => {
  const { user, isApproved, isLoading: authLoading } = useAuth();
  const {
    notifications, 
    unreadCount, 
    isLoading, 
    markAsRead, 
    markAllAsRead, 
    deleteNotification,
    clearAllNotifications 
  } = useNotificationsCenter();

  if (authLoading) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-[50vh]">
          <Loader2 className="w-8 h-8 animate-spin text-neon-cyan" />
        </div>
      </Layout>
    );
  }

  if (!user || !isApproved) {
    return <Navigate to="/auth" replace />;
  }

  // Filter notifications by type
  const reservationNotifications = notifications.filter(n => 
    n.type.includes('reservation')
  );
  const messageNotifications = notifications.filter(n => 
    n.type === 'new_message'
  );
  const creditNotifications = notifications.filter(n => 
    n.type.includes('credit')
  );

  const renderNotificationList = (items: typeof notifications) => {
    if (items.length === 0) {
      return (
        <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
          <Bell className="w-12 h-12 mb-4 opacity-30" />
          <p className="text-sm">No hay notificaciones</p>
        </div>
      );
    }

    return (
      <div className="divide-y divide-border/30">
        {items.map((notification) => (
          <NotificationItem
            key={notification.id}
            notification={notification}
            onMarkAsRead={markAsRead}
            onDelete={deleteNotification}
          />
        ))}
      </div>
    );
  };

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8 max-w-2xl">
        {/* Header */}
        <BackButton className="mb-4" />
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center">
              <Bell className="w-5 h-5 text-neon-cyan" />
            </div>
            <div>
              <h1 className="font-orbitron font-bold text-xl">Notificaciones</h1>
              {unreadCount > 0 && (
                <p className="text-xs text-muted-foreground">
                  {unreadCount} sin leer
                </p>
              )}
            </div>
          </div>

          <div className="flex items-center gap-2">
            {unreadCount > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={markAllAsRead}
                className="text-xs"
              >
                <CheckCheck className="w-4 h-4 mr-1" />
                Marcar leídas
              </Button>
            )}
            {notifications.length > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={clearAllNotifications}
                className="text-xs text-destructive hover:text-destructive"
              >
                <Trash2 className="w-4 h-4 mr-1" />
                Limpiar
              </Button>
            )}
          </div>
        </div>

        {/* Tabs */}
        <Tabs defaultValue="all" className="w-full">
          <TabsList className="w-full grid grid-cols-4 mb-4">
            <TabsTrigger value="all" className="text-xs">
              Todas
              {unreadCount > 0 && (
                <span className="ml-1.5 px-1.5 py-0.5 rounded-full bg-destructive text-destructive-foreground text-[10px]">
                  {unreadCount}
                </span>
              )}
            </TabsTrigger>
            <TabsTrigger value="reservations" className="text-xs">
              <Calendar className="w-3.5 h-3.5 mr-1" />
              Reservas
            </TabsTrigger>
            <TabsTrigger value="messages" className="text-xs">
              <MessageSquare className="w-3.5 h-3.5 mr-1" />
              Mensajes
            </TabsTrigger>
            <TabsTrigger value="credits" className="text-xs">
              <Wallet className="w-3.5 h-3.5 mr-1" />
              Créditos
            </TabsTrigger>
          </TabsList>

          <div className="bg-card/50 rounded-xl border border-border/50 overflow-hidden">
            {isLoading ? (
              <div className="flex items-center justify-center py-12">
                <Loader2 className="w-6 h-6 animate-spin text-neon-cyan" />
              </div>
            ) : (
              <>
                <TabsContent value="all" className="m-0">
                  {renderNotificationList(notifications)}
                </TabsContent>
                <TabsContent value="reservations" className="m-0">
                  {renderNotificationList(reservationNotifications)}
                </TabsContent>
                <TabsContent value="messages" className="m-0">
                  {renderNotificationList(messageNotifications)}
                </TabsContent>
                <TabsContent value="credits" className="m-0">
                  {renderNotificationList(creditNotifications)}
                </TabsContent>
              </>
            )}
          </div>
        </Tabs>
      </div>
    </Layout>
  );
};

export default Notifications;
