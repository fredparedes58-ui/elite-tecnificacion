import React from 'react';
import {
  Radar,
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  ResponsiveContainer,
} from 'recharts';

interface DataPoint {
  stat: string;
  value: number;
  fullMark: number;
}

interface SimpleRadarChartProps {
  data: DataPoint[];
}

const SimpleRadarChart: React.FC<SimpleRadarChartProps> = ({ data }) => {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <RadarChart cx="50%" cy="50%" outerRadius="70%" data={data}>
        <PolarGrid
          stroke="hsl(var(--neon-cyan) / 0.2)"
          strokeWidth={1}
        />
        <PolarAngleAxis
          dataKey="stat"
          tick={{
            fill: 'hsl(var(--muted-foreground))',
            fontSize: 10,
            fontFamily: 'Rajdhani',
          }}
        />
        <PolarRadiusAxis
          angle={90}
          domain={[0, 100]}
          tick={false}
          axisLine={false}
        />
        <Radar
          name="Stats"
          dataKey="value"
          stroke="hsl(var(--neon-cyan))"
          fill="hsl(var(--neon-cyan))"
          fillOpacity={0.3}
          strokeWidth={2}
        />
      </RadarChart>
    </ResponsiveContainer>
  );
};

export default SimpleRadarChart;
