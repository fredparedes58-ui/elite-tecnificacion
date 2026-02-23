import React, { useState, useEffect } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { useCreditPackages } from '@/hooks/useCreditPackages';
import { useAuth } from '@/contexts/AuthContext';
import { 
  CreditCard, 
  Plus, 
  Minus,
  Package,
  History,
  Loader2,
  Edit3,
  Save,
  Receipt,
  Banknote
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

interface CreditWalletManagerProps {
  userId: string;
  userName: string;
  currentBalance: number;
  onBalanceUpdated: () => void;
  onViewHistory: () => void;
}

// Fallback if no packages exist
const FALLBACK_BONUS_OPTIONS = [
  { id: 'fallback-4', credits: 4, name: 'Bono 4', price: 0 },
  { id: 'fallback-8', credits: 8, name: 'Bono 8', price: 0 },
  { id: 'fallback-12', credits: 12, name: 'Bono 12', price: 0 },
];

const GRADIENT_COLORS = [
  'from-blue-500 to-cyan-500',
  'from-purple-500 to-pink-500',
  'from-amber-500 to-orange-500',
  'from-green-500 to-emerald-500',
  'from-red-500 to-rose-500',
  'from-indigo-500 to-violet-500',
];

const CreditWalletManager: React.FC<CreditWalletManagerProps> = ({
  userId,
  userName,
  currentBalance,
  onBalanceUpdated,
  onViewHistory,
}) => {
  const { activePackages, loading: packagesLoading } = useCreditPackages();
  const { user } = useAuth();
  const [customAmount, setCustomAmount] = useState<string>('');
  const [removeAmount, setRemoveAmount] = useState<string>('');
  const [directBalance, setDirectBalance] = useState<string>(currentBalance.toString());
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('add');
  const { toast } = useToast();

  // Payment fields
  const [paymentMethod, setPaymentMethod] = useState<string>('efectivo');
  const [cashAmount, setCashAmount] = useState<string>('');
  const [paymentNotes, setPaymentNotes] = useState<string>('');

  // Use active packages or fallback
  const bonusOptions = activePackages.length > 0 ? activePackages : FALLBACK_BONUS_OPTIONS;

  // Update direct balance when prop changes
  useEffect(() => {
    setDirectBalance(currentBalance.toString());
  }, [currentBalance]);

  // Send receipt email
  const sendReceipt = async (params: {
    credits_added: number;
    new_balance: number;
    payment_method?: string;
    cash_amount?: number;
    package_name?: string;
    description?: string;
  }) => {
    try {
      // Get parent email
      const { data: profile } = await supabase
        .from('profiles')
        .select('email, full_name')
        .eq('id', userId)
        .single();

      if (!profile?.email) return;

      // Get player names for this parent
      const { data: playersList } = await supabase
        .from('players')
        .select('name')
        .eq('parent_id', userId)
        .limit(5);

      const playerNames = playersList?.map(p => p.name).join(', ') || userName;

      await supabase.functions.invoke('send-credit-receipt', {
        body: {
          parent_email: profile.email,
          parent_name: profile.full_name || userName,
          player_name: playerNames,
          credits_added: params.credits_added,
          new_balance: params.new_balance,
          payment_method: params.payment_method,
          cash_amount: params.cash_amount,
          package_name: params.package_name,
          description: params.description,
        },
      });
    } catch (err) {
      console.error('Error sending receipt:', err);
      // Don't block the flow if receipt fails
    }
  };

  // Record cash payment
  const recordCashPayment = async (transactionId: string) => {
    const amount = parseFloat(cashAmount);
    if (!cashAmount || isNaN(amount) || amount <= 0) return;

    try {
      await supabase.from('cash_payments').insert({
        user_id: userId,
        transaction_id: transactionId,
        cash_amount: amount,
        payment_method: paymentMethod,
        notes: paymentNotes || null,
        received_by: user?.id || null,
      });
    } catch (err) {
      console.error('Error recording cash payment:', err);
    }
  };

  const addCredits = async (amount: number, description: string, packageId?: string, packageName?: string) => {
    if (amount <= 0) return;
    
    setLoading(true);
    try {
      const newBalance = currentBalance + amount;

      const { error: updateError } = await supabase
        .from('user_credits')
        .update({ 
          balance: newBalance,
          updated_at: new Date().toISOString()
        })
        .eq('user_id', userId);

      if (updateError) throw updateError;

      const { data: txData, error: logError } = await supabase
        .from('credit_transactions')
        .insert({
          user_id: userId,
          amount: amount,
          transaction_type: 'credit',
          description: description,
          package_id: packageId || null,
        })
        .select('id')
        .single();

      if (logError) throw logError;

      // Record cash payment if amount provided
      if (txData?.id) {
        await recordCashPayment(txData.id);
      }

      // Send receipt email
      const cashAmountNum = parseFloat(cashAmount);
      await sendReceipt({
        credits_added: amount,
        new_balance: newBalance,
        payment_method: paymentMethod,
        cash_amount: !isNaN(cashAmountNum) && cashAmountNum > 0 ? cashAmountNum : undefined,
        package_name: packageName,
        description,
      });

      toast({
        title: '✅ Créditos añadidos',
        description: `+${amount} créditos para ${userName}. Recibo enviado.`,
      });

      onBalanceUpdated();
      setCustomAmount('');
      setCashAmount('');
      setPaymentNotes('');
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

  const removeCredits = async (amount: number) => {
    if (amount <= 0) return;
    if (amount > currentBalance) {
      toast({
        title: 'Error',
        description: 'No puedes quitar más créditos de los disponibles',
        variant: 'destructive',
      });
      return;
    }
    
    setLoading(true);
    try {
      const { error: updateError } = await supabase
        .from('user_credits')
        .update({ 
          balance: currentBalance - amount,
          updated_at: new Date().toISOString()
        })
        .eq('user_id', userId);

      if (updateError) throw updateError;

      const { error: logError } = await supabase
        .from('credit_transactions')
        .insert({
          user_id: userId,
          amount: -amount,
          transaction_type: 'debit',
          description: `Ajuste manual -${amount}`,
        });

      if (logError) throw logError;

      toast({
        title: '⚠️ Créditos quitados',
        description: `-${amount} créditos de ${userName}`,
      });

      onBalanceUpdated();
      setRemoveAmount('');
    } catch (error) {
      console.error('Error removing credits:', error);
      toast({
        title: 'Error',
        description: 'No se pudieron quitar los créditos',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const setDirectCredits = async () => {
    const newBalance = parseInt(directBalance, 10);
    if (isNaN(newBalance) || newBalance < 0) {
      toast({
        title: 'Cantidad inválida',
        description: 'Ingresa un número válido (0 o mayor)',
        variant: 'destructive',
      });
      return;
    }

    if (newBalance === currentBalance) {
      toast({
        title: 'Sin cambios',
        description: 'El saldo es igual al actual',
      });
      return;
    }
    
    setLoading(true);
    try {
      const { error: updateError } = await supabase
        .from('user_credits')
        .update({ 
          balance: newBalance,
          updated_at: new Date().toISOString()
        })
        .eq('user_id', userId);

      if (updateError) throw updateError;

      const difference = newBalance - currentBalance;
      const { error: logError } = await supabase
        .from('credit_transactions')
        .insert({
          user_id: userId,
          amount: difference,
          transaction_type: 'manual_adjustment',
          description: `Ajuste directo: ${currentBalance} → ${newBalance}`,
        });

      if (logError) throw logError;

      toast({
        title: '✅ Saldo actualizado',
        description: `Nuevo saldo: ${newBalance} créditos`,
      });

      onBalanceUpdated();
    } catch (error) {
      console.error('Error setting credits:', error);
      toast({
        title: 'Error',
        description: 'No se pudo actualizar el saldo',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleBonusClick = (pkg: typeof bonusOptions[0]) => {
    const packageId = pkg.id.startsWith('fallback') ? undefined : pkg.id;
    addCredits(pkg.credits, `${pkg.name} +${pkg.credits} sesiones`, packageId, pkg.name);
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
  };

  const handleRemove = () => {
    const amount = parseInt(removeAmount, 10);
    if (isNaN(amount) || amount <= 0) {
      toast({
        title: 'Cantidad inválida',
        description: 'Ingresa un número positivo',
        variant: 'destructive',
      });
      return;
    }
    removeCredits(amount);
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

      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid w-full grid-cols-3 bg-muted/50">
          <TabsTrigger value="add" className="data-[state=active]:bg-green-500/20 data-[state=active]:text-green-400">
            <Plus className="w-3 h-3 mr-1" />
            Añadir
          </TabsTrigger>
          <TabsTrigger value="remove" className="data-[state=active]:bg-red-500/20 data-[state=active]:text-red-400">
            <Minus className="w-3 h-3 mr-1" />
            Quitar
          </TabsTrigger>
          <TabsTrigger value="set" className="data-[state=active]:bg-blue-500/20 data-[state=active]:text-blue-400">
            <Edit3 className="w-3 h-3 mr-1" />
            Modificar
          </TabsTrigger>
        </TabsList>

        {/* Add Credits Tab */}
        <TabsContent value="add" className="space-y-4 mt-4">
          <div>
            <Label className="text-xs text-muted-foreground mb-2 block">
              Paquetes de Créditos {packagesLoading && <span className="text-neon-cyan">(cargando...)</span>}
            </Label>
            <div className="grid grid-cols-3 gap-2">
              {bonusOptions.map((pkg, index) => (
                <button
                  key={pkg.id}
                  onClick={() => handleBonusClick(pkg)}
                  disabled={loading || packagesLoading}
                  className={cn(
                    "relative overflow-hidden p-3 rounded-xl border border-neon-cyan/20 transition-all duration-300",
                    "hover:scale-105 hover:border-neon-cyan/40 active:scale-95",
                    "disabled:opacity-50 disabled:cursor-not-allowed",
                    `bg-gradient-to-br ${GRADIENT_COLORS[index % GRADIENT_COLORS.length]}`
                  )}
                >
                  <div className="relative z-10 flex flex-col items-center gap-1">
                    <Package className="w-4 h-4 text-background" />
                    <span className="text-background font-orbitron font-bold">+{pkg.credits}</span>
                    <span className="text-background/80 text-[10px]">{pkg.name}</span>
                  </div>
                </button>
              ))}
            </div>
          </div>

          <div>
            <Label className="text-xs text-muted-foreground mb-2 block">Carga Manual</Label>
            <div className="flex gap-2">
              <div className="relative flex-1">
                <Plus className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-green-400" />
                <Input
                  type="number"
                  min="1"
                  value={customAmount}
                  onChange={(e) => setCustomAmount(e.target.value)}
                  placeholder="Cantidad a añadir"
                  className="pl-9 bg-muted/50 border-green-500/30"
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
                    Añadir
                  </>
                )}
              </NeonButton>
            </div>
          </div>

          {/* Payment Info Section */}
          <div className="p-3 rounded-lg bg-muted/20 border border-border space-y-3">
            <div className="flex items-center gap-2 mb-1">
              <Banknote className="w-4 h-4 text-green-400" />
              <Label className="text-xs text-muted-foreground">Registro de Pago (opcional)</Label>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label className="text-[11px] text-muted-foreground">Método de pago</Label>
                <Select value={paymentMethod} onValueChange={setPaymentMethod}>
                  <SelectTrigger className="bg-background border-border mt-1 h-9 text-sm">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="efectivo">💵 Efectivo</SelectItem>
                    <SelectItem value="transferencia">🏦 Transferencia</SelectItem>
                    <SelectItem value="bizum">📱 Bizum</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label className="text-[11px] text-muted-foreground">Monto recibido (€)</Label>
                <Input
                  type="number"
                  min="0"
                  step="0.01"
                  value={cashAmount}
                  onChange={(e) => setCashAmount(e.target.value)}
                  placeholder="0.00"
                  className="bg-background border-border mt-1 h-9 text-sm"
                  disabled={loading}
                />
              </div>
            </div>

            <div>
              <Label className="text-[11px] text-muted-foreground">Notas (opcional)</Label>
              <Textarea
                value={paymentNotes}
                onChange={(e) => setPaymentNotes(e.target.value)}
                placeholder="Notas adicionales del pago..."
                className="bg-background border-border mt-1 text-sm min-h-[40px]"
                rows={2}
                disabled={loading}
              />
            </div>

            <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground">
              <Receipt className="w-3 h-3" />
              Se enviará un recibo por email al padre automáticamente
            </div>
          </div>
        </TabsContent>

        {/* Remove Credits Tab */}
        <TabsContent value="remove" className="space-y-4 mt-4">
          <div className="p-3 rounded-lg bg-red-500/10 border border-red-500/30">
            <p className="text-sm text-red-400">
              ⚠️ Esta acción quitará créditos del saldo del usuario.
            </p>
          </div>

          <div>
            <Label className="text-xs text-muted-foreground mb-2 block">Cantidad a Quitar</Label>
            <div className="flex gap-2">
              <div className="relative flex-1">
                <Minus className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-red-400" />
                <Input
                  type="number"
                  min="1"
                  max={currentBalance}
                  value={removeAmount}
                  onChange={(e) => setRemoveAmount(e.target.value)}
                  placeholder="Cantidad a quitar"
                  className="pl-9 bg-muted/50 border-red-500/30"
                  disabled={loading}
                />
              </div>
              <NeonButton
                variant="outline"
                onClick={handleRemove}
                disabled={loading || !removeAmount}
                className="border-red-500/50 text-red-400 hover:bg-red-500/20"
              >
                {loading ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <>
                    <Minus className="w-4 h-4 mr-1" />
                    Quitar
                  </>
                )}
              </NeonButton>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-2">
            {[1, 2, 5].map((amount) => (
              <button
                key={amount}
                onClick={() => removeCredits(amount)}
                disabled={loading || currentBalance < amount}
                className={cn(
                  "p-2 rounded-lg border border-red-500/30 bg-red-500/10 transition-all",
                  "hover:bg-red-500/20 hover:border-red-500/50",
                  "disabled:opacity-50 disabled:cursor-not-allowed"
                )}
              >
                <span className="text-red-400 font-orbitron font-bold">-{amount}</span>
              </button>
            ))}
          </div>
        </TabsContent>

        {/* Set Credits Tab */}
        <TabsContent value="set" className="space-y-4 mt-4">
          <div className="p-3 rounded-lg bg-blue-500/10 border border-blue-500/30">
            <p className="text-sm text-blue-400">
              📝 Establece un saldo específico directamente.
            </p>
          </div>

          <div>
            <Label className="text-xs text-muted-foreground mb-2 block">Nuevo Saldo</Label>
            <div className="flex gap-2">
              <div className="relative flex-1">
                <Edit3 className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-blue-400" />
                <Input
                  type="number"
                  min="0"
                  value={directBalance}
                  onChange={(e) => setDirectBalance(e.target.value)}
                  placeholder="Nuevo saldo"
                  className="pl-9 bg-muted/50 border-blue-500/30"
                  disabled={loading}
                />
              </div>
              <NeonButton
                variant="cyan"
                onClick={setDirectCredits}
                disabled={loading}
              >
                {loading ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <>
                    <Save className="w-4 h-4 mr-1" />
                    Guardar
                  </>
                )}
              </NeonButton>
            </div>
          </div>

          <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
            <span className="text-sm text-muted-foreground">Saldo actual:</span>
            <span className="font-orbitron font-bold text-neon-cyan">{currentBalance}</span>
          </div>
        </TabsContent>
      </Tabs>

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
