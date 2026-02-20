import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useUnreadCounts } from '@/hooks/useUnreadCounts';
import { 
  Home, 
  Calendar, 
  Users, 
  MessageSquare,
  Shield,
  Target,
  Coins,
  Settings
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface NavItem {
  href: string;
  label: string;
  labelShort: string; // para móvil, evita corte
  icon: React.ElementType;
}

const BottomNav: React.FC = () => {
  const { user, isAdmin, isApproved } = useAuth();
  const { totalUnread } = useUnreadCounts();
  const location = useLocation();

  const navItems: NavItem[] = React.useMemo(() => {
    if (!user) return [];

    if (isAdmin) {
      return [
        { href: '/admin', label: 'Inicio', labelShort: 'Inicio', icon: Home },
        { href: '/admin/reservations', label: 'Calendario', labelShort: 'Cal', icon: Calendar },
        { href: '/scouting', label: 'Scouting', labelShort: 'Scout', icon: Target },
        { href: '/admin/chat', label: 'Chat', labelShort: 'Chat', icon: MessageSquare },
        { href: '/admin/users', label: 'Usuarios', labelShort: 'Usu.', icon: Shield },
      ];
    }

    if (isApproved) {
      return [
        { href: '/dashboard', label: 'Inicio', labelShort: 'Inicio', icon: Home },
        { href: '/reservations', label: 'Reservas', labelShort: 'Reserv.', icon: Calendar },
        { href: '/players', label: 'Jugadores', labelShort: 'Jug.', icon: Users },
        { href: '/my-credits', label: 'Créditos', labelShort: 'Créd.', icon: Coins },
        { href: '/settings', label: 'Ajustes', labelShort: 'Ajust.', icon: Settings },
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

  const isChatPath = (href: string) => href === '/admin/chat' || href === '/chat';

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 md:hidden">
      <div className="h-px bg-gradient-to-r from-transparent via-neon-cyan/50 to-transparent" />
      
      <div className="bg-background/95 backdrop-blur-xl border-t border-neon-cyan/10 pb-safe-bottom">
        <div className="flex items-center justify-around h-14 px-1 min-w-0">
          {navItems.map((item) => {
            const active = isActive(item.href);
            const showBadge = isChatPath(item.href) && totalUnread > 0;
            
            return (
              <Link
                key={item.href}
                to={item.href}
                className={cn(
                  'flex flex-col items-center justify-center gap-0.5 flex-1 min-w-0 py-2 relative transition-all duration-300',
                  active ? 'text-neon-cyan' : 'text-muted-foreground'
                )}
              >
                {active && (
                  <div className="absolute -top-0.5 left-1/2 -translate-x-1/2 w-6 h-0.5 rounded-full bg-neon-cyan shadow-[0_0_10px_rgba(0,240,255,0.5)]" />
                )}
                
                <div
                  className={cn(
                    'p-1 rounded-lg transition-all duration-300 relative shrink-0',
                    active
                      ? 'bg-neon-cyan/10 shadow-[0_0_15px_rgba(0,240,255,0.2)]'
                      : 'hover:bg-muted/50'
                  )}
                >
                  <item.icon
                    className={cn(
                      'w-4 h-4 md:w-5 md:h-5 transition-all',
                      active && 'drop-shadow-[0_0_6px_rgba(0,240,255,0.8)]'
                    )}
                  />
                  {showBadge && (
                    <span className="absolute -top-1 -right-1 min-w-[14px] h-[14px] rounded-full bg-destructive text-destructive-foreground text-[9px] font-bold flex items-center justify-center px-0.5 shadow-lg animate-pulse">
                      {totalUnread > 99 ? '99+' : totalUnread}
                    </span>
                  )}
                </div>

                <span
                  className={cn(
                    'text-[9px] md:text-[10px] font-rajdhani font-medium transition-all truncate w-full text-center',
                    active ? 'opacity-100' : 'opacity-70'
                  )}
                  title={item.label}
                >
                  {item.labelShort}
                </span>
              </Link>
            );
          })}
        </div>

        <div className="h-safe-area-inset-bottom bg-background" />
      </div>
    </nav>
  );
};

export default BottomNav;
