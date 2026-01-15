import React, { useState, useMemo, useCallback } from 'react';
import { DndContext, DragEndEvent, DragOverlay, useDraggable, useDroppable, closestCenter } from '@dnd-kit/core';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { useAllReservations, Reservation } from '@/hooks/useReservations';
import { useTrainers, Trainer } from '@/hooks/useTrainers';
import { usePlayers } from '@/hooks/usePlayers';
import { useToast } from '@/hooks/use-toast';
import { format, startOfWeek, addDays, isSameDay, parseISO, setHours, setMinutes } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  Clock, 
  User, 
  ChevronLeft,
  ChevronRight,
  GripVertical,
  UserPlus,
  Search,
  CreditCard,
  X,
  Plus
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
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { supabase } from '@/integrations/supabase/client';
import { useQuery } from '@tanstack/react-query';

// Session time slots (7am to 9pm)
const TIME_SLOTS = Array.from({ length: 14 }, (_, i) => i + 7);

// Days of week
const DAYS_OF_WEEK = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

interface ReservationWithTrainer extends Reservation {
  trainer?: Trainer;
  trainer_id?: string;
}

interface PlayerWithCredits {
  id: string;
  name: string;
  category: string;
  level: string;
  position: string | null;
  parent_id: string;
  credits: number;
}

// Draggable player from sidebar
const DraggablePlayer: React.FC<{
  player: PlayerWithCredits;
  isSelected: boolean;
  onClick: () => void;
}> = ({ player, isSelected, onClick }) => {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `player-${player.id}`,
    data: { type: 'player', player },
  });

  return (
    <div
      ref={setNodeRef}
      onClick={onClick}
      className={`p-2 rounded-lg border cursor-pointer transition-all ${
        isDragging ? 'opacity-50' : ''
      } ${
        isSelected 
          ? 'bg-neon-cyan/20 border-neon-cyan/50' 
          : 'bg-muted/30 border-border hover:border-neon-cyan/30'
      }`}
      {...listeners}
      {...attributes}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <GripVertical className="w-3 h-3 text-muted-foreground" />
          <div>
            <p className="text-sm font-rajdhani font-medium truncate">{player.name}</p>
            <p className="text-xs text-muted-foreground">{player.category}</p>
          </div>
        </div>
        <Badge variant="outline" className={`text-xs ${player.credits > 0 ? 'text-green-400 border-green-400/30' : 'text-red-400 border-red-400/30'}`}>
          <CreditCard className="w-3 h-3 mr-1" />
          {player.credits}
        </Badge>
      </div>
    </div>
  );
};

// Draggable reservation card
const DraggableReservation: React.FC<{
  reservation: ReservationWithTrainer;
  onClick: () => void;
}> = ({ reservation, onClick }) => {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: reservation.id,
    data: { type: 'reservation', reservation },
  });

  const statusColors: Record<string, string> = {
    approved: 'bg-neon-cyan/20 border-neon-cyan/30',
    completed: 'bg-green-500/20 border-green-500/30',
    pending: 'bg-yellow-500/20 border-yellow-500/30',
    rejected: 'bg-red-500/20 border-red-500/30',
    no_show: 'bg-orange-500/20 border-orange-500/30',
  };

  return (
    <div
      ref={setNodeRef}
      className={`w-full p-1.5 rounded text-left transition-all cursor-grab active:cursor-grabbing text-xs ${
        isDragging ? 'opacity-50' : ''
      } ${statusColors[reservation.status || 'pending']}`}
      {...listeners}
      {...attributes}
    >
      <button 
        onClick={(e) => { e.stopPropagation(); onClick(); }}
        className="w-full text-left hover:underline"
      >
        <div className="font-rajdhani font-medium truncate">
          {reservation.player?.name || reservation.title}
        </div>
        <div className="text-muted-foreground truncate">
          {format(parseISO(reservation.start_time), 'HH:mm')}
        </div>
      </button>
    </div>
  );
};

// Droppable cell for the schedule
const DroppableCell: React.FC<{
  id: string;
  children: React.ReactNode;
  onClick: () => void;
}> = ({ id, children, onClick }) => {
  const { setNodeRef, isOver } = useDroppable({ id });

  return (
    <div 
      ref={setNodeRef}
      onClick={onClick}
      className={`min-h-[60px] p-1 border-r border-b border-neon-cyan/10 space-y-1 cursor-pointer transition-colors hover:bg-muted/20 ${
        isOver ? 'bg-neon-cyan/10' : ''
      }`}
    >
      {children}
    </div>
  );
};

const WeeklyScheduleView: React.FC = () => {
  const { reservations, loading, updateReservation, refetch } = useAllReservations();
  const { trainers } = useTrainers();
  const { players } = usePlayers();
  const { toast } = useToast();
  
  const [weekStart, setWeekStart] = useState<Date>(() => startOfWeek(new Date(), { weekStartsOn: 1 }));
  const [selectedPlayer, setSelectedPlayer] = useState<PlayerWithCredits | null>(null);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [playerSearch, setPlayerSearch] = useState('');
  const [addPlayerModalOpen, setAddPlayerModalOpen] = useState(false);
  const [selectedCell, setSelectedCell] = useState<{ day: Date; hour: number } | null>(null);
  const [selectedPlayerForAdd, setSelectedPlayerForAdd] = useState<string>('');
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [selectedReservation, setSelectedReservation] = useState<ReservationWithTrainer | null>(null);

  // Fetch players with credits
  const { data: playersWithCredits = [] } = useQuery({
    queryKey: ['players-with-credits'],
    queryFn: async () => {
      const { data: playersData, error: playersError } = await supabase
        .from('players')
        .select('id, name, category, level, position, parent_id')
        .order('name');

      if (playersError) throw playersError;

      const parentIds = [...new Set(playersData?.map(p => p.parent_id) || [])];
      const { data: creditsData } = await supabase
        .from('user_credits')
        .select('user_id, balance')
        .in('user_id', parentIds);

      const creditsMap = new Map(creditsData?.map(c => [c.user_id, c.balance]) || []);

      return (playersData || []).map(player => ({
        ...player,
        credits: creditsMap.get(player.parent_id) || 0
      })) as PlayerWithCredits[];
    }
  });

  // Generate week days
  const weekDays = useMemo(() => {
    return Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  }, [weekStart]);

  // Filter players by search
  const filteredPlayers = useMemo(() => {
    if (!playerSearch) return playersWithCredits;
    const search = playerSearch.toLowerCase();
    return playersWithCredits.filter(p => 
      p.name.toLowerCase().includes(search) ||
      p.category.toLowerCase().includes(search)
    );
  }, [playersWithCredits, playerSearch]);

  // Group reservations by day and hour
  const scheduleGrid = useMemo(() => {
    const grid: Record<string, Record<number, ReservationWithTrainer[]>> = {};
    
    weekDays.forEach(day => {
      const dayKey = format(day, 'yyyy-MM-dd');
      grid[dayKey] = {};
      TIME_SLOTS.forEach(hour => {
        grid[dayKey][hour] = [];
      });
    });

    reservations.forEach(reservation => {
      const resDate = parseISO(reservation.start_time);
      const dayKey = format(resDate, 'yyyy-MM-dd');
      const hour = resDate.getHours();
      
      if (grid[dayKey] && grid[dayKey][hour] !== undefined) {
        const trainer = trainers.find(t => t.id === (reservation as any).trainer_id);
        grid[dayKey][hour].push({
          ...reservation,
          trainer,
          trainer_id: (reservation as any).trainer_id
        });
      }
    });

    return grid;
  }, [reservations, weekDays, trainers]);

  const handleDragEnd = useCallback(async (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveId(null);
    
    if (!over) return;
    
    const [dayKey, hourStr] = (over.id as string).split('-hour-');
    const targetHour = parseInt(hourStr);
    const targetDate = parseISO(dayKey);
    
    if (isNaN(targetHour)) return;

    const activeData = active.data.current;
    
    if (activeData?.type === 'player') {
      // Dropping a player to create/assign to a session
      const player = activeData.player as PlayerWithCredits;
      
      // Check if there's already a reservation in this slot
      const existingReservations = scheduleGrid[dayKey]?.[targetHour] || [];
      
      if (existingReservations.length === 0) {
        // No session exists - we could create one or show modal
        toast({
          title: 'Sin sesión',
          description: 'No hay sesión en este horario. Haz click en la celda para crear una.',
          variant: 'destructive',
        });
        return;
      }
      
      // Assign player to first available session in this slot
      const targetReservation = existingReservations[0];
      const success = await updateReservation(targetReservation.id, {
        player_id: player.id,
      });
      
      if (success) {
        toast({
          title: 'Jugador asignado',
          description: `${player.name} ha sido asignado a la sesión.`,
        });
        refetch();
      }
    } else if (activeData?.type === 'reservation') {
      // Moving a reservation
      const reservation = activeData.reservation as ReservationWithTrainer;
      
      const originalStart = parseISO(reservation.start_time);
      const originalEnd = parseISO(reservation.end_time);
      const duration = originalEnd.getTime() - originalStart.getTime();
      
      const newStart = setMinutes(setHours(targetDate, targetHour), 0);
      const newEnd = new Date(newStart.getTime() + duration);

      const success = await updateReservation(reservation.id, {
        start_time: newStart.toISOString(),
        end_time: newEnd.toISOString(),
      });

      if (success) {
        toast({
          title: 'Sesión movida',
          description: 'La sesión ha sido reasignada.',
        });
      }
    }
  }, [scheduleGrid, updateReservation, toast, refetch]);

  const handleCellClick = (day: Date, hour: number) => {
    setSelectedCell({ day, hour });
    setSelectedPlayerForAdd('');
    setAddPlayerModalOpen(true);
  };

  const handleAddPlayerToSession = async () => {
    if (!selectedCell || !selectedPlayerForAdd) return;
    
    const dayKey = format(selectedCell.day, 'yyyy-MM-dd');
    const existingReservations = scheduleGrid[dayKey]?.[selectedCell.hour] || [];
    
    if (existingReservations.length > 0) {
      // Assign to existing session
      const success = await updateReservation(existingReservations[0].id, {
        player_id: selectedPlayerForAdd,
      });
      
      if (success) {
        toast({
          title: 'Jugador asignado',
          description: 'El jugador ha sido asignado a la sesión.',
        });
        setAddPlayerModalOpen(false);
        refetch();
      }
    } else {
      toast({
        title: 'Sin sesión',
        description: 'No hay sesión en este horario para asignar el jugador.',
        variant: 'destructive',
      });
    }
  };

  const openReservationDetail = (reservation: ReservationWithTrainer) => {
    setSelectedReservation(reservation);
    setDetailModalOpen(true);
  };

  const navigateWeek = (direction: 'prev' | 'next') => {
    setWeekStart(prev => addDays(prev, direction === 'next' ? 7 : -7));
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-12 h-12 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <DndContext 
      collisionDetection={closestCenter}
      onDragStart={(event) => setActiveId(event.active.id as string)}
      onDragEnd={handleDragEnd}
    >
      <div className="flex gap-4">
        {/* Left Sidebar - Players with Credits */}
        <EliteCard className="w-72 shrink-0 p-4">
          <div className="mb-4">
            <h3 className="font-orbitron text-lg gradient-text mb-2">Jugadores</h3>
            <p className="text-xs text-muted-foreground">Arrastra un jugador a una sesión</p>
          </div>
          
          {/* Search */}
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Buscar jugador..."
              value={playerSearch}
              onChange={(e) => setPlayerSearch(e.target.value)}
              className="pl-10 bg-background border-neon-cyan/30 text-sm"
            />
          </div>
          
          {/* Players List */}
          <ScrollArea className="h-[500px]">
            <div className="space-y-2 pr-2">
              {filteredPlayers.map(player => (
                <DraggablePlayer
                  key={player.id}
                  player={player}
                  isSelected={selectedPlayer?.id === player.id}
                  onClick={() => setSelectedPlayer(selectedPlayer?.id === player.id ? null : player)}
                />
              ))}
            </div>
          </ScrollArea>
          
          {/* Selected Player Info */}
          {selectedPlayer && (
            <div className="mt-4 p-3 rounded-lg bg-neon-cyan/10 border border-neon-cyan/30">
              <div className="flex items-center justify-between mb-2">
                <span className="font-rajdhani font-medium">{selectedPlayer.name}</span>
                <button onClick={() => setSelectedPlayer(null)}>
                  <X className="w-4 h-4 text-muted-foreground hover:text-foreground" />
                </button>
              </div>
              <div className="text-xs text-muted-foreground space-y-1">
                <p>Categoría: {selectedPlayer.category}</p>
                <p>Nivel: {selectedPlayer.level}</p>
                <p className={selectedPlayer.credits > 0 ? 'text-green-400' : 'text-red-400'}>
                  Créditos: {selectedPlayer.credits}
                </p>
              </div>
            </div>
          )}
        </EliteCard>

        {/* Main Schedule Grid */}
        <div className="flex-1 min-w-0">
          {/* Week Navigation */}
          <div className="flex items-center justify-between mb-4">
            <NeonButton variant="outline" size="sm" onClick={() => navigateWeek('prev')}>
              <ChevronLeft className="w-4 h-4" />
            </NeonButton>
            <h2 className="font-orbitron font-bold text-lg gradient-text text-center">
              {format(weekStart, "dd MMM", { locale: es })} - {format(addDays(weekStart, 6), "dd MMM yyyy", { locale: es })}
            </h2>
            <NeonButton variant="outline" size="sm" onClick={() => navigateWeek('next')}>
              <ChevronRight className="w-4 h-4" />
            </NeonButton>
          </div>

          <EliteCard className="overflow-x-auto">
            <div className="min-w-[800px]">
              {/* Header Row - Days of Week */}
              <div className="grid border-b border-neon-cyan/20" style={{ gridTemplateColumns: `60px repeat(7, 1fr)` }}>
                <div className="p-2 font-orbitron text-xs text-muted-foreground border-r border-neon-cyan/10">
                  Hora
                </div>
                {weekDays.map((day, idx) => (
                  <div key={idx} className="p-2 text-center border-r border-neon-cyan/10 last:border-r-0">
                    <div className="font-orbitron text-sm text-neon-cyan">{DAYS_OF_WEEK[idx]}</div>
                    <div className="text-xs text-muted-foreground">{format(day, 'dd/MM')}</div>
                  </div>
                ))}
              </div>

              {/* Time Rows */}
              {TIME_SLOTS.map(hour => (
                <div 
                  key={hour} 
                  className="grid"
                  style={{ gridTemplateColumns: `60px repeat(7, 1fr)` }}
                >
                  {/* Hour Label */}
                  <div className="p-1 font-orbitron text-xs text-neon-cyan border-r border-b border-neon-cyan/10 flex items-center justify-center">
                    {String(hour).padStart(2, '0')}:00
                  </div>
                  
                  {/* Day Cells */}
                  {weekDays.map((day, dayIdx) => {
                    const dayKey = format(day, 'yyyy-MM-dd');
                    const cellReservations = scheduleGrid[dayKey]?.[hour] || [];
                    const dropId = `${dayKey}-hour-${hour}`;
                    
                    return (
                      <DroppableCell 
                        key={dropId} 
                        id={dropId}
                        onClick={() => handleCellClick(day, hour)}
                      >
                        {cellReservations.map(reservation => (
                          <DraggableReservation
                            key={reservation.id}
                            reservation={reservation}
                            onClick={() => openReservationDetail(reservation)}
                          />
                        ))}
                        {cellReservations.length === 0 && (
                          <div className="h-full flex items-center justify-center opacity-0 hover:opacity-50 transition-opacity">
                            <Plus className="w-4 h-4 text-muted-foreground" />
                          </div>
                        )}
                      </DroppableCell>
                    );
                  })}
                </div>
              ))}
            </div>
          </EliteCard>
        </div>
      </div>

      {/* Drag Overlay */}
      <DragOverlay>
        {activeId && (
          <div className="p-2 rounded-md bg-neon-cyan/20 border border-neon-cyan/50 shadow-lg opacity-90">
            <div className="text-xs font-rajdhani font-medium">Moviendo...</div>
          </div>
        )}
      </DragOverlay>

      {/* Add Player Modal */}
      <Dialog open={addPlayerModalOpen} onOpenChange={setAddPlayerModalOpen}>
        <DialogContent className="bg-card border-neon-cyan/30 max-w-md">
          <DialogHeader>
            <DialogTitle className="font-orbitron gradient-text">
              Agregar Jugador a Sesión
            </DialogTitle>
          </DialogHeader>
          
          {selectedCell && (
            <div className="space-y-4">
              <div className="p-3 rounded-lg bg-muted/30 border border-border">
                <p className="text-sm">
                  <span className="text-muted-foreground">Fecha:</span>{' '}
                  <span className="font-orbitron text-neon-cyan">
                    {format(selectedCell.day, "EEEE dd/MM", { locale: es })}
                  </span>
                </p>
                <p className="text-sm">
                  <span className="text-muted-foreground">Hora:</span>{' '}
                  <span className="font-orbitron text-neon-cyan">
                    {String(selectedCell.hour).padStart(2, '0')}:00
                  </span>
                </p>
              </div>
              
              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <UserPlus className="w-4 h-4 text-neon-cyan" />
                  Seleccionar Jugador
                </Label>
                <Select value={selectedPlayerForAdd} onValueChange={setSelectedPlayerForAdd}>
                  <SelectTrigger className="bg-background border-neon-cyan/30">
                    <SelectValue placeholder="Buscar jugador..." />
                  </SelectTrigger>
                  <SelectContent className="max-h-60">
                    {playersWithCredits.map(player => (
                      <SelectItem key={player.id} value={player.id}>
                        <div className="flex items-center justify-between w-full gap-4">
                          <span>{player.name}</span>
                          <span className="text-xs text-muted-foreground">
                            {player.category} • {player.credits} créditos
                          </span>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <NeonButton 
                variant="cyan" 
                className="w-full"
                onClick={handleAddPlayerToSession}
                disabled={!selectedPlayerForAdd}
              >
                <UserPlus className="w-4 h-4 mr-2" />
                Agregar a Sesión
              </NeonButton>
            </div>
          )}
        </DialogContent>
      </Dialog>

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
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Título:</span>
                  <span className="font-rajdhani">{selectedReservation.title}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Jugador:</span>
                  <span className="font-rajdhani text-neon-cyan">{selectedReservation.player?.name || 'Sin asignar'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Hora:</span>
                  <span className="font-orbitron">
                    {format(parseISO(selectedReservation.start_time), 'HH:mm')} - {format(parseISO(selectedReservation.end_time), 'HH:mm')}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Estado:</span>
                  <StatusBadge variant={selectedReservation.status === 'approved' ? 'info' : 'warning'}>
                    {selectedReservation.status}
                  </StatusBadge>
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </DndContext>
  );
};

export default WeeklyScheduleView;
