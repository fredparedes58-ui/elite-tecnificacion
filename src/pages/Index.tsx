import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import Layout from '@/components/layout/Layout';
import { NeonButton } from '@/components/ui/NeonButton';
import { EliteCard } from '@/components/ui/EliteCard';
import BlockedScreen from './BlockedScreen';
import ViewModeToggle from '@/components/admin/ViewModeToggle';
import CreditsReportDashboard from '@/components/admin/CreditsReportDashboard';
import { ViewModeProvider, useViewMode } from '@/contexts/ViewModeContext';
import { Target, Users, Calendar, MessageSquare, Shield, Zap, BarChart3, CreditCard, Activity, GitCompare, UserCircle } from 'lucide-react';
import AdminKPIDashboard from '@/components/admin/AdminKPIDashboard';
import PerformanceSummaryCard from '@/components/admin/PerformanceSummaryCard';
import { usePendingPlayers } from '@/hooks/usePendingPlayers';

const AdminDashboardContent: React.FC = () => {
  const { viewMode } = useViewMode();
  const [activeTab, setActiveTab] = useState<'overview' | 'credits'>('overview');
  const { players: pendingPlayers } = usePendingPlayers();
  const pendingCount = pendingPlayers.length;

  if (viewMode === 'parent') {
    return <ParentView />;
  }

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="font-orbitron font-bold text-3xl gradient-text">Panel de Administración</h1>
            <p className="text-muted-foreground font-rajdhani mt-1">Gestión completa de Elite 380</p>
          </div>
          <ViewModeToggle />
        </div>

        {/* Tab navigation */}
        <div className="flex gap-2 mb-6">
          <button
            onClick={() => setActiveTab('overview')}
            className={`px-4 py-2 rounded-lg font-rajdhani font-semibold transition-all ${
              activeTab === 'overview'
                ? 'bg-neon-cyan/20 text-neon-cyan border border-neon-cyan/30'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            <BarChart3 className="w-4 h-4 inline-block mr-2" />
            Vista General
          </button>
          <button
            onClick={() => setActiveTab('credits')}
            className={`px-4 py-2 rounded-lg font-rajdhani font-semibold transition-all ${
              activeTab === 'credits'
                ? 'bg-neon-cyan/20 text-neon-cyan border border-neon-cyan/30'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            <CreditCard className="w-4 h-4 inline-block mr-2" />
            Reporte de Créditos
          </button>
        </div>

        {activeTab === 'overview' ? (
          <div className="space-y-6">
            <AdminKPIDashboard />
            <PerformanceSummaryCard />

            {/* Quick access cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <Link to="/admin/players">
                <EliteCard className="p-6 hover:border-neon-cyan/50 transition-all cursor-pointer">
                  <div className="flex items-center gap-3">
                    <Users className="w-8 h-8 text-neon-cyan" />
                    <div>
                      <h3 className="font-orbitron font-bold text-lg">Jugadores</h3>
                      <p className="text-muted-foreground text-sm font-rajdhani">
                        {pendingCount > 0 ? `${pendingCount} pendientes` : 'Gestionar jugadores'}
                      </p>
                    </div>
                  </div>
                </EliteCard>
              </Link>
              <Link to="/admin/reservations">
                <EliteCard className="p-6 hover:border-neon-cyan/50 transition-all cursor-pointer">
                  <div className="flex items-center gap-3">
                    <Calendar className="w-8 h-8 text-neon-purple" />
                    <div>
                      <h3 className="font-orbitron font-bold text-lg">Reservas</h3>
                      <p className="text-muted-foreground text-sm font-rajdhani">Calendario de sesiones</p>
                    </div>
                  </div>
                </EliteCard>
              </Link>
              <Link to="/admin/chat">
                <EliteCard className="p-6 hover:border-neon-cyan/50 transition-all cursor-pointer">
                  <div className="flex items-center gap-3">
                    <MessageSquare className="w-8 h-8 text-neon-green" />
                    <div>
                      <h3 className="font-orbitron font-bold text-lg">Mensajes</h3>
                      <p className="text-muted-foreground text-sm font-rajdhani">Consola de chat</p>
                    </div>
                  </div>
                </EliteCard>
              </Link>
            </div>
          </div>
        ) : (
          <CreditsReportDashboard />
        )}
      </div>
    </Layout>
  );
};

const ParentView: React.FC = () => {
  const { user } = useAuth();

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto text-center mb-12">
          <h1 className="font-orbitron font-bold text-3xl gradient-text mb-2">Bienvenido a Elite 380</h1>
          <p className="text-muted-foreground font-rajdhani text-lg">Tu portal de entrenamiento personalizado</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-4xl mx-auto">
          <Link to="/players">
            <EliteCard className="p-6 hover:border-neon-cyan/50 transition-all cursor-pointer h-full">
              <div className="flex flex-col items-center gap-3 text-center">
                <UserCircle className="w-10 h-10 text-neon-cyan" />
                <h3 className="font-orbitron font-bold">Mis Jugadores</h3>
                <p className="text-muted-foreground text-sm font-rajdhani">Ver y gestionar jugadores</p>
              </div>
            </EliteCard>
          </Link>
          <Link to="/reservations">
            <EliteCard className="p-6 hover:border-neon-cyan/50 transition-all cursor-pointer h-full">
              <div className="flex flex-col items-center gap-3 text-center">
                <Calendar className="w-10 h-10 text-neon-purple" />
                <h3 className="font-orbitron font-bold">Reservas</h3>
                <p className="text-muted-foreground text-sm font-rajdhani">Agendar sesiones</p>
              </div>
            </EliteCard>
          </Link>
          <Link to="/credits">
            <EliteCard className="p-6 hover:border-neon-cyan/50 transition-all cursor-pointer h-full">
              <div className="flex flex-col items-center gap-3 text-center">
                <CreditCard className="w-10 h-10 text-neon-green" />
                <h3 className="font-orbitron font-bold">Créditos</h3>
                <p className="text-muted-foreground text-sm font-rajdhani">Balance y paquetes</p>
              </div>
            </EliteCard>
          </Link>
        </div>
      </div>
    </Layout>
  );
};

const Index: React.FC = () => {
  const { user, isAdmin, isApproved, isLoading } = useAuth();

  // Show loading
  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  // Show blocked screen for unapproved users
  if (user && !isApproved && !isAdmin) {
    return <BlockedScreen />;
  }

  // Redirect to admin dashboard
  if (isAdmin) {
    return (
      <ViewModeProvider>
        <AdminDashboardContent />
      </ViewModeProvider>
    );
  }

  // Landing page for guests or approved users
  return (
    <Layout>
      <div className="relative min-h-[calc(100vh-4rem)] flex items-center">
        {/* Background effects */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-20 left-10 w-72 h-72 bg-neon-cyan/5 rounded-full blur-3xl" />
          <div className="absolute bottom-20 right-10 w-96 h-96 bg-neon-purple/5 rounded-full blur-3xl" />
        </div>

        <div className="container mx-auto px-4 py-16 relative z-10">
          <div className="max-w-4xl mx-auto text-center">
            {/* Logo */}
            <div className="inline-block mb-8">
              <div className="relative">
                <div className="w-24 h-24 rounded-2xl bg-gradient-to-br from-neon-cyan to-neon-purple flex items-center justify-center">
                  <span className="font-orbitron font-black text-4xl text-background">E</span>
                </div>
                <div className="absolute inset-0 rounded-2xl bg-gradient-to-br from-neon-cyan to-neon-purple opacity-50 blur-xl" />
              </div>
            </div>

            {/* Title */}
            <h1 className="font-orbitron font-black text-5xl md:text-7xl mb-4">
              <span className="gradient-text">ELITE 380</span>
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground font-rajdhani mb-8">
              Entrenamiento de élite para jóvenes futbolistas
            </p>

            {/* CTA */}
            {user ? (
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link to="/players">
                  <NeonButton size="lg">
                    <Target className="w-5 h-5 mr-2" />
                    Mis Jugadores
                  </NeonButton>
                </Link>
                <Link to="/reservations">
                  <NeonButton variant="outline" size="lg">
                    <Calendar className="w-5 h-5 mr-2" />
                    Reservar Sesión
                  </NeonButton>
                </Link>
              </div>
            ) : (
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link to="/auth">
                  <NeonButton size="lg">
                    <Zap className="w-5 h-5 mr-2" />
                    Comenzar Ahora
                  </NeonButton>
                </Link>
              </div>
            )}

            {/* Features */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-16">
              <EliteCard className="p-6">
                <Target className="w-8 h-8 text-neon-cyan mx-auto mb-3" />
                <h3 className="font-orbitron font-bold mb-2">Entrenamiento Personalizado</h3>
                <p className="text-muted-foreground text-sm font-rajdhani">
                  Sesiones adaptadas al nivel y objetivos de cada jugador
                </p>
              </EliteCard>
              <EliteCard className="p-6">
                <Activity className="w-8 h-8 text-neon-purple mx-auto mb-3" />
                <h3 className="font-orbitron font-bold mb-2">Seguimiento de Progreso</h3>
                <p className="text-muted-foreground text-sm font-rajdhani">
                  Estadísticas detalladas y evolución del rendimiento
                </p>
              </EliteCard>
              <EliteCard className="p-6">
                <Shield className="w-8 h-8 text-neon-green mx-auto mb-3" />
                <h3 className="font-orbitron font-bold mb-2">Plataforma Segura</h3>
                <p className="text-muted-foreground text-sm font-rajdhani">
                  Comunicación directa con entrenadores y gestión de reservas
                </p>
              </EliteCard>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default Index;
