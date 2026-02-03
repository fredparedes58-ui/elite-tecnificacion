import React from 'react';
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
import type { Player } from '@/hooks/useMyPlayers';

const reservationSchema = z.object({
  title: z.string().min(3, 'El título debe tener al menos 3 caracteres'),
  description: z.string().optional(),
  date: z.string().min(1, 'Selecciona una fecha'),
  start_time: z.string().min(1, 'Selecciona hora de inicio'),
  end_time: z.string().min(1, 'Selecciona hora de fin'),
  player_id: z.string().optional(),
  trainer_id: z.string().optional(),
});

type ReservationFormData = z.infer<typeof reservationSchema>;

interface ReservationFormProps {
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

const ReservationForm: React.FC<ReservationFormProps> = ({
  players,
  credits,
  onSubmit,
  onCancel,
  loading,
}) => {
  const { trainers } = useTrainers();
  
  const form = useForm<ReservationFormData>({
    resolver: zodResolver(reservationSchema),
    defaultValues: {
      title: '',
      description: '',
      date: '',
      start_time: '',
      end_time: '',
      player_id: '',
      trainer_id: '',
    },
  });

  const handleSubmit = async (data: ReservationFormData) => {
    const startDateTime = `${data.date}T${data.start_time}:00`;
    const endDateTime = `${data.date}T${data.end_time}:00`;

    await onSubmit({
      title: data.title,
      description: data.description,
      start_time: startDateTime,
      end_time: endDateTime,
      player_id: data.player_id === '_none' ? undefined : data.player_id || undefined,
      trainer_id: data.trainer_id === '_none' ? undefined : data.trainer_id || undefined,
    });

    form.reset();
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
        {credits < 1 && (
          <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/30 text-destructive text-sm">
            No tienes créditos disponibles para hacer reservas.
          </div>
        )}

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
              <FormLabel className="font-rajdhani">Jugador (opcional)</FormLabel>
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
                    <SelectValue placeholder="Selecciona entrenador" />
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
          name="date"
          render={({ field }) => (
            <FormItem>
              <FormLabel className="font-rajdhani">Fecha</FormLabel>
              <FormControl>
                <Input
                  {...field}
                  type="date"
                  min={new Date().toISOString().split('T')[0]}
                  className="bg-muted/50 border-neon-cyan/30"
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="grid grid-cols-2 gap-4">
          <FormField
            control={form.control}
            name="start_time"
            render={({ field }) => (
              <FormItem>
                <FormLabel className="font-rajdhani">Hora inicio</FormLabel>
                <FormControl>
                  <Input
                    {...field}
                    type="time"
                    className="bg-muted/50 border-neon-cyan/30"
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="end_time"
            render={({ field }) => (
              <FormItem>
                <FormLabel className="font-rajdhani">Hora fin</FormLabel>
                <FormControl>
                  <Input
                    {...field}
                    type="time"
                    className="bg-muted/50 border-neon-cyan/30"
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
        </div>

        <FormField
          control={form.control}
          name="description"
          render={({ field }) => (
            <FormItem>
              <FormLabel className="font-rajdhani">Descripción (opcional)</FormLabel>
              <FormControl>
                <Textarea
                  {...field}
                  placeholder="Detalles adicionales..."
                  className="bg-muted/50 border-neon-cyan/30 resize-none"
                  rows={3}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="flex gap-3 pt-4">
          <NeonButton type="button" variant="outline" onClick={onCancel} className="flex-1">
            Cancelar
          </NeonButton>
          <NeonButton
            type="submit"
            variant="gradient"
            className="flex-1"
            disabled={loading || credits < 1}
          >
            {loading ? 'Enviando...' : 'Solicitar Reserva'}
          </NeonButton>
        </div>

        <p className="text-xs text-muted-foreground text-center">
          Esta reserva costará 1 crédito cuando sea aprobada
        </p>
      </form>
    </Form>
  );
};

export default ReservationForm;
