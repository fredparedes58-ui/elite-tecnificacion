import React from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { NeonButton } from '@/components/ui/NeonButton';
import { Input } from '@/components/ui/input';
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
import { Constants } from '@/integrations/supabase/types';

const playerSchema = z.object({
  name: z.string().min(2, 'El nombre debe tener al menos 2 caracteres'),
  birth_date: z.string().optional(),
  category: z.enum(Constants.player_category as [string, ...string[]]),
  level: z.enum(Constants.player_level as [string, ...string[]]).optional(),
  position: z.string().optional(),
});

type PlayerFormData = z.infer<typeof playerSchema>;

interface PlayerFormProps {
  onSubmit: (data: PlayerFormData) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

const PlayerForm: React.FC<PlayerFormProps> = ({ onSubmit, onCancel, loading }) => {
  const form = useForm<PlayerFormData>({
    resolver: zodResolver(playerSchema),
    defaultValues: {
      name: '',
      birth_date: '',
      category: 'U10',
      level: 'beginner',
      position: '',
    },
  });

  const handleSubmit = async (data: PlayerFormData) => {
    await onSubmit(data);
    form.reset();
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel className="font-rajdhani">Nombre del jugador</FormLabel>
              <FormControl>
                <Input
                  {...field}
                  placeholder="Nombre completo"
                  className="bg-muted/50 border-neon-cyan/30"
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="birth_date"
          render={({ field }) => (
            <FormItem>
              <FormLabel className="font-rajdhani">Fecha de nacimiento</FormLabel>
              <FormControl>
                <Input
                  {...field}
                  type="date"
                  className="bg-muted/50 border-neon-cyan/30"
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="category"
          render={({ field }) => (
            <FormItem>
              <FormLabel className="font-rajdhani">Categoría</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger className="bg-muted/50 border-neon-cyan/30">
                    <SelectValue placeholder="Selecciona categoría" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  {Constants.player_category.map((cat) => (
                    <SelectItem key={cat} value={cat}>
                      {cat}
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
          name="level"
          render={({ field }) => (
            <FormItem>
              <FormLabel className="font-rajdhani">Nivel</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger className="bg-muted/50 border-neon-cyan/30">
                    <SelectValue placeholder="Selecciona nivel" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  {Constants.player_level.map((level) => (
                    <SelectItem key={level} value={level}>
                      {level.charAt(0).toUpperCase() + level.slice(1)}
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
          name="position"
          render={({ field }) => (
            <FormItem>
              <FormLabel className="font-rajdhani">Posición</FormLabel>
              <FormControl>
                <Input
                  {...field}
                  placeholder="Ej: Delantero, Portero..."
                  className="bg-muted/50 border-neon-cyan/30"
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
          <NeonButton type="submit" variant="gradient" className="flex-1" disabled={loading}>
            {loading ? 'Guardando...' : 'Guardar Jugador'}
          </NeonButton>
        </div>
      </form>
    </Form>
  );
};

export default PlayerForm;
