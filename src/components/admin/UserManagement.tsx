import React from 'react';
import { useUsers } from '@/hooks/useUsers';
import { useAllCredits } from '@/hooks/useCredits';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table';
import { 
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Check, X, Coins, User } from 'lucide-react';

const UserManagement: React.FC = () => {
  const { users, loading, approveUser, updateUserApproval } = useUsers();
  const { updateCredits } = useAllCredits();
  const { toast } = useToast();
  const [creditAmount, setCreditAmount] = React.useState<{ [key: string]: string }>({});
  const [dialogOpen, setDialogOpen] = React.useState<string | null>(null);

  const handleApprove = async (userId: string) => {
    const success = await approveUser(userId);
    if (success) {
      toast({
        title: 'Usuario aprobado',
        description: 'El usuario ahora tiene acceso al sistema.',
      });
    }
  };

  const handleToggleApproval = async (userId: string, currentStatus: boolean) => {
    const success = await updateUserApproval(userId, !currentStatus);
    if (success) {
      toast({
        title: currentStatus ? 'Acceso revocado' : 'Usuario aprobado',
        description: currentStatus 
          ? 'El usuario ya no tiene acceso al sistema.' 
          : 'El usuario ahora tiene acceso al sistema.',
      });
    }
  };

  const handleUpdateCredits = async (userId: string) => {
    const amount = parseInt(creditAmount[userId] || '0');
    if (isNaN(amount) || amount < 0) {
      toast({
        title: 'Error',
        description: 'Ingresa un número válido de créditos.',
        variant: 'destructive',
      });
      return;
    }

    const success = await updateCredits(userId, amount);
    if (success) {
      toast({
        title: 'Créditos actualizados',
        description: `El usuario ahora tiene ${amount} créditos.`,
      });
      setDialogOpen(null);
    }
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
      <div className="flex items-center justify-between">
        <h2 className="font-orbitron font-bold text-2xl gradient-text">
          Gestión de Usuarios
        </h2>
        <StatusBadge variant="info">{users.length} usuarios</StatusBadge>
      </div>

      <EliteCard className="overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="border-neon-cyan/20">
              <TableHead className="font-orbitron">Usuario</TableHead>
              <TableHead className="font-orbitron">Email</TableHead>
              <TableHead className="font-orbitron">Rol</TableHead>
              <TableHead className="font-orbitron">Créditos</TableHead>
              <TableHead className="font-orbitron">Estado</TableHead>
              <TableHead className="font-orbitron text-right">Acciones</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {users.map((user) => (
              <TableRow key={user.id} className="border-neon-cyan/10">
                <TableCell>
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center">
                      {user.avatar_url ? (
                        <img
                          src={user.avatar_url}
                          alt={user.full_name || ''}
                          className="w-full h-full rounded-full object-cover"
                        />
                      ) : (
                        <User className="w-5 h-5 text-neon-cyan" />
                      )}
                    </div>
                    <span className="font-rajdhani font-medium">
                      {user.full_name || 'Sin nombre'}
                    </span>
                  </div>
                </TableCell>
                <TableCell className="text-muted-foreground">{user.email}</TableCell>
                <TableCell>
                  <StatusBadge variant={user.role === 'admin' ? 'success' : 'default'}>
                    {user.role}
                  </StatusBadge>
                </TableCell>
                <TableCell>
                  <Dialog open={dialogOpen === user.id} onOpenChange={(open) => setDialogOpen(open ? user.id : null)}>
                    <DialogTrigger asChild>
                      <button className="flex items-center gap-2 px-3 py-1 rounded-lg bg-neon-purple/10 border border-neon-purple/30 text-neon-purple hover:bg-neon-purple/20 transition-colors">
                        <Coins className="w-4 h-4" />
                        <span className="font-rajdhani font-semibold">{user.credits}</span>
                      </button>
                    </DialogTrigger>
                    <DialogContent className="bg-background border-neon-cyan/30">
                      <DialogHeader>
                        <DialogTitle className="font-orbitron gradient-text">
                          Asignar Créditos
                        </DialogTitle>
                      </DialogHeader>
                      <div className="space-y-4 pt-4">
                        <p className="text-muted-foreground font-rajdhani">
                          Usuario: <span className="text-foreground">{user.full_name || user.email}</span>
                        </p>
                        <p className="text-muted-foreground font-rajdhani">
                          Créditos actuales: <span className="text-neon-cyan">{user.credits}</span>
                        </p>
                        <Input
                          type="number"
                          min="0"
                          placeholder="Nuevos créditos"
                          value={creditAmount[user.id] || ''}
                          onChange={(e) => setCreditAmount({ ...creditAmount, [user.id]: e.target.value })}
                          className="bg-muted/50 border-neon-cyan/30"
                        />
                        <NeonButton
                          variant="gradient"
                          onClick={() => handleUpdateCredits(user.id)}
                          className="w-full"
                        >
                          Actualizar Créditos
                        </NeonButton>
                      </div>
                    </DialogContent>
                  </Dialog>
                </TableCell>
                <TableCell>
                  <StatusBadge variant={user.is_approved ? 'success' : 'warning'}>
                    {user.is_approved ? 'Aprobado' : 'Pendiente'}
                  </StatusBadge>
                </TableCell>
                <TableCell className="text-right">
                  {user.role !== 'admin' && (
                    <NeonButton
                      variant={user.is_approved ? 'outline' : 'cyan'}
                      size="sm"
                      onClick={() => handleToggleApproval(user.id, user.is_approved)}
                    >
                      {user.is_approved ? (
                        <>
                          <X className="w-4 h-4 mr-1" />
                          Revocar
                        </>
                      ) : (
                        <>
                          <Check className="w-4 h-4 mr-1" />
                          Aprobar
                        </>
                      )}
                    </NeonButton>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </EliteCard>
    </div>
  );
};

export default UserManagement;
