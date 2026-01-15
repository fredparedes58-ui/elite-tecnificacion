import React, { useState, useMemo, useEffect } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Input } from '@/components/ui/input';
import { NeonButton } from '@/components/ui/NeonButton';
import CreditWalletManager from './CreditWalletManager';
import CreditTransactionHistory from './CreditTransactionHistory';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { supabase } from '@/integrations/supabase/client';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useToast } from '@/hooks/use-toast';
import { Search, User, Mail, Phone, CreditCard, AlertCircle, TrendingDown, Footprints, MapPin, Calendar, BellRing, Wallet, History, Send, Loader2 } from 'lucide-react';
import { differenceInYears } from 'date-fns';
import { Badge } from '@/components/ui/badge';

interface PlayerWithCreditsAndParent {
  id: string;
  name: string;
  birth_date: string | null;
  position: string | null;
  category: string;
  level: string;
  current_club: string | null;
  dominant_leg: string | null;
  parent: {
    id: string;
    full_name: string | null;
    email: string;
    phone: string | null;
  } | null;
  credits: number;
}

interface CreditTransaction {
  id: string;
  user_id: string;
  reservation_id: string | null;
  amount: number;
  transaction_type: 'debit' | 'credit' | 'refund' | 'manual_adjustment';
  description: string | null;
  created_at: string;
}

const PlayerCreditsView: React.FC = () => {
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [creditFilter, setCreditFilter] = useState<string>('all');
  const [notifiedIds, setNotifiedIds] = useState<Set<string>>(new Set());
  const [selectedPlayer, setSelectedPlayer] = useState<PlayerWithCreditsAndParent | null>(null);
  const [walletModalOpen, setWalletModalOpen] = useState(false);
  const [historyModalOpen, setHistoryModalOpen] = useState(false);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [sendingEmails, setSendingEmails] = useState(false);
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: players = [], isLoading, refetch } = useQuery({
    queryKey: ['players-credits-directory'],
    queryFn: async () => {
      const { data: playersData, error } = await supabase
        .from('players')
        .select(`
          id,
          name,
          birth_date,
          position,
          category,
          level,
          current_club,
          dominant_leg,
          parent_id
        `)
        .order('name');

      if (error) throw error;

      const parentIds = [...new Set(playersData?.map(p => p.parent_id) || [])];
      
      const [profilesRes, creditsRes] = await Promise.all([
        supabase.from('profiles').select('id, full_name, email, phone').in('id', parentIds),
        supabase.from('user_credits').select('user_id, balance').in('user_id', parentIds)
      ]);

      const profileMap = new Map(profilesRes.data?.map(p => [p.id, p]) || []);
      const creditsMap = new Map(creditsRes.data?.map(c => [c.user_id, c.balance]) || []);

      return (playersData || []).map(player => ({
        ...player,
        parent: profileMap.get(player.parent_id) || null,
        credits: creditsMap.get(player.parent_id) || 0
      })) as PlayerWithCreditsAndParent[];
    }
  });

  // Fetch transactions for selected user
  const { data: transactions = [], isLoading: loadingTransactions } = useQuery({
    queryKey: ['credit-transactions', selectedUserId],
    queryFn: async () => {
      if (!selectedUserId) return [];
      
      const { data, error } = await supabase
        .from('credit_transactions')
        .select('*')
        .eq('user_id', selectedUserId)
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) throw error;
      return data as CreditTransaction[];
    },
    enabled: !!selectedUserId,
  });

  useEffect(() => {
    if (players.length === 0) return;

    const playersNeedingAttention = players.filter(p => p.credits <= 5);
    const newNotifications: string[] = [];

    playersNeedingAttention.forEach(player => {
      if (!notifiedIds.has(player.id)) {
        newNotifications.push(player.id);
      }
    });

    if (newNotifications.length > 0) {
      const zeroCount = playersNeedingAttention.filter(p => p.credits === 0).length;
      const lowCount = playersNeedingAttention.filter(p => p.credits > 0 && p.credits <= 5).length;

      if (zeroCount > 0 || lowCount > 0) {
        toast({
          title: '🔔 Alerta de Créditos',
          description: `${zeroCount} jugadores sin créditos, ${lowCount} con créditos bajos`,
          variant: zeroCount > 0 ? 'destructive' : 'default',
        });
      }

      setNotifiedIds(prev => new Set([...prev, ...newNotifications]));
    }
  }, [players, notifiedIds, toast]);

  const filteredPlayers = useMemo(() => {
    return players.filter(player => {
      const matchesSearch = !search || 
        player.name.toLowerCase().includes(search.toLowerCase()) ||
        player.parent?.full_name?.toLowerCase().includes(search.toLowerCase()) ||
        player.parent?.email.toLowerCase().includes(search.toLowerCase()) ||
        player.position?.toLowerCase().includes(search.toLowerCase());
      
      const matchesCategory = categoryFilter === 'all' || player.category === categoryFilter;
      
      let matchesCredits = true;
      if (creditFilter === 'zero') {
        matchesCredits = player.credits === 0;
      } else if (creditFilter === 'low') {
        matchesCredits = player.credits > 0 && player.credits <= 5;
      } else if (creditFilter === 'normal') {
        matchesCredits = player.credits > 5;
      }

      return matchesSearch && matchesCategory && matchesCredits;
    });
  }, [players, search, categoryFilter, creditFilter]);

  const stats = useMemo(() => {
    const totalPlayers = players.length;
    const zeroCredits = players.filter(p => p.credits === 0).length;
    const lowCredits = players.filter(p => p.credits > 0 && p.credits <= 5).length;
    const totalCredits = players.reduce((sum, p) => sum + p.credits, 0);
    return { totalPlayers, zeroCredits, lowCredits, totalCredits };
  }, [players]);

  const calculateAge = (birthDate: string | null) => {
    if (!birthDate) return '-';
    return differenceInYears(new Date(), new Date(birthDate));
  };

  const getLegLabel = (leg: string | null) => {
    switch (leg) {
      case 'right': return 'Derecha';
      case 'left': return 'Izquierda';
      case 'both': return 'Ambidiestro';
      default: return '-';
    }
  };

  const getCreditsBadge = (credits: number) => {
    if (credits === 0) {
      return <Badge variant="destructive" className="bg-red-500/20 text-red-400 border-red-500/30">0 créditos</Badge>;
    } else if (credits <= 5) {
      return <Badge variant="outline" className="bg-yellow-500/20 text-yellow-400 border-yellow-500/30">{credits} créditos</Badge>;
    }
    return <Badge variant="outline" className="bg-green-500/20 text-green-400 border-green-500/30">{credits} créditos</Badge>;
  };

  const handleOpenWallet = (player: PlayerWithCreditsAndParent) => {
    setSelectedPlayer(player);
    setWalletModalOpen(true);
  };

  const handleOpenHistory = (userId: string) => {
    setSelectedUserId(userId);
    setHistoryModalOpen(true);
  };

  const handleBalanceUpdated = () => {
    refetch();
    queryClient.invalidateQueries({ queryKey: ['credit-transactions', selectedUserId] });
  };

  const handleNotifyLowCredits = () => {
    const lowCreditPlayers = players.filter(p => p.credits <= 5);
    
    lowCreditPlayers.forEach(player => {
      if (player.credits === 0) {
        toast({
          title: `⚠️ ${player.name} - SIN CRÉDITOS`,
          description: `Padre: ${player.parent?.full_name || 'N/A'} - Email: ${player.parent?.email || 'N/A'}`,
          variant: 'destructive',
        });
      } else {
        toast({
          title: `⚡ ${player.name} - Créditos bajos`,
          description: `Solo ${player.credits} créditos. Padre: ${player.parent?.full_name || 'N/A'}`,
        });
      }
    });
  };

  const handleSendEmailAlerts = async () => {
    const lowCreditPlayers = players.filter(p => p.credits <= 5 && p.parent);
    
    if (lowCreditPlayers.length === 0) {
      toast({
        title: 'Sin alertas',
        description: 'No hay jugadores con créditos bajos o agotados',
      });
      return;
    }

    setSendingEmails(true);
    let sentCount = 0;
    let errorCount = 0;

    for (const player of lowCreditPlayers) {
      if (!player.parent) continue;
      
      try {
        const alertType = player.credits === 0 ? 'exhausted' : 'low';
        const { error } = await supabase.functions.invoke('send-credit-alert-email', {
          body: {
            user_id: player.parent.id,
            player_name: player.name,
            credits_remaining: player.credits,
            alert_type: alertType,
          },
        });
        
        if (error) throw error;
        sentCount++;
      } catch (err) {
        console.error(`Error sending alert for ${player.name}:`, err);
        errorCount++;
      }
    }

    setSendingEmails(false);
    
    if (sentCount > 0) {
      toast({
        title: '📧 Emails enviados',
        description: `${sentCount} alertas enviadas${errorCount > 0 ? `, ${errorCount} fallaron` : ''}`,
      });
    } else {
      toast({
        title: 'Error',
        description: 'No se pudieron enviar los emails',
        variant: 'destructive',
      });
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-12 h-12 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
        <div>
          <h2 className="font-orbitron font-bold text-2xl gradient-text">
            Créditos de Jugadores
          </h2>
          <p className="text-muted-foreground mt-1">
            Control de créditos disponibles por jugador
          </p>
        </div>
        <div className="flex items-center gap-2">
          <NeonButton 
            variant="outline" 
            onClick={handleNotifyLowCredits}
            className="flex items-center gap-2"
          >
            <BellRing className="w-4 h-4" />
            Ver alertas
          </NeonButton>
          <NeonButton 
            variant="gradient" 
            onClick={handleSendEmailAlerts}
            disabled={sendingEmails}
            className="flex items-center gap-2"
          >
            {sendingEmails ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Send className="w-4 h-4" />
            )}
            Enviar emails de alerta
          </NeonButton>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-neon-cyan/20">
              <User className="w-5 h-5 text-neon-cyan" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Total Jugadores</p>
              <p className="font-orbitron text-2xl text-neon-cyan">{stats.totalPlayers}</p>
            </div>
          </div>
        </EliteCard>
        
        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-red-500/20">
              <AlertCircle className="w-5 h-5 text-red-400" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Sin Créditos</p>
              <p className="font-orbitron text-2xl text-red-400">{stats.zeroCredits}</p>
            </div>
          </div>
        </EliteCard>
        
        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-yellow-500/20">
              <TrendingDown className="w-5 h-5 text-yellow-400" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Créditos Bajos (≤5)</p>
              <p className="font-orbitron text-2xl text-yellow-400">{stats.lowCredits}</p>
            </div>
          </div>
        </EliteCard>
        
        <EliteCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-green-500/20">
              <CreditCard className="w-5 h-5 text-green-400" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Total Créditos</p>
              <p className="font-orbitron text-2xl text-green-400">{stats.totalCredits}</p>
            </div>
          </div>
        </EliteCard>
      </div>

      {/* Filters */}
      <EliteCard className="p-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="md:col-span-2 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Buscar por nombre, padre, email o posición..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-10 bg-background border-neon-cyan/30"
            />
          </div>
          
          <Select value={categoryFilter} onValueChange={setCategoryFilter}>
            <SelectTrigger className="bg-background border-neon-purple/30">
              <SelectValue placeholder="Categoría" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Todas las categorías</SelectItem>
              <SelectItem value="U8">U8</SelectItem>
              <SelectItem value="U10">U10</SelectItem>
              <SelectItem value="U12">U12</SelectItem>
              <SelectItem value="U14">U14</SelectItem>
              <SelectItem value="U16">U16</SelectItem>
              <SelectItem value="U18">U18</SelectItem>
            </SelectContent>
          </Select>

          <Select value={creditFilter} onValueChange={setCreditFilter}>
            <SelectTrigger className="bg-background border-neon-purple/30">
              <SelectValue placeholder="Créditos" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Todos los créditos</SelectItem>
              <SelectItem value="zero">Sin créditos (0)</SelectItem>
              <SelectItem value="low">Créditos bajos (1-5)</SelectItem>
              <SelectItem value="normal">Créditos normales (&gt;5)</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </EliteCard>

      {/* Players Table */}
      <EliteCard className="overflow-hidden">
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow className="border-neon-cyan/20">
                <TableHead className="font-orbitron">Jugador</TableHead>
                <TableHead className="font-orbitron">Edad</TableHead>
                <TableHead className="font-orbitron">Categoría</TableHead>
                <TableHead className="font-orbitron">Posición</TableHead>
                <TableHead className="font-orbitron">Padre/Tutor</TableHead>
                <TableHead className="font-orbitron text-center">Créditos</TableHead>
                <TableHead className="font-orbitron text-center">Acciones</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredPlayers.map((player) => (
                <TableRow 
                  key={player.id} 
                  className={`border-neon-cyan/10 hover:bg-muted/30 ${
                    player.credits === 0 ? 'bg-red-500/5' : player.credits <= 5 ? 'bg-yellow-500/5' : ''
                  }`}
                >
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                        player.credits === 0 ? 'bg-red-500/20' : player.credits <= 5 ? 'bg-yellow-500/20' : 'bg-neon-cyan/20'
                      }`}>
                        <User className={`w-4 h-4 ${
                          player.credits === 0 ? 'text-red-400' : player.credits <= 5 ? 'text-yellow-400' : 'text-neon-cyan'
                        }`} />
                      </div>
                      <span className="font-rajdhani font-medium">{player.name}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1 text-sm">
                      <Calendar className="w-3 h-3 text-muted-foreground" />
                      {calculateAge(player.birth_date)} años
                    </div>
                  </TableCell>
                  <TableCell>
                    <StatusBadge variant="info">{player.category}</StatusBadge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1 text-sm">
                      <MapPin className="w-3 h-3 text-muted-foreground" />
                      {player.position || '-'}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div>
                      <span className="font-rajdhani font-medium">
                        {player.parent?.full_name || 'Sin asignar'}
                      </span>
                      {player.parent?.email && (
                        <p className="text-xs text-muted-foreground truncate max-w-32">
                          {player.parent.email}
                        </p>
                      )}
                    </div>
                  </TableCell>
                  <TableCell className="text-center">
                    {getCreditsBadge(player.credits)}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center justify-center gap-2">
                      <NeonButton
                        variant="cyan"
                        size="sm"
                        onClick={() => handleOpenWallet(player)}
                      >
                        <Wallet className="w-3 h-3 mr-1" />
                        Cargar
                      </NeonButton>
                      <NeonButton
                        variant="outline"
                        size="sm"
                        onClick={() => player.parent && handleOpenHistory(player.parent.id)}
                        disabled={!player.parent}
                      >
                        <History className="w-3 h-3" />
                      </NeonButton>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </EliteCard>

      {/* Wallet Modal */}
      <Dialog open={walletModalOpen} onOpenChange={setWalletModalOpen}>
        <DialogContent className="bg-background border-neon-cyan/30 max-w-md">
          <DialogHeader>
            <DialogTitle className="font-orbitron gradient-text flex items-center gap-2">
              <Wallet className="w-5 h-5" />
              Gestión de Cartera
            </DialogTitle>
          </DialogHeader>
          {selectedPlayer && selectedPlayer.parent && (
            <CreditWalletManager
              userId={selectedPlayer.parent.id}
              userName={selectedPlayer.parent.full_name || selectedPlayer.name}
              currentBalance={selectedPlayer.credits}
              onBalanceUpdated={handleBalanceUpdated}
              onViewHistory={() => {
                setSelectedUserId(selectedPlayer.parent!.id);
                setWalletModalOpen(false);
                setHistoryModalOpen(true);
              }}
            />
          )}
        </DialogContent>
      </Dialog>

      {/* History Modal */}
      <Dialog open={historyModalOpen} onOpenChange={setHistoryModalOpen}>
        <DialogContent className="bg-background border-neon-cyan/30 max-w-lg">
          <DialogHeader>
            <DialogTitle className="font-orbitron gradient-text flex items-center gap-2">
              <History className="w-5 h-5" />
              Historial de Movimientos
            </DialogTitle>
          </DialogHeader>
          <CreditTransactionHistory
            transactions={transactions}
            loading={loadingTransactions}
          />
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default PlayerCreditsView;
