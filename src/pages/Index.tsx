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
import { Target, Users, Calendar, MessageSquare, Shield, Zap, BarChart3, CreditCard, Activity, UserCircle, CalendarDays, UserCheck } from 'lucide-react';
import AdminKPIDashboard from '@/components/admin/AdminKPIDashboard';
import PerformanceSummaryCard from '@/components/admin/PerformanceSummaryCard';
import { usePendingPlayers } from '@/hooks/usePendingPlayers';
import { motion } from 'framer-motion';

const fadeInUp = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.5 },
};

const staggerContainer = {
  animate: { transition: { staggerChildren: 0.08 } },
};

const AdminDashboardContent: React.FC = () => {
  const { viewMode } = useViewMode();
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<'overview' | 'credits' | null>(null);
  const { players: pendingPlayers } = usePendingPlayers();
  const pendingCount = pendingPlayers.length;

  if (viewMode === 'parent') {
    return <ParentView />;
  }

  const adminCards = [
    { href: '/admin/users', icon: Users, label: 'Usuarios', desc: 'Aprobar y gestionar usuarios', color: 'text-neon-cyan' },
    { href: '/scouting', icon: Target, label: 'Scouting', desc: 'Ver todos los jugadores', color: 'text-neon-purple' },
    { href: '/admin/reservations', icon: CalendarDays, label: 'Reservas', desc: 'Aprobar reservas pendientes', color: 'text-neon-cyan' },
    { href: '/admin/chat', icon: MessageSquare, label: 'Chats', desc: 'Consola de mensajes', color: 'text-neon-pink' },
    { href: '/admin/player-approval', icon: UserCheck, label: 'Aprobación', desc: 'Aprobar jugadores pendientes', color: 'text-yellow-400', badge: pendingCount },
    { href: '/admin/credits', icon: CreditCard, label: 'Créditos', desc: 'Gestión de cartera de jugadores', color: 'text-neon-green' },
  ];

  return (
    <Layout>
      <div className="container mx-auto px-4 py-6 md:py-8">
        {/* Header */}
        <motion.div 
          className="flex flex-col md:flex-row md:items-center justify-between mb-8 gap-4"
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          <div>
            <h1 className="font-orbitron font-black text-3xl md:text-4xl tracking-tight">
              <span className="text-neon-purple">PANEL</span>{' '}
              <span className="gradient-text">ADMINISTRADOR</span>
            </h1>
            <p className="text-muted-foreground font-rajdhani mt-1 text-lg">
              Bienvenido, {profile?.full_name || 'Admin'}. Tienes acceso completo al sistema.
            </p>
          </div>
          <div className="flex items-center">
            <ViewModeToggle />
          </div>
        </motion.div>

        {/* Tab navigation - KPIs style */}
        <div className="flex gap-1 mb-6">
          <button
            onClick={() => setActiveTab(activeTab === 'overview' ? null : 'overview')}
            className={`flex items-center gap-2 px-5 py-3 rounded-xl font-orbitron font-semibold text-xs uppercase tracking-wider transition-all duration-300 ${
              activeTab === 'overview'
                ? 'bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/40 shadow-lg shadow-neon-cyan/10'
                : 'text-muted-foreground hover:text-foreground border border-neon-cyan/20 hover:border-neon-cyan/40'
            }`}
          >
            <BarChart3 className="w-4 h-4" />
            KPIs
          </button>
          <button
            onClick={() => setActiveTab(activeTab === 'credits' ? null : 'credits')}
            className={`flex items-center gap-2 px-5 py-3 rounded-xl font-orbitron font-semibold text-xs uppercase tracking-wider transition-all duration-300 ${
              activeTab === 'credits'
                ? 'bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/40 shadow-lg shadow-neon-cyan/10'
                : 'text-muted-foreground hover:text-foreground border border-neon-cyan/20 hover:border-neon-cyan/40'
            }`}
          >
            <CreditCard className="w-4 h-4" />
            Reportes Créditos
          </button>
        </div>

        {activeTab === 'overview' && (
          <motion.div 
            className="space-y-6 mb-6"
            variants={staggerContainer}
            initial="initial"
            animate="animate"
          >
            <motion.div variants={fadeInUp}>
              <AdminKPIDashboard />
            </motion.div>
            
            <motion.div variants={fadeInUp}>
              <PerformanceSummaryCard />
            </motion.div>
          </motion.div>
        )}

        {activeTab === 'credits' && (
          <motion.div {...fadeInUp} className="mb-6">
            <CreditsReportDashboard />
          </motion.div>
        )}

        {/* Admin quick access cards - always visible */}
        <motion.div 
          className="grid grid-cols-2 md:grid-cols-4 gap-3 md:gap-4"
          variants={staggerContainer}
          initial="initial"
          animate="animate"
        >
          {adminCards.map((card) => (
            <motion.div key={card.href} variants={fadeInUp}>
              <Link to={card.href}>
                <EliteCard className="p-5 md:p-6 hover:border-neon-cyan/50 transition-all duration-300 cursor-pointer group h-full relative">
                  {card.badge && card.badge > 0 && (
                    <span className="absolute -top-2 -right-2 w-6 h-6 rounded-full bg-destructive text-destructive-foreground text-xs font-bold flex items-center justify-center shadow-lg shadow-destructive/30 animate-pulse">
                      {card.badge}
                    </span>
                  )}
                  <card.icon className={`w-8 h-8 ${card.color} mb-3 group-hover:scale-110 transition-transform duration-300`} />
                  <h3 className="font-orbitron font-bold text-sm md:text-base">{card.label}</h3>
                  <p className="text-muted-foreground text-xs md:text-sm font-rajdhani mt-1">{card.desc}</p>
                </EliteCard>
              </Link>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </Layout>
  );
};
const ParentView: React.FC = () => {
  const { user } = useAuth();

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8">
        <motion.div 
          className="max-w-4xl mx-auto text-center mb-12"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <h1 className="font-orbitron font-black text-3xl md:text-4xl mb-2">
            <span className="text-neon-purple">BIENVENIDO</span>{' '}
            <span className="gradient-text">A ELITE 380</span>
          </h1>
          <p className="text-muted-foreground font-rajdhani text-lg">Tu portal de entrenamiento personalizado</p>
        </motion.div>

        <motion.div 
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-4xl mx-auto"
          variants={staggerContainer}
          initial="initial"
          animate="animate"
        >
          {[
            { href: '/players', icon: UserCircle, label: 'Mis Jugadores', desc: 'Ver y gestionar jugadores', color: 'text-neon-cyan' },
            { href: '/reservations', icon: Calendar, label: 'Reservas', desc: 'Agendar sesiones', color: 'text-neon-purple' },
            { href: '/credits', icon: CreditCard, label: 'Créditos', desc: 'Balance y paquetes', color: 'text-neon-green' },
          ].map((card) => (
            <motion.div key={card.href} variants={fadeInUp}>
              <Link to={card.href}>
                <EliteCard className="p-8 hover:border-neon-cyan/50 transition-all duration-300 cursor-pointer h-full group">
                  <div className="flex flex-col items-center gap-4 text-center">
                    <card.icon className={`w-12 h-12 ${card.color} group-hover:scale-110 transition-transform duration-300`} />
                    <h3 className="font-orbitron font-bold text-lg">{card.label}</h3>
                    <p className="text-muted-foreground text-sm font-rajdhani">{card.desc}</p>
                  </div>
                </EliteCard>
              </Link>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </Layout>
  );
};

const Index: React.FC = () => {
  const { user, isAdmin, isApproved, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="relative">
          <div className="w-16 h-16 border-4 border-neon-cyan/20 border-t-neon-cyan rounded-full animate-spin" />
          <div className="absolute inset-0 w-16 h-16 border-4 border-transparent border-b-neon-purple rounded-full animate-spin" style={{ animationDirection: 'reverse', animationDuration: '1.5s' }} />
        </div>
      </div>
    );
  }

  if (user && !isApproved && !isAdmin) {
    return <BlockedScreen />;
  }

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
      <div className="relative min-h-[calc(100vh-4rem)] flex items-center overflow-hidden">
        {/* Background effects - more vibrant */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-20 left-10 w-96 h-96 bg-neon-cyan/8 rounded-full blur-[100px] animate-pulse" />
          <div className="absolute bottom-20 right-10 w-[500px] h-[500px] bg-neon-purple/8 rounded-full blur-[120px]" />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-72 h-72 bg-neon-pink/5 rounded-full blur-[80px]" />
        </div>

        <div className="container mx-auto px-4 py-16 relative z-10">
          <motion.div 
            className="max-w-4xl mx-auto text-center"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6 }}
          >
            {/* Logo */}
            <motion.div 
              className="inline-block mb-8"
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ duration: 0.5, type: 'spring' }}
            >
              <div className="relative">
                <div className="w-28 h-28 rounded-2xl bg-gradient-to-br from-neon-cyan via-neon-purple to-neon-pink flex items-center justify-center shadow-2xl shadow-neon-cyan/20">
                  <span className="font-orbitron font-black text-5xl text-background">380</span>
                </div>
                <div className="absolute inset-0 rounded-2xl bg-gradient-to-br from-neon-cyan to-neon-purple opacity-40 blur-2xl animate-pulse" />
              </div>
            </motion.div>

            {/* Title */}
            <motion.h1 
              className="font-orbitron font-black text-5xl md:text-7xl lg:text-8xl mb-4 tracking-tight"
              initial={{ y: 30, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.2, duration: 0.5 }}
            >
              <span className="text-neon-cyan">ELITE</span>{' '}
              <span className="text-neon-pink">380</span>
            </motion.h1>
            <motion.p 
              className="text-xl md:text-2xl text-muted-foreground font-rajdhani mb-10"
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.35, duration: 0.5 }}
            >
              Entrenamiento de élite para jóvenes futbolistas
            </motion.p>

            {/* CTA */}
            <motion.div
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.5, duration: 0.5 }}
            >
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
            </motion.div>

            {/* Features */}
            <motion.div 
              className="grid grid-cols-1 md:grid-cols-3 gap-5 mt-20"
              variants={staggerContainer}
              initial="initial"
              animate="animate"
            >
              {[
                { icon: Target, title: 'Entrenamiento Personalizado', desc: 'Sesiones adaptadas al nivel y objetivos de cada jugador', color: 'text-neon-cyan' },
                { icon: Activity, title: 'Seguimiento de Progreso', desc: 'Estadísticas detalladas y evolución del rendimiento', color: 'text-neon-purple' },
                { icon: Shield, title: 'Plataforma Segura', desc: 'Comunicación directa con entrenadores y gestión de reservas', color: 'text-neon-green' },
              ].map((feat) => (
                <motion.div key={feat.title} variants={fadeInUp}>
                  <EliteCard className="p-7 group hover:border-neon-cyan/40 transition-all duration-300">
                    <feat.icon className={`w-9 h-9 ${feat.color} mx-auto mb-4 group-hover:scale-110 transition-transform duration-300`} />
                    <h3 className="font-orbitron font-bold mb-2 text-sm">{feat.title}</h3>
                    <p className="text-muted-foreground text-sm font-rajdhani">{feat.desc}</p>
                  </EliteCard>
                </motion.div>
              ))}
            </motion.div>
          </motion.div>
        </div>
      </div>
    </Layout>
  );
};

export default Index;
