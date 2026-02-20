import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

export interface CreditTransaction {
  id: string;
  user_id: string;
  reservation_id: string | null;
  amount: number;
  transaction_type: 'debit' | 'credit' | 'refund' | 'manual_adjustment';
  description: string | null;
  created_at: string;
}

export const useCreditTransactions = () => {
  const { user, isAdmin } = useAuth();
  const [transactions, setTransactions] = useState<CreditTransaction[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchTransactions = async () => {
    if (!user) return;

    try {
      setLoading(true);
      
      let query = supabase
        .from('credit_transactions')
        .select('*')
        .order('created_at', { ascending: false });

      // Non-admins only see their own transactions
      if (!isAdmin) {
        query = query.eq('user_id', user.id);
      }

      const { data, error } = await query.limit(100);

      if (error) throw error;
      setTransactions((data || []) as CreditTransaction[]);
    } catch (err) {
      console.error('Error fetching credit transactions:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTransactions();
  }, [user, isAdmin]);

  return { transactions, loading, refetch: fetchTransactions };
};

export default useCreditTransactions;
