import React, { useState } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { 
  CreditCard, 
  Plus, 
  Minus,
  Package,
  History,
  Loader2
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface CreditWalletManagerProps {
  userId: string;
  userName: string;
  currentBalance: number;
  onBalanceUpdated: () => void;
  onViewHistory: () => void;
}

const BONUS_OPTIONS = [
  { amount: 4, label: 'Bono 4', color: 'from-blue-500 to-cyan-500' },
  { amount: 8, label: 'Bono 8', color: 'from-purple-500 to-pink-500' },
  { amount: 12, label: 'Bono 12', color: 'from-amber-500 to-orange-500' },
];

const CreditWalletManager: React.FC<CreditWalletManagerProps> = ({
  userId,
  userName,
  currentBalance,
  onBalanceUpdated,
  onViewHistory,
}) => {
  const [customAmount, setCustomAmount] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const addCredits = async (amount: number, description: string) => {
    if (amount <= 0) return;
    
    setLoading(true);
    try {
      // Update balance
      const { error: updateError } = await supabase
        .from('user_credits')
        .update({ 
          balance: currentBalance + amount,
          updated_at: new Date().toISOString()
        })
        .eq('user_id', userId);

      if (updateError) throw updateError;

      // Log transaction
      const { error: logError } = await supabase
        .from('credit_transactions')
        .insert({
          user_id: userId,
          amount: amount,
          transaction_type: 'credit',
          description: description,
        });

      if (logError) throw logError;

      // Check if credits were low/zero before and send notification
      const newBalance = currentBalance + amount;
      if (currentBalance === 0 || currentBalance <= 5) {
        // Credits restored - no need for alert
      }

      toast({
        title: '✅ Créditos añadidos',
        description: `+${amount} créditos para ${userName}`,
      });

      onBalanceUpdated();
    } catch (error) {
      console.error('Error adding credits:', error);
      toast({
        title: 'Error',
        description: 'No se pudieron añadir los créditos',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleBonusClick = (amount: number) => {
    addCredits(amount, `Bono +${amount} sesiones`);
  };

  const handleCustomAdd = () => {
    const amount = parseInt(customAmount, 10);
    if (isNaN(amount) || amount <= 0) {
      toast({
        title: 'Cantidad inválida',
        description: 'Ingresa un número positivo',
        variant: 'destructive',
      });
      return;
    }
    addCredits(amount, `Carga manual +${amount}`);
    setCustomAmount('');
  };

  return (
    <EliteCard className="p-4 space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className={cn(
            "p-2 rounded-lg",
            currentBalance === 0 ? 'bg-red-500/20' : currentBalance <= 5 ? 'bg-yellow-500/20' : 'bg-green-500/20'
          )}>
            <CreditCard className={cn(
              "w-5 h-5",
              currentBalance === 0 ? 'text-red-400' : currentBalance <= 5 ? 'text-yellow-400' : 'text-green-400'
            )} />
          </div>
          <div>
            <p className="text-sm text-muted-foreground">Gestión de Cartera</p>
            <p className="font-rajdhani font-bold">{userName}</p>
          </div>
        </div>
        
        <div className="text-right">
          <p className="text-xs text-muted-foreground">Saldo actual</p>
          <p className={cn(
            "font-orbitron text-2xl font-bold",
            currentBalance === 0 ? 'text-red-400' : currentBalance <= 5 ? 'text-yellow-400' : 'text-neon-cyan'
          )}>
            {currentBalance}
          </p>
        </div>
      </div>

      {/* Bonus Buttons */}
      <div>
        <Label className="text-xs text-muted-foreground mb-2 block">Bonos de Sesiones</Label>
        <div className="grid grid-cols-3 gap-2">
          {BONUS_OPTIONS.map((bonus) => (
            <button
              key={bonus.amount}
              onClick={() => handleBonusClick(bonus.amount)}
              disabled={loading}
              className={cn(
                "relative overflow-hidden p-3 rounded-xl border border-white/10 transition-all duration-300",
                "hover:scale-105 hover:border-white/30 active:scale-95",
                "disabled:opacity-50 disabled:cursor-not-allowed",
                `bg-gradient-to-br ${bonus.color}`
              )}
            >
              <div className="relative z-10 flex flex-col items-center gap-1">
                <Package className="w-4 h-4 text-white" />
                <span className="text-white font-orbitron font-bold">+{bonus.amount}</span>
                <span className="text-white/80 text-[10px]">{bonus.label}</span>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Custom Amount */}
      <div>
        <Label className="text-xs text-muted-foreground mb-2 block">Carga Manual</Label>
        <div className="flex gap-2">
          <div className="relative flex-1">
            <Plus className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              type="number"
              min="1"
              value={customAmount}
              onChange={(e) => setCustomAmount(e.target.value)}
              placeholder="Cantidad"
              className="pl-9 bg-muted/50 border-neon-cyan/30"
              disabled={loading}
            />
          </div>
          <NeonButton
            variant="gradient"
            onClick={handleCustomAdd}
            disabled={loading || !customAmount}
          >
            {loading ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <>
                <Plus className="w-4 h-4 mr-1" />
                Cargar
              </>
            )}
          </NeonButton>
        </div>
      </div>

      {/* History Button */}
      <NeonButton
        variant="outline"
        size="sm"
        onClick={onViewHistory}
        className="w-full"
      >
        <History className="w-4 h-4 mr-2" />
        Ver Historial de Movimientos
      </NeonButton>
    </EliteCard>
  );
};

export default CreditWalletManager;
