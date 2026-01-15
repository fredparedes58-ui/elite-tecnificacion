import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useCredits } from '@/hooks/useCredits';
import { useCreditTransactions } from '@/hooks/useCreditTransactions';
import Layout from '@/components/layout/Layout';
import CreditBalanceCard from '@/components/credits/CreditBalanceCard';
import CreditHistoryList from '@/components/credits/CreditHistoryList';

const MyCredits: React.FC = () => {
  const { user, isApproved, isAdmin, isLoading } = useAuth();
  const { credits, loading: creditsLoading } = useCredits();
  const { transactions, loading: transactionsLoading } = useCreditTransactions();

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
    return <Navigate to="/admin" replace />;
  }

  if (!isApproved) {
    return <Navigate to="/" replace />;
  }

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8 space-y-8">
        {/* Header */}
        <div>
          <h1 className="font-orbitron font-bold text-3xl md:text-4xl gradient-text mb-2">
            Mis Créditos
          </h1>
          <p className="text-muted-foreground font-rajdhani">
            Consulta tu balance y movimientos de créditos
          </p>
        </div>

        {/* Balance Card */}
        <CreditBalanceCard balance={credits} />

        {/* Transaction History */}
        <CreditHistoryList 
          transactions={transactions} 
          loading={transactionsLoading || creditsLoading} 
        />
      </div>
    </Layout>
  );
};

export default MyCredits;
