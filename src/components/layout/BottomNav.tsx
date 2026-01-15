import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { 
  Home, 
  Calendar, 
  Users, 
  User,
  MessageSquare,
  Shield,
  Target,
  Bell
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface NavItem {
  href: string;
  label: string;
  icon: React.ElementType;
}

const BottomNav: React.FC = () => {
  const { user, isAdmin, isApproved } = useAuth();
  const location = useLocation();

  const navItems: NavItem[] = React.useMemo(() => {
    if (!user) return [];

    if (isAdmin) {
      return [
        { href: '/admin', label: 'Inicio', icon: Home },
        { href: '/admin/reservations', label: 'Calendario', icon: Calendar },
        { href: '/scouting', label: 'Scouting', icon: Target },
        { href: '/admin/chat', label: 'Chat', icon: MessageSquare },
        { href: '/admin/users', label: 'Usuarios', icon: Shield },
      ];
    }

    if (isApproved) {
      return [
        { href: '/dashboard', label: 'Inicio', icon: Home },
        { href: '/reservations', label: 'Calendario', icon: Calendar },
        { href: '/players', label: 'Mi Carta', icon: Users },
        { href: '/notifications', label: 'Alertas', icon: Bell },
        { href: '/chat', label: 'Chat', icon: MessageSquare },
      ];
    }

    return [];
  }, [user, isAdmin, isApproved]);

  if (!user || navItems.length === 0) return null;

  const isActive = (path: string) => {
    if (path === '/admin' || path === '/dashboard') {
      return location.pathname === path;
    }
    return location.pathname.startsWith(path);
  };

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 md:hidden">
      {/* Gradient border top */}
      <div className="h-px bg-gradient-to-r from-transparent via-neon-cyan/50 to-transparent" />
      
      {/* Navigation bar */}
      <div className="bg-background/95 backdrop-blur-xl border-t border-neon-cyan/10">
        <div className="flex items-center justify-around h-16 px-2">
          {navItems.map((item) => {
            const active = isActive(item.href);
            
            return (
              <Link
                key={item.href}
                to={item.href}
                className={cn(
                  'flex flex-col items-center justify-center gap-1 flex-1 py-2 relative transition-all duration-300',
                  active ? 'text-neon-cyan' : 'text-muted-foreground'
                )}
              >
                {/* Active indicator */}
                {active && (
                  <div className="absolute -top-0.5 left-1/2 -translate-x-1/2 w-8 h-1 rounded-full bg-neon-cyan shadow-[0_0_10px_rgba(0,240,255,0.5)]" />
                )}
                
                {/* Icon container */}
                <div
                  className={cn(
                    'p-1.5 rounded-lg transition-all duration-300',
                    active
                      ? 'bg-neon-cyan/10 shadow-[0_0_15px_rgba(0,240,255,0.2)]'
                      : 'hover:bg-muted/50'
                  )}
                >
                  <item.icon
                    className={cn(
                      'w-5 h-5 transition-all',
                      active && 'drop-shadow-[0_0_6px_rgba(0,240,255,0.8)]'
                    )}
                  />
                </div>

                {/* Label */}
                <span
                  className={cn(
                    'text-[10px] font-rajdhani font-medium transition-all',
                    active ? 'opacity-100' : 'opacity-70'
                  )}
                >
                  {item.label}
                </span>
              </Link>
            );
          })}
        </div>

        {/* Safe area for iOS */}
        <div className="h-safe-area-inset-bottom bg-background" />
      </div>
    </nav>
  );
};

export default BottomNav;
