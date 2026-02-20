import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import Layout from '@/components/layout/Layout';
import PlayerDirectory from '@/components/admin/PlayerDirectory';

const AdminPlayers: React.FC = () => {
  const { isAdmin, isLoading } = useAuth();

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
      <div className="container mx-auto px-0 md:px-4 py-4 md:py-8 max-w-full">
        <div className="mb-4 md:mb-6">
          <h1 className="font-orbitron font-bold text-xl md:text-3xl gradient-text mb-1 md:mb-2">
            Jugadores
          </h1>
          <p className="text-muted-foreground font-rajdhani text-sm md:text-base">
            Directorio y gestión de jugadores
          </p>
        </div>
        <PlayerDirectory />
      </div>
    </Layout>
  );
};

export default AdminPlayers;
