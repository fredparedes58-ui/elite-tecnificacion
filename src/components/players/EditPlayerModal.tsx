import React from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
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
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { NeonButton } from '@/components/ui/NeonButton';
import type { Player } from '@/hooks/useMyPlayers';
import { Loader2, Save } from 'lucide-react';

const formSchema = z.object({
  name: z.string().min(2, 'Nombre muy corto'),
  birth_date: z.string().optional(),
  category: z.enum(['U8', 'U10', 'U12', 'U14', 'U16', 'U18']),
  level: z.enum(['beginner', 'intermediate', 'advanced', 'elite']),
  position: z.string().optional(),
  current_club: z.string().optional(),
  dominant_leg: z.enum(['right', 'left', 'both']).optional(),
  notes: z.string().optional(),
});

type FormData = z.infer<typeof formSchema>;

interface EditPlayerModalProps {
  isOpen: boolean;
  onClose: () => void;
  player: Player | null;
  onSave: (id: string, data: Partial<Omit<Player, 'stats'>>) => Promise<boolean>;
  loading?: boolean;
}

const EditPlayerModal: React.FC<EditPlayerModalProps> = ({
  isOpen,
  onClose,
  player,
  onSave,
  loading = false,
}) => {
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: player?.name || '',
      birth_date: player?.birth_date || '',
      category: player?.category || 'U10',
      level: player?.level || 'beginner',
      position: player?.position || '',
      current_club: player?.current_club || '',
      dominant_leg: (player?.dominant_leg as 'right' | 'left' | 'both') || 'right',
      notes: player?.notes || '',
    },
  });

  React.useEffect(() => {
    if (player) {
      form.reset({
        name: player.name,
        birth_date: player.birth_date || '',
        category: player.category,
        level: player.level,
        position: player.position || '',
        current_club: player.current_club || '',
        dominant_leg: (player.dominant_leg as 'right' | 'left' | 'both') || 'right',
        notes: player.notes || '',
      });
    }
  }, [player, form]);

  const handleSubmit = async (data: FormData) => {
    if (!player) return;
    const success = await onSave(player.id, data);
    if (success) {
      onClose();
    }
  };

  const categories = [
    { value: 'U8', label: 'Sub-8' },
    { value: 'U10', label: 'Sub-10' },
    { value: 'U12', label: 'Sub-12' },
    { value: 'U14', label: 'Sub-14' },
    { value: 'U16', label: 'Sub-16' },
    { value: 'U18', label: 'Sub-18' },
  ];

  const levels = [
    { value: 'beginner', label: 'Principiante' },
    { value: 'intermediate', label: 'Intermedio' },
    { value: 'advanced', label: 'Avanzado' },
    { value: 'elite', label: 'Élite' },
  ];

  const positions = [
    'Portero',
    'Defensa Central',
    'Lateral Derecho',
    'Lateral Izquierdo',
    'Mediocentro',
    'Mediapunta',
    'Extremo Derecho',
    'Extremo Izquierdo',
    'Delantero Centro',
  ];

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="bg-background border-neon-cyan/30 max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="font-orbitron gradient-text">
            ✏️ Editar Jugador
          </DialogTitle>
          <DialogDescription>
            Modifica los datos de {player?.name}
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Nombre completo</FormLabel>
                  <FormControl>
                    <Input {...field} placeholder="Nombre del jugador" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="grid grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="birth_date"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Fecha de nacimiento</FormLabel>
                    <FormControl>
                      <Input {...field} type="date" />
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
                    <FormLabel>Categoría</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {categories.map((cat) => (
                          <SelectItem key={cat.value} value={cat.value}>
                            {cat.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="level"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Nivel</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {levels.map((lv) => (
                          <SelectItem key={lv.value} value={lv.value}>
                            {lv.label}
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
                name="dominant_leg"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Pierna dominante</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="right">Derecha</SelectItem>
                        <SelectItem value="left">Izquierda</SelectItem>
                        <SelectItem value="both">Ambidiestro</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <FormField
              control={form.control}
              name="position"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Posición</FormLabel>
                  <Select onValueChange={field.onChange} value={field.value || ''}>
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Selecciona posición" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {positions.map((pos) => (
                        <SelectItem key={pos} value={pos}>
                          {pos}
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
              name="current_club"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Club actual</FormLabel>
                  <FormControl>
                    <Input {...field} placeholder="Nombre del club" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="notes"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Notas adicionales</FormLabel>
                  <FormControl>
                    <Textarea
                      {...field}
                      placeholder="Información adicional sobre el jugador..."
                      rows={3}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="flex gap-3 pt-4">
              <NeonButton
                type="button"
                variant="outline"
                onClick={onClose}
                className="flex-1"
                disabled={loading}
              >
                Cancelar
              </NeonButton>
              <NeonButton
                type="submit"
                variant="gradient"
                className="flex-1"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    Guardando...
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4 mr-2" />
                    Guardar Cambios
                  </>
                )}
              </NeonButton>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
};

export default EditPlayerModal;
