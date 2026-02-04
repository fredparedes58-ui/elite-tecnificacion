import React from 'react';
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend, 
  ResponsiveContainer 
} from 'recharts';
import { format, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import { usePlayerStatsHistory, PlayerStatsRecord } from '@/hooks/usePlayerStatsHistory';
import { EliteCard } from '@/components/ui/EliteCard';
import { TrendingUp, BarChart3 } from 'lucide-react';

interface PlayerProgressChartProps {
  playerId: string;
  currentStats?: {
    speed: number;
    technique: number;
    physical: number;
    mental: number;
    tactical: number;
  };
}

const STAT_COLORS = {
  speed: '#00f5ff',      // neon-cyan
  technique: '#a855f7',  // neon-purple
  physical: '#22c55e',   // green
  mental: '#f59e0b',     // amber
  tactical: '#ec4899',   // pink
};

const STAT_LABELS: Record<string, string> = {
  speed: 'Velocidad',
  technique: 'Técnica',
  physical: 'Físico',
  mental: 'Mental',
  tactical: 'Táctico',
};

const PlayerProgressChart: React.FC<PlayerProgressChartProps> = ({ 
  playerId,
  currentStats 
}) => {
  const { data: history, isLoading } = usePlayerStatsHistory(playerId);

  if (isLoading) {
    return (
      <EliteCard className="p-6">
        <div className="flex items-center justify-center h-64">
          <div className="w-8 h-8 border-2 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
        </div>
      </EliteCard>
    );
  }

  // Combine history with current stats
  const chartData: Array<{
    date: string;
    dateLabel: string;
    speed: number;
    technique: number;
    physical: number;
    mental: number;
    tactical: number;
    notes?: string;
  }> = [];

  // Add historical data
  if (history && history.length > 0) {
    history.forEach((record) => {
      chartData.push({
        date: record.recorded_at,
        dateLabel: format(parseISO(record.recorded_at), 'dd MMM', { locale: es }),
        speed: record.stats.speed,
        technique: record.stats.technique,
        physical: record.stats.physical,
        mental: record.stats.mental,
        tactical: record.stats.tactical,
        notes: record.notes || undefined,
      });
    });
  }

  // Add current stats as latest point if we have them
  if (currentStats) {
    const today = new Date().toISOString();
    const hasToday = chartData.some(d => 
      format(parseISO(d.date), 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd')
    );
    
    if (!hasToday) {
      chartData.push({
        date: today,
        dateLabel: 'Actual',
        ...currentStats,
      });
    }
  }

  if (chartData.length < 2) {
    return (
      <EliteCard className="p-6">
        <div className="flex items-center gap-3 mb-4">
          <TrendingUp className="w-5 h-5 text-neon-cyan" />
          <h3 className="font-orbitron font-semibold text-lg">Evolución de Stats</h3>
        </div>
        <div className="flex flex-col items-center justify-center h-48 text-muted-foreground">
          <BarChart3 className="w-12 h-12 mb-3 opacity-50" />
          <p className="text-sm text-center">
            Se necesitan al menos 2 registros para mostrar la evolución.
          </p>
          <p className="text-xs mt-1 opacity-70">
            Los registros se crean al completar sesiones.
          </p>
        </div>
      </EliteCard>
    );
  }

  // Calculate improvements
  const firstRecord = chartData[0];
  const lastRecord = chartData[chartData.length - 1];
  const improvements = {
    speed: lastRecord.speed - firstRecord.speed,
    technique: lastRecord.technique - firstRecord.technique,
    physical: lastRecord.physical - firstRecord.physical,
    mental: lastRecord.mental - firstRecord.mental,
    tactical: lastRecord.tactical - firstRecord.tactical,
  };

  return (
    <EliteCard className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <TrendingUp className="w-5 h-5 text-neon-cyan" />
          <h3 className="font-orbitron font-semibold text-lg">Evolución de Stats</h3>
        </div>
        <span className="text-xs text-muted-foreground">
          {chartData.length} registros
        </span>
      </div>

      {/* Chart */}
      <div className="h-64 mb-6">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--muted)/0.3)" />
            <XAxis 
              dataKey="dateLabel" 
              stroke="hsl(var(--muted-foreground))"
              fontSize={11}
              tickLine={false}
            />
            <YAxis 
              domain={[0, 100]} 
              stroke="hsl(var(--muted-foreground))"
              fontSize={11}
              tickLine={false}
              width={30}
            />
            <Tooltip 
              contentStyle={{
                backgroundColor: 'hsl(var(--background))',
                border: '1px solid hsl(var(--border))',
                borderRadius: '8px',
                fontSize: '12px',
              }}
              labelStyle={{ fontWeight: 'bold', marginBottom: '4px' }}
            />
            <Legend 
              wrapperStyle={{ fontSize: '11px', paddingTop: '10px' }}
              formatter={(value) => STAT_LABELS[value] || value}
            />
            {Object.entries(STAT_COLORS).map(([key, color]) => (
              <Line
                key={key}
                type="monotone"
                dataKey={key}
                name={key}
                stroke={color}
                strokeWidth={2}
                dot={{ r: 4, fill: color }}
                activeDot={{ r: 6 }}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Improvements Summary */}
      <div className="grid grid-cols-5 gap-2">
        {Object.entries(improvements).map(([key, value]) => (
          <div 
            key={key}
            className="text-center p-2 rounded-lg bg-muted/30 border border-muted/50"
          >
            <div 
              className={`text-lg font-orbitron font-bold ${
                value > 0 ? 'text-green-400' : value < 0 ? 'text-red-400' : 'text-muted-foreground'
              }`}
            >
              {value > 0 ? '+' : ''}{value}
            </div>
            <div className="text-[9px] text-muted-foreground uppercase">
              {STAT_LABELS[key]?.substring(0, 4) || key.substring(0, 3)}
            </div>
          </div>
        ))}
      </div>
    </EliteCard>
  );
};

export default PlayerProgressChart;
