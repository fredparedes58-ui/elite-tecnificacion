import React, { useState, useMemo } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { Badge } from '@/components/ui/badge';
import { useReservations } from '@/hooks/useReservations';
import { useCapacityColors } from '@/hooks/useCapacityColors';
import { format, startOfWeek, addDays, parseISO, setHours, setMinutes } from 'date-fns';
import { es } from 'date-fns/locale';
import { ChevronLeft, ChevronRight, Clock, Users } from 'lucide-react';
import { cn } from '@/lib/utils';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

// Time slots from 4pm to 10pm (16:00 - 22:00)
const TIME_SLOTS = [16, 17, 18, 19, 20, 21];
const DAYS_OF_WEEK = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

interface CapacityCalendarProps {
  onSelectSlot?: (date: Date, hour: number) => void;
  selectedSlot?: { date: Date; hour: number } | null;
}

const CapacityCalendar: React.FC<CapacityCalendarProps> = ({
  onSelectSlot,
  selectedSlot,
}) => {
  const { reservations, loading } = useReservations();
  const [weekStart, setWeekStart] = useState<Date>(() =>
    startOfWeek(new Date(), { weekStartsOn: 1 })
  );

  const weekDays = useMemo(() => {
    return Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  }, [weekStart]);

  const {
    capacityGrid,
    getCapacityClass,
    getCapacityBadgeClass,
    isSlotFull,
    MAX_CAPACITY,
  } = useCapacityColors(reservations, weekDays, TIME_SLOTS);

  const navigateWeek = (direction: 'prev' | 'next') => {
    setWeekStart((prev) => addDays(prev, direction === 'next' ? 7 : -7));
  };

  const handleSlotClick = (day: Date, hour: number) => {
    const dayKey = format(day, 'yyyy-MM-dd');
    if (isSlotFull(dayKey, hour)) return;
    onSelectSlot?.(day, hour);
  };

  const isSelected = (day: Date, hour: number) => {
    if (!selectedSlot) return false;
    return (
      format(day, 'yyyy-MM-dd') === format(selectedSlot.date, 'yyyy-MM-dd') &&
      hour === selectedSlot.hour
    );
  };

  if (loading) {
    return (
      <EliteCard>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin w-8 h-8 border-2 border-neon-cyan border-t-transparent rounded-full" />
        </div>
      </EliteCard>
    );
  }

  return (
    <EliteCard className="overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-orbitron gradient-text">Disponibilidad</h3>
        <div className="flex items-center gap-2">
          <NeonButton
            variant="outline"
            size="sm"
            onClick={() => navigateWeek('prev')}
          >
            <ChevronLeft className="w-4 h-4" />
          </NeonButton>
          <span className="text-sm font-rajdhani text-muted-foreground min-w-[120px] text-center">
            {format(weekStart, "d MMM", { locale: es })} -{' '}
            {format(addDays(weekStart, 6), "d MMM yyyy", { locale: es })}
          </span>
          <NeonButton
            variant="outline"
            size="sm"
            onClick={() => navigateWeek('next')}
          >
            <ChevronRight className="w-4 h-4" />
          </NeonButton>
        </div>
      </div>

      {/* Legend */}
      <div className="flex items-center gap-4 mb-4 text-xs">
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded bg-green-500/30 border border-green-500/50" />
          <span className="text-muted-foreground">Disponible</span>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded bg-amber-500/30 border border-amber-500/50" />
          <span className="text-muted-foreground">Casi lleno</span>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded bg-red-500/30 border border-red-500/50" />
          <span className="text-muted-foreground">Completo</span>
        </div>
      </div>

      {/* Calendar Grid */}
      <TooltipProvider>
        <div className="overflow-x-auto -mx-4 px-4">
          <div className="min-w-[600px]">
            {/* Days Header */}
            <div className="grid grid-cols-8 gap-1 mb-1">
              <div className="p-2 text-center">
                <Clock className="w-4 h-4 mx-auto text-muted-foreground" />
              </div>
              {weekDays.map((day, i) => (
                <div key={i} className="p-2 text-center">
                  <div className="text-xs text-muted-foreground">
                    {DAYS_OF_WEEK[i]}
                  </div>
                  <div
                    className={cn(
                      'text-sm font-rajdhani font-bold',
                      format(day, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd')
                        ? 'text-neon-cyan'
                        : 'text-foreground'
                    )}
                  >
                    {format(day, 'd')}
                  </div>
                </div>
              ))}
            </div>

            {/* Time Slots */}
            {TIME_SLOTS.map((hour) => (
              <div key={hour} className="grid grid-cols-8 gap-1 mb-1">
                {/* Hour Label */}
                <div className="p-2 flex items-center justify-center">
                  <span className="text-xs font-rajdhani text-muted-foreground">
                    {hour}:00
                  </span>
                </div>

                {/* Day Cells */}
                {weekDays.map((day, dayIndex) => {
                  const dayKey = format(day, 'yyyy-MM-dd');
                  const capacity = capacityGrid[dayKey]?.[hour];
                  const isFull = isSlotFull(dayKey, hour);
                  const selected = isSelected(day, hour);

                  return (
                    <Tooltip key={dayIndex}>
                      <TooltipTrigger asChild>
                        <button
                          onClick={() => handleSlotClick(day, hour)}
                          disabled={isFull}
                          className={cn(
                            'p-2 rounded-lg border transition-all duration-200 min-h-[48px] relative',
                            getCapacityClass(dayKey, hour),
                            selected && 'ring-2 ring-neon-cyan ring-offset-2 ring-offset-background',
                            !isFull && 'hover:scale-[1.02] cursor-pointer'
                          )}
                        >
                          <div className="flex flex-col items-center gap-1">
                            <div className="flex items-center gap-0.5">
                              <Users className="w-3 h-3" />
                              <span className="text-xs font-rajdhani font-bold">
                                {capacity?.total || 0}/{MAX_CAPACITY}
                              </span>
                            </div>
                            {capacity && capacity.total > 0 && (
                              <div className="w-full bg-background/50 rounded-full h-1 overflow-hidden">
                                <div
                                  className={cn(
                                    'h-full transition-all',
                                    capacity.color === 'green' && 'bg-green-500',
                                    capacity.color === 'amber' && 'bg-amber-500',
                                    capacity.color === 'red' && 'bg-red-500'
                                  )}
                                  style={{ width: `${capacity.percentage}%` }}
                                />
                              </div>
                            )}
                          </div>
                        </button>
                      </TooltipTrigger>
                      <TooltipContent>
                        <div className="text-center">
                          <p className="font-rajdhani font-bold">
                            {format(day, "EEEE d 'de' MMMM", { locale: es })}
                          </p>
                          <p className="text-muted-foreground">
                            {hour}:00 - {hour + 1}:00
                          </p>
                          <Badge
                            variant="outline"
                            className={cn('mt-1', getCapacityBadgeClass(dayKey, hour))}
                          >
                            {capacity?.label || 'Disponible'}
                          </Badge>
                        </div>
                      </TooltipContent>
                    </Tooltip>
                  );
                })}
              </div>
            ))}
          </div>
        </div>
      </TooltipProvider>
    </EliteCard>
  );
};

export default CapacityCalendar;
