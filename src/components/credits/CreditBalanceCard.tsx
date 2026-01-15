import React from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { Coins, TrendingUp, TrendingDown, AlertTriangle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface CreditBalanceCardProps {
  balance: number;
}

const CreditBalanceCard: React.FC<CreditBalanceCardProps> = ({ balance }) => {
  const getBalanceStatus = () => {
    if (balance > 5) {
      return {
        color: 'text-green-400',
        bgColor: 'from-green-500/20 to-green-600/10',
        borderColor: 'border-green-500/30',
        icon: TrendingUp,
        message: 'Tienes créditos suficientes para tus próximas sesiones',
        percentage: 100,
      };
    } else if (balance > 0) {
      return {
        color: 'text-yellow-400',
        bgColor: 'from-yellow-500/20 to-yellow-600/10',
        borderColor: 'border-yellow-500/30',
        icon: AlertTriangle,
        message: 'Quedan pocos créditos, considera recargar pronto',
        percentage: (balance / 8) * 100,
      };
    } else {
      return {
        color: 'text-red-400',
        bgColor: 'from-red-500/20 to-red-600/10',
        borderColor: 'border-red-500/30',
        icon: TrendingDown,
        message: 'Sin créditos disponibles. Recarga para reservar sesiones',
        percentage: 0,
      };
    }
  };

  const status = getBalanceStatus();
  const StatusIcon = status.icon;

  return (
    <EliteCard className={cn('p-6', status.borderColor)}>
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className={cn(
            'w-12 h-12 rounded-xl bg-gradient-to-br flex items-center justify-center',
            status.bgColor
          )}>
            <Coins className={cn('w-6 h-6', status.color)} />
          </div>
          <div>
            <p className="text-sm text-muted-foreground font-rajdhani">Balance Actual</p>
            <h2 className={cn('font-orbitron font-bold text-4xl', status.color)}>
              {balance}
            </h2>
          </div>
        </div>
        <StatusIcon className={cn('w-6 h-6', status.color)} />
      </div>

      {/* Progress Bar */}
      <div className="mb-3">
        <div className="w-full h-2 rounded-full bg-muted/50 overflow-hidden">
          <div
            className={cn(
              'h-full rounded-full transition-all duration-500',
              balance > 5 ? 'bg-green-500' : balance > 0 ? 'bg-yellow-500' : 'bg-red-500'
            )}
            style={{ width: `${Math.min(status.percentage, 100)}%` }}
          />
        </div>
      </div>

      <p className="text-sm text-muted-foreground font-rajdhani">
        {status.message}
      </p>
    </EliteCard>
  );
};

export default CreditBalanceCard;
