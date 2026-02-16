import React from 'react';
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
  UserPlus,
  AlertTriangle,
  Loader2
} from 'lucide-react';

const AdminNotifications: React.FC = () => {
  const { user, isAdmin, isLoading: authLoading } = useAuth();
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

  if (!user || !isAdmin) {
    return <Navigate to="/" replace />;
  }

  // Filter notifications by type for admin
  const userNotifications = notifications.filter(n => 
    n.type === 'new_user' || n.type === 'new_player_pending'
  );
  const reservationNotifications = notifications.filter(n => 
    n.type === 'new_reservation_request'
  );
  const messageNotifications = notifications.filter(n => 
    n.type === 'new_message'
  );
  const systemNotifications = notifications.filter(n => 
    n.type.includes('system') || n.type.includes('alert')
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

  // Stats cards
  const stats = [
    { 
      label: 'Nuevos Usuarios', 
      count: userNotifications.filter(n => !n.is_read).length,
      icon: UserPlus,
      color: 'text-neon-purple'
    },
    { 
      label: 'Solicitudes Pendientes', 
      count: reservationNotifications.filter(n => !n.is_read).length,
      icon: Calendar,
      color: 'text-neon-cyan'
    },
    { 
      label: 'Mensajes Sin Leer', 
      count: messageNotifications.filter(n => !n.is_read).length,
      icon: MessageSquare,
      color: 'text-green-500'
    },
    { 
      label: 'Alertas', 
      count: systemNotifications.filter(n => !n.is_read).length,
      icon: AlertTriangle,
      color: 'text-yellow-500'
    },
  ];

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8 max-w-4xl">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center">
              <Bell className="w-6 h-6 text-neon-cyan" />
            </div>
            <div>
              <h1 className="font-orbitron font-bold text-2xl">Centro de Notificaciones</h1>
              <p className="text-sm text-muted-foreground">
                Panel de control para el administrador
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {unreadCount > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={markAllAsRead}
              >
                <CheckCheck className="w-4 h-4 mr-2" />
                Marcar todas como leídas
              </Button>
            )}
            {notifications.length > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={clearAllNotifications}
                className="text-destructive hover:text-destructive"
              >
                <Trash2 className="w-4 h-4 mr-2" />
                Limpiar todo
              </Button>
            )}
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className="bg-card/50 rounded-xl border border-border/50 p-4"
            >
              <div className="flex items-center gap-3">
                <div className={`p-2 rounded-lg bg-muted/50`}>
                  <stat.icon className={`w-5 h-5 ${stat.color}`} />
                </div>
                <div>
                  <p className="text-2xl font-orbitron font-bold">{stat.count}</p>
                  <p className="text-xs text-muted-foreground">{stat.label}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Tabs */}
        <Tabs defaultValue="all" className="w-full">
          <TabsList className="w-full grid grid-cols-5 mb-4">
            <TabsTrigger value="all">
              Todas
              {unreadCount > 0 && (
                <span className="ml-1.5 px-1.5 py-0.5 rounded-full bg-destructive text-destructive-foreground text-[10px]">
                  {unreadCount}
                </span>
              )}
            </TabsTrigger>
            <TabsTrigger value="users">
              <UserPlus className="w-4 h-4 mr-1" />
              Usuarios
            </TabsTrigger>
            <TabsTrigger value="reservations">
              <Calendar className="w-4 h-4 mr-1" />
              Reservas
            </TabsTrigger>
            <TabsTrigger value="messages">
              <MessageSquare className="w-4 h-4 mr-1" />
              Mensajes
            </TabsTrigger>
            <TabsTrigger value="system">
              <AlertTriangle className="w-4 h-4 mr-1" />
              Sistema
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
                <TabsContent value="users" className="m-0">
                  {renderNotificationList(userNotifications)}
                </TabsContent>
                <TabsContent value="reservations" className="m-0">
                  {renderNotificationList(reservationNotifications)}
                </TabsContent>
                <TabsContent value="messages" className="m-0">
                  {renderNotificationList(messageNotifications)}
                </TabsContent>
                <TabsContent value="system" className="m-0">
                  {renderNotificationList(systemNotifications)}
                </TabsContent>
              </>
            )}
          </div>
        </Tabs>
      </div>
    </Layout>
  );
};

export default AdminNotifications;
