import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { startOfMonth, endOfMonth, subMonths, format, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';

export interface MonthlyKPI {
  month: string;
  monthLabel: string;
  attendance: number;
  totalSessions: number;
  completedSessions: number;
  noShowSessions: number;
  activePlayers: number;
  cashIncome: number;
  creditsConsumed: number;
  creditsLoaded: number;
}

export function useAdminKPIs(monthsBack: number = 6) {
  return useQuery({
    queryKey: ['admin-kpis', monthsBack],
    queryFn: async (): Promise<MonthlyKPI[]> => {
      const startDate = startOfMonth(subMonths(new Date(), monthsBack - 1));

      // Fetch all data in parallel
      const [reservationsRes, cashRes, creditsRes] = await Promise.all([
        supabase
          .from('reservations')
          .select('id, status, start_time, player_id')
          .gte('start_time', startDate.toISOString())
          .in('status', ['completed', 'no_show', 'approved', 'pending']),
        supabase
          .from('cash_payments')
          .select('cash_amount, created_at')
          .gte('created_at', startDate.toISOString()),
        supabase
          .from('credit_transactions')
          .select('amount, transaction_type, created_at')
          .gte('created_at', startDate.toISOString()),
      ]);

      const reservations = reservationsRes.data || [];
      const cashPayments = cashRes.data || [];
      const creditTxs = creditsRes.data || [];

      // Build monthly buckets
      const months: Record<string, MonthlyKPI> = {};
      for (let i = monthsBack - 1; i >= 0; i--) {
        const d = subMonths(new Date(), i);
        const key = format(d, 'yyyy-MM');
        months[key] = {
          month: key,
          monthLabel: format(d, 'MMM yy', { locale: es }),
          attendance: 0,
          totalSessions: 0,
          completedSessions: 0,
          noShowSessions: 0,
          activePlayers: 0,
          cashIncome: 0,
          creditsConsumed: 0,
          creditsLoaded: 0,
        };
      }

      // Aggregate reservations
      const playersByMonth: Record<string, Set<string>> = {};
      reservations.forEach((r) => {
        const key = format(parseISO(r.start_time), 'yyyy-MM');
        if (!months[key]) return;
        months[key].totalSessions++;
        if (r.status === 'completed') months[key].completedSessions++;
        if (r.status === 'no_show') months[key].noShowSessions++;
        if (r.player_id) {
          if (!playersByMonth[key]) playersByMonth[key] = new Set();
          playersByMonth[key].add(r.player_id);
        }
      });

      // Calculate attendance rate & active players
      Object.keys(months).forEach((key) => {
        const m = months[key];
        const finalized = m.completedSessions + m.noShowSessions;
        m.attendance = finalized > 0 ? Math.round((m.completedSessions / finalized) * 100) : 0;
        m.activePlayers = playersByMonth[key]?.size || 0;
      });

      // Aggregate cash
      cashPayments.forEach((cp) => {
        const key = format(parseISO(cp.created_at!), 'yyyy-MM');
        if (months[key]) months[key].cashIncome += Number(cp.cash_amount);
      });

      // Aggregate credits
      creditTxs.forEach((tx) => {
        const key = format(parseISO(tx.created_at), 'yyyy-MM');
        if (!months[key]) return;
        if (tx.transaction_type === 'debit') {
          months[key].creditsConsumed += Math.abs(tx.amount);
        } else if (tx.transaction_type === 'credit' || tx.transaction_type === 'manual_adjustment') {
          if (tx.amount > 0) months[key].creditsLoaded += tx.amount;
        }
      });

      return Object.values(months);
    },
  });
}
