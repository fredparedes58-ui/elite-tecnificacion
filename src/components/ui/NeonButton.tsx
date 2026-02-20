import React from 'react';
import { cn } from '@/lib/utils';

interface NeonButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'cyan' | 'purple' | 'pink' | 'gradient' | 'outline';
  size?: 'sm' | 'md' | 'lg';
  glow?: boolean;
  children: React.ReactNode;
}

const NeonButton = React.forwardRef<HTMLButtonElement, NeonButtonProps>(
  ({ className, variant = 'cyan', size = 'md', glow = true, children, disabled, ...props }, ref) => {
    const variants = {
      cyan: 'border-neon-cyan text-neon-cyan hover:bg-neon-cyan hover:text-background',
      purple: 'border-neon-purple text-neon-purple hover:bg-neon-purple hover:text-background',
      pink: 'border-neon-pink text-neon-pink hover:bg-neon-pink hover:text-background',
      gradient: 'border-transparent bg-gradient-to-r from-neon-cyan to-neon-purple text-background hover:opacity-90',
      outline: 'border-muted-foreground/50 text-muted-foreground hover:border-foreground hover:text-foreground',
    };

    const sizes = {
      sm: 'px-4 py-2 text-sm',
      md: 'px-6 py-3 text-base',
      lg: 'px-8 py-4 text-lg',
    };

    const glowStyles: Record<string, string> = glow ? {
      cyan: 'hover:shadow-[0_0_20px_hsl(var(--neon-cyan)/0.5),0_0_40px_hsl(var(--neon-cyan)/0.3)]',
      purple: 'hover:shadow-[0_0_20px_hsl(var(--neon-purple)/0.5),0_0_40px_hsl(var(--neon-purple)/0.3)]',
      pink: 'hover:shadow-[0_0_20px_hsl(var(--neon-pink)/0.5),0_0_40px_hsl(var(--neon-pink)/0.3)]',
      gradient: 'hover:shadow-[0_0_20px_hsl(var(--neon-cyan)/0.4),0_0_40px_hsl(var(--neon-purple)/0.3)]',
      outline: '',
    } : {};

    return (
      <button
        ref={ref}
        disabled={disabled}
        className={cn(
          'relative overflow-hidden font-orbitron font-semibold uppercase tracking-wider',
          'rounded-lg border-2 transition-all duration-300',
          'disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-transparent',
          variants[variant],
          sizes[size],
          glow && glowStyles[variant],
          className
        )}
        {...props}
      >
        {children}
      </button>
    );
  }
);

NeonButton.displayName = 'NeonButton';

export { NeonButton };
