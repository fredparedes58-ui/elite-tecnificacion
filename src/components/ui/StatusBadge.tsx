import React from 'react';
import { cn } from '@/lib/utils';

type StatusType = 'pending' | 'approved' | 'rejected';
type LevelType = 'beginner' | 'intermediate' | 'advanced' | 'elite';
type CategoryType = 'U8' | 'U10' | 'U12' | 'U14' | 'U16' | 'U18';

interface StatusBadgeProps {
  type: 'status' | 'level' | 'category';
  value: StatusType | LevelType | CategoryType;
  className?: string;
}

const StatusBadge: React.FC<StatusBadgeProps> = ({ type, value, className }) => {
  const getStyles = () => {
    if (type === 'status') {
      switch (value) {
        case 'pending':
          return 'bg-yellow-500/20 text-yellow-400 border-yellow-500/50';
        case 'approved':
          return 'bg-green-500/20 text-green-400 border-green-500/50';
        case 'rejected':
          return 'bg-red-500/20 text-red-400 border-red-500/50';
        default:
          return 'bg-muted text-muted-foreground border-border';
      }
    }
    
    if (type === 'level') {
      switch (value) {
        case 'beginner':
          return 'bg-blue-500/20 text-blue-400 border-blue-500/50';
        case 'intermediate':
          return 'bg-green-500/20 text-green-400 border-green-500/50';
        case 'advanced':
          return 'bg-purple-500/20 text-purple-400 border-purple-500/50';
        case 'elite':
          return 'bg-gradient-to-r from-neon-cyan/20 to-neon-purple/20 text-neon-cyan border-neon-cyan/50';
        default:
          return 'bg-muted text-muted-foreground border-border';
      }
    }

    if (type === 'category') {
      return 'bg-neon-purple/20 text-neon-purple border-neon-purple/50';
    }

    return 'bg-muted text-muted-foreground border-border';
  };

  const getLabel = () => {
    if (type === 'status') {
      switch (value) {
        case 'pending': return 'Pendiente';
        case 'approved': return 'Aprobado';
        case 'rejected': return 'Rechazado';
        default: return value;
      }
    }
    
    if (type === 'level') {
      switch (value) {
        case 'beginner': return 'Principiante';
        case 'intermediate': return 'Intermedio';
        case 'advanced': return 'Avanzado';
        case 'elite': return 'Elite';
        default: return value;
      }
    }

    return value;
  };

  return (
    <span
      className={cn(
        'inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold font-rajdhani uppercase tracking-wider border',
        getStyles(),
        className
      )}
    >
      {getLabel()}
    </span>
  );
};

export { StatusBadge };
