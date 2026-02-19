/**
 * Código de colores por nivel/categoría del jugador (consistente en toda la app).
 * Elite = Dorado, Promesa (advanced) = Verde Neón, Base = Azul.
 */
import type { Database } from '@/integrations/supabase/types';

type PlayerLevel = Database['public']['Enums']['player_level'];
type PlayerCategory = Database['public']['Enums']['player_category'];

export const PLAYER_LEVEL_COLORS: Record<PlayerLevel, string> = {
  elite: '#E5B318',       // Dorado
  advanced: '#39FF14',    // Verde neón (Promesa)
  intermediate: '#06b6d4', // Azul (Base)
  beginner: '#06b6d4',    // Azul (Base)
};

export const PLAYER_LEVEL_LABELS: Record<PlayerLevel, string> = {
  elite: 'Elite',
  advanced: 'Promesa',
  intermediate: 'Base',
  beginner: 'Base',
};

export const PLAYER_CATEGORY_COLORS: Record<PlayerCategory, string> = {
  U8: '#06b6d4',
  U10: '#06b6d4',
  U12: '#22c55e',
  U14: '#39FF14',
  U16: '#a855f7',
  U18: '#E5B318',
};

/** Color para gráficos/líneas según level (Elite=gold, Promesa=neon green, Base=blue). */
export function getLevelColor(level: PlayerLevel | null | undefined): string {
  if (!level) return '#06b6d4';
  return PLAYER_LEVEL_COLORS[level] ?? '#06b6d4';
}
