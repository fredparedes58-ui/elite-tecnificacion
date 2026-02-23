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
                  "zod": "^4.3.6"
  },
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "build:dev": "vite build --mode development",
    "preview": "vite preview"
  }
}
