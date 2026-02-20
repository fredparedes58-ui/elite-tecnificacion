import React, { useState, useMemo, useCallback, useEffect } from 'react';
import { DndContext, DragEndEvent, DragOverlay, useDraggable, useDroppable, closestCenter } from '@dnd-kit/core';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Reservation } from '@/hooks/useReservations';
import { Trainer } from '@/hooks/useTrainers';
import { useToast } from '@/hooks/use-toast';
import { format, startOfWeek, addDays, parseISO, setHours, setMinutes, differenceInYears } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  User, 
  ChevronLeft,
  ChevronRight,
  GripVertical,
  UserPlus,
  Search,
  CreditCard,
  X,
  Plus,
  Calendar,
  Footprints,
  MapPin,
  AlertTriangle,
  CalendarPlus,
  History,
  CheckCircle,
  Filter
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import { Checkbox } from '@/components/ui/checkbox';
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { supabase } from '@/integrations/supabase/client';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/contexts/AuthContext';
import { MoveConfirmationModal } from './MoveConfirmationModal';
import { SessionHistoryPanel } from './SessionHistoryPanel';
import CompleteSessionModal from './CompleteSessionModal';
import type { Database } from '@/integrations/supabase/types';

type ReservationStatus = Database['public']['Enums']['reservation_status'];

// Session time slots (7am to 9pm)
const TIME_SLOTS = Array.from({ length: 14 }, (_, i) => i + 7);

// Days of week
const DAYS_OF_WEEK = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

interface ReservationWithTrainer extends Reservation {
  trainer?: Trainer;
}

interface PlayerWithFullInfo {
  id: string;
  name: string;
  category: string;
  level: string;
  position: string | null;
  dominant_leg: string | null;
  birth_date: string | null;
  parent_id: string;
  parent_name: string | null;
  credits: number;
}

interface PlayerWithStats {
  id: string;
  name: string;
  category: string;
  level: string;
}

interface WeeklyScheduleViewProps {
  reservations: Reservation[];
  reservationsLoading: boolean;
  trainers: Trainer[];
  players: PlayerWithStats[];
  updateReservation: (id: string, updates: {
    trainer_id?: string | null;
    player_id?: string | null;
    start_time?: string;
    end_time?: string;
    status?: ReservationStatus;
  }, sendEmail?: boolean) => Promise<boolean>;
  createReservation: (reservation: {
    title: string;
    description?: string;
    start_time: string;
    end_time: string;
    player_id?: string;
    trainer_id?: string;
    credit_cost?: number;
    user_id?: string;
    status?: ReservationStatus;
  }) => Promise<any>;
  deleteReservation?: (id: string) => Promise<boolean>;
  refetch: () => void;
}

// Draggable player from sidebar with full info
const DraggablePlayer: React.FC<{
  player: PlayerWithFullInfo;
  isSelected: boolean;
  onClick: () => void;
}> = ({ player, isSelected, onClick }) => {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `player-${player.id}`,
    data: { type: 'player', player },
  });

  const age = player.birth_date ? differenceInYears(new Date(), new Date(player.birth_date)) : null;
  const legLabel = player.dominant_leg === 'right' ? 'Der' : player.dominant_leg === 'left' ? 'Izq' : player.dominant_leg === 'both' ? 'Amb' : '-';

  return (
    <div
      ref={setNodeRef}
      onClick={onClick}
      className={`p-3 rounded-lg border cursor-pointer transition-all ${
        isDragging ? 'opacity-50' : ''
      } ${
        isSelected 
          ? 'bg-neon-cyan/20 border-neon-cyan/50' 
          : player.credits === 0 
            ? 'bg-red-500/10 border-red-500/30 hover:border-red-500/50'
            : player.credits <= 5
              ? 'bg-yellow-500/10 border-yellow-500/30 hover:border-yellow-500/50'
              : 'bg-muted/30 border-border hover:border-neon-cyan/30'
      }`}
      {...listeners}
      {...attributes}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-start gap-2 min-w-0 flex-1">
          <GripVertical className="w-3 h-3 text-muted-foreground mt-1 shrink-0" />
          <div className="min-w-0">
            <p className="text-sm font-rajdhani font-bold truncate">{player.name}</p>
            <p className="text-xs text-muted-foreground truncate">
              Padre: {player.parent_name || 'N/A'}
            </p>
            <div className="flex flex-wrap gap-1 mt-1">
              <Badge variant="outline" className="text-[10px] px-1 py-0 bg-neon-cyan/10 text-neon-cyan border-neon-cyan/30">
                {player.category}
              </Badge>
              {age && (
                <Badge variant="outline" className="text-[10px] px-1 py-0">
                  {age} años
                </Badge>
              )}
            </div>
            <div className="flex items-center gap-2 mt-1 text-[10px] text-muted-foreground">
              {player.position && (
                <span className="flex items-center gap-0.5">
                  <MapPin className="w-2.5 h-2.5" />
                  {player.position}
                </span>
              )}
              <span className="flex items-center gap-0.5">
                <Footprints className="w-2.5 h-2.5" />
                {legLabel}
              </span>
            </div>
          </div>
        </div>
        <Badge 
          variant="outline" 
          className={`text-xs shrink-0 ${
            player.credits === 0 
              ? 'text-red-400 border-red-400/30 bg-red-500/10' 
              : player.credits <= 5
                ? 'text-yellow-400 border-yellow-400/30 bg-yellow-500/10'
                : 'text-green-400 border-green-400/30 bg-green-500/10'
          }`}
        >
          <CreditCard className="w-3 h-3 mr-1" />
          {player.credits}
        </Badge>
      </div>
    </div>
  );
};

// Draggable reservation card - supports both click and double-click
const DraggableReservation: React.FC<{
  reservation: ReservationWithTrainer;
  onClick: () => void;
  onDoubleClick: () => void;
}> = ({ reservation, onClick, onDoubleClick }) => {
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

  const trainerColor = reservation.trainer?.color || null;

  return (
    <div
      ref={setNodeRef}
      onDoubleClick={(e) => { e.stopPropagation(); onDoubleClick(); }}
      className={`w-full p-1.5 rounded text-left transition-all cursor-grab active:cursor-grabbing text-xs border ${
        isDragging ? 'opacity-50' : ''
      } ${statusColors[reservation.status || 'pending']}`}
      style={trainerColor ? { 
        borderLeftWidth: '3px', 
        borderLeftColor: trainerColor,
        backgroundColor: `${trainerColor}15`,
      } : undefined}
      {...listeners}
      {...attributes}
    >
      <div 
        onClick={(e) => { e.stopPropagation(); onClick(); }}
        className="hover:underline cursor-pointer"
      >
        <div className="font-rajdhani font-medium truncate">
          {reservation.player?.name || reservation.title}
        </div>
        <div className="text-muted-foreground truncate flex items-center gap-1 flex-wrap">
          {format(parseISO(reservation.start_time), 'HH:mm')}
          {reservation.trainer ? (
            <span 
              className="inline-block w-2 h-2 rounded-full ml-auto shrink-0"
              style={{ backgroundColor: trainerColor || '#888' }}
              title={reservation.trainer.name}
            />
          ) : (
            <span className="text-amber-400 text-[10px] font-medium" title="Doble clic para asignar entrenador">
              Sin entrenador
            </span>
          )}
        </div>
      </div>
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

const WeeklyScheduleView: React.FC<WeeklyScheduleViewProps> = ({
  reservations,
  reservationsLoading,
  trainers,
  players,
  updateReservation,
  createReservation,
  deleteReservation,
  refetch
}) => {
  const { toast } = useToast();
  const { user } = useAuth();
  
  const [weekStart, setWeekStart] = useState<Date>(() => startOfWeek(new Date(), { weekStartsOn: 1 }));
  const [selectedPlayer, setSelectedPlayer] = useState<PlayerWithFullInfo | null>(null);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [playerSearch, setPlayerSearch] = useState('');
  const [addPlayerModalOpen, setAddPlayerModalOpen] = useState(false);
  const [selectedCell, setSelectedCell] = useState<{ day: Date; hour: number } | null>(null);
  const [selectedPlayerForAdd, setSelectedPlayerForAdd] = useState<string>('');
  const [selectedTrainerForAdd, setSelectedTrainerForAdd] = useState<string>('');
  const [sessionTitle, setSessionTitle] = useState('');
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [selectedReservation, setSelectedReservation] = useState<ReservationWithTrainer | null>(null);
  const [lowCreditsNotified, setLowCreditsNotified] = useState<Set<string>>(new Set());
  const [coachFilterIds, setCoachFilterIds] = useState<string[]>([]);
  const [coachFilterOpen, setCoachFilterOpen] = useState(false);
  
  // States for editing reservation in detail modal
  const [editingPlayer, setEditingPlayer] = useState<string>('');
  const [editingTrainer, setEditingTrainer] = useState<string>('');
  const [editingStatus, setEditingStatus] = useState<string>('');
  const [isUpdating, setIsUpdating] = useState(false);
  
  // Move confirmation modal state
  const [moveConfirmModalOpen, setMoveConfirmModalOpen] = useState(false);
  const [pendingMove, setPendingMove] = useState<{
    reservation: ReservationWithTrainer;
    targetDate: Date;
    targetHour: number;
    playerName: string;
    trainerName?: string;
    conflictWarning?: string;
  } | null>(null);

  // Complete session modal state
  const [completeSessionModalOpen, setCompleteSessionModalOpen] = useState(false);
  const [reservationToComplete, setReservationToComplete] = useState<{
    id: string;
    title: string;
    player_id: string | null;
    player_name?: string;
    start_time: string;
    current_stats?: {
      speed: number;
      technique: number;
      physical: number;
      mental: number;
      tactical: number;
    };
  } | null>(null);

  // Fetch players with full info including credits and parent name
  const { data: playersWithFullInfo = [] } = useQuery({
    queryKey: ['players-full-info'],
    queryFn: async () => {
      const { data: playersData, error: playersError } = await supabase
        .from('players')
        .select('id, name, category, level, position, dominant_leg, birth_date, parent_id')
        .order('name');

      if (playersError) throw playersError;

      const parentIds = [...new Set(playersData?.map(p => p.parent_id) || [])];
      
      const [creditsRes, profilesRes] = await Promise.all([
        supabase.from('user_credits').select('user_id, balance').in('user_id', parentIds),
        supabase.from('profiles').select('id, full_name').in('id', parentIds)
      ]);

      const creditsMap = new Map(creditsRes.data?.map(c => [c.user_id, c.balance]) || []);
      const profilesMap = new Map(profilesRes.data?.map(p => [p.id, p.full_name]) || []);

      return (playersData || []).map(player => ({
        ...player,
        credits: creditsMap.get(player.parent_id) || 0,
        parent_name: profilesMap.get(player.parent_id) || null
      })) as PlayerWithFullInfo[];
    },
    staleTime: 60 * 1000, // 1 minute
    gcTime: 5 * 60 * 1000,
  });

  // Check for low credits and notify
  useEffect(() => {
    const lowCreditPlayers = playersWithFullInfo.filter(p => p.credits === 0 || p.credits <= 5);
    const newNotifications: string[] = [];
    
    lowCreditPlayers.forEach(player => {
      if (!lowCreditsNotified.has(player.id)) {
        newNotifications.push(player.id);
        if (player.credits === 0) {
          toast({
            title: '⚠️ Sin Créditos',
            description: `${player.name} (Padre: ${player.parent_name || 'N/A'}) no tiene créditos disponibles.`,
            variant: 'destructive',
          });
        } else if (player.credits <= 5) {
          toast({
            title: '⚡ Créditos Bajos',
            description: `${player.name} solo tiene ${player.credits} créditos restantes.`,
          });
        }
      }
    });

    if (newNotifications.length > 0) {
      setLowCreditsNotified(prev => new Set([...prev, ...newNotifications]));
    }
  }, [playersWithFullInfo, lowCreditsNotified, toast]);

  // Generate week days
  const weekDays = useMemo(() => {
    return Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  }, [weekStart]);

  // Filter players by search
  const filteredPlayers = useMemo(() => {
    if (!playerSearch) return playersWithFullInfo;
    const search = playerSearch.toLowerCase();
    return playersWithFullInfo.filter(p => 
      p.name.toLowerCase().includes(search) ||
      p.category.toLowerCase().includes(search) ||
      p.parent_name?.toLowerCase().includes(search) ||
      p.position?.toLowerCase().includes(search)
    );
  }, [playersWithFullInfo, playerSearch]);

  // Stats for sidebar
  const stats = useMemo(() => {
    const total = playersWithFullInfo.length;
    const zeroCredits = playersWithFullInfo.filter(p => p.credits === 0).length;
    const lowCredits = playersWithFullInfo.filter(p => p.credits > 0 && p.credits <= 5).length;
    return { total, zeroCredits, lowCredits };
  }, [playersWithFullInfo]);

  // Filter reservations by selected coach(es)
  const filteredReservations = useMemo(() => {
    if (coachFilterIds.length === 0) return reservations;
    return reservations.filter(r => r.trainer_id && coachFilterIds.includes(r.trainer_id));
  }, [reservations, coachFilterIds]);

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

    filteredReservations.forEach(reservation => {
      const resDate = parseISO(reservation.start_time);
      const dayKey = format(resDate, 'yyyy-MM-dd');
      const hour = resDate.getHours();
      
      if (grid[dayKey] && grid[dayKey][hour] !== undefined) {
        const trainer = trainers.find(t => t.id === reservation.trainer_id);
        grid[dayKey][hour].push({
          ...reservation,
          trainer,
        });
      }
    });

    return grid;
  }, [filteredReservations, weekDays, trainers]);

  // Check for schedule conflicts - if the player already has a session at the target time
  const checkConflicts = useCallback((playerId: string, targetDate: Date, targetHour: number, excludeReservationId?: string): string | undefined => {
    const dayKey = format(targetDate, 'yyyy-MM-dd');
    
    // Check all reservations for this day and hour
    const existingSessionsAtTime = scheduleGrid[dayKey]?.[targetHour] || [];
    
    // Also check adjacent hours for overlapping sessions
    const conflictingSession = existingSessionsAtTime.find(r => 
      r.player_id === playerId && r.id !== excludeReservationId
    );
    
    if (conflictingSession) {
      const playerName = playersWithFullInfo.find(p => p.id === playerId)?.name || 'El jugador';
      return `${playerName} ya tiene una sesión programada a las ${targetHour}:00 este día.`;
    }
    
    return undefined;
  }, [scheduleGrid, playersWithFullInfo]);

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
      const player = activeData.player as PlayerWithFullInfo;
      const existingReservations = scheduleGrid[dayKey]?.[targetHour] || [];
      
      // Check for conflicts first
      const conflict = checkConflicts(player.id, targetDate, targetHour);
      if (conflict) {
        toast({
          title: '⚠️ Conflicto de Horario',
          description: conflict,
          variant: 'destructive',
        });
        return;
      }
      
      if (existingReservations.length === 0) {
        // Create new session with this player
        const newStart = setMinutes(setHours(targetDate, targetHour), 0);
        const newEnd = new Date(newStart.getTime() + 60 * 60 * 1000); // 1 hour

        const result = await createReservation({
          title: `Sesión - ${player.name}`,
          start_time: newStart.toISOString(),
          end_time: newEnd.toISOString(),
          player_id: player.id,
          user_id: user?.id,
          status: 'approved',
          credit_cost: 1,
        });

        if (result) {
          toast({
            title: 'Sesión creada',
            description: `Nueva sesión creada para ${player.name}.`,
          });
          refetch();
        }
        return;
      }
      
      // Assign player to existing session
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
      const reservation = activeData.reservation as ReservationWithTrainer;
      
      const originalStart = parseISO(reservation.start_time);
      
      // If moving to the same cell, ignore
      if (format(originalStart, 'yyyy-MM-dd') === dayKey && originalStart.getHours() === targetHour) {
        return;
      }
      
      // Check for conflicts if there's a player assigned
      let conflict: string | undefined;
      if (reservation.player_id) {
        conflict = checkConflicts(reservation.player_id, targetDate, targetHour, reservation.id);
      }
      
      // Get player and trainer names for the modal
      const playerName = reservation.player_id 
        ? playersWithFullInfo.find(p => p.id === reservation.player_id)?.name || 'Sin jugador'
        : 'Sin jugador';
      const trainerName = reservation.trainer?.name;
      
      // Show confirmation modal
      setPendingMove({
        reservation,
        targetDate,
        targetHour,
        playerName,
        trainerName,
        conflictWarning: conflict,
      });
      setMoveConfirmModalOpen(true);
    }
  }, [scheduleGrid, updateReservation, createReservation, toast, refetch, user, checkConflicts, playersWithFullInfo]);

  // Handle confirmed move
  const handleConfirmMove = useCallback(async () => {
    if (!pendingMove) return;
    
    setIsUpdating(true);
    try {
      const { reservation, targetDate, targetHour } = pendingMove;
      
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
          title: '✅ Sesión movida',
          description: 'La sesión ha sido reprogramada exitosamente.',
        });
        refetch();
      }
    } finally {
      setIsUpdating(false);
      setMoveConfirmModalOpen(false);
      setPendingMove(null);
    }
  }, [pendingMove, updateReservation, toast, refetch]);

  const handleCellClick = (day: Date, hour: number) => {
    setSelectedCell({ day, hour });
    setSelectedPlayerForAdd('');
    setSelectedTrainerForAdd('');
    setSessionTitle('Sesión de entrenamiento');
    setAddPlayerModalOpen(true);
  };

  const handleCreateOrAssignSession = async () => {
    if (!selectedCell) return;
    
    const dayKey = format(selectedCell.day, 'yyyy-MM-dd');
    const existingReservations = scheduleGrid[dayKey]?.[selectedCell.hour] || [];
    
    if (existingReservations.length > 0 && selectedPlayerForAdd) {
      // Assign to existing session
      const success = await updateReservation(existingReservations[0].id, {
        player_id: selectedPlayerForAdd,
        trainer_id: selectedTrainerForAdd || null,
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
      // Create new session
      const newStart = setMinutes(setHours(selectedCell.day, selectedCell.hour), 0);
      const newEnd = new Date(newStart.getTime() + 60 * 60 * 1000);

      const result = await createReservation({
        title: sessionTitle || 'Sesión de entrenamiento',
        start_time: newStart.toISOString(),
        end_time: newEnd.toISOString(),
        player_id: selectedPlayerForAdd || undefined,
        trainer_id: selectedTrainerForAdd || undefined,
        user_id: user?.id,
        status: 'approved',
        credit_cost: 1,
      });

      if (result) {
        toast({
          title: 'Sesión creada',
          description: 'La nueva sesión ha sido creada exitosamente.',
        });
        setAddPlayerModalOpen(false);
        refetch();
      }
    }
  };

  const openReservationDetail = (reservation: ReservationWithTrainer) => {
    setSelectedReservation(reservation);
    setEditingPlayer(reservation.player_id || '');
    setEditingTrainer(reservation.trainer_id || '');
    setEditingStatus(reservation.status || 'pending');
    setDetailModalOpen(true);
  };

  const handleUpdateReservation = async () => {
    if (!selectedReservation) return;
    
    setIsUpdating(true);
    try {
      const updates: {
        player_id?: string | null;
        trainer_id?: string | null;
        status?: ReservationStatus;
      } = {};

      const normalizedEditingPlayer = editingPlayer === '_none' ? '' : editingPlayer;
      const normalizedEditingTrainer = editingTrainer === '_none' ? '' : editingTrainer;
      
      if (normalizedEditingPlayer !== (selectedReservation.player_id || '')) {
        updates.player_id = normalizedEditingPlayer || null;
      }
      if (normalizedEditingTrainer !== (selectedReservation.trainer_id || '')) {
        updates.trainer_id = normalizedEditingTrainer || null;
      }
      if (editingStatus !== (selectedReservation.status || 'pending')) {
        updates.status = editingStatus as ReservationStatus;
      }

      if (Object.keys(updates).length === 0) {
        toast({
          title: 'Sin cambios',
          description: 'No hay cambios que guardar.',
        });
        setIsUpdating(false);
        return;
      }

      const success = await updateReservation(selectedReservation.id, updates);
      
      if (success) {
        toast({
          title: '✅ Sesión actualizada',
          description: 'Los cambios han sido guardados.',
        });
        setDetailModalOpen(false);
        refetch();
      } else {
        toast({
          title: 'Error',
          description: 'No se pudo actualizar la sesión.',
          variant: 'destructive',
        });
      }
    } finally {
      setIsUpdating(false);
    }
  };

  const handleRemovePlayer = async () => {
    if (!selectedReservation) return;
    
    setIsUpdating(true);
    try {
      const success = await updateReservation(selectedReservation.id, { player_id: null });
      
      if (success) {
        toast({
          title: 'Jugador removido',
          description: 'El jugador ha sido quitado de la sesión.',
        });
        setEditingPlayer('');
        refetch();
      }
    } finally {
      setIsUpdating(false);
    }
  };

  const handleDeleteSession = async () => {
    if (!selectedReservation || !deleteReservation) return;
    
    setIsUpdating(true);
    try {
      const success = await deleteReservation(selectedReservation.id);
      
      if (success) {
        toast({
          title: 'Sesión eliminada',
          description: 'La sesión ha sido eliminada correctamente.',
        });
        setDetailModalOpen(false);
        refetch();
      } else {
        toast({
          title: 'Error',
          description: 'No se pudo eliminar la sesión.',
          variant: 'destructive',
        });
      }
    } finally {
      setIsUpdating(false);
    }
  };

  const handleOpenCompleteSession = () => {
    if (!selectedReservation) return;
    
    const player = playersWithFullInfo.find(p => p.id === selectedReservation.player_id);
    const playerFromList = players.find(p => p.id === selectedReservation.player_id);
    
    setReservationToComplete({
      id: selectedReservation.id,
      title: selectedReservation.title,
      player_id: selectedReservation.player_id || null,
      player_name: selectedReservation.player?.name || player?.name,
      start_time: selectedReservation.start_time,
      current_stats: playerFromList ? {
        speed: 50,
        technique: 50,
        physical: 50,
        mental: 50,
        tactical: 50,
      } : undefined,
    });
    setCompleteSessionModalOpen(true);
    setDetailModalOpen(false);
  };

  const navigateWeek = (direction: 'prev' | 'next') => {
    setWeekStart(prev => addDays(prev, direction === 'next' ? 7 : -7));
  };

  const existingSessionsInCell = selectedCell 
    ? (scheduleGrid[format(selectedCell.day, 'yyyy-MM-dd')]?.[selectedCell.hour] || [])
    : [];

  if (reservationsLoading) {
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
      <div className="flex flex-col lg:flex-row gap-4">
        {/* Left Sidebar - Players with Full Info */}
        <EliteCard className="w-full lg:w-80 shrink-0 p-4">
          <div className="mb-4">
            <h3 className="font-orbitron text-lg gradient-text mb-2">Jugadores</h3>
            <p className="text-xs text-muted-foreground">Arrastra un jugador a una celda</p>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-2 mb-4">
            <div className="p-2 rounded-lg bg-neon-cyan/10 border border-neon-cyan/30 text-center">
              <p className="text-lg font-orbitron text-neon-cyan">{stats.total}</p>
              <p className="text-[10px] text-muted-foreground">Total</p>
            </div>
            <div className="p-2 rounded-lg bg-red-500/10 border border-red-500/30 text-center">
              <p className="text-lg font-orbitron text-red-400">{stats.zeroCredits}</p>
              <p className="text-[10px] text-muted-foreground">Sin créditos</p>
            </div>
            <div className="p-2 rounded-lg bg-yellow-500/10 border border-yellow-500/30 text-center">
              <p className="text-lg font-orbitron text-yellow-400">{stats.lowCredits}</p>
              <p className="text-[10px] text-muted-foreground">Bajos</p>
            </div>
          </div>
          
          {/* Search */}
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Buscar jugador, padre, posición..."
              value={playerSearch}
              onChange={(e) => setPlayerSearch(e.target.value)}
              className="pl-10 bg-background border-neon-cyan/30 text-sm"
            />
          </div>
          
          {/* Players List */}
          <ScrollArea className="h-[280px] lg:h-[450px]">
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
          
          {/* Selected Player Detail */}
          {selectedPlayer && (
            <div className="mt-4 p-3 rounded-lg bg-neon-cyan/10 border border-neon-cyan/30">
              <div className="flex items-center justify-between mb-2">
                <span className="font-rajdhani font-bold">{selectedPlayer.name}</span>
                <button onClick={() => setSelectedPlayer(null)}>
                  <X className="w-4 h-4 text-muted-foreground hover:text-foreground" />
                </button>
              </div>
              <div className="text-xs space-y-1">
                <p><span className="text-muted-foreground">Padre:</span> {selectedPlayer.parent_name || 'N/A'}</p>
                <p><span className="text-muted-foreground">Categoría:</span> {selectedPlayer.category}</p>
                <p><span className="text-muted-foreground">Posición:</span> {selectedPlayer.position || 'N/A'}</p>
                <p><span className="text-muted-foreground">Pierna:</span> {selectedPlayer.dominant_leg === 'right' ? 'Derecha' : selectedPlayer.dominant_leg === 'left' ? 'Izquierda' : 'Ambidiestro'}</p>
                <p className={selectedPlayer.credits > 5 ? 'text-green-400' : selectedPlayer.credits > 0 ? 'text-yellow-400' : 'text-red-400'}>
                  <span className="text-muted-foreground">Créditos:</span> {selectedPlayer.credits}
                </p>
              </div>
            </div>
          )}
        </EliteCard>

        {/* Main Schedule Grid */}
        <div className="flex-1 min-w-0">
          {/* Week Navigation + Coach Filter */}
          <div className="flex flex-wrap items-center justify-between gap-2 mb-2">
            <NeonButton variant="outline" size="sm" onClick={() => navigateWeek('prev')}>
              <ChevronLeft className="w-4 h-4" />
            </NeonButton>
            <h2 className="font-orbitron font-bold text-lg gradient-text text-center order-first w-full lg:order-none lg:w-auto">
              {format(weekStart, "dd MMM", { locale: es })} - {format(addDays(weekStart, 6), "dd MMM yyyy", { locale: es })}
            </h2>
            <div className="flex items-center gap-2">
              {trainers.length > 0 && (
                <Popover open={coachFilterOpen} onOpenChange={setCoachFilterOpen}>
                  <PopoverTrigger asChild>
                    <NeonButton variant="outline" size="sm" className="gap-2">
                      <Filter className="w-4 h-4" />
                      {coachFilterIds.length === 0
                        ? 'Todos'
                        : coachFilterIds.length === 1
                          ? trainers.find(t => t.id === coachFilterIds[0])?.name ?? '1 coach'
                          : `${coachFilterIds.length} coaches`}
                    </NeonButton>
                  </PopoverTrigger>
                  <PopoverContent className="w-56 p-3 bg-card border-neon-cyan/30" align="end">
                    <p className="text-xs font-orbitron text-neon-cyan mb-2">Ver agenda de</p>
                    <div className="space-y-2">
                      <label className="flex items-center gap-2 cursor-pointer rounded-md p-2 hover:bg-muted/50">
                        <Checkbox
                          checked={coachFilterIds.length === 0}
                          onCheckedChange={(checked) => {
                            if (checked) setCoachFilterIds([]);
                          }}
                        />
                        <span className="text-sm">Todos</span>
                      </label>
                      {trainers.map(trainer => (
                        <label key={trainer.id} className="flex items-center gap-2 cursor-pointer rounded-md p-2 hover:bg-muted/50">
                          <Checkbox
                            checked={coachFilterIds.includes(trainer.id)}
                            onCheckedChange={(checked) => {
                              if (checked) {
                                setCoachFilterIds(prev => prev.length === 0 ? [trainer.id] : [...prev, trainer.id]);
                              } else {
                                setCoachFilterIds(prev => prev.filter(id => id !== trainer.id));
                              }
                            }}
                          />
                          <span className="w-2.5 h-2.5 rounded-full border border-white/20 shrink-0" style={{ backgroundColor: trainer.color || '#06b6d4' }} />
                          <span className="text-sm">{trainer.name}</span>
                        </label>
                      ))}
                    </div>
                  </PopoverContent>
                </Popover>
              )}
              <NeonButton variant="outline" size="sm" onClick={() => navigateWeek('next')}>
                <ChevronRight className="w-4 h-4" />
              </NeonButton>
            </div>
          </div>

          {/* Trainer Legend */}
          {trainers.length > 0 && (
            <div className="flex flex-wrap items-center gap-3 mb-4 px-1">
              <span className="text-xs text-muted-foreground">Entrenadores:</span>
              {trainers.map(trainer => (
                <div key={trainer.id} className="flex items-center gap-1.5">
                  <span 
                    className="w-3 h-3 rounded-full border border-white/20"
                    style={{ backgroundColor: trainer.color || '#06b6d4' }}
                  />
                  <span className="text-xs text-muted-foreground">{trainer.name}</span>
                </div>
              ))}
            </div>
          )}

          <EliteCard className="overflow-auto max-h-[calc(100vh-18rem)] min-h-[320px]">
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
                            onDoubleClick={() => openReservationDetail(reservation)}
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

      {/* Create/Add Session Modal */}
      <Dialog open={addPlayerModalOpen} onOpenChange={setAddPlayerModalOpen}>
        <DialogContent className="bg-card border-neon-cyan/30 max-w-md">
          <DialogHeader>
            <DialogTitle className="font-orbitron gradient-text flex items-center gap-2">
              <CalendarPlus className="w-5 h-5" />
              {existingSessionsInCell.length > 0 ? 'Agregar Jugador a Sesión' : 'Crear Nueva Sesión'}
            </DialogTitle>
          </DialogHeader>
          
          {selectedCell && (
            <div className="space-y-4">
              <div className="p-3 rounded-lg bg-muted/30 border border-border">
                <div className="flex items-center gap-2">
                  <Calendar className="w-4 h-4 text-neon-cyan" />
                  <span className="font-orbitron text-neon-cyan">
                    {format(selectedCell.day, "EEEE dd/MM", { locale: es })} - {String(selectedCell.hour).padStart(2, '0')}:00
                  </span>
                </div>
                {existingSessionsInCell.length > 0 && (
                  <p className="text-xs text-muted-foreground mt-2">
                    Ya existe {existingSessionsInCell.length} sesión(es) en este horario
                  </p>
                )}
              </div>

              {existingSessionsInCell.length === 0 && (
                <div className="space-y-2">
                  <Label>Título de la sesión</Label>
                  <Input
                    value={sessionTitle}
                    onChange={(e) => setSessionTitle(e.target.value)}
                    placeholder="Sesión de entrenamiento"
                    className="bg-background border-neon-cyan/30"
                  />
                </div>
              )}
              
              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <UserPlus className="w-4 h-4 text-neon-cyan" />
                  Jugador (opcional)
                </Label>
                <Select value={selectedPlayerForAdd} onValueChange={setSelectedPlayerForAdd}>
                  <SelectTrigger className="bg-background border-neon-cyan/30">
                    <SelectValue placeholder="Seleccionar jugador..." />
                  </SelectTrigger>
                  <SelectContent className="max-h-60">
                    <SelectItem value="none">Sin jugador asignado</SelectItem>
                    {playersWithFullInfo.map(player => (
                      <SelectItem key={player.id} value={player.id}>
                        <div className="flex items-center justify-between w-full gap-2">
                          <span>{player.name}</span>
                          <span className={`text-xs ${player.credits === 0 ? 'text-red-400' : player.credits <= 5 ? 'text-yellow-400' : 'text-muted-foreground'}`}>
                            {player.category} • {player.credits} créditos
                          </span>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <User className="w-4 h-4 text-neon-purple" />
                  Entrenador (opcional)
                </Label>
                <Select value={selectedTrainerForAdd} onValueChange={setSelectedTrainerForAdd}>
                  <SelectTrigger className="bg-background border-neon-purple/30">
                    <SelectValue placeholder="Seleccionar entrenador..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">Sin entrenador asignado</SelectItem>
                    {trainers.map(trainer => (
                      <SelectItem key={trainer.id} value={trainer.id}>
                        {trainer.name} {trainer.specialty ? `- ${trainer.specialty}` : ''}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {selectedPlayerForAdd && playersWithFullInfo.find(p => p.id === selectedPlayerForAdd)?.credits === 0 && (
                <div className="p-3 rounded-lg bg-red-500/10 border border-red-500/30 flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4 text-red-400" />
                  <p className="text-xs text-red-400">Este jugador no tiene créditos disponibles</p>
                </div>
              )}
              
              <NeonButton 
                variant="cyan" 
                className="w-full"
                onClick={handleCreateOrAssignSession}
              >
                {existingSessionsInCell.length > 0 ? (
                  <>
                    <UserPlus className="w-4 h-4 mr-2" />
                    Agregar a Sesión
                  </>
                ) : (
                  <>
                    <CalendarPlus className="w-4 h-4 mr-2" />
                    Crear Sesión
                  </>
                )}
              </NeonButton>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Reservation Detail Modal - Full Player Management with History */}
      <Dialog open={detailModalOpen} onOpenChange={setDetailModalOpen}>
        <DialogContent className="bg-card border-neon-cyan/30 max-w-lg">
          <DialogHeader>
            <DialogTitle className="font-orbitron gradient-text flex items-center gap-2">
              <Calendar className="w-5 h-5" />
              Gestionar Sesión
            </DialogTitle>
          </DialogHeader>
          
          {selectedReservation && (
            <Tabs defaultValue="details" className="w-full">
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="details">Detalles</TabsTrigger>
                <TabsTrigger value="history" className="flex items-center gap-1">
                  <History className="w-3 h-3" />
                  Historial
                </TabsTrigger>
              </TabsList>
              
              <TabsContent value="details" className="space-y-5 mt-4">
                {/* Session Info */}
                <div className="p-3 rounded-lg bg-muted/30 border border-border">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-rajdhani font-bold">{selectedReservation.title}</span>
                    <span className="font-orbitron text-sm text-neon-cyan">
                      {format(parseISO(selectedReservation.start_time), 'EEEE dd/MM', { locale: es })}
                    </span>
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {format(parseISO(selectedReservation.start_time), 'HH:mm')} - {format(parseISO(selectedReservation.end_time), 'HH:mm')}
                  </div>
                </div>

                {/* Player Selection */}
                <div className="space-y-2">
                  <Label className="flex items-center gap-2">
                    <UserPlus className="w-4 h-4 text-neon-cyan" />
                    Jugador Asignado
                  </Label>
                  <div className="flex gap-2">
                    <Select value={editingPlayer} onValueChange={setEditingPlayer}>
                      <SelectTrigger className="bg-background border-neon-cyan/30 flex-1">
                        <SelectValue placeholder="Seleccionar jugador..." />
                      </SelectTrigger>
                      <SelectContent className="max-h-60">
                        <SelectItem value="_none">Sin jugador asignado</SelectItem>
                        {playersWithFullInfo.map(player => (
                          <SelectItem key={player.id} value={player.id}>
                            <div className="flex items-center justify-between w-full gap-2">
                              <span>{player.name}</span>
                              <span className={`text-xs ${player.credits === 0 ? 'text-destructive' : player.credits <= 5 ? 'text-warning' : 'text-muted-foreground'}`}>
                                {player.category} • {player.credits}c
                              </span>
                            </div>
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    {editingPlayer && editingPlayer !== '_none' && (
                      <NeonButton 
                        variant="outline" 
                        size="sm"
                        onClick={handleRemovePlayer}
                        disabled={isUpdating}
                        className="shrink-0"
                      >
                        <X className="w-4 h-4" />
                      </NeonButton>
                    )}
                  </div>
                </div>

                {/* Trainer Selection */}
                <div className="space-y-2">
                  <Label className="flex items-center gap-2">
                    <User className="w-4 h-4 text-neon-purple" />
                    Entrenador Asignado
                  </Label>
                  <Select value={editingTrainer} onValueChange={setEditingTrainer}>
                    <SelectTrigger className="bg-background border-neon-purple/30">
                      <SelectValue placeholder="Seleccionar entrenador..." />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="_none">Sin entrenador asignado</SelectItem>
                      {trainers.map(trainer => (
                        <SelectItem key={trainer.id} value={trainer.id}>
                          {trainer.name} {trainer.specialty ? `- ${trainer.specialty}` : ''}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Status Selection */}
                <div className="space-y-2">
                  <Label>Estado de la Sesión</Label>
                  <Select value={editingStatus} onValueChange={setEditingStatus}>
                    <SelectTrigger className="bg-background border-border">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pending">
                        <span className="flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full bg-warning" />
                          Pendiente
                        </span>
                      </SelectItem>
                      <SelectItem value="approved">
                        <span className="flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full bg-neon-cyan" />
                          Aprobada
                        </span>
                      </SelectItem>
                      <SelectItem value="completed">
                        <span className="flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full bg-success" />
                          Completada
                        </span>
                      </SelectItem>
                      <SelectItem value="no_show">
                        <span className="flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full bg-warning" />
                          No Asistió
                        </span>
                      </SelectItem>
                      <SelectItem value="rejected">
                        <span className="flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full bg-destructive" />
                          Rechazada
                        </span>
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Warning for 0 credit player */}
                {editingPlayer && editingPlayer !== '_none' && playersWithFullInfo.find(p => p.id === editingPlayer)?.credits === 0 && (
                  <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/30 flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4 text-destructive" />
                    <p className="text-xs text-destructive">Este jugador no tiene créditos disponibles</p>
                  </div>
                )}

                {/* Action Buttons */}
                <div className="flex flex-col gap-3 pt-2">
                  {/* Complete Session Button - only for approved sessions */}
                  {selectedReservation.status === 'approved' && (
                    <NeonButton
                      variant="gradient"
                      className="w-full"
                      onClick={handleOpenCompleteSession}
                    >
                      <CheckCircle className="w-4 h-4 mr-2" />
                      Finalizar Sesión
                    </NeonButton>
                  )}

                  <div className="flex gap-3">
                    <NeonButton 
                      variant="cyan" 
                      className="flex-1"
                      onClick={handleUpdateReservation}
                      disabled={isUpdating}
                    >
                      {isUpdating ? (
                        <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
                      ) : (
                        <>
                          <Plus className="w-4 h-4 mr-2" />
                          Guardar Cambios
                        </>
                      )}
                    </NeonButton>
                    
                    {deleteReservation && (
                      <NeonButton 
                        variant="outline"
                        onClick={handleDeleteSession}
                        disabled={isUpdating}
                        className="border-destructive/30 text-destructive hover:bg-destructive/10"
                      >
                        <X className="w-4 h-4" />
                      </NeonButton>
                    )}
                  </div>
                </div>
              </TabsContent>
              
              <TabsContent value="history" className="mt-4">
                <SessionHistoryPanel reservationId={selectedReservation.id} />
              </TabsContent>
            </Tabs>
          )}
        </DialogContent>
      </Dialog>

      {/* Move Confirmation Modal */}
      <MoveConfirmationModal
        isOpen={moveConfirmModalOpen}
        onClose={() => {
          setMoveConfirmModalOpen(false);
          setPendingMove(null);
        }}
        onConfirm={handleConfirmMove}
        isLoading={isUpdating}
        moveDetails={pendingMove ? {
          playerName: pendingMove.playerName,
          oldDate: parseISO(pendingMove.reservation.start_time),
          oldHour: parseISO(pendingMove.reservation.start_time).getHours(),
          newDate: pendingMove.targetDate,
          newHour: pendingMove.targetHour,
          trainerName: pendingMove.trainerName,
          conflictWarning: pendingMove.conflictWarning,
        } : null}
      />

      {/* Complete Session Modal */}
      <CompleteSessionModal
        open={completeSessionModalOpen}
        onOpenChange={setCompleteSessionModalOpen}
        reservation={reservationToComplete}
        onComplete={() => {
          setReservationToComplete(null);
          refetch();
        }}
      />
    </DndContext>
  );
};

export default WeeklyScheduleView;
