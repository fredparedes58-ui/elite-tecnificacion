import React from 'react';
import { cn } from '@/lib/utils';

interface EliteCardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'glow' | 'hexagon';
  hover?: boolean;
  children: React.ReactNode;
}

const EliteCard = React.forwardRef<HTMLDivElement, EliteCardProps>(
  ({ className, variant = 'default', hover = true, children, ...props }, ref) => {
    const baseStyles = 'relative bg-card rounded-lg overflow-hidden transition-all duration-300';
    
    const variants = {
      default: cn(
        'border border-neon-cyan/30',
        'shadow-[0_0_15px_hsl(var(--neon-cyan)/0.1),inset_0_0_30px_hsl(var(--neon-cyan)/0.05)]'
      ),
      glow: cn(
        'border border-neon-purple/40',
        'shadow-[0_0_20px_hsl(var(--neon-purple)/0.2),0_0_40px_hsl(var(--neon-cyan)/0.1)]'
      ),
      hexagon: cn(
        'border border-neon-cyan/30',
        '[clip-path:polygon(5%_0%,95%_0%,100%_50%,95%_100%,5%_100%,0%_50%)]'
      ),
    };

    const hoverStyles = hover ? cn(
      'hover:border-neon-cyan/60',
      'hover:shadow-[0_0_25px_hsl(var(--neon-cyan)/0.2),0_0_50px_hsl(var(--neon-purple)/0.1),inset_0_0_30px_hsl(var(--neon-cyan)/0.08)]'
    ) : '';

    return (
      <div
        ref={ref}
        className={cn(baseStyles, variants[variant], hoverStyles, className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

EliteCard.displayName = 'EliteCard';

export { EliteCard };
