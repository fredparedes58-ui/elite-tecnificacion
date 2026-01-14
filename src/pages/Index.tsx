import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import Layout from '@/components/layout/Layout';
import { NeonButton } from '@/components/ui/NeonButton';
import { EliteCard } from '@/components/ui/EliteCard';
import BlockedScreen from './BlockedScreen';
import { Target, Users, Calendar, MessageSquare, Shield, Zap } from 'lucide-react';

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
      <Layout>
        <div className="container mx-auto px-4 py-8">
          <div className="text-center mb-12">
            <h1 className="font-orbitron font-bold text-4xl md:text-5xl gradient-text mb-4">
              PANEL ADMINISTRADOR
            </h1>
            <p className="text-muted-foreground text-lg font-rajdhani">
              Bienvenido, Pedro. Tienes acceso completo al sistema.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            <Link to="/admin/users">
              <EliteCard className="p-6 h-full">
                <Users className="w-10 h-10 text-neon-cyan mb-4" />
                <h3 className="font-orbitron font-semibold text-lg mb-2">Usuarios</h3>
                <p className="text-muted-foreground text-sm">Aprobar y gestionar usuarios</p>
              </EliteCard>
            </Link>
            <Link to="/scouting">
              <EliteCard className="p-6 h-full">
                <Target className="w-10 h-10 text-neon-purple mb-4" />
                <h3 className="font-orbitron font-semibold text-lg mb-2">Scouting</h3>
                <p className="text-muted-foreground text-sm">Ver todos los jugadores</p>
              </EliteCard>
            </Link>
            <Link to="/admin/reservations">
              <EliteCard className="p-6 h-full">
                <Calendar className="w-10 h-10 text-neon-cyan mb-4" />
                <h3 className="font-orbitron font-semibold text-lg mb-2">Reservas</h3>
                <p className="text-muted-foreground text-sm">Aprobar reservas pendientes</p>
              </EliteCard>
            </Link>
            <Link to="/admin/chat">
              <EliteCard className="p-6 h-full">
                <MessageSquare className="w-10 h-10 text-neon-purple mb-4" />
                <h3 className="font-orbitron font-semibold text-lg mb-2">Chats</h3>
                <p className="text-muted-foreground text-sm">Consola de mensajes</p>
              </EliteCard>
            </Link>
          </div>
        </div>
      </Layout>
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
              Academia de Fútbol de Alto Rendimiento
            </p>

            {/* Features */}
            <div className="grid md:grid-cols-3 gap-6 mb-12">
              <EliteCard className="p-6">
                <Zap className="w-8 h-8 text-neon-cyan mx-auto mb-3" />
                <h3 className="font-orbitron font-semibold mb-2">Scouting Avanzado</h3>
                <p className="text-sm text-muted-foreground">Stats y radar charts de cada jugador</p>
              </EliteCard>
              <EliteCard className="p-6">
                <Calendar className="w-8 h-8 text-neon-purple mx-auto mb-3" />
                <h3 className="font-orbitron font-semibold mb-2">Reservas</h3>
                <p className="text-sm text-muted-foreground">Sistema de créditos para entrenamientos</p>
              </EliteCard>
              <EliteCard className="p-6">
                <Shield className="w-8 h-8 text-neon-cyan mx-auto mb-3" />
                <h3 className="font-orbitron font-semibold mb-2">Chat Directo</h3>
                <p className="text-sm text-muted-foreground">Comunicación con el staff</p>
              </EliteCard>
            </div>

            {/* CTA */}
            {!user ? (
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link to="/auth">
                  <NeonButton variant="gradient" size="lg">
                    Comenzar Ahora
                  </NeonButton>
                </Link>
              </div>
            ) : (
              <Link to="/dashboard">
                <NeonButton variant="cyan" size="lg">
                  Ir a Mi Panel
                </NeonButton>
              </Link>
            )}
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default Index;
