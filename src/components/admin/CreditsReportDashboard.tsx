import React, { useMemo, useState } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { supabase } from '@/integrations/supabase/client';
import { useQuery } from '@tanstack/react-query';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend, 
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import { 
  ChartContainer, 
  ChartTooltip, 
  ChartTooltipContent 
} from '@/components/ui/chart';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { format, subMonths, startOfMonth, endOfMonth, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import { TrendingUp, TrendingDown, CreditCard, RefreshCw, BarChart3 } from 'lucide-react';

interface CreditTransaction {
  id: string;
  amount: number;
  transaction_type: string;
  created_at: string;
}

const COLORS = ['#00f0ff', '#a855f7', '#10b981', '#f59e0b', '#ef4444'];

const CreditsReportDashboard: React.FC = () => {
  const [monthsBack, setMonthsBack] = useState<number>(6);

  const { data: transactions = [], isLoading, refetch } = useQuery({
    queryKey: ['credit-transactions-report', monthsBack],
    queryFn: async () => {
      const startDate = startOfMonth(subMonths(new Date(), monthsBack - 1));
      
      const { data, error } = await supabase
        .from('credit_transactions')
        .select('id, amount, transaction_type, created_at')
        .gte('created_at', startDate.toISOString())
        .order('created_at', { ascending: true });

      if (error) throw error;
      return data as CreditTransaction[];
    }
  });

  const monthlyData = useMemo(() => {
    const months: { [key: string]: { loaded: number; consumed: number; refunded: number } } = {};
    
    // Initialize months
    for (let i = monthsBack - 1; i >= 0; i--) {
      const date = subMonths(new Date(), i);
      const key = format(date, 'yyyy-MM');
      months[key] = { loaded: 0, consumed: 0, refunded: 0 };
    }

    // Aggregate transactions
    transactions.forEach(tx => {
      const key = format(parseISO(tx.created_at), 'yyyy-MM');
      if (months[key]) {
        if (tx.transaction_type === 'credit' || tx.transaction_type === 'manual_adjustment') {
          if (tx.amount > 0) {
            months[key].loaded += tx.amount;
          }
        } else if (tx.transaction_type === 'debit') {
          months[key].consumed += Math.abs(tx.amount);
        } else if (tx.transaction_type === 'refund') {
          months[key].refunded += tx.amount;
        }
      }
    });

    return Object.entries(months).map(([month, data]) => ({
      month: format(parseISO(`${month}-01`), 'MMM yy', { locale: es }),
      fullMonth: format(parseISO(`${month}-01`), 'MMMM yyyy', { locale: es }),
      cargados: data.loaded,
      consumidos: data.consumed,
      reembolsos: data.refunded,
      balance: data.loaded - data.consumed + data.refunded
    }));
  }, [transactions, monthsBack]);

  const totals = useMemo(() => {
    return monthlyData.reduce((acc, month) => ({
      loaded: acc.loaded + month.cargados,
      consumed: acc.consumed + month.consumidos,
      refunded: acc.refunded + month.reembolsos
    }), { loaded: 0, consumed: 0, refunded: 0 });
  }, [monthlyData]);

  const pieData = useMemo(() => [
    { name: 'Cargados', value: totals.loaded, color: '#10b981' },
    { name: 'Consumidos', value: totals.consumed, color: '#ef4444' },
    { name: 'Reembolsos', value: totals.refunded, color: '#f59e0b' },
  ].filter(d => d.value > 0), [totals]);

  const chartConfig = {
    cargados: {
      label: "Cargados",
      color: "hsl(var(--chart-1))",
    },
    consumidos: {
      label: "Consumidos",
      color: "hsl(var(--chart-2))",
    },
    reembolsos: {
      label: "Reembolsos",
      color: "hsl(var(--chart-3))",
    },
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-12 h-12 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
        <div>
          <h2 className="font-orbitron font-bold text-2xl gradient-text flex items-center gap-2">
            <BarChart3 className="w-6 h-6" />
            Reportes de Créditos
          </h2>
          <p className="text-muted-foreground mt-1">
            Análisis de créditos cargados vs consumidos
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Select 
            value={monthsBack.toString()} 
            onValueChange={(v) => setMonthsBack(parseInt(v))}
          >
            <SelectTrigger className="w-40 bg-background border-neon-cyan/30">
              <SelectValue placeholder="Período" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="3">Últimos 3 meses</SelectItem>
              <SelectItem value="6">Últimos 6 meses</SelectItem>
              <SelectItem value="12">Último año</SelectItem>
            </SelectContent>
          </Select>
          <NeonButton variant="outline" onClick={() => refetch()}>
            <RefreshCw className="w-4 h-4" />
          </NeonButton>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-green-500/20">
              <TrendingUp className="w-5 h-5 text-green-400" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Créditos Cargados</p>
              <p className="font-orbitron text-2xl text-green-400">{totals.loaded}</p>
            </div>
          </div>
        </EliteCard>
        
        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-red-500/20">
              <TrendingDown className="w-5 h-5 text-red-400" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Créditos Consumidos</p>
              <p className="font-orbitron text-2xl text-red-400">{totals.consumed}</p>
            </div>
          </div>
        </EliteCard>
        
        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-neon-cyan/20">
              <CreditCard className="w-5 h-5 text-neon-cyan" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Balance Neto</p>
              <p className="font-orbitron text-2xl text-neon-cyan">
                {totals.loaded - totals.consumed + totals.refunded}
              </p>
            </div>
          </div>
        </EliteCard>
      </div>

      {/* Bar Chart */}
      <EliteCard className="p-6">
        <h3 className="font-orbitron font-semibold mb-4 text-lg">
          Créditos Mensuales
        </h3>
        <ChartContainer config={chartConfig} className="h-[300px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={monthlyData}>
              <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
              <XAxis 
                dataKey="month" 
                stroke="hsl(var(--muted-foreground))"
                fontSize={12}
              />
              <YAxis 
                stroke="hsl(var(--muted-foreground))"
                fontSize={12}
              />
              <ChartTooltip 
                content={<ChartTooltipContent />}
              />
              <Legend />
              <Bar 
                dataKey="cargados" 
                fill="#10b981" 
                name="Cargados"
                radius={[4, 4, 0, 0]}
              />
              <Bar 
                dataKey="consumidos" 
                fill="#ef4444" 
                name="Consumidos"
                radius={[4, 4, 0, 0]}
              />
              <Bar 
                dataKey="reembolsos" 
                fill="#f59e0b" 
                name="Reembolsos"
                radius={[4, 4, 0, 0]}
              />
            </BarChart>
          </ResponsiveContainer>
        </ChartContainer>
      </EliteCard>

      {/* Line Chart & Pie Chart */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <EliteCard className="p-6">
          <h3 className="font-orbitron font-semibold mb-4 text-lg">
            Tendencia de Balance
          </h3>
          <ChartContainer config={chartConfig} className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={monthlyData}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis 
                  dataKey="month" 
                  stroke="hsl(var(--muted-foreground))"
                  fontSize={12}
                />
                <YAxis 
                  stroke="hsl(var(--muted-foreground))"
                  fontSize={12}
                />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Line 
                  type="monotone" 
                  dataKey="balance" 
                  stroke="#00f0ff" 
                  strokeWidth={2}
                  dot={{ fill: '#00f0ff', strokeWidth: 2 }}
                  name="Balance"
                />
              </LineChart>
            </ResponsiveContainer>
          </ChartContainer>
        </EliteCard>

        <EliteCard className="p-6">
          <h3 className="font-orbitron font-semibold mb-4 text-lg">
            Distribución de Movimientos
          </h3>
          <div className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={90}
                  paddingAngle={5}
                  dataKey="value"
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {pieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: 'hsl(var(--popover))',
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px'
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </EliteCard>
      </div>
    </div>
  );
};

export default CreditsReportDashboard;
