import React, { useState, useMemo } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Calendar } from '@/components/ui/calendar';
import { useAllReservations, Reservation } from '@/hooks/useReservations';
import { useTrainers, Trainer } from '@/hooks/useTrainers';
import { useToast } from '@/hooks/use-toast';
import { format, isSameDay, startOfDay, addHours, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  Check, 
  X, 
  Clock, 
  User, 
  Users,
  ChevronLeft,
  ChevronRight,
  AlertCircle,
  CheckCircle2,
  XCircle
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

// Session time slots (7am to 9pm)
const TIME_SLOTS = Array.from({ length: 14 }, (_, i) => i + 7); // 7, 8, 9... 20

interface ReservationWithTrainer extends Reservation {
  trainer?: Trainer;
}

const getStatusConfig = (status: string) => {
  switch (status) {
    case 'approved':
      return { variant: 'info' as const, label: 'Aprobada', icon: CheckCircle2, color: 'text-neon-cyan' };
    case 'completed':
      return { variant: 'success' as const, label: 'Completada', icon: CheckCircle2, color: 'text-green-400' };
    case 'pending':
      return { variant: 'warning' as const, label: 'Pendiente', icon: Clock, color: 'text-yellow-400' };
    case 'rejected':
      return { variant: 'error' as const, label: 'Rechazada', icon: XCircle, color: 'text-red-400' };
    case 'no_show':
      return { variant: 'error' as const, label: 'No Asistió', icon: AlertCircle, color: 'text-orange-400' };
    default:
      return { variant: 'default' as const, label: status, icon: Clock, color: 'text-muted-foreground' };
  }
};

const ReservationCalendarView: React.FC = () => {
  const { reservations, loading, updateReservationStatus, refetch } = useAllReservations();
  const { trainers } = useTrainers();
  const { toast } = useToast();
  
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [selectedReservation, setSelectedReservation] = useState<ReservationWithTrainer | null>(null);
  const [detailModalOpen, setDetailModalOpen] = useState(false);

  // Filter reservations for selected date
  const dayReservations = useMemo(() => {
    return reservations.filter(r => {
      const reservationDate = parseISO(r.start_time);
      return isSameDay(reservationDate, selectedDate);
    });
  }, [reservations, selectedDate]);

  // Group reservations by trainer and hour
  const scheduleGrid = useMemo(() => {
    const grid: Record<string, Record<number, ReservationWithTrainer[]>> = {};
    
    // Initialize grid for all trainers
    trainers.forEach(trainer => {
      grid[trainer.id] = {};
      TIME_SLOTS.forEach(hour => {
        grid[trainer.id][hour] = [];
      });
    });
    
    // Add "Sin Asignar" column for reservations without trainer
    grid['unassigned'] = {};
    TIME_SLOTS.forEach(hour => {
      grid['unassigned'][hour] = [];
    });

    // Populate grid
    dayReservations.forEach(reservation => {
      const hour = parseISO(reservation.start_time).getHours();
      const trainerId = (reservation as any).trainer_id || 'unassigned';
      const trainer = trainers.find(t => t.id === trainerId);
      
      if (!grid[trainerId]) {
        grid[trainerId] = {};
        TIME_SLOTS.forEach(h => {
          grid[trainerId][h] = [];
        });
      }
      
      if (grid[trainerId][hour]) {
        grid[trainerId][hour].push({
          ...reservation,
          trainer
        });
      }
    });

    return grid;
  }, [dayReservations, trainers]);

  // Dates with reservations for calendar highlighting
  const datesWithReservations = useMemo(() => {
    const dates = new Set<string>();
    reservations.forEach(r => {
      const date = format(parseISO(r.start_time), 'yyyy-MM-dd');
      dates.add(date);
    });
    return dates;
  }, [reservations]);

  const handleStatusUpdate = async (id: string, status: 'approved' | 'rejected' | 'completed' | 'no_show' | 'pending') => {
    const success = await updateReservationStatus(id, status);
    if (success) {
      toast({
        title: 'Estado actualizado',
        description: `La reserva ha sido marcada como ${getStatusConfig(status).label}.`,
      });
      setDetailModalOpen(false);
    } else {
      toast({
        title: 'Error',
        description: 'No se pudo actualizar el estado.',
        variant: 'destructive',
      });
    }
  };

  const openReservationDetail = (reservation: ReservationWithTrainer) => {
    setSelectedReservation(reservation);
    setDetailModalOpen(true);
  };

  const navigateDay = (direction: 'prev' | 'next') => {
    const newDate = new Date(selectedDate);
    newDate.setDate(newDate.getDate() + (direction === 'next' ? 1 : -1));
    setSelectedDate(newDate);
  };

  // Get active trainers plus unassigned column
  const columns = useMemo(() => {
    const cols: { id: string; name: string; specialty?: string }[] = [
      { id: 'unassigned', name: 'Sin Asignar' }
    ];
    trainers.forEach(t => {
      cols.push({ id: t.id, name: t.name, specialty: t.specialty || undefined });
    });
    return cols;
  }, [trainers]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-12 h-12 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col lg:flex-row gap-6">
        {/* Calendar */}
        <EliteCard className="p-4 lg:w-80 shrink-0">
          <Calendar
            mode="single"
            selected={selectedDate}
            onSelect={(date) => date && setSelectedDate(date)}
            locale={es}
            className="pointer-events-auto"
            modifiers={{
              hasReservation: (date) => datesWithReservations.has(format(date, 'yyyy-MM-dd'))
            }}
            modifiersStyles={{
              hasReservation: {
                backgroundColor: 'hsl(var(--neon-cyan) / 0.2)',
                borderRadius: '4px'
              }
            }}
          />
          
          {/* Stats */}
          <div className="mt-4 pt-4 border-t border-border space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Total hoy:</span>
              <span className="font-orbitron text-neon-cyan">{dayReservations.length}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Pendientes:</span>
              <span className="font-orbitron text-yellow-400">
                {dayReservations.filter(r => r.status === 'pending').length}
              </span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Completadas:</span>
              <span className="font-orbitron text-green-400">
                {dayReservations.filter(r => r.status === 'completed').length}
              </span>
            </div>
          </div>
        </EliteCard>

        {/* Schedule Grid */}
        <div className="flex-1 min-w-0">
          {/* Date Navigation */}
          <div className="flex items-center justify-between mb-4">
            <NeonButton variant="outline" size="sm" onClick={() => navigateDay('prev')}>
              <ChevronLeft className="w-4 h-4" />
            </NeonButton>
            <h2 className="font-orbitron font-bold text-xl gradient-text text-center">
              {format(selectedDate, "EEEE, dd 'de' MMMM yyyy", { locale: es })}
            </h2>
            <NeonButton variant="outline" size="sm" onClick={() => navigateDay('next')}>
              <ChevronRight className="w-4 h-4" />
            </NeonButton>
          </div>

          {/* Grid */}
          <EliteCard className="overflow-x-auto">
            <div className="min-w-[800px]">
              {/* Header Row - Trainers */}
              <div className="grid border-b border-neon-cyan/20" style={{ gridTemplateColumns: `80px repeat(${columns.length}, 1fr)` }}>
                <div className="p-3 font-orbitron text-sm text-muted-foreground border-r border-neon-cyan/10">
                  Hora
                </div>
                {columns.map(col => (
                  <div key={col.id} className="p-3 text-center border-r border-neon-cyan/10 last:border-r-0">
                    <div className="font-orbitron text-sm text-foreground">{col.name}</div>
                    {col.specialty && (
                      <div className="text-xs text-neon-purple">{col.specialty}</div>
                    )}
                  </div>
                ))}
              </div>

              {/* Time Rows */}
              {TIME_SLOTS.map(hour => (
                <div 
                  key={hour} 
                  className="grid border-b border-neon-cyan/10 last:border-b-0 min-h-[80px]"
                  style={{ gridTemplateColumns: `80px repeat(${columns.length}, 1fr)` }}
                >
                  {/* Hour Label */}
                  <div className="p-2 font-orbitron text-sm text-neon-cyan border-r border-neon-cyan/10 flex items-start justify-center">
                    {String(hour).padStart(2, '0')}:00
                  </div>
                  
                  {/* Trainer Columns */}
                  {columns.map(col => {
                    const cellReservations = scheduleGrid[col.id]?.[hour] || [];
                    
                    return (
                      <div 
                        key={`${col.id}-${hour}`} 
                        className="p-1 border-r border-neon-cyan/10 last:border-r-0 space-y-1"
                      >
                        {cellReservations.map(reservation => {
                          const statusConfig = getStatusConfig(reservation.status || 'pending');
                          const StatusIcon = statusConfig.icon;
                          
                          return (
                            <button
                              key={reservation.id}
                              onClick={() => openReservationDetail(reservation)}
                              className={`w-full p-2 rounded-md text-left transition-all hover:scale-[1.02] hover:shadow-lg ${
                                reservation.status === 'completed' 
                                  ? 'bg-green-500/20 border border-green-500/30'
                                  : reservation.status === 'no_show'
                                  ? 'bg-orange-500/20 border border-orange-500/30'
                                  : reservation.status === 'approved'
                                  ? 'bg-neon-cyan/10 border border-neon-cyan/30'
                                  : reservation.status === 'rejected'
                                  ? 'bg-red-500/20 border border-red-500/30'
                                  : 'bg-yellow-500/10 border border-yellow-500/30'
                              }`}
                            >
                              <div className="flex items-center gap-1 mb-1">
                                <StatusIcon className={`w-3 h-3 ${statusConfig.color}`} />
                                <span className="text-xs font-rajdhani font-medium truncate">
                                  {reservation.title}
                                </span>
                              </div>
                              <div className="flex items-center gap-1 text-xs text-muted-foreground">
                                <User className="w-3 h-3" />
                                <span className="truncate">
                                  {reservation.player?.name || reservation.user?.full_name || 'Jugador'}
                                </span>
                              </div>
                            </button>
                          );
                        })}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          </EliteCard>
        </div>
      </div>

      {/* Reservation Detail Modal */}
      <Dialog open={detailModalOpen} onOpenChange={setDetailModalOpen}>
        <DialogContent className="bg-card border-neon-cyan/30">
          <DialogHeader>
            <DialogTitle className="font-orbitron gradient-text">
              Detalle de Sesión
            </DialogTitle>
          </DialogHeader>
          
          {selectedReservation && (
            <div className="space-y-4">
              {/* Info */}
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Título:</span>
                  <span className="font-rajdhani font-medium">{selectedReservation.title}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Usuario:</span>
                  <span className="font-rajdhani">{selectedReservation.user?.full_name || 'N/A'}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Jugador:</span>
                  <span className="font-rajdhani">{selectedReservation.player?.name || 'N/A'}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Hora:</span>
                  <span className="font-orbitron text-neon-cyan">
                    {format(parseISO(selectedReservation.start_time), 'HH:mm')} - {format(parseISO(selectedReservation.end_time), 'HH:mm')}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Entrenador:</span>
                  <span className="font-rajdhani">{selectedReservation.trainer?.name || 'Sin asignar'}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Estado:</span>
                  <StatusBadge variant={getStatusConfig(selectedReservation.status || 'pending').variant}>
                    {getStatusConfig(selectedReservation.status || 'pending').label}
                  </StatusBadge>
                </div>
              </div>

              {/* Description */}
              {selectedReservation.description && (
                <div className="p-3 rounded-lg bg-muted/30 border border-border">
                  <p className="text-sm text-muted-foreground">{selectedReservation.description}</p>
                </div>
              )}

              {/* Action Buttons */}
              <div className="space-y-3 pt-4 border-t border-border">
                <p className="text-sm text-muted-foreground font-rajdhani">Cambiar estado:</p>
                <div className="grid grid-cols-2 gap-2">
                  {selectedReservation.status === 'pending' && (
                    <>
                      <NeonButton
                        variant="cyan"
                        size="sm"
                        onClick={() => handleStatusUpdate(selectedReservation.id, 'approved')}
                      >
                        <Check className="w-4 h-4 mr-1" />
                        Aprobar
                      </NeonButton>
                      <NeonButton
                        variant="outline"
                        size="sm"
                        onClick={() => handleStatusUpdate(selectedReservation.id, 'rejected')}
                      >
                        <X className="w-4 h-4 mr-1" />
                        Rechazar
                      </NeonButton>
                    </>
                  )}
                  {selectedReservation.status === 'approved' && (
                    <>
                      <NeonButton
                        variant="gradient"
                        size="sm"
                        onClick={() => handleStatusUpdate(selectedReservation.id, 'completed')}
                      >
                        <CheckCircle2 className="w-4 h-4 mr-1" />
                        Completada
                      </NeonButton>
                      <NeonButton
                        variant="outline"
                        size="sm"
                        onClick={() => handleStatusUpdate(selectedReservation.id, 'no_show')}
                        className="text-orange-400 border-orange-400/30 hover:bg-orange-400/10"
                      >
                        <AlertCircle className="w-4 h-4 mr-1" />
                        No Asistió
                      </NeonButton>
                    </>
                  )}
                  {(selectedReservation.status === 'completed' || selectedReservation.status === 'no_show' || selectedReservation.status === 'rejected') && (
                    <NeonButton
                      variant="outline"
                      size="sm"
                      onClick={() => handleStatusUpdate(selectedReservation.id, 'approved')}
                      className="col-span-2"
                    >
                      Volver a Aprobada
                    </NeonButton>
                  )}
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default ReservationCalendarView;
