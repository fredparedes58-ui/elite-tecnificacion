import React from 'react';
import { cn } from '@/lib/utils';

type BadgeVariant = 'default' | 'success' | 'warning' | 'error' | 'info';

interface StatusBadgeProps {
  variant?: BadgeVariant;
  className?: string;
  children: React.ReactNode;
}

const StatusBadge: React.FC<StatusBadgeProps> = ({ variant = 'default', className, children }) => {
  const getStyles = () => {
    switch (variant) {
      case 'success':
        return 'bg-green-500/20 text-green-400 border-green-500/50';
      case 'warning':
        return 'bg-yellow-500/20 text-yellow-400 border-yellow-500/50';
      case 'error':
        return 'bg-red-500/20 text-red-400 border-red-500/50';
      case 'info':
        return 'bg-neon-cyan/20 text-neon-cyan border-neon-cyan/50';
      default:
        return 'bg-neon-purple/20 text-neon-purple border-neon-purple/50';
    }
  };

  return (
    <span
      className={cn(
        'inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold font-rajdhani uppercase tracking-wider border',
        getStyles(),
        className
      )}
    >
      {children}
    </span>
  );
};

export { StatusBadge };
export type { StatusBadgeProps, BadgeVariant };
