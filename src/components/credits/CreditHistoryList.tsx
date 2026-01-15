import React, { useState } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { ScrollArea } from '@/components/ui/scroll-area';
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { format, isThisWeek, isThisMonth } from 'date-fns';
import { es } from 'date-fns/locale';
import { ArrowUpCircle, ArrowDownCircle, RefreshCw, Settings, Package } from 'lucide-react';
import { cn } from '@/lib/utils';
import type { CreditTransaction } from '@/hooks/useCreditTransactions';

interface CreditHistoryListProps {
  transactions: CreditTransaction[];
  loading?: boolean;
}

const CreditHistoryList: React.FC<CreditHistoryListProps> = ({ transactions, loading }) => {
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [dateFilter, setDateFilter] = useState<string>('all');

  const getTransactionIcon = (type: string, amount: number) => {
    if (amount > 0) {
      return <ArrowUpCircle className="w-5 h-5 text-green-400" />;
    } else if (type === 'refund') {
      return <RefreshCw className="w-5 h-5 text-blue-400" />;
    } else if (type === 'manual_adjustment') {
      return <Settings className="w-5 h-5 text-purple-400" />;
    }
    return <ArrowDownCircle className="w-5 h-5 text-red-400" />;
  };

  const getTransactionLabel = (type: string) => {
    switch (type) {
      case 'credit':
        return 'Carga';
      case 'debit':
        return 'Consumo';
      case 'refund':
        return 'Reembolso';
      case 'manual_adjustment':
        return 'Ajuste';
      default:
        return type;
    }
  };

  const filteredTransactions = transactions.filter((tx) => {
    // Type filter
    if (typeFilter !== 'all') {
      if (typeFilter === 'credits' && tx.amount <= 0) return false;
      if (typeFilter === 'debits' && tx.amount >= 0) return false;
    }

    // Date filter
    if (dateFilter !== 'all') {
      const txDate = new Date(tx.created_at);
      if (dateFilter === 'week' && !isThisWeek(txDate, { weekStartsOn: 1 })) return false;
      if (dateFilter === 'month' && !isThisMonth(txDate)) return false;
    }

    return true;
  });

  if (loading) {
    return (
      <EliteCard className="p-6">
        <div className="flex items-center justify-center py-12">
          <div className="w-8 h-8 border-2 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
        </div>
      </EliteCard>
    );
  }

  return (
    <EliteCard className="p-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <h3 className="font-orbitron font-semibold text-lg">Historial de Movimientos</h3>
        <div className="flex gap-2">
          <Select value={typeFilter} onValueChange={setTypeFilter}>
            <SelectTrigger className="w-[130px] bg-muted/50 border-neon-cyan/30">
              <SelectValue placeholder="Tipo" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Todos</SelectItem>
              <SelectItem value="credits">Cargas</SelectItem>
              <SelectItem value="debits">Consumos</SelectItem>
            </SelectContent>
          </Select>
          <Select value={dateFilter} onValueChange={setDateFilter}>
            <SelectTrigger className="w-[130px] bg-muted/50 border-neon-cyan/30">
              <SelectValue placeholder="Fecha" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Todos</SelectItem>
              <SelectItem value="week">Esta semana</SelectItem>
              <SelectItem value="month">Este mes</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <ScrollArea className="h-[400px]">
        {filteredTransactions.length === 0 ? (
          <div className="text-center py-12">
            <Package className="w-12 h-12 text-muted-foreground/30 mx-auto mb-3" />
            <p className="text-muted-foreground text-sm">No hay movimientos</p>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredTransactions.map((tx) => (
              <div
                key={tx.id}
                className="flex items-center gap-4 p-4 rounded-lg bg-muted/30 border border-neon-cyan/10 hover:border-neon-cyan/20 transition-colors"
              >
                <div className="flex-shrink-0">
                  {getTransactionIcon(tx.transaction_type, tx.amount)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-rajdhani font-medium truncate">
                    {tx.description || getTransactionLabel(tx.transaction_type)}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {format(new Date(tx.created_at), "dd MMM yyyy, HH:mm", { locale: es })}
                  </p>
                </div>
                <div className="flex-shrink-0 text-right">
                  <span
                    className={cn(
                      'font-orbitron font-bold text-lg',
                      tx.amount > 0 ? 'text-green-400' : 'text-red-400'
                    )}
                  >
                    {tx.amount > 0 ? '+' : ''}{tx.amount}
                  </span>
                  <p className="text-xs text-muted-foreground">créditos</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </ScrollArea>
    </EliteCard>
  );
};

export default CreditHistoryList;
