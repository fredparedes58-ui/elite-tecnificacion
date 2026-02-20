import React, { useState } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { useTrainers, Trainer } from '@/hooks/useTrainers';
import { useToast } from '@/hooks/use-toast';
import { 
  Plus, 
  Edit2, 
  Trash2, 
  User, 
  Mail, 
  Phone,
  Save,
  X
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';

interface TrainerFormData {
  name: string;
  email: string;
  phone: string;
  specialty: string;
  bio: string;
  color: string;
}

const TRAINER_COLOR_OPTIONS = [
  '#06b6d4', '#a855f7', '#f59e0b', '#10b981', '#ef4444', 
  '#3b82f6', '#ec4899', '#f97316', '#14b8a6', '#8b5cf6',
];

const emptyForm: TrainerFormData = {
  name: '',
  email: '',
  phone: '',
  specialty: '',
  bio: '',
  color: '#06b6d4',
};

const TrainerManagement: React.FC = () => {
  const { trainers, loading, createTrainer, updateTrainer, deleteTrainer } = useTrainers();
  const { toast } = useToast();
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [selectedTrainer, setSelectedTrainer] = useState<Trainer | null>(null);
  const [formData, setFormData] = useState<TrainerFormData>(emptyForm);
  const [saving, setSaving] = useState(false);

  const handleOpenCreate = () => {
    setSelectedTrainer(null);
    setFormData(emptyForm);
    setIsModalOpen(true);
  };

  const handleOpenEdit = (trainer: Trainer) => {
    setSelectedTrainer(trainer);
    setFormData({
      name: trainer.name,
      email: trainer.email || '',
      phone: trainer.phone || '',
      specialty: trainer.specialty || '',
      bio: trainer.bio || '',
      color: trainer.color || '#06b6d4',
    });
    setIsModalOpen(true);
  };

  const handleOpenDelete = (trainer: Trainer) => {
    setSelectedTrainer(trainer);
    setIsDeleteDialogOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.name.trim()) {
      toast({
        title: 'Error',
        description: 'El nombre es requerido.',
        variant: 'destructive',
      });
      return;
    }

    setSaving(true);

    try {
      if (selectedTrainer) {
        // Update
        const success = await updateTrainer(selectedTrainer.id, {
          name: formData.name,
          email: formData.email || null,
          phone: formData.phone || null,
          specialty: formData.specialty || null,
          bio: formData.bio || null,
          color: formData.color || '#06b6d4',
        });
        
        if (success) {
          toast({
            title: 'Entrenador actualizado',
            description: `${formData.name} ha sido actualizado.`,
          });
          setIsModalOpen(false);
        }
      } else {
        // Create
        const result = await createTrainer({
          name: formData.name,
          email: formData.email || null,
          phone: formData.phone || null,
          specialty: formData.specialty || null,
          bio: formData.bio || null,
          color: formData.color || '#06b6d4',
          photo_url: null,
          is_active: true,
        });
        
        if (result) {
          toast({
            title: 'Entrenador creado',
            description: `${formData.name} ha sido agregado al equipo.`,
          });
          setIsModalOpen(false);
        }
      }
    } catch (error) {
      toast({
        title: 'Error',
        description: 'No se pudo guardar el entrenador.',
        variant: 'destructive',
      });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedTrainer) return;

    const success = await deleteTrainer(selectedTrainer.id);
    
    if (success) {
      toast({
        title: 'Entrenador eliminado',
        description: `${selectedTrainer.name} ha sido eliminado.`,
      });
    } else {
      toast({
        title: 'Error',
        description: 'No se pudo eliminar el entrenador.',
        variant: 'destructive',
      });
    }
    
    setIsDeleteDialogOpen(false);
    setSelectedTrainer(null);
  };

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
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-orbitron font-bold text-2xl gradient-text">
            Entrenadores
          </h2>
          <p className="text-muted-foreground font-rajdhani">
            Gestiona el equipo de entrenadores de Elite 380
          </p>
        </div>
        <NeonButton variant="gradient" onClick={handleOpenCreate}>
          <Plus className="w-4 h-4 mr-2" />
          Agregar Entrenador
        </NeonButton>
      </div>

      {/* Trainers Grid */}
      {trainers.length === 0 ? (
        <EliteCard className="p-12 text-center">
          <User className="w-16 h-16 text-neon-purple/30 mx-auto mb-4" />
          <h3 className="font-orbitron font-semibold text-lg mb-2">
            No hay entrenadores
          </h3>
          <p className="text-muted-foreground mb-6">
            Agrega entrenadores para asignar sesiones
          </p>
          <NeonButton variant="gradient" onClick={handleOpenCreate}>
            <Plus className="w-4 h-4 mr-2" />
            Agregar primer entrenador
          </NeonButton>
        </EliteCard>
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {trainers.map((trainer) => (
            <EliteCard key={trainer.id} className="p-5">
              <div className="flex items-start gap-4">
                {/* Avatar */}
                <div className="w-14 h-14 rounded-lg bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center shrink-0 relative overflow-hidden">
                  {trainer.photo_url ? (
                    <img 
                      src={trainer.photo_url} 
                      alt={trainer.name}
                      className="w-full h-full object-cover rounded-lg"
                    />
                  ) : (
                    <User className="w-7 h-7 text-neon-cyan" />
                  )}
                  {/* Color indicator */}
                  <div 
                    className="absolute bottom-0 left-0 right-0 h-1.5"
                    style={{ backgroundColor: trainer.color || '#06b6d4' }}
                  />
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <h3 className="font-orbitron font-semibold truncate">
                    {trainer.name}
                  </h3>
                  {trainer.specialty && (
                    <StatusBadge variant="info" className="mt-1">
                      {trainer.specialty}
                    </StatusBadge>
                  )}
                </div>

                {/* Actions */}
                <div className="flex gap-1">
                  <button
                    onClick={() => handleOpenEdit(trainer)}
                    className="p-2 text-muted-foreground hover:text-neon-cyan transition-colors"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleOpenDelete(trainer)}
                    className="p-2 text-muted-foreground hover:text-destructive transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Contact Info */}
              <div className="mt-4 space-y-2 text-sm">
                {trainer.email && (
                  <div className="flex items-center gap-2 text-muted-foreground">
                    <Mail className="w-4 h-4 text-neon-cyan" />
                    <span className="truncate">{trainer.email}</span>
                  </div>
                )}
                {trainer.phone && (
                  <div className="flex items-center gap-2 text-muted-foreground">
                    <Phone className="w-4 h-4 text-neon-purple" />
                    <span>{trainer.phone}</span>
                  </div>
                )}
                {trainer.bio && (
                  <p className="text-muted-foreground line-clamp-2 mt-2">
                    {trainer.bio}
                  </p>
                )}
              </div>
            </EliteCard>
          ))}
        </div>
      )}

      {/* Create/Edit Modal */}
      <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
        <DialogContent className="bg-card border-neon-cyan/30">
          <DialogHeader>
            <DialogTitle className="font-orbitron gradient-text">
              {selectedTrainer ? 'Editar Entrenador' : 'Nuevo Entrenador'}
            </DialogTitle>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <Label htmlFor="name">Nombre *</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="Nombre del entrenador"
                className="mt-1"
              />
            </div>

            <div>
              <Label htmlFor="specialty">Especialidad</Label>
              <Input
                id="specialty"
                value={formData.specialty}
                onChange={(e) => setFormData({ ...formData, specialty: e.target.value })}
                placeholder="Ej: Técnica, Físico, Porteros..."
                className="mt-1"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  placeholder="email@ejemplo.com"
                  className="mt-1"
                />
              </div>
              <div>
                <Label htmlFor="phone">Teléfono</Label>
                <Input
                  id="phone"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  placeholder="+34 600 000 000"
                  className="mt-1"
                />
              </div>
            </div>

            <div>
              <Label htmlFor="bio">Biografía</Label>
              <Textarea
                id="bio"
                value={formData.bio}
                onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
                placeholder="Experiencia y formación del entrenador..."
                className="mt-1"
                rows={3}
              />
            </div>

            <div>
              <Label>Color de identificación</Label>
              <div className="flex flex-wrap gap-2 mt-2">
                {TRAINER_COLOR_OPTIONS.map((color) => (
                  <button
                    key={color}
                    type="button"
                    onClick={() => setFormData({ ...formData, color })}
                    className={`w-8 h-8 rounded-lg border-2 transition-all ${
                      formData.color === color 
                        ? 'border-white scale-110 shadow-lg' 
                        : 'border-transparent hover:border-white/30'
                    }`}
                    style={{ backgroundColor: color }}
                  />
                ))}
              </div>
            </div>

            <div className="flex gap-3 pt-4">
              <NeonButton
                type="submit"
                variant="gradient"
                className="flex-1"
                disabled={saving}
              >
                {saving ? (
                  <div className="w-4 h-4 border-2 border-background/50 border-t-background rounded-full animate-spin mr-2" />
                ) : (
                  <Save className="w-4 h-4 mr-2" />
                )}
                {selectedTrainer ? 'Guardar Cambios' : 'Crear Entrenador'}
              </NeonButton>
              <NeonButton
                type="button"
                variant="outline"
                onClick={() => setIsModalOpen(false)}
                disabled={saving}
              >
                <X className="w-4 h-4 mr-2" />
                Cancelar
              </NeonButton>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <AlertDialogContent className="bg-card border-destructive/30">
          <AlertDialogHeader>
            <AlertDialogTitle className="font-orbitron">
              ¿Eliminar entrenador?
            </AlertDialogTitle>
            <AlertDialogDescription>
              Esta acción eliminará a <strong>{selectedTrainer?.name}</strong> del sistema.
              Las sesiones asignadas quedarán sin entrenador.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
};

export default TrainerManagement;
