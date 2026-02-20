import React, { useState, useMemo } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Reservation } from '@/hooks/useReservations';
import { Trainer } from '@/hooks/useTrainers';
import { format, startOfMonth, endOfMonth, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import { ChevronLeft, ChevronRight, Users, User, Calendar, TrendingUp, Download, Loader2 } from 'lucide-react';
import { NeonButton } from '@/components/ui/NeonButton';
import * as XLSX from 'xlsx';

interface PlayerWithStats {
  id: string;
  name: string;
  category: string;
  level: string;
}

interface AttendanceReportsProps {
  reservations: Reservation[];
  reservationsLoading: boolean;
  trainers: Trainer[];
  players: PlayerWithStats[];
}

const AttendanceReports: React.FC<AttendanceReportsProps> = ({
  reservations,
  reservationsLoading,
  trainers,
  players
}) => {
  const [selectedMonth, setSelectedMonth] = useState(new Date());
  const [exporting, setExporting] = useState(false);

  // Navigate months
  const navigateMonth = (direction: 'prev' | 'next') => {
    const newDate = new Date(selectedMonth);
    newDate.setMonth(newDate.getMonth() + (direction === 'next' ? 1 : -1));
    setSelectedMonth(newDate);
  };

  // Filter reservations for selected month
  const monthReservations = useMemo(() => {
    const monthStart = startOfMonth(selectedMonth);
    const monthEnd = endOfMonth(selectedMonth);
    
    return reservations.filter(r => {
      const date = parseISO(r.start_time);
      return date >= monthStart && date <= monthEnd;
    });
  }, [reservations, selectedMonth]);

  // Stats by status
  const statusStats = useMemo(() => {
    const stats = {
      completed: 0,
      approved: 0,
      pending: 0,
      no_show: 0,
      rejected: 0,
    };

    monthReservations.forEach(r => {
      const status = r.status || 'pending';
      if (status in stats) {
        stats[status as keyof typeof stats]++;
      }
    });

    return [
      { name: 'Completadas', value: stats.completed, color: 'hsl(120, 70%, 50%)' },
      { name: 'Aprobadas', value: stats.approved, color: 'hsl(180, 100%, 50%)' },
      { name: 'Pendientes', value: stats.pending, color: 'hsl(45, 100%, 50%)' },
      { name: 'No Asistió', value: stats.no_show, color: 'hsl(30, 100%, 50%)' },
      { name: 'Rechazadas', value: stats.rejected, color: 'hsl(0, 70%, 50%)' },
    ].filter(s => s.value > 0);
  }, [monthReservations]);

  // Stats by trainer
  const trainerStats = useMemo(() => {
    const stats: Record<string, { name: string; total: number; completed: number; no_show: number }> = {};

    // Initialize all trainers
    trainers.forEach(t => {
      stats[t.id] = { name: t.name, total: 0, completed: 0, no_show: 0 };
    });
    stats['unassigned'] = { name: 'Sin Asignar', total: 0, completed: 0, no_show: 0 };

    monthReservations.forEach(r => {
      const trainerId = r.trainer_id || 'unassigned';
      if (!stats[trainerId]) {
        stats[trainerId] = { name: 'Desconocido', total: 0, completed: 0, no_show: 0 };
      }
      stats[trainerId].total++;
      if (r.status === 'completed') stats[trainerId].completed++;
      if (r.status === 'no_show') stats[trainerId].no_show++;
    });

    return Object.values(stats).filter(s => s.total > 0);
  }, [monthReservations, trainers]);

  // Stats by player
  const playerStats = useMemo(() => {
    const stats: Record<string, { name: string; total: number; completed: number; no_show: number; rate: number }> = {};

    monthReservations.forEach(r => {
      const playerId = r.player_id || 'unknown';
      const playerName = r.player?.name || 'Sin jugador';
      
      if (!stats[playerId]) {
        stats[playerId] = { name: playerName, total: 0, completed: 0, no_show: 0, rate: 0 };
      }
      stats[playerId].total++;
      if (r.status === 'completed') stats[playerId].completed++;
      if (r.status === 'no_show') stats[playerId].no_show++;
    });

    // Calculate attendance rate
    Object.values(stats).forEach(s => {
      const attended = s.completed;
      const relevant = s.completed + s.no_show;
      s.rate = relevant > 0 ? Math.round((attended / relevant) * 100) : 0;
    });

    return Object.values(stats)
      .filter(s => s.total > 0 && s.name !== 'Sin jugador')
      .sort((a, b) => b.total - a.total);
  }, [monthReservations]);

  // Overall stats
  const overallStats = useMemo(() => {
    const total = monthReservations.length;
    const completed = monthReservations.filter(r => r.status === 'completed').length;
    const noShow = monthReservations.filter(r => r.status === 'no_show').length;
    const relevant = completed + noShow;
    const rate = relevant > 0 ? Math.round((completed / relevant) * 100) : 0;

    return { total, completed, noShow, rate };
  }, [monthReservations]);

  // Export to Excel
  const handleExportExcel = async () => {
    setExporting(true);
    try {
      // Prepare data sheets
      const summaryData = [{
        'Mes': format(selectedMonth, 'MMMM yyyy', { locale: es }),
        'Total Sesiones': overallStats.total,
        'Completadas': overallStats.completed,
        'No Asistió': overallStats.noShow,
        'Tasa Asistencia': `${overallStats.rate}%`,
      }];

      const trainerData = trainerStats.map(t => ({
        'Entrenador': t.name,
        'Total Sesiones': t.total,
        'Completadas': t.completed,
        'No Asistió': t.no_show,
      }));

      const playerData = playerStats.map(p => ({
        'Jugador': p.name,
        'Total Sesiones': p.total,
        'Completadas': p.completed,
        'No Asistió': p.no_show,
        'Tasa Asistencia': `${p.rate}%`,
      }));

      const sessionsData = monthReservations.map(r => ({
        'Fecha': format(parseISO(r.start_time), 'dd/MM/yyyy'),
        'Hora': format(parseISO(r.start_time), 'HH:mm'),
        'Título': r.title,
        'Jugador': r.player?.name || 'Sin asignar',
        'Estado': r.status || 'pending',
        'Créditos': r.credit_cost,
      }));

      // Create workbook
      const wb = XLSX.utils.book_new();
      
      const wsSummary = XLSX.utils.json_to_sheet(summaryData);
      XLSX.utils.book_append_sheet(wb, wsSummary, 'Resumen');
      
      if (trainerData.length > 0) {
        const wsTrainers = XLSX.utils.json_to_sheet(trainerData);
        XLSX.utils.book_append_sheet(wb, wsTrainers, 'Por Entrenador');
      }
      
      if (playerData.length > 0) {
        const wsPlayers = XLSX.utils.json_to_sheet(playerData);
        XLSX.utils.book_append_sheet(wb, wsPlayers, 'Por Jugador');
      }
      
      if (sessionsData.length > 0) {
        const wsSessions = XLSX.utils.json_to_sheet(sessionsData);
        XLSX.utils.book_append_sheet(wb, wsSessions, 'Detalle Sesiones');
      }

      // Generate filename
      const filename = `Asistencia_${format(selectedMonth, 'yyyy-MM')}.xlsx`;
      
      // Download
      XLSX.writeFile(wb, filename);
    } catch (error) {
      console.error('Error exporting:', error);
    } finally {
      setExporting(false);
    }
  };

  if (reservationsLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-12 h-12 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="font-orbitron font-bold text-2xl gradient-text">
            Reportes de Asistencia
          </h2>
          <p className="text-muted-foreground font-rajdhani">
            Estadísticas mensuales de sesiones
          </p>
        </div>

        {/* Month Navigation */}
        <div className="flex items-center gap-4">
          <NeonButton 
            variant="outline" 
            size="sm" 
            onClick={handleExportExcel}
            disabled={exporting || monthReservations.length === 0}
          >
            {exporting ? (
              <Loader2 className="w-4 h-4 animate-spin mr-1" />
            ) : (
              <Download className="w-4 h-4 mr-1" />
            )}
            Excel
          </NeonButton>
          <NeonButton variant="outline" size="sm" onClick={() => navigateMonth('prev')}>
            <ChevronLeft className="w-4 h-4" />
          </NeonButton>
          <span className="font-orbitron text-lg text-neon-cyan min-w-[160px] text-center">
            {format(selectedMonth, 'MMMM yyyy', { locale: es })}
          </span>
          <NeonButton variant="outline" size="sm" onClick={() => navigateMonth('next')}>
            <ChevronRight className="w-4 h-4" />
          </NeonButton>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <EliteCard className="p-4 text-center">
          <Calendar className="w-8 h-8 text-neon-cyan mx-auto mb-2" />
          <p className="font-orbitron text-2xl text-foreground">{overallStats.total}</p>
          <p className="text-sm text-muted-foreground">Total Sesiones</p>
        </EliteCard>
        <EliteCard className="p-4 text-center">
          <TrendingUp className="w-8 h-8 text-green-400 mx-auto mb-2" />
          <p className="font-orbitron text-2xl text-green-400">{overallStats.completed}</p>
          <p className="text-sm text-muted-foreground">Completadas</p>
        </EliteCard>
        <EliteCard className="p-4 text-center">
          <User className="w-8 h-8 text-orange-400 mx-auto mb-2" />
          <p className="font-orbitron text-2xl text-orange-400">{overallStats.noShow}</p>
          <p className="text-sm text-muted-foreground">No Asistieron</p>
        </EliteCard>
        <EliteCard className="p-4 text-center">
          <Users className="w-8 h-8 text-neon-purple mx-auto mb-2" />
          <p className="font-orbitron text-2xl text-neon-purple">{overallStats.rate}%</p>
          <p className="text-sm text-muted-foreground">Tasa Asistencia</p>
        </EliteCard>
      </div>

      {/* Charts */}
      <div className="grid lg:grid-cols-2 gap-6">
        {/* Status Pie Chart */}
        <EliteCard className="p-6">
          <h3 className="font-orbitron text-lg mb-4">Estado de Sesiones</h3>
          {statusStats.length > 0 ? (
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={statusStats}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={2}
                  dataKey="value"
                  label={({ name, value }) => `${name}: ${value}`}
                >
                  {statusStats.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: 'hsl(var(--card))', 
                    border: '1px solid hsl(var(--neon-cyan) / 0.3)',
                    borderRadius: '8px'
                  }} 
                />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[250px] flex items-center justify-center text-muted-foreground">
              No hay datos para este mes
            </div>
          )}
        </EliteCard>

        {/* Trainer Bar Chart */}
        <EliteCard className="p-6">
          <h3 className="font-orbitron text-lg mb-4">Sesiones por Entrenador</h3>
          {trainerStats.length > 0 ? (
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={trainerStats} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis type="number" stroke="hsl(var(--muted-foreground))" />
                <YAxis 
                  dataKey="name" 
                  type="category" 
                  width={100} 
                  tick={{ fill: 'hsl(var(--muted-foreground))', fontSize: 12 }}
                />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: 'hsl(var(--card))', 
                    border: '1px solid hsl(var(--neon-cyan) / 0.3)',
                    borderRadius: '8px'
                  }} 
                />
                <Bar dataKey="completed" name="Completadas" fill="hsl(120, 70%, 50%)" stackId="a" />
                <Bar dataKey="no_show" name="No Asistió" fill="hsl(30, 100%, 50%)" stackId="a" />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[250px] flex items-center justify-center text-muted-foreground">
              No hay datos para este mes
            </div>
          )}
        </EliteCard>
      </div>
    </div>
  );
};

export default AttendanceReports;
