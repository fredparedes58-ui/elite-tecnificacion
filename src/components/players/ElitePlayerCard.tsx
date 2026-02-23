/**
 * Elite Player Card - Estilo EA Sports FC / Ultimate Team
 * Dark mode, bordes neón (#39FF14), glassmorphism, radar 6 puntas.
 * Coach: skills y Notas editables con mutación optimista. Valor Total en tiempo real.
 */
import React, { useMemo, useState, useCallback, useEffect } from 'react';
import { cn } from '@/lib/utils';

const NEON_GREEN = '#39FF14';

export interface PlayerSkills {
  velocidad: number;
  tiro: number;
  pase: number;
  regate: number;
  defensa: number;
  fisico: number;
}

const SKILL_KEYS: (keyof PlayerSkills)[] = [
  'velocidad',
  'tiro',
  'pase',
  'regate',
  'defensa',
  'fisico',
];

const SKILL_LABELS: Record<keyof PlayerSkills, string> = {
  velocidad: 'Velocidad',
  tiro: 'Tiro',
  pase: 'Pase',
  regate: 'Regate',
  defensa: 'Defensa',
  fisico: 'Físico',
};

export interface ElitePlayerCardProps {
  name: string;
  position?: string | null;
  photoUrl?: string | null;
  skills: PlayerSkills;
  notes?: string | null;
  isCoach?: boolean;
  onSkillsChange?: (skills: PlayerSkills) => void | Promise<void>;
  onNotesChange?: (notes: string) => void | Promise<void>;
  className?: string;
}

function computeValorTotal(skills: PlayerSkills): number {
  const sum = SKILL_KEYS.reduce((acc, k) => acc + skills[k], 0);
  return Math.round(sum / 6);
}

export const ElitePlayerCard: React.FC<ElitePlayerCardProps> = ({
  name,
  position,
  photoUrl,
  skills,
  notes = '',
  isCoach = false,
  onSkillsChange,
  onNotesChange,
  className,
}) => {
  const [localSkills, setLocalSkills] = useState<PlayerSkills>(skills);
  const [localNotes, setLocalNotes] = useState(notes);
  const [isEditingNotes, setIsEditingNotes] = useState(false);
  const [hoveredSkill, setHoveredSkill] = useState<keyof PlayerSkills | null>(null);

  useEffect(() => {
    setLocalSkills(skills);
  }, [skills]);
  useEffect(() => {
    if (!isEditingNotes) setLocalNotes(notes ?? '');
  }, [notes, isEditingNotes]);

  const valorTotal = useMemo(() => computeValorTotal(localSkills), [localSkills]);

  const handleSkillChange = useCallback(
    (key: keyof PlayerSkills, delta: number) => {
      if (!isCoach) return;
      const next = { ...localSkills, [key]: Math.min(100, Math.max(0, localSkills[key] + delta)) };
      setLocalSkills(next);
      onSkillsChange?.(next);
    },
    [isCoach, localSkills, onSkillsChange]
  );

  const handleNotesBlur = useCallback(() => {
    setIsEditingNotes(false);
    if (localNotes !== notes) onNotesChange?.(localNotes);
  }, [localNotes, notes, onNotesChange]);

  const size = 160;
  const center = size / 2;
  const radius = size * 0.32;
  const angleStep = (2 * Math.PI) / 6;

  const getPoint = (value: number, index: number) => {
    const angle = angleStep * index - Math.PI / 2;
    const r = (value / 100) * radius;
    return {
      x: center + r * Math.cos(angle),
      y: center + r * Math.sin(angle),
    };
  };

  const getLevelPolygon = (level: number) =>
    SKILL_KEYS.map((_, i) => getPoint(level, i))
      .map((p) => `${p.x},${p.y}`)
      .join(' ');

  const getStatsPolygon = () =>
    SKILL_KEYS.map((key, i) => getPoint(localSkills[key], i))
      .map((p) => `${p.x},${p.y}`)
      .join(' ');

  const getLabelPos = (index: number) => {
    const angle = angleStep * index - Math.PI / 2;
    const r = radius + size * 0.12;
    return {
      x: center + r * Math.cos(angle),
      y: center + r * Math.sin(angle),
    };
  };

  return (
    <div
      className={cn(
        'relative rounded-2xl overflow-hidden',
        'bg-black/60 border-2 border-[#39FF14]/50',
        'backdrop-blur-xl shadow-[0_0_30px_rgba(57,255,20,0.15),inset_0_1px_0_rgba(255,255,255,0.1)]',
        'min-w-[280px] max-w-[320px]',
        className
      )}
      style={{
        borderColor: `${NEON_GREEN}80`,
        boxShadow: `0 0 30px ${NEON_GREEN}26, inset 0 1px 0 rgba(255,255,255,0.08)`,
      }}
    >
      {/* Valor Total - esquina superior derecha */}
      <div
        className="absolute top-3 right-3 z-10 font-orbitron font-black text-2xl tabular-nums"
        style={{
          color: NEON_GREEN,
          textShadow: `0 0 12px ${NEON_GREEN}, 0 0 24px ${NEON_GREEN}80`,
        }}
      >
        {valorTotal}
      </div>

      {/* Gradiente metálico superior */}
      <div
        className="absolute inset-0 pointer-events-none rounded-2xl"
        style={{
          background: `linear-gradient(165deg, rgba(255,255,255,0.12) 0%, transparent 50%, rgba(0,0,0,0.2) 100%)`,
        }}
      />

      <div className="relative p-4">
        {/* Foto + nombre + posición */}
        <div className="flex items-center gap-4 mb-4">
          <div
            className="w-16 h-16 rounded-xl overflow-hidden border-2 flex-shrink-0"
            style={{ borderColor: `${NEON_GREEN}60` }}
          >
            {photoUrl ? (
              <img
                src={photoUrl}
                alt={name}
                className="w-full h-full object-cover"
              />
            ) : (
              <div
                className="w-full h-full flex items-center justify-center text-2xl font-bold"
                style={{ backgroundColor: `${NEON_GREEN}20`, color: NEON_GREEN }}
              >
                {name.charAt(0)}
              </div>
            )}
          </div>
          <div className="min-w-0 flex-1">
            <h3 className="font-orbitron font-bold text-lg text-foreground truncate">
              {name}
            </h3>
            {position && (
              <p className="text-sm truncate" style={{ color: `${NEON_GREEN}cc` }}>
                {position}
              </p>
            )}
          </div>
        </div>

        {/* Radar 6 puntas */}
        <div className="flex justify-center mb-4">
          <svg
            width={size}
            height={size}
            viewBox={`0 0 ${size} ${size}`}
            className="flex-shrink-0"
          >
            {/* Niveles de fondo */}
            {[20, 40, 60, 80, 100].map((level) => (
              <polygon
                key={level}
                points={getLevelPolygon(level)}
                fill="none"
                stroke={`${NEON_GREEN}20`}
                strokeWidth="1"
              />
            ))}
            {/* Ejes */}
            {SKILL_KEYS.map((_, i) => {
              const p = getPoint(100, i);
              return (
                <line
                  key={i}
                  x1={center}
                  y1={center}
                  x2={p.x}
                  y2={p.y}
                  stroke={`${NEON_GREEN}30`}
                  strokeWidth="1"
                />
              );
            })}
            {/* Área de stats */}
            <polygon
              points={getStatsPolygon()}
              fill={`${NEON_GREEN}30`}
              stroke={NEON_GREEN}
              strokeWidth="2"
              style={{ filter: `drop-shadow(0 0 6px ${NEON_GREEN}80)` }}
            />
            {/* Labels */}
            {SKILL_KEYS.map((key, i) => {
              const pos = getLabelPos(i);
              const isHover = hoveredSkill === key;
              return (
                <g key={key}>
                  <text
                    x={pos.x}
                    y={pos.y}
                    textAnchor="middle"
                    dominantBaseline="middle"
                    className="text-[10px] font-rajdhani fill-white/90"
                  >
                    {SKILL_LABELS[key].slice(0, 3)}
                  </text>
                  {isCoach && (
                    <g
                      onMouseEnter={() => setHoveredSkill(key)}
                      onMouseLeave={() => setHoveredSkill(null)}
                    >
                      <rect
                        x={pos.x - 18}
                        y={pos.y - 8}
                        width={36}
                        height={16}
                        fill="transparent"
                        className="cursor-pointer"
                      />
                      {isHover && (
                        <text
                          x={pos.x}
                          y={pos.y - 14}
                          textAnchor="middle"
                          className="text-[9px] fill-[#39FF14]"
                        >
                          {localSkills[key]}
                        </text>
                      )}
                    </g>
                  )}
                </g>
              );
            })}
          </svg>
        </div>

        {/* Controles +1/-1 para coach (hover effect) */}
        {isCoach && (
          <div className="flex flex-wrap justify-center gap-2 mb-3">
            {SKILL_KEYS.map((key) => (
              <div
                key={key}
                className="flex items-center gap-0.5 rounded-lg border px-2 py-1"
                style={{ borderColor: `${NEON_GREEN}40` }}
              >
                <span className="text-[10px] text-foreground/80 w-10">{SKILL_LABELS[key].slice(0, 3)}</span>
                <button
                  type="button"
                  className="w-5 h-5 rounded text-xs font-bold flex items-center justify-center hover:bg-[#39FF14]/20 transition-colors"
                  style={{ color: NEON_GREEN }}
                  onClick={() => handleSkillChange(key, -5)}
                >
                  −
                </button>
                <span className="w-6 text-center text-xs font-orbitron" style={{ color: NEON_GREEN }}>
                  {localSkills[key]}
                </span>
                <button
                  type="button"
                  className="w-5 h-5 rounded text-xs font-bold flex items-center justify-center hover:bg-[#39FF14]/20 transition-colors"
                  style={{ color: NEON_GREEN }}
                  onClick={() => handleSkillChange(key, 5)}
                >
                  +
                </button>
              </div>
            ))}
          </div>
        )}

        {/* Notas (editables por coach) */}
        <div className="rounded-xl border p-3 min-h-[60px]" style={{ borderColor: `${NEON_GREEN}30` }}>
          {isCoach && isEditingNotes ? (
            <textarea
              value={localNotes}
              onChange={(e) => setLocalNotes(e.target.value)}
              onBlur={handleNotesBlur}
              onKeyDown={(e) => e.key === 'Enter' && (e.target as HTMLTextAreaElement).blur()}
              placeholder="Notas del entrenador..."
              className="w-full bg-transparent text-sm text-foreground/90 placeholder-muted-foreground resize-none focus:outline-none"
              rows={2}
              autoFocus
            />
          ) : (
            <p
              className={cn(
                'text-sm text-foreground/80 whitespace-pre-wrap',
                isCoach && 'cursor-pointer hover:bg-foreground/5 rounded p-1 -m-1'
              )}
              onClick={() => isCoach && setIsEditingNotes(true)}
            >
              {localNotes || (isCoach ? 'Clic para añadir notas...' : '—')}
            </p>
          )}
        </div>
      </div>
    </div>
  );
};

/** Convierte stats en formato BD (p. ej. speed, technique...) a PlayerSkills para la carta. */
export function mapStatsToPlayerSkills(stats: Record<string, unknown> | null): PlayerSkills {
  const def: PlayerSkills = {
    velocidad: 50,
    tiro: 50,
    pase: 50,
    regate: 50,
    defensa: 50,
    fisico: 50,
  };
  if (!stats || typeof stats !== 'object') return def;
  const map: Record<keyof PlayerSkills, string[]> = {
    velocidad: ['velocidad', 'speed'],
    tiro: ['tiro', 'shooting', 'mental'],
    pase: ['pase', 'passing', 'paseo', 'technique'],
    regate: ['regate', 'dribbling', 'technique'],
    defensa: ['defensa', 'defending', 'tactical'],
    fisico: ['fisico', 'physical', 'physicality'],
  };
  const out = { ...def };
  (Object.keys(map) as (keyof PlayerSkills)[]).forEach((key) => {
    const candidates = map[key];
    for (const c of candidates) {
      const v = stats[c];
      if (typeof v === 'number' && v >= 0 && v <= 100) {
        out[key] = Math.round(v);
        break;
      }
    }
  });
  return out;
}

/** Convierte PlayerSkills (6) al formato de stats en BD (speed, technique, physical, mental, tactical). */
export function playerSkillsToStats(skills: PlayerSkills): Record<string, number> {
  return {
    speed: skills.velocidad,
    technique: Math.round((skills.pase + skills.regate) / 2),
    physical: skills.fisico,
    mental: skills.tiro,
    tactical: skills.defensa,
  };
}

export default ElitePlayerCard;
