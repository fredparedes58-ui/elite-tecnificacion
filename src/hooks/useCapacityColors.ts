import { useMemo } from 'react';
import { format, parseISO } from 'date-fns';

export interface CapacityInfo {
  total: number;
  available: number;
  color: 'green' | 'amber' | 'red';
  label: string;
  percentage: number;
}

const MAX_CAPACITY_PER_BLOCK = 6; // 3 con Pedro + 3 con Saúl

export const useCapacityColors = (
  reservations: Array<{ start_time: string; status?: string | null }>,
  weekDays: Date[],
  timeSlots: number[]
) => {
  const capacityGrid = useMemo(() => {
    const grid: Record<string, Record<number, CapacityInfo>> = {};

    weekDays.forEach((day) => {
      const dayKey = format(day, 'yyyy-MM-dd');
      grid[dayKey] = {};

      timeSlots.forEach((hour) => {
        // Count approved/completed reservations for this slot
        const slotReservations = reservations.filter((r) => {
          if (!r.status || !['approved', 'completed', 'pending'].includes(r.status)) {
            return false;
          }
          const resDate = parseISO(r.start_time);
          return (
            format(resDate, 'yyyy-MM-dd') === dayKey &&
            resDate.getHours() === hour
          );
        });

        const total = slotReservations.length;
        const available = MAX_CAPACITY_PER_BLOCK - total;
        const percentage = (total / MAX_CAPACITY_PER_BLOCK) * 100;

        let color: 'green' | 'amber' | 'red';
        let label: string;

        if (total >= MAX_CAPACITY_PER_BLOCK) {
          color = 'red';
          label = 'Completo';
        } else if (total >= 4) {
          color = 'amber';
          label = `${available} disponibles`;
        } else {
          color = 'green';
          label = `${available} disponibles`;
        }

        grid[dayKey][hour] = {
          total,
          available,
          color,
          label,
          percentage,
        };
      });
    });

    return grid;
  }, [reservations, weekDays, timeSlots]);

  const getCapacityClass = (dayKey: string, hour: number): string => {
    const info = capacityGrid[dayKey]?.[hour];
    if (!info) return '';

    switch (info.color) {
      case 'green':
        return 'bg-green-500/10 border-green-500/30 hover:bg-green-500/20';
      case 'amber':
        return 'bg-amber-500/10 border-amber-500/30 hover:bg-amber-500/20';
      case 'red':
        return 'bg-red-500/10 border-red-500/30 hover:bg-red-500/20 cursor-not-allowed';
      default:
        return '';
    }
  };

  const getCapacityBadgeClass = (dayKey: string, hour: number): string => {
    const info = capacityGrid[dayKey]?.[hour];
    if (!info) return '';

    switch (info.color) {
      case 'green':
        return 'bg-green-500/20 text-green-400 border-green-500/30';
      case 'amber':
        return 'bg-amber-500/20 text-amber-400 border-amber-500/30';
      case 'red':
        return 'bg-red-500/20 text-red-400 border-red-500/30';
      default:
        return '';
    }
  };

  const isSlotFull = (dayKey: string, hour: number): boolean => {
    const info = capacityGrid[dayKey]?.[hour];
    return info?.total >= MAX_CAPACITY_PER_BLOCK;
  };

  return {
    capacityGrid,
    getCapacityClass,
    getCapacityBadgeClass,
    isSlotFull,
    MAX_CAPACITY: MAX_CAPACITY_PER_BLOCK,
  };
};

export default useCapacityColors;
