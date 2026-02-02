import React, { useState, useMemo, useEffect } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { Badge } from '@/components/ui/badge';
import { format, startOfWeek, addDays } from 'date-fns';
import { es } from 'date-fns/locale';
import { ChevronLeft, ChevronRight, Clock, Users, Check } from 'lucide-react';
import { cn } from '@/lib/utils';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';
import { supabase } from '@/integrations/supabase/client';

const TIME_SLOTS = [16, 17, 18, 19, 20, 21];
const DAYS_OF_WEEK = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
const MAX_CAPACITY = 6;

export interface SelectedSlot {
  date: Date;
  hour: number;
}

interface AvailabilitySlot {
  date: string;
  hour: number;
  count: number;
}

interface AvailabilityPickerProps {
  onSelectSlot: (slot: SelectedSlot | null) => void;
  selectedSlot: SelectedSlot | null;
}

const AvailabilityPicker: React.FC<AvailabilityPickerProps> = ({
  onSelectSlot,
  selectedSlot,
}) => {
  const [loading, setLoading] = useState(true);
  const [availability, setAvailability] = useState<AvailabilitySlot[]>([]);
  const [weekStart, setWeekStart] = useState<Date>(() =>
    startOfWeek(new Date(), { weekStartsOn: 1 })
  );

  const weekDays = useMemo(() => {
    return Array.from({ length: 6 }, (_, i) => addDays(weekStart, i));
  }, [weekStart]);

  // Fetch availability when week changes
  useEffect(() => {
    const fetchAvailability = async () => {
      setLoading(true);
      try {
        const startDate = weekStart.toISOString();
        const endDate = addDays(weekStart, 6).toISOString();
        
        const { data, error } = await supabase.functions.invoke('get-availability', {
          body: { start_date: startDate, end_date: endDate },
        });

        if (error) throw error;
        setAvailability(data.slots || []);
      } catch (err) {
        console.error('Error fetching availability:', err);
        setAvailability([]);
      } finally {
        setLoading(false);
      }
    };

    fetchAvailability();
  }, [weekStart]);

  // Build capacity grid from availability data
  const capacityGrid = useMemo(() => {
    const grid: Record<string, Record<number, { total: number; color: 'green' | 'amber' | 'red'; label: string; percentage: number }>> = {};

    weekDays.forEach((day) => {
      const dayKey = format(day, 'yyyy-MM-dd');
      grid[dayKey] = {};

      TIME_SLOTS.forEach((hour) => {
        const slot = availability.find(s => s.date === dayKey && s.hour === hour);
        const total = slot?.count || 0;
        const available = MAX_CAPACITY - total;
        const percentage = (total / MAX_CAPACITY) * 100;

        let color: 'green' | 'amber' | 'red';
        let label: string;

        if (total >= MAX_CAPACITY) {
          color = 'red';
          label = 'Completo';
        } else if (total >= 4) {
          color = 'amber';
          label = `${available} disponibles`;
        } else {
          color = 'green';
          label = `${available} disponibles`;
        }

        grid[dayKey][hour] = { total, color, label, percentage };
      });
    });

    return grid;
  }, [availability, weekDays]);

  const navigateWeek = (direction: 'prev' | 'next') => {
    setWeekStart((prev) => addDays(prev, direction === 'next' ? 7 : -7));
  };

  const handleSlotClick = (day: Date, hour: number) => {
    const dayKey = format(day, 'yyyy-MM-dd');
    const slotInfo = capacityGrid[dayKey]?.[hour];
    if (slotInfo?.total >= MAX_CAPACITY) return;
    
    const slotDate = new Date(day);
    slotDate.setHours(hour, 0, 0, 0);
    if (slotDate < new Date()) return;
    
    if (isSelected(day, hour)) {
      onSelectSlot(null);
    } else {
      onSelectSlot({ date: day, hour });
    }
  };

  const isSelected = (day: Date, hour: number) => {
    if (!selectedSlot) return false;
    return (
      format(day, 'yyyy-MM-dd') === format(selectedSlot.date, 'yyyy-MM-dd') &&
      hour === selectedSlot.hour
    );
  };

  const isPast = (day: Date, hour: number) => {
    const slotDate = new Date(day);
    slotDate.setHours(hour, 0, 0, 0);
    return slotDate < new Date();
  };

  const getCapacityClass = (dayKey: string, hour: number): string => {
    const info = capacityGrid[dayKey]?.[hour];
    if (!info) return 'bg-green-500/10 border-green-500/30';

    switch (info.color) {
      case 'green':
        return 'bg-green-500/10 border-green-500/30 hover:bg-green-500/20';
      case 'amber':
        return 'bg-amber-500/10 border-amber-500/30 hover:bg-amber-500/20';
      case 'red':
        return 'bg-red-500/10 border-red-500/30 cursor-not-allowed opacity-60';
      default:
        return '';
    }
  };

  if (loading) {
    return (
      <EliteCard className="p-6">
        <div className="flex items-center justify-center h-48">
          <div className="animate-spin w-8 h-8 border-2 border-neon-cyan border-t-transparent rounded-full" />
        </div>
      </EliteCard>
    );
  }

  return (
    <EliteCard className="p-4 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-orbitron gradient-text">Selecciona un horario</h3>
        <div className="flex items-center gap-2">
          <NeonButton
            variant="outline"
            size="sm"
            onClick={() => navigateWeek('prev')}
          >
            <ChevronLeft className="w-4 h-4" />
          </NeonButton>
          <span className="text-sm font-rajdhani text-muted-foreground min-w-[140px] text-center">
            {format(weekStart, "d MMM", { locale: es })} -{' '}
            {format(addDays(weekStart, 5), "d MMM yyyy", { locale: es })}
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
      <div className="flex flex-wrap items-center gap-3 mb-4 text-xs">
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
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded bg-neon-cyan/50 border-2 border-neon-cyan" />
          <span className="text-muted-foreground">Seleccionado</span>
        </div>
      </div>

      {/* Calendar Grid */}
      <TooltipProvider>
        <div className="overflow-x-auto -mx-4 px-4">
          <div className="min-w-[500px]">
            {/* Days Header */}
            <div className="grid grid-cols-7 gap-1 mb-1">
              <div className="p-2 text-center">
                <Clock className="w-4 h-4 mx-auto text-muted-foreground" />
              </div>
              {weekDays.map((day, i) => {
                const isToday = format(day, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd');
                return (
                  <div key={i} className="p-2 text-center">
                    <div className="text-xs text-muted-foreground">
                      {DAYS_OF_WEEK[i]}
                    </div>
                    <div
                      className={cn(
                        'text-sm font-rajdhani font-bold',
                        isToday ? 'text-neon-cyan' : 'text-foreground'
                      )}
                    >
                      {format(day, 'd')}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Time Slots */}
            {TIME_SLOTS.map((hour) => (
              <div key={hour} className="grid grid-cols-7 gap-1 mb-1">
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
                  const isFull = capacity?.total >= MAX_CAPACITY;
                  const selected = isSelected(day, hour);
                  const past = isPast(day, hour);

                  return (
                    <Tooltip key={dayIndex}>
                      <TooltipTrigger asChild>
                        <button
                          onClick={() => handleSlotClick(day, hour)}
                          disabled={isFull || past}
                          className={cn(
                            'p-2 rounded-lg border transition-all duration-200 min-h-[48px] relative',
                            past 
                              ? 'bg-muted/20 border-muted/30 opacity-50 cursor-not-allowed'
                              : getCapacityClass(dayKey, hour),
                            selected && 'ring-2 ring-neon-cyan ring-offset-2 ring-offset-background bg-neon-cyan/20',
                            !isFull && !past && 'hover:scale-[1.02] cursor-pointer'
                          )}
                        >
                          <div className="flex flex-col items-center gap-1">
                            {selected ? (
                              <Check className="w-5 h-5 text-neon-cyan" />
                            ) : (
                              <>
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
                              </>
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
                          {past ? (
                            <Badge variant="outline" className="mt-1 text-muted-foreground">
                              Pasado
                            </Badge>
                          ) : (
                            <Badge
                              variant="outline"
                              className={cn(
                                'mt-1',
                                capacity?.color === 'green' && 'bg-green-500/20 text-green-400 border-green-500/30',
                                capacity?.color === 'amber' && 'bg-amber-500/20 text-amber-400 border-amber-500/30',
                                capacity?.color === 'red' && 'bg-red-500/20 text-red-400 border-red-500/30'
                              )}
                            >
                              {capacity?.label || 'Disponible'}
                            </Badge>
                          )}
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

      {/* Selected Slot Summary */}
      {selectedSlot && (
        <div className="mt-4 p-3 rounded-lg bg-neon-cyan/10 border border-neon-cyan/30">
          <p className="text-sm font-rajdhani text-center">
            <span className="text-muted-foreground">Horario seleccionado:</span>{' '}
            <span className="text-neon-cyan font-bold">
              {format(selectedSlot.date, "EEEE d 'de' MMMM", { locale: es })} a las {selectedSlot.hour}:00
            </span>
          </p>
        </div>
      )}
    </EliteCard>
  );
};

export default AvailabilityPicker;
