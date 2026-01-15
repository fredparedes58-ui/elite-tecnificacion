import React, { useState, useEffect } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import Layout from '@/components/layout/Layout';
import ReservationManagement from '@/components/admin/ReservationManagement';
import ReservationCalendarView from '@/components/admin/ReservationCalendarView';
import WeeklyScheduleView from '@/components/admin/WeeklyScheduleView';
import TrainerManagement from '@/components/admin/TrainerManagement';
import AttendanceReports from '@/components/admin/AttendanceReports';
import PlayerDirectory from '@/components/admin/PlayerDirectory';
import PlayerCreditsView from '@/components/admin/PlayerCreditsView';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Calendar, List, Users, BarChart3, UserCircle, CalendarDays, CreditCard, Wifi } from 'lucide-react';
import { useAllReservations } from '@/hooks/useReservations';
import { useTrainers } from '@/hooks/useTrainers';
import { usePlayers } from '@/hooks/usePlayers';

const AdminReservations: React.FC = () => {
  const { isAdmin, isLoading } = useAuth();
  const [activeTab, setActiveTab] = useState('weekly');
  const [realtimeFlash, setRealtimeFlash] = useState(false);

  // Centralized data fetching - data is cached and shared across all tabs
  const { 
    reservations, 
    loading: reservationsLoading, 
    updateReservation, 
    updateReservationStatus, 
    createReservation, 
    deleteReservation,
    refetch: refetchReservations,
    isRealtimeConnected,
    lastRealtimeUpdate,
  } = useAllReservations();
  const { trainers, loading: trainersLoading } = useTrainers();
  const { players, isLoading: playersLoading, refetch: refetchPlayers } = usePlayers();

  // Combined loading state for initial load only
  const initialLoading = reservationsLoading && trainersLoading && playersLoading;

  // Flash effect when realtime updates occur
  useEffect(() => {
    if (lastRealtimeUpdate) {
      setRealtimeFlash(true);
      const timeout = setTimeout(() => setRealtimeFlash(false), 1500);
      return () => clearTimeout(timeout);
    }
  }, [lastRealtimeUpdate]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAdmin) {
    return <Navigate to="/" replace />;
  }

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8">
        <div className="mb-6 flex items-start justify-between flex-wrap gap-4">
          <div>
            <h1 className="font-orbitron font-bold text-3xl gradient-text mb-2">
              Gestión de Reservas
            </h1>
            <p className="text-muted-foreground font-rajdhani">
              Administra sesiones, entrenadores y horarios
            </p>
          </div>
          
          {/* Real-time connection indicator */}
          <Badge 
            variant="outline" 
            className={`flex items-center gap-2 transition-all duration-300 ${
              isRealtimeConnected 
                ? realtimeFlash 
                  ? 'bg-green-500/30 border-green-400 text-green-300 animate-pulse' 
                  : 'bg-green-500/10 border-green-500/30 text-green-400'
                : 'bg-yellow-500/10 border-yellow-500/30 text-yellow-400'
            }`}
          >
            <Wifi className={`w-3.5 h-3.5 ${isRealtimeConnected ? '' : 'opacity-50'}`} />
            <span className="text-xs font-medium">
              {isRealtimeConnected ? 'Tiempo Real' : 'Conectando...'}
            </span>
          </Badge>
        </div>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
          <TabsList className="bg-card border border-neon-cyan/20 flex-wrap h-auto gap-1 p-1">
            <TabsTrigger value="weekly" className="data-[state=active]:bg-neon-cyan/20 data-[state=active]:text-neon-cyan">
              <CalendarDays className="w-4 h-4 mr-2" />
              Semanal
            </TabsTrigger>
            <TabsTrigger value="calendar" className="data-[state=active]:bg-neon-cyan/20 data-[state=active]:text-neon-cyan">
              <Calendar className="w-4 h-4 mr-2" />
              Calendario
            </TabsTrigger>
            <TabsTrigger value="list" className="data-[state=active]:bg-neon-cyan/20 data-[state=active]:text-neon-cyan">
              <List className="w-4 h-4 mr-2" />
              Lista
            </TabsTrigger>
            <TabsTrigger value="players" className="data-[state=active]:bg-neon-purple/20 data-[state=active]:text-neon-purple">
              <UserCircle className="w-4 h-4 mr-2" />
              Jugadores
            </TabsTrigger>
            <TabsTrigger value="credits" className="data-[state=active]:bg-green-500/20 data-[state=active]:text-green-400">
              <CreditCard className="w-4 h-4 mr-2" />
              Créditos
            </TabsTrigger>
            <TabsTrigger value="trainers" className="data-[state=active]:bg-neon-purple/20 data-[state=active]:text-neon-purple">
              <Users className="w-4 h-4 mr-2" />
              Entrenadores
            </TabsTrigger>
            <TabsTrigger value="reports" className="data-[state=active]:bg-green-500/20 data-[state=active]:text-green-400">
              <BarChart3 className="w-4 h-4 mr-2" />
              Reportes
            </TabsTrigger>
          </TabsList>

          {/* Use forceMount + hidden class to keep components mounted */}
          <TabsContent value="weekly" forceMount className={activeTab !== 'weekly' ? 'hidden' : 'mt-0'}>
            <WeeklyScheduleView 
              reservations={reservations}
              reservationsLoading={reservationsLoading}
              trainers={trainers}
              players={players}
              updateReservation={updateReservation}
              createReservation={createReservation}
              deleteReservation={deleteReservation}
              refetch={refetchReservations}
            />
          </TabsContent>

          <TabsContent value="calendar" forceMount className={activeTab !== 'calendar' ? 'hidden' : 'mt-0'}>
            <ReservationCalendarView 
              reservations={reservations}
              reservationsLoading={reservationsLoading}
              trainers={trainers}
              players={players}
              updateReservation={updateReservation}
              updateReservationStatus={updateReservationStatus}
              refetch={refetchReservations}
            />
          </TabsContent>

          <TabsContent value="list" forceMount className={activeTab !== 'list' ? 'hidden' : 'mt-0'}>
            <ReservationManagement 
              reservations={reservations}
              loading={reservationsLoading}
              updateReservationStatus={updateReservationStatus}
            />
          </TabsContent>

          <TabsContent value="players" forceMount className={activeTab !== 'players' ? 'hidden' : 'mt-0'}>
            <PlayerDirectory />
          </TabsContent>

          <TabsContent value="credits" forceMount className={activeTab !== 'credits' ? 'hidden' : 'mt-0'}>
            <PlayerCreditsView />
          </TabsContent>

          <TabsContent value="trainers" forceMount className={activeTab !== 'trainers' ? 'hidden' : 'mt-0'}>
            <TrainerManagement />
          </TabsContent>

          <TabsContent value="reports" forceMount className={activeTab !== 'reports' ? 'hidden' : 'mt-0'}>
            <AttendanceReports 
              reservations={reservations}
              reservationsLoading={reservationsLoading}
              trainers={trainers}
              players={players}
            />
          </TabsContent>
        </Tabs>
      </div>
    </Layout>
  );
};

export default AdminReservations;
