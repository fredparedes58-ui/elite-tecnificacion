import React, { useState, useMemo } from 'react';
import { EliteCard } from '@/components/ui/EliteCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { Input } from '@/components/ui/input';
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
import { supabase } from '@/integrations/supabase/client';
import { useQuery } from '@tanstack/react-query';
import { Search, User, Mail, Phone, CreditCard, AlertCircle, CheckCircle, TrendingDown } from 'lucide-react';
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

const PlayerCreditsView: React.FC = () => {
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [creditFilter, setCreditFilter] = useState<string>('all');

  const { data: players = [], isLoading } = useQuery({
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

      // Fetch parent info and credits
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

  const filteredPlayers = useMemo(() => {
    return players.filter(player => {
      const matchesSearch = !search || 
        player.name.toLowerCase().includes(search.toLowerCase()) ||
        player.parent?.full_name?.toLowerCase().includes(search.toLowerCase()) ||
        player.parent?.email.toLowerCase().includes(search.toLowerCase());
      
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

  const getCreditsBadge = (credits: number) => {
    if (credits === 0) {
      return <Badge variant="destructive" className="bg-red-500/20 text-red-400 border-red-500/30">0 créditos</Badge>;
    } else if (credits <= 5) {
      return <Badge variant="outline" className="bg-yellow-500/20 text-yellow-400 border-yellow-500/30">{credits} créditos</Badge>;
    }
    return <Badge variant="outline" className="bg-green-500/20 text-green-400 border-green-500/30">{credits} créditos</Badge>;
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
              placeholder="Buscar por nombre de jugador o padre..."
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
                <TableHead className="font-orbitron">Club</TableHead>
                <TableHead className="font-orbitron">Padre/Tutor</TableHead>
                <TableHead className="font-orbitron">Contacto</TableHead>
                <TableHead className="font-orbitron text-center">Créditos</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredPlayers.map((player) => (
                <TableRow key={player.id} className="border-neon-cyan/10 hover:bg-muted/30">
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-full bg-neon-cyan/20 flex items-center justify-center">
                        <User className="w-4 h-4 text-neon-cyan" />
                      </div>
                      <div>
                        <span className="font-rajdhani font-medium">{player.name}</span>
                        {player.position && (
                          <p className="text-xs text-muted-foreground">{player.position}</p>
                        )}
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <span className="text-sm">{calculateAge(player.birth_date)} años</span>
                  </TableCell>
                  <TableCell>
                    <StatusBadge variant="info">{player.category}</StatusBadge>
                  </TableCell>
                  <TableCell>
                    <span className="text-sm text-neon-purple">{player.current_club || '-'}</span>
                  </TableCell>
                  <TableCell>
                    <span className="font-rajdhani">
                      {player.parent?.full_name || 'Sin asignar'}
                    </span>
                  </TableCell>
                  <TableCell>
                    {player.parent ? (
                      <div className="space-y-1">
                        <div className="flex items-center gap-1 text-xs text-muted-foreground">
                          <Mail className="w-3 h-3" />
                          <span className="truncate max-w-32">{player.parent.email}</span>
                        </div>
                        {player.parent.phone && (
                          <div className="flex items-center gap-1 text-xs text-neon-cyan">
                            <Phone className="w-3 h-3" />
                            <span>{player.parent.phone}</span>
                          </div>
                        )}
                      </div>
                    ) : (
                      <span className="text-muted-foreground">-</span>
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    {getCreditsBadge(player.credits)}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </EliteCard>
    </div>
  );
};

export default PlayerCreditsView;
