import React, { useState, useMemo } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { useAdminKPIs } from '@/hooks/useAdminKPIs';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  AreaChart,
  Area,
} from 'recharts';
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from '@/components/ui/chart';
import { Users, CalendarCheck, Banknote, CreditCard, TrendingUp, Percent } from 'lucide-react';

const AdminKPIDashboard: React.FC = () => {
  const [monthsBack, setMonthsBack] = useState(6);
  const { data: kpis = [], isLoading } = useAdminKPIs(monthsBack);

  const totals = useMemo(() => {
    if (!kpis.length) return { attendance: 0, activePlayers: 0, cashIncome: 0, creditsConsumed: 0, totalSessions: 0 };
    const latest = kpis[kpis.length - 1];
    const totalCompleted = kpis.reduce((s, k) => s + k.completedSessions, 0);
    const totalFinalized = kpis.reduce((s, k) => s + k.completedSessions + k.noShowSessions, 0);
    return {
      attendance: totalFinalized > 0 ? Math.round((totalCompleted / totalFinalized) * 100) : 0,
      activePlayers: latest.activePlayers,
      cashIncome: kpis.reduce((s, k) => s + k.cashIncome, 0),
      creditsConsumed: kpis.reduce((s, k) => s + k.creditsConsumed, 0),
      totalSessions: kpis.reduce((s, k) => s + k.totalSessions, 0),
    };
  }, [kpis]);

  const chartConfig = {
    attendance: { label: 'Asistencia %', color: '#10b981' },
    activePlayers: { label: 'Jugadores', color: '#a855f7' },
    cashIncome: { label: 'Ingresos €', color: '#f59e0b' },
    creditsConsumed: { label: 'Créditos', color: '#00f0ff' },
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
      {/* Period Selector */}
      <div className="flex items-center justify-between">
        <h2 className="font-orbitron font-bold text-2xl gradient-text flex items-center gap-2">
          <TrendingUp className="w-6 h-6" />
          KPIs del Centro
        </h2>
        <Select value={monthsBack.toString()} onValueChange={(v) => setMonthsBack(parseInt(v))}>
          <SelectTrigger className="w-40 bg-background border-neon-cyan/30">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="3">3 meses</SelectItem>
            <SelectItem value="6">6 meses</SelectItem>
            <SelectItem value="12">12 meses</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-green-500/20">
              <Percent className="w-5 h-5 text-green-400" />
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Asistencia Global</p>
              <p className="font-orbitron text-2xl text-green-400">{totals.attendance}%</p>
            </div>
          </div>
        </EliteCard>

        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-neon-purple/20">
              <Users className="w-5 h-5 text-neon-purple" />
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Jugadores Activos</p>
              <p className="font-orbitron text-2xl text-neon-purple">{totals.activePlayers}</p>
            </div>
          </div>
        </EliteCard>

        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-yellow-500/20">
              <Banknote className="w-5 h-5 text-yellow-400" />
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Ingresos Efectivo</p>
              <p className="font-orbitron text-2xl text-yellow-400">{totals.cashIncome.toFixed(0)}€</p>
            </div>
          </div>
        </EliteCard>

        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-neon-cyan/20">
              <CreditCard className="w-5 h-5 text-neon-cyan" />
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Créditos Consumidos</p>
              <p className="font-orbitron text-2xl text-neon-cyan">{totals.creditsConsumed}</p>
            </div>
          </div>
        </EliteCard>
      </div>

      {/* Attendance Chart */}
      <EliteCard className="p-6">
        <h3 className="font-orbitron font-semibold mb-4">Tasa de Asistencia Mensual</h3>
        <ChartContainer config={chartConfig} className="h-[280px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={kpis}>
              <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
              <XAxis dataKey="monthLabel" stroke="hsl(var(--muted-foreground))" fontSize={12} />
              <YAxis domain={[0, 100]} stroke="hsl(var(--muted-foreground))" fontSize={12} unit="%" />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Area
                type="monotone"
                dataKey="attendance"
                stroke="#10b981"
                fill="#10b981"
                fillOpacity={0.15}
                strokeWidth={2}
                name="Asistencia %"
              />
            </AreaChart>
          </ResponsiveContainer>
        </ChartContainer>
      </EliteCard>

      {/* Players & Revenue Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <EliteCard className="p-6">
          <h3 className="font-orbitron font-semibold mb-4">Jugadores Activos / Mes</h3>
          <ChartContainer config={chartConfig} className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={kpis}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="monthLabel" stroke="hsl(var(--muted-foreground))" fontSize={12} />
                <YAxis stroke="hsl(var(--muted-foreground))" fontSize={12} />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Bar dataKey="activePlayers" fill="#a855f7" name="Jugadores" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </ChartContainer>
        </EliteCard>

        <EliteCard className="p-6">
          <h3 className="font-orbitron font-semibold mb-4">Ingresos y Créditos</h3>
          <ChartContainer config={chartConfig} className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={kpis}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="monthLabel" stroke="hsl(var(--muted-foreground))" fontSize={12} />
                <YAxis stroke="hsl(var(--muted-foreground))" fontSize={12} />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Legend />
                <Line type="monotone" dataKey="cashIncome" stroke="#f59e0b" strokeWidth={2} name="Efectivo €" dot={{ r: 4 }} />
                <Line type="monotone" dataKey="creditsConsumed" stroke="#00f0ff" strokeWidth={2} name="Créditos" dot={{ r: 4 }} />
              </LineChart>
            </ResponsiveContainer>
          </ChartContainer>
        </EliteCard>
      </div>
    </div>
  );
};

export default AdminKPIDashboard;
