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
import { Search, User, Mail, Phone, Calendar, MapPin, Footprints } from 'lucide-react';
import { format, differenceInYears } from 'date-fns';

interface PlayerWithParent {
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
}

const PlayerDirectory: React.FC = () => {
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [positionFilter, setPositionFilter] = useState<string>('all');
  const [legFilter, setLegFilter] = useState<string>('all');

  const { data: players = [], isLoading } = useQuery({
    queryKey: ['players-with-parents'],
    queryFn: async () => {
      const { data, error } = await supabase
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

      // Fetch parent info separately
      const parentIds = [...new Set(data?.map(p => p.parent_id) || [])];
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, full_name, email, phone')
        .in('id', parentIds);

      const profileMap = new Map(profiles?.map(p => [p.id, p]) || []);

      return (data || []).map(player => ({
        ...player,
        parent: profileMap.get(player.parent_id) || null
      })) as PlayerWithParent[];
    }
  });

  const positions = useMemo(() => {
    const posSet = new Set(players.map(p => p.position).filter(Boolean));
    return Array.from(posSet).sort();
  }, [players]);

  const filteredPlayers = useMemo(() => {
    return players.filter(player => {
      const matchesSearch = !search || 
        player.name.toLowerCase().includes(search.toLowerCase()) ||
        player.parent?.full_name?.toLowerCase().includes(search.toLowerCase()) ||
        player.parent?.email.toLowerCase().includes(search.toLowerCase()) ||
        player.current_club?.toLowerCase().includes(search.toLowerCase());
      
      const matchesCategory = categoryFilter === 'all' || player.category === categoryFilter;
      const matchesPosition = positionFilter === 'all' || player.position === positionFilter;
      const matchesLeg = legFilter === 'all' || player.dominant_leg === legFilter;

      return matchesSearch && matchesCategory && matchesPosition && matchesLeg;
    });
  }, [players, search, categoryFilter, positionFilter, legFilter]);

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

  const getLevelVariant = (level: string): 'success' | 'warning' | 'info' | 'default' => {
    switch (level) {
      case 'elite': return 'success';
      case 'advanced': return 'info';
      case 'intermediate': return 'warning';
      default: return 'default';
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
            Directorio de Jugadores
          </h2>
          <p className="text-muted-foreground mt-1">
            {filteredPlayers.length} de {players.length} jugadores
          </p>
        </div>
      </div>

      {/* Filters */}
      <EliteCard className="p-4">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <div className="lg:col-span-2 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Buscar por nombre, padre, email o club..."
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

          <Select value={positionFilter} onValueChange={setPositionFilter}>
            <SelectTrigger className="bg-background border-neon-purple/30">
              <SelectValue placeholder="Posición" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Todas las posiciones</SelectItem>
              {positions.map(pos => (
                <SelectItem key={pos} value={pos!}>{pos}</SelectItem>
              ))}
            </SelectContent>
          </Select>

          <Select value={legFilter} onValueChange={setLegFilter}>
            <SelectTrigger className="bg-background border-neon-purple/30">
              <SelectValue placeholder="Pierna" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Ambas piernas</SelectItem>
              <SelectItem value="right">Derecha</SelectItem>
              <SelectItem value="left">Izquierda</SelectItem>
              <SelectItem value="both">Ambidiestro</SelectItem>
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
                <TableHead className="font-orbitron">Pierna</TableHead>
                <TableHead className="font-orbitron">Club Actual</TableHead>
                <TableHead className="font-orbitron">Nivel</TableHead>
                <TableHead className="font-orbitron">Padre/Tutor</TableHead>
                <TableHead className="font-orbitron">Contacto</TableHead>
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
                      <span className="font-rajdhani font-medium">{player.name}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1 text-muted-foreground">
                      <Calendar className="w-3 h-3" />
                      <span>{calculateAge(player.birth_date)} años</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <StatusBadge variant="info">{player.category}</StatusBadge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1">
                      <MapPin className="w-3 h-3 text-muted-foreground" />
                      <span className="text-sm">{player.position || '-'}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1">
                      <Footprints className="w-3 h-3 text-muted-foreground" />
                      <span className="text-sm">{getLegLabel(player.dominant_leg)}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <span className="text-sm text-neon-purple">{player.current_club || '-'}</span>
                  </TableCell>
                  <TableCell>
                    <StatusBadge variant={getLevelVariant(player.level)}>
                      {player.level}
                    </StatusBadge>
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
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </EliteCard>
    </div>
  );
};

export default PlayerDirectory;
