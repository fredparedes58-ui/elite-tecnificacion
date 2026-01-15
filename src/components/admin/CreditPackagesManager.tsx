import React, { useState } from 'react';
import { useCreditPackages, CreditPackage } from '@/hooks/useCreditPackages';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { useToast } from '@/hooks/use-toast';
import { 
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Package, Plus, Edit, Trash2, Coins, Euro } from 'lucide-react';

const CreditPackagesManager: React.FC = () => {
  const { packages, loading, createPackage, updatePackage, deletePackage } = useCreditPackages();
  const { toast } = useToast();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingPackage, setEditingPackage] = useState<CreditPackage | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    credits: 4,
    price: 60,
    description: '',
    is_active: true,
  });

  const resetForm = () => {
    setFormData({
      name: '',
      credits: 4,
      price: 60,
      description: '',
      is_active: true,
    });
    setEditingPackage(null);
  };

  const handleOpenDialog = (pkg?: CreditPackage) => {
    if (pkg) {
      setEditingPackage(pkg);
      setFormData({
        name: pkg.name,
        credits: pkg.credits,
        price: pkg.price,
        description: pkg.description || '',
        is_active: pkg.is_active,
      });
    } else {
      resetForm();
    }
    setDialogOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.name.trim()) {
      toast({
        title: 'Error',
        description: 'El nombre es requerido',
        variant: 'destructive',
      });
      return;
    }

    if (editingPackage) {
      const success = await updatePackage(editingPackage.id, formData);
      if (success) {
        toast({ title: 'Paquete actualizado', description: `${formData.name} ha sido actualizado.` });
        setDialogOpen(false);
        resetForm();
      }
    } else {
      const result = await createPackage(formData);
      if (result) {
        toast({ title: 'Paquete creado', description: `${formData.name} ha sido creado.` });
        setDialogOpen(false);
        resetForm();
      }
    }
  };

  const handleDelete = async (pkg: CreditPackage) => {
    if (!confirm(`¿Desactivar el paquete "${pkg.name}"?`)) return;
    
    const success = await deletePackage(pkg.id);
    if (success) {
      toast({ title: 'Paquete desactivado', description: `${pkg.name} ha sido desactivado.` });
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-8 h-8 border-2 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="font-orbitron font-semibold text-lg">Paquetes de Créditos</h3>
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger asChild>
            <NeonButton variant="gradient" size="sm" onClick={() => handleOpenDialog()}>
              <Plus className="w-4 h-4 mr-2" />
              Nuevo Paquete
            </NeonButton>
          </DialogTrigger>
          <DialogContent className="bg-background border-neon-cyan/30">
            <DialogHeader>
              <DialogTitle className="font-orbitron gradient-text">
                {editingPackage ? 'Editar Paquete' : 'Nuevo Paquete'}
              </DialogTitle>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <Label htmlFor="name">Nombre del Paquete</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="Ej: Bono Mensual"
                  className="bg-muted/50 border-neon-cyan/30"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="credits">Créditos</Label>
                  <Input
                    id="credits"
                    type="number"
                    min={1}
                    value={formData.credits}
                    onChange={(e) => setFormData({ ...formData, credits: parseInt(e.target.value) || 0 })}
                    className="bg-muted/50 border-neon-cyan/30"
                  />
                </div>
                <div>
                  <Label htmlFor="price">Precio (€)</Label>
                  <Input
                    id="price"
                    type="number"
                    min={0}
                    step={0.01}
                    value={formData.price}
                    onChange={(e) => setFormData({ ...formData, price: parseFloat(e.target.value) || 0 })}
                    className="bg-muted/50 border-neon-cyan/30"
                  />
                </div>
              </div>
              <div>
                <Label htmlFor="description">Descripción</Label>
                <Textarea
                  id="description"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Descripción opcional del paquete"
                  className="bg-muted/50 border-neon-cyan/30"
                  rows={2}
                />
              </div>
              <div className="flex items-center justify-between">
                <Label htmlFor="is_active">Paquete Activo</Label>
                <Switch
                  id="is_active"
                  checked={formData.is_active}
                  onCheckedChange={(checked) => setFormData({ ...formData, is_active: checked })}
                />
              </div>
              <div className="flex gap-3 pt-2">
                <NeonButton type="button" variant="outline" className="flex-1" onClick={() => setDialogOpen(false)}>
                  Cancelar
                </NeonButton>
                <NeonButton type="submit" variant="gradient" className="flex-1">
                  {editingPackage ? 'Guardar' : 'Crear'}
                </NeonButton>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {packages.length === 0 ? (
        <EliteCard className="p-8 text-center">
          <Package className="w-12 h-12 text-muted-foreground/30 mx-auto mb-3" />
          <p className="text-muted-foreground">No hay paquetes configurados</p>
        </EliteCard>
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {packages.map((pkg) => (
            <EliteCard 
              key={pkg.id} 
              className={`p-5 ${!pkg.is_active ? 'opacity-50' : ''}`}
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2">
                  <Package className="w-5 h-5 text-neon-cyan" />
                  <h4 className="font-orbitron font-semibold">{pkg.name}</h4>
                </div>
                <StatusBadge variant={pkg.is_active ? 'success' : 'default'}>
                  {pkg.is_active ? 'Activo' : 'Inactivo'}
                </StatusBadge>
              </div>

              {pkg.description && (
                <p className="text-sm text-muted-foreground mb-4">{pkg.description}</p>
              )}

              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <Coins className="w-4 h-4 text-neon-purple" />
                  <span className="font-orbitron font-bold text-neon-purple">{pkg.credits}</span>
                  <span className="text-sm text-muted-foreground">créditos</span>
                </div>
                <div className="flex items-center gap-1">
                  <Euro className="w-4 h-4 text-green-400" />
                  <span className="font-orbitron font-bold text-green-400">{pkg.price}</span>
                </div>
              </div>

              <div className="flex gap-2">
                <NeonButton 
                  variant="outline" 
                  size="sm" 
                  className="flex-1"
                  onClick={() => handleOpenDialog(pkg)}
                >
                  <Edit className="w-3 h-3 mr-1" />
                  Editar
                </NeonButton>
                {pkg.is_active && (
                  <NeonButton 
                    variant="outline" 
                    size="sm"
                    onClick={() => handleDelete(pkg)}
                  >
                    <Trash2 className="w-3 h-3" />
                  </NeonButton>
                )}
              </div>
            </EliteCard>
          ))}
        </div>
      )}
    </div>
  );
};

export default CreditPackagesManager;
