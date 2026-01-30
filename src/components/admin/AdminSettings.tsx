import React, { useState, useEffect } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { useSystemConfig } from '@/hooks/useSystemConfig';
import { useToast } from '@/hooks/use-toast';
import { 
  Settings, 
  Clock, 
  Users, 
  CalendarDays, 
  Coins, 
  AlertTriangle,
  Loader2,
  Save
} from 'lucide-react';

const DAYS_OF_WEEK = [
  { value: 1, label: 'Lunes' },
  { value: 2, label: 'Martes' },
  { value: 3, label: 'Miércoles' },
  { value: 4, label: 'Jueves' },
  { value: 5, label: 'Viernes' },
  { value: 6, label: 'Sábado' },
  { value: 7, label: 'Domingo' },
];

const AdminSettings: React.FC = () => {
  const { config, loading, updateConfig } = useSystemConfig();
  const { toast } = useToast();
  const [saving, setSaving] = useState<string | null>(null);
  
  // Local state for form fields
  const [sessionStart, setSessionStart] = useState(8);
  const [sessionEnd, setSessionEnd] = useState(21);
  const [maxCapacity, setMaxCapacity] = useState(6);
  const [activeDays, setActiveDays] = useState<number[]>([1, 2, 3, 4, 5, 6]);
  const [creditThreshold, setCreditThreshold] = useState(3);
  const [cancellationHours, setCancellationHours] = useState(24);

  // Sync local state with config
  useEffect(() => {
    if (!loading) {
      setSessionStart(config.session_hours.start);
      setSessionEnd(config.session_hours.end);
      setMaxCapacity(config.max_capacity.value);
      setActiveDays(config.active_days.days);
      setCreditThreshold(config.credit_alert_threshold.value);
      setCancellationHours(config.cancellation_window.hours);
    }
  }, [config, loading]);

  const handleSave = async (key: string, value: Record<string, unknown>) => {
    setSaving(key);
    const success = await updateConfig(key as keyof typeof config, value as typeof config[keyof typeof config]);
    setSaving(null);
    
    if (success) {
      toast({
        title: '✅ Configuración guardada',
        description: 'Los cambios han sido aplicados correctamente.',
      });
    } else {
      toast({
        title: 'Error',
        description: 'No se pudieron guardar los cambios.',
        variant: 'destructive',
      });
    }
  };

  const toggleDay = (day: number) => {
    setActiveDays(prev => 
      prev.includes(day) 
        ? prev.filter(d => d !== day)
        : [...prev, day].sort()
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <Loader2 className="w-8 h-8 animate-spin text-neon-cyan" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3 mb-6">
        <div className="p-2 rounded-lg bg-neon-cyan/20">
          <Settings className="w-6 h-6 text-neon-cyan" />
        </div>
        <div>
          <h2 className="font-orbitron font-bold text-xl">Configuración del Sistema</h2>
          <p className="text-sm text-muted-foreground">Ajusta los parámetros operativos de la academia</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Session Hours */}
        <EliteCard className="p-6">
          <div className="flex items-center gap-2 mb-4">
            <Clock className="w-5 h-5 text-neon-cyan" />
            <h3 className="font-orbitron font-semibold">Horario de Sesiones</h3>
          </div>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Hora Inicio</Label>
                <Input
                  type="number"
                  min={0}
                  max={23}
                  value={sessionStart}
                  onChange={(e) => setSessionStart(Number(e.target.value))}
                  className="bg-muted/50 border-neon-cyan/30"
                />
              </div>
              <div>
                <Label>Hora Fin</Label>
                <Input
                  type="number"
                  min={0}
                  max={23}
                  value={sessionEnd}
                  onChange={(e) => setSessionEnd(Number(e.target.value))}
                  className="bg-muted/50 border-neon-cyan/30"
                />
              </div>
            </div>
            <NeonButton
              variant="outline"
              size="sm"
              onClick={() => handleSave('session_hours', { start: sessionStart, end: sessionEnd })}
              disabled={saving === 'session_hours'}
            >
              {saving === 'session_hours' ? (
                <Loader2 className="w-4 h-4 animate-spin mr-2" />
              ) : (
                <Save className="w-4 h-4 mr-2" />
              )}
              Guardar
            </NeonButton>
          </div>
        </EliteCard>

        {/* Max Capacity */}
        <EliteCard className="p-6">
          <div className="flex items-center gap-2 mb-4">
            <Users className="w-5 h-5 text-neon-purple" />
            <h3 className="font-orbitron font-semibold">Capacidad Máxima</h3>
          </div>
          <div className="space-y-4">
            <div>
              <Label>Jugadores por sesión</Label>
              <Input
                type="number"
                min={1}
                max={20}
                value={maxCapacity}
                onChange={(e) => setMaxCapacity(Number(e.target.value))}
                className="bg-muted/50 border-neon-cyan/30"
              />
            </div>
            <NeonButton
              variant="outline"
              size="sm"
              onClick={() => handleSave('max_capacity', { value: maxCapacity })}
              disabled={saving === 'max_capacity'}
            >
              {saving === 'max_capacity' ? (
                <Loader2 className="w-4 h-4 animate-spin mr-2" />
              ) : (
                <Save className="w-4 h-4 mr-2" />
              )}
              Guardar
            </NeonButton>
          </div>
        </EliteCard>

        {/* Active Days */}
        <EliteCard className="p-6">
          <div className="flex items-center gap-2 mb-4">
            <CalendarDays className="w-5 h-5 text-neon-cyan" />
            <h3 className="font-orbitron font-semibold">Días Activos</h3>
          </div>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-2">
              {DAYS_OF_WEEK.map((day) => (
                <div key={day.value} className="flex items-center space-x-2">
                  <Checkbox
                    id={`day-${day.value}`}
                    checked={activeDays.includes(day.value)}
                    onCheckedChange={() => toggleDay(day.value)}
                  />
                  <label
                    htmlFor={`day-${day.value}`}
                    className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
                  >
                    {day.label}
                  </label>
                </div>
              ))}
            </div>
            <NeonButton
              variant="outline"
              size="sm"
              onClick={() => handleSave('active_days', { days: activeDays })}
              disabled={saving === 'active_days'}
            >
              {saving === 'active_days' ? (
                <Loader2 className="w-4 h-4 animate-spin mr-2" />
              ) : (
                <Save className="w-4 h-4 mr-2" />
              )}
              Guardar
            </NeonButton>
          </div>
        </EliteCard>

        {/* Credit Alert Threshold */}
        <EliteCard className="p-6">
          <div className="flex items-center gap-2 mb-4">
            <Coins className="w-5 h-5 text-neon-gold" />
            <h3 className="font-orbitron font-semibold">Umbral de Créditos</h3>
          </div>
          <div className="space-y-4">
            <div>
              <Label>Alertar cuando los créditos sean ≤</Label>
              <Input
                type="number"
                min={0}
                max={10}
                value={creditThreshold}
                onChange={(e) => setCreditThreshold(Number(e.target.value))}
                className="bg-muted/50 border-neon-cyan/30"
              />
            </div>
            <NeonButton
              variant="outline"
              size="sm"
              onClick={() => handleSave('credit_alert_threshold', { value: creditThreshold })}
              disabled={saving === 'credit_alert_threshold'}
            >
              {saving === 'credit_alert_threshold' ? (
                <Loader2 className="w-4 h-4 animate-spin mr-2" />
              ) : (
                <Save className="w-4 h-4 mr-2" />
              )}
              Guardar
            </NeonButton>
          </div>
        </EliteCard>

        {/* Cancellation Window */}
        <EliteCard className="p-6 md:col-span-2">
          <div className="flex items-center gap-2 mb-4">
            <AlertTriangle className="w-5 h-5 text-yellow-400" />
            <h3 className="font-orbitron font-semibold">Ventana de Cancelación</h3>
          </div>
          <div className="space-y-4">
            <div className="max-w-xs">
              <Label>Horas mínimas antes de la sesión para cancelar sin penalización</Label>
              <Input
                type="number"
                min={0}
                max={72}
                value={cancellationHours}
                onChange={(e) => setCancellationHours(Number(e.target.value))}
                className="bg-muted/50 border-neon-cyan/30"
              />
            </div>
            <p className="text-sm text-muted-foreground">
              Los padres recibirán una advertencia si intentan cancelar con menos de {cancellationHours} horas de anticipación.
            </p>
            <NeonButton
              variant="outline"
              size="sm"
              onClick={() => handleSave('cancellation_window', { hours: cancellationHours })}
              disabled={saving === 'cancellation_window'}
            >
              {saving === 'cancellation_window' ? (
                <Loader2 className="w-4 h-4 animate-spin mr-2" />
              ) : (
                <Save className="w-4 h-4 mr-2" />
              )}
              Guardar
            </NeonButton>
          </div>
        </EliteCard>
      </div>
    </div>
  );
};

export default AdminSettings;
