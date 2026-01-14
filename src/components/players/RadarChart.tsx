import React from 'react';

interface Stats {
  speed: number;
  technique: number;
  physical: number;
  mental: number;
  tactical: number;
}

interface RadarChartProps {
  stats: Stats;
  size?: number;
  showLabels?: boolean;
}

const RadarChart: React.FC<RadarChartProps> = ({ stats, size = 200, showLabels = true }) => {
  const center = size / 2;
  const radius = size * 0.4;
  const labels = ['Velocidad', 'Técnica', 'Físico', 'Mental', 'Táctico'];
  const statKeys = ['speed', 'technique', 'physical', 'mental', 'tactical'] as const;
  const angleStep = (2 * Math.PI) / 5;

  // Get point coordinates for a value (0-100) at a given index
  const getPoint = (value: number, index: number) => {
    const angle = angleStep * index - Math.PI / 2;
    const r = (value / 100) * radius;
    return {
      x: center + r * Math.cos(angle),
      y: center + r * Math.sin(angle),
    };
  };

  // Generate polygon points for the background levels
  const getLevelPolygon = (level: number) => {
    return statKeys
      .map((_, i) => {
        const point = getPoint(level, i);
        return `${point.x},${point.y}`;
      })
      .join(' ');
  };

  // Generate polygon points for the stats
  const getStatsPolygon = () => {
    return statKeys
      .map((key, i) => {
        const point = getPoint(stats[key], i);
        return `${point.x},${point.y}`;
      })
      .join(' ');
  };

  // Get label position
  const getLabelPosition = (index: number) => {
    const angle = angleStep * index - Math.PI / 2;
    const r = radius + 25;
    return {
      x: center + r * Math.cos(angle),
      y: center + r * Math.sin(angle),
    };
  };

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="drop-shadow-lg">
      {/* Background circles/levels */}
      {[20, 40, 60, 80, 100].map((level) => (
        <polygon
          key={level}
          points={getLevelPolygon(level)}
          fill="none"
          stroke="hsl(var(--neon-cyan) / 0.1)"
          strokeWidth="1"
        />
      ))}

      {/* Axis lines */}
      {statKeys.map((_, i) => {
        const point = getPoint(100, i);
        return (
          <line
            key={i}
            x1={center}
            y1={center}
            x2={point.x}
            y2={point.y}
            stroke="hsl(var(--neon-cyan) / 0.2)"
            strokeWidth="1"
          />
        );
      })}

      {/* Stats polygon with gradient */}
      <defs>
        <linearGradient id="statsGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="hsl(var(--neon-cyan))" stopOpacity="0.8" />
          <stop offset="100%" stopColor="hsl(var(--neon-purple))" stopOpacity="0.8" />
        </linearGradient>
        <filter id="glow">
          <feGaussianBlur stdDeviation="3" result="coloredBlur" />
          <feMerge>
            <feMergeNode in="coloredBlur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>

      <polygon
        points={getStatsPolygon()}
        fill="url(#statsGradient)"
        fillOpacity="0.3"
        stroke="url(#statsGradient)"
        strokeWidth="2"
        filter="url(#glow)"
      />

      {/* Stat points */}
      {statKeys.map((key, i) => {
        const point = getPoint(stats[key], i);
        return (
          <circle
            key={key}
            cx={point.x}
            cy={point.y}
            r="4"
            fill="hsl(var(--neon-cyan))"
            stroke="hsl(var(--background))"
            strokeWidth="2"
            filter="url(#glow)"
          />
        );
      })}

      {/* Labels */}
      {showLabels && labels.map((label, i) => {
        const pos = getLabelPosition(i);
        return (
          <text
            key={label}
            x={pos.x}
            y={pos.y}
            textAnchor="middle"
            dominantBaseline="middle"
            className="fill-muted-foreground text-[10px] font-rajdhani uppercase"
          >
            {label}
          </text>
        );
      })}
    </svg>
  );
};

export default RadarChart;
