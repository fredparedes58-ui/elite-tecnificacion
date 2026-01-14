import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import Layout from '@/components/layout/Layout';
import ParentChat from '@/components/chat/ParentChat';

const Chat: React.FC = () => {
  const { user, isApproved, isAdmin, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/auth" replace />;
  }

  if (isAdmin) {
    return <Navigate to="/admin/chat" replace />;
  }

  if (!isApproved) {
    return <Navigate to="/" replace />;
  }

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8">
        <div className="text-center mb-8">
          <h1 className="font-orbitron font-bold text-3xl md:text-4xl gradient-text mb-2">
            Chat con Elite 380
          </h1>
          <p className="text-muted-foreground font-rajdhani">
            Comunícate directamente con nuestro equipo
          </p>
        </div>
        <div className="max-w-3xl mx-auto">
          <ParentChat />
        </div>
      </div>
    </Layout>
  );
};

export default Chat;
