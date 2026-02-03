import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { NeonButton } from '@/components/ui/NeonButton';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useTrainers } from '@/hooks/useTrainers';
import AvailabilityPicker, { SelectedSlot } from './AvailabilityPicker';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { Calendar, Clock, Coins, ArrowLeft, Send } from 'lucide-react';
import type { Player } from '@/hooks/useMyPlayers';

const reservationSchema = z.object({
  title: z.string().min(3, 'El título debe tener al menos 3 caracteres'),
  description: z.string().optional(),
  player_id: z.string().optional(),
  trainer_id: z.string().optional(),
});

type ReservationFormData = z.infer<typeof reservationSchema>;

interface NewReservationWithCalendarProps {
  players: Player[];
  credits: number;
  onSubmit: (data: {
    title: string;
    description?: string;
    start_time: string;
    end_time: string;
    player_id?: string;
    trainer_id?: string;
  }) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

const NewReservationWithCalendar: React.FC<NewReservationWithCalendarProps> = ({
  players,
  credits,
  onSubmit,
  onCancel,
  loading,
}) => {
  const { trainers } = useTrainers();
  const [step, setStep] = useState<'calendar' | 'details'>('calendar');
  const [selectedSlot, setSelectedSlot] = useState<SelectedSlot | null>(null);

  const form = useForm<ReservationFormData>({
    resolver: zodResolver(reservationSchema),
    defaultValues: {
      title: '',
      description: '',
      player_id: '_none',
      trainer_id: '_none',
    },
  });

  const handleSlotSelect = (slot: SelectedSlot | null) => {
    setSelectedSlot(slot);
  };

  const handleContinue = () => {
    if (selectedSlot) {
      setStep('details');
    }
  };

  const handleBack = () => {
    setStep('calendar');
  };

  const handleSubmit = async (data: ReservationFormData) => {
    if (!selectedSlot) return;

    const startDate = new Date(selectedSlot.date);
    startDate.setHours(selectedSlot.hour, 0, 0, 0);
    
    const endDate = new Date(selectedSlot.date);
    endDate.setHours(selectedSlot.hour + 1, 0, 0, 0);

    await onSubmit({
      title: data.title,
      description: data.description,
      start_time: startDate.toISOString(),
      end_time: endDate.toISOString(),
      player_id: data.player_id === '_none' ? undefined : data.player_id || undefined,
      trainer_id: data.trainer_id === '_none' ? undefined : data.trainer_id || undefined,
    });

    form.reset();
    setSelectedSlot(null);
    setStep('calendar');
  };

  if (credits < 1) {
    return (
      <div className="p-6 text-center">
        <div className="w-16 h-16 rounded-full bg-destructive/10 border border-destructive/30 flex items-center justify-center mx-auto mb-4">
          <Coins className="w-8 h-8 text-destructive" />
        </div>
        <h3 className="font-orbitron font-semibold text-lg mb-2">Sin créditos</h3>
        <p className="text-muted-foreground text-sm mb-4">
          Necesitas al menos 1 crédito para hacer una reserva.
        </p>
        <NeonButton variant="outline" onClick={onCancel}>
          Volver
        </NeonButton>
      </div>
    );
  }

  if (step === 'calendar') {
    return (
      <div className="space-y-4">
        <AvailabilityPicker
          onSelectSlot={handleSlotSelect}
          selectedSlot={selectedSlot}
        />
        
        <div className="flex gap-3">
          <NeonButton variant="outline" onClick={onCancel} className="flex-1">
            Cancelar
          </NeonButton>
          <NeonButton
            variant="gradient"
            onClick={handleContinue}
            disabled={!selectedSlot}
            className="flex-1"
          >
            Continuar
          </NeonButton>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Selected Time Summary */}
      {selectedSlot && (
        <div className="p-4 rounded-lg bg-neon-cyan/10 border border-neon-cyan/30">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center gap-2 text-sm font-semibold mb-1">
                <Calendar className="w-4 h-4 text-neon-cyan" />
                <span>{format(selectedSlot.date, "EEEE d 'de' MMMM", { locale: es })}</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Clock className="w-4 h-4 text-neon-purple" />
                <span>{selectedSlot.hour}:00 - {selectedSlot.hour + 1}:00</span>
              </div>
            </div>
            <NeonButton variant="outline" size="sm" onClick={handleBack}>
              <ArrowLeft className="w-4 h-4 mr-1" />
              Cambiar
            </NeonButton>
          </div>
        </div>
      )}

      <Form {...form}>
        <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
          <FormField
            control={form.control}
            name="title"
            render={({ field }) => (
              <FormItem>
                <FormLabel className="font-rajdhani">Título de la reserva</FormLabel>
                <FormControl>
                  <Input
                    {...field}
                    placeholder="Ej: Entrenamiento técnico"
                    className="bg-muted/50 border-neon-cyan/30"
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="player_id"
            render={({ field }) => (
              <FormItem>
                <FormLabel className="font-rajdhani">Jugador</FormLabel>
                <Select onValueChange={field.onChange} defaultValue={field.value}>
                  <FormControl>
                    <SelectTrigger className="bg-muted/50 border-neon-cyan/30">
                      <SelectValue placeholder="Selecciona jugador" />
                    </SelectTrigger>
                  </FormControl>
                  <SelectContent>
                    <SelectItem value="_none">Sin jugador específico</SelectItem>
                    {players.map((player) => (
                      <SelectItem key={player.id} value={player.id}>
                        {player.name} - {player.category}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="trainer_id"
            render={({ field }) => (
              <FormItem>
                <FormLabel className="font-rajdhani">Entrenador preferido (opcional)</FormLabel>
                <Select onValueChange={field.onChange} defaultValue={field.value}>
                  <FormControl>
                    <SelectTrigger className="bg-muted/50 border-neon-purple/30">
                      <SelectValue placeholder="Sin preferencia" />
                    </SelectTrigger>
                  </FormControl>
                  <SelectContent>
                    <SelectItem value="_none">Sin preferencia</SelectItem>
                    {trainers.map((trainer) => (
                      <SelectItem key={trainer.id} value={trainer.id}>
                        {trainer.name} {trainer.specialty ? `- ${trainer.specialty}` : ''}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="description"
            render={({ field }) => (
              <FormItem>
                <FormLabel className="font-rajdhani">Notas adicionales (opcional)</FormLabel>
                <FormControl>
                  <Textarea
                    {...field}
                    placeholder="Detalles adicionales para Pedro..."
                    className="bg-muted/50 border-neon-cyan/30 resize-none"
                    rows={3}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <div className="flex gap-3 pt-2">
            <NeonButton type="button" variant="outline" onClick={handleBack} className="flex-1">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Atrás
            </NeonButton>
            <NeonButton
              type="submit"
              variant="gradient"
              className="flex-1"
              disabled={loading}
            >
              {loading ? (
                'Enviando...'
              ) : (
                <>
                  <Send className="w-4 h-4 mr-2" />
                  Enviar a Pedro
                </>
              )}
            </NeonButton>
          </div>

          <p className="text-xs text-muted-foreground text-center">
            <Coins className="w-3 h-3 inline mr-1" />
            Se descontará 1 crédito cuando Pedro apruebe la reserva
          </p>
        </form>
      </Form>
    </div>
  );
};

export default NewReservationWithCalendar;
