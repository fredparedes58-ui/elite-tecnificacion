import React, { useMemo } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { format, parseISO, subMonths, startOfMonth } from 'date-fns';
import { es } from 'date-fns/locale';
import { usePlayerStatsHistory } from '@/hooks/usePlayerStatsHistory';
import { EliteCard } from '@/components/ui/EliteCard';
import { getLevelColor } from '@/lib/constants/playerLevelColors';
import type { Database } from '@/integrations/supabase/types';

type PlayerLevel = Database['public']['Enums']['player_level'];

const SIX_METRICS = ['velocidad', 'tiro', 'pase', 'regate', 'defensa', 'fisico'] as const;
const FIVE_METRICS = ['speed', 'technique', 'physical', 'mental', 'tactical'] as const;

function avgRatingFromStats(stats: Record<string, unknown>): number {
  let sum = 0;
  let count = 0;
  for (const k of SIX_METRICS) {
    const v = stats[k];
    if (typeof v === 'number' && v >= 0 && v <= 100) {
      sum += v;
      count++;
    }
  }
  if (count > 0) return Math.round((sum / count) * 100) / 100;
  for (const k of FIVE_METRICS) {
    const v = stats[k];
    if (typeof v === 'number' && v >= 0 && v <= 100) {
      sum += v;
      count++;
    }
  }
  if (count > 0) return Math.round((sum / count) * 100) / 100;
  return 0;
}

interface AverageRatingLineChartProps {
  playerId: string;
  playerLevel?: PlayerLevel | null;
  currentStats?: Record<string, number> | null;
  className?: string;
}

const AverageRatingLineChart: React.FC<AverageRatingLineChartProps> = ({
  playerId,
  playerLevel,
  currentStats,
  className,
}) => {
  const { data: history, isLoading } = usePlayerStatsHistory(playerId);

  const chartData = useMemo(() => {
    const now = new Date();
    const months: Array<{ monthKey: string; monthLabel: string; avgRating: number; recordedAt: string }> = [];
    for (let i = 5; i >= 0; i--) {
      const d = subMonths(now, i);
      const monthStart = startOfMonth(d);
      months.push({
        monthKey: format(monthStart, 'yyyy-MM'),
        monthLabel: format(monthStart, 'MMM yy', { locale: es }),
        avgRating: 0,
        recordedAt: monthStart.toISOString(),
      });
    }

    if (!history || history.length === 0) {
      if (currentStats && Object.keys(currentStats).length > 0) {
        const last = months[months.length - 1];
        last.avgRating = avgRatingFromStats(currentStats as Record<string, unknown>);
        last.recordedAt = new Date().toISOString();
      }
      return months;
    }

    const byMonth = new Map<string, { avg: number; recordedAt: string }>();
    history.forEach((record) => {
      const monthKey = format(parseISO(record.recorded_at), 'yyyy-MM');
      const avg = avgRatingFromStats(record.stats as Record<string, unknown>);
      const existing = byMonth.get(monthKey);
      if (!existing || parseISO(record.recorded_at) > parseISO(existing.recordedAt)) {
        byMonth.set(monthKey, { avg, recordedAt: record.recorded_at });
      }
    });

    months.forEach((m) => {
      const v = byMonth.get(m.monthKey);
      if (v) {
        m.avgRating = v.avg;
        m.recordedAt = v.recordedAt;
      }
    });

    if (currentStats && Object.keys(currentStats).length > 0) {
      const thisMonth = format(now, 'yyyy-MM');
      const currentAvg = avgRatingFromStats(currentStats as Record<string, unknown>);
      const idx = months.findIndex((m) => m.monthKey === thisMonth);
      if (idx >= 0 && (months[idx].avgRating === 0 || months[idx].monthKey === thisMonth)) {
        months[idx].avgRating = currentAvg;
        months[idx].recordedAt = now.toISOString();
      }
    }

    return months;
  }, [history, currentStats]);

  const strokeColor = getLevelColor(playerLevel ?? undefined);
  const hasData = chartData.some((d) => d.avgRating > 0);

  if (isLoading) {
    return (
      <EliteCard className={`p-6 ${className ?? ''}`}>
        <div className="flex items-center justify-center h-64">
          <div className="w-8 h-8 border-2 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
        </div>
      </EliteCard>
    );
  }

  return (
    <EliteCard className={`p-6 backdrop-blur-sm border-neon-cyan/20 ${className ?? ''}`}>
      <h3 className="font-orbitron font-semibold text-lg mb-4" style={{ color: strokeColor }}>
        Evolución — Average Rating (6 meses)
      </h3>
      {!hasData ? (
        <div className="h-64 flex items-center justify-center text-muted-foreground text-sm">
          Aún no hay datos de evolución. Se registrarán al completar sesiones o actualizar la carta.
        </div>
      ) : (
        <div className="h-64 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--muted)/0.3)" />
              <XAxis
                dataKey="monthLabel"
                stroke="hsl(var(--muted-foreground))"
                fontSize={11}
                tickLine={false}
              />
              <YAxis
                domain={[0, 100]}
                stroke="hsl(var(--muted-foreground))"
                fontSize={11}
                tickLine={false}
                width={28}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'hsl(var(--background))',
                  border: '1px solid hsl(var(--border))',
                  borderRadius: '8px',
                  fontSize: '12px',
                }}
                formatter={(value: number) => [value.toFixed(1), 'Media']}
                labelFormatter={(label) => label}
              />
              <Line
                type="monotone"
                dataKey="avgRating"
                name="Media"
                stroke={strokeColor}
                strokeWidth={2}
                dot={{ r: 4, fill: strokeColor }}
                activeDot={{ r: 6 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      )}
    </EliteCard>
  );
};

export default AverageRatingLineChart;
