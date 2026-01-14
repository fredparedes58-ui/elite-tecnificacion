import React from 'react';
import { Search } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { EliteCard } from '@/components/ui/EliteCard';

interface ScoutingFiltersProps {
  category: string;
  level: string;
  search: string;
  onCategoryChange: (value: string) => void;
  onLevelChange: (value: string) => void;
  onSearchChange: (value: string) => void;
}

const categories = [
  { value: 'all', label: 'Todas las categorías' },
  { value: 'U8', label: 'U8 (Sub-8)' },
  { value: 'U10', label: 'U10 (Sub-10)' },
  { value: 'U12', label: 'U12 (Sub-12)' },
  { value: 'U14', label: 'U14 (Sub-14)' },
  { value: 'U16', label: 'U16 (Sub-16)' },
  { value: 'U18', label: 'U18 (Sub-18)' },
];

const levels = [
  { value: 'all', label: 'Todos los niveles' },
  { value: 'beginner', label: 'Principiante' },
  { value: 'intermediate', label: 'Intermedio' },
  { value: 'advanced', label: 'Avanzado' },
  { value: 'elite', label: 'Élite' },
];

const ScoutingFilters: React.FC<ScoutingFiltersProps> = ({
  category,
  level,
  search,
  onCategoryChange,
  onLevelChange,
  onSearchChange,
}) => {
  return (
    <EliteCard className="p-4 mb-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Buscar jugador..."
            value={search}
            onChange={(e) => onSearchChange(e.target.value)}
            className="pl-10 bg-background border-border focus:border-neon-cyan/60 font-rajdhani"
          />
        </div>

        {/* Category Filter */}
        <Select value={category} onValueChange={onCategoryChange}>
          <SelectTrigger className="bg-background border-border focus:border-neon-cyan/60 font-rajdhani">
            <SelectValue placeholder="Categoría" />
          </SelectTrigger>
          <SelectContent className="bg-card border-border">
            {categories.map((cat) => (
              <SelectItem key={cat.value} value={cat.value} className="font-rajdhani focus:bg-neon-cyan/10 focus:text-neon-cyan">
                {cat.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        {/* Level Filter */}
        <Select value={level} onValueChange={onLevelChange}>
          <SelectTrigger className="bg-background border-border focus:border-neon-cyan/60 font-rajdhani">
            <SelectValue placeholder="Nivel" />
          </SelectTrigger>
          <SelectContent className="bg-card border-border">
            {levels.map((lvl) => (
              <SelectItem key={lvl.value} value={lvl.value} className="font-rajdhani focus:bg-neon-cyan/10 focus:text-neon-cyan">
                {lvl.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
    </EliteCard>
  );
};

export default ScoutingFilters;
