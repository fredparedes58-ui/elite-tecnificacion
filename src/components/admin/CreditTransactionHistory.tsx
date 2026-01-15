import React from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  ArrowUpCircle, 
  ArrowDownCircle, 
  RefreshCw, 
  Settings,
  Calendar,
  FileText
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface Transaction {
  id: string;
  user_id: string;
  reservation_id: string | null;
  amount: number;
  transaction_type: 'debit' | 'credit' | 'refund' | 'manual_adjustment';
  description: string | null;
  created_at: string;
}

interface CreditTransactionHistoryProps {
  transactions: Transaction[];
  loading?: boolean;
}

const getTransactionIcon = (type: string, amount: number) => {
  if (amount > 0) {
    return <ArrowUpCircle className="w-5 h-5 text-green-400" />;
  }
  return <ArrowDownCircle className="w-5 h-5 text-red-400" />;
};

const getTransactionBadge = (type: string) => {
  switch (type) {
    case 'credit':
      return <Badge className="bg-green-500/20 text-green-400 border-green-500/30">Carga</Badge>;
    case 'debit':
      return <Badge className="bg-red-500/20 text-red-400 border-red-500/30">Sesión</Badge>;
    case 'refund':
      return <Badge className="bg-blue-500/20 text-blue-400 border-blue-500/30">Reembolso</Badge>;
    case 'manual_adjustment':
      return <Badge className="bg-purple-500/20 text-purple-400 border-purple-500/30">Ajuste</Badge>;
    default:
      return <Badge variant="outline">{type}</Badge>;
  }
};

const CreditTransactionHistory: React.FC<CreditTransactionHistoryProps> = ({
  transactions,
  loading,
}) => {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-8 h-8 border-2 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  if (transactions.length === 0) {
    return (
      <EliteCard className="p-8 text-center">
        <FileText className="w-12 h-12 text-muted-foreground/30 mx-auto mb-4" />
        <p className="text-muted-foreground">No hay movimientos registrados</p>
      </EliteCard>
    );
  }

  return (
    <ScrollArea className="h-[400px] pr-4">
      <div className="space-y-3">
        {transactions.map((transaction) => (
          <EliteCard 
            key={transaction.id} 
            className={cn(
              "p-4 transition-all hover:border-neon-cyan/30",
              transaction.amount > 0 ? 'border-l-2 border-l-green-500' : 'border-l-2 border-l-red-500'
            )}
          >
            <div className="flex items-start gap-3">
              {/* Icon */}
              <div className={cn(
                "p-2 rounded-lg shrink-0",
                transaction.amount > 0 ? 'bg-green-500/10' : 'bg-red-500/10'
              )}>
                {getTransactionIcon(transaction.transaction_type, transaction.amount)}
              </div>

              {/* Content */}
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="font-rajdhani font-medium text-sm truncate">
                      {transaction.description || 'Movimiento de créditos'}
                    </p>
                    <div className="flex items-center gap-2 mt-1">
                      {getTransactionBadge(transaction.transaction_type)}
                      <span className="text-xs text-muted-foreground flex items-center gap-1">
                        <Calendar className="w-3 h-3" />
                        {format(new Date(transaction.created_at), "d MMM yyyy, HH:mm", { locale: es })}
                      </span>
                    </div>
                  </div>

                  {/* Amount */}
                  <div className={cn(
                    "font-orbitron font-bold text-lg shrink-0",
                    transaction.amount > 0 ? 'text-green-400' : 'text-red-400'
                  )}>
                    {transaction.amount > 0 ? '+' : ''}{transaction.amount}
                  </div>
                </div>
              </div>
            </div>
          </EliteCard>
        ))}
      </div>
    </ScrollArea>
  );
};

export default CreditTransactionHistory;
