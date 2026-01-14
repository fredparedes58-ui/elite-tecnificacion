import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import Layout from '@/components/layout/Layout';
import ReservationManagement from '@/components/admin/ReservationManagement';
import ReservationCalendarView from '@/components/admin/ReservationCalendarView';
import TrainerManagement from '@/components/admin/TrainerManagement';
import AttendanceReports from '@/components/admin/AttendanceReports';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Calendar, List, Users, BarChart3 } from 'lucide-react';

const AdminReservations: React.FC = () => {
  const { isAdmin, isLoading } = useAuth();
  const [activeTab, setActiveTab] = useState('calendar');

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
        <div className="mb-6">
          <h1 className="font-orbitron font-bold text-3xl gradient-text mb-2">
            Gestión de Reservas
          </h1>
          <p className="text-muted-foreground font-rajdhani">
            Administra sesiones, entrenadores y horarios
          </p>
        </div>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
          <TabsList className="bg-card border border-neon-cyan/20">
            <TabsTrigger value="calendar" className="data-[state=active]:bg-neon-cyan/20 data-[state=active]:text-neon-cyan">
              <Calendar className="w-4 h-4 mr-2" />
              Calendario
            </TabsTrigger>
            <TabsTrigger value="list" className="data-[state=active]:bg-neon-cyan/20 data-[state=active]:text-neon-cyan">
              <List className="w-4 h-4 mr-2" />
              Lista
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

          <TabsContent value="calendar" className="mt-0">
            <ReservationCalendarView />
          </TabsContent>

          <TabsContent value="list" className="mt-0">
            <ReservationManagement />
          </TabsContent>

          <TabsContent value="trainers" className="mt-0">
            <TrainerManagement />
          </TabsContent>

          <TabsContent value="reports" className="mt-0">
            <AttendanceReports />
          </TabsContent>
        </Tabs>
      </div>
    </Layout>
  );
};

export default AdminReservations;
