import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useUnreadCounts } from '@/hooks/useUnreadCounts';
import { NeonButton } from '@/components/ui/NeonButton';
import NotificationBell from '@/components/notifications/NotificationBell';
import { 
  User, 
  LogOut, 
  Menu, 
  X, 
  LayoutDashboard, 
  Users, 
  MessageSquare, 
  Calendar, 
  CalendarDays,
  Target,
  Shield,
  Bell,
  Settings,
  UserCheck,
} from 'lucide-react';
import { cn } from '@/lib/utils';

const Navbar: React.FC = () => {
  const { user, profile, isAdmin, isApproved, signOut } = useAuth();
  const { totalUnread } = useUnreadCounts();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false);

  const handleSignOut = async () => {
    await signOut();
    navigate('/');
  };

  const navLinks = React.useMemo(() => {
    if (!user) return [];
    
    const links = [];
    
    if (isAdmin) {
      links.push(
        { href: '/admin', label: 'Inicio Admin', icon: Shield },
        { href: '/admin/reservations', label: 'Reservas / Calendario', icon: CalendarDays },
        { href: '/admin/users', label: 'Usuarios', icon: Users },
        { href: '/admin/chat', label: 'Chats', icon: MessageSquare },
        { href: '/scouting', label: 'Scouting', icon: Target },
        { href: '/admin/player-approval', label: 'Aprobación jugadores', icon: UserCheck },
        { href: '/admin/notifications', label: 'Notificaciones', icon: Bell },
        { href: '/admin/settings', label: 'Configuración', icon: Settings },
      );
    } else if (isApproved) {
      links.push(
        { href: '/dashboard', label: 'Mi Panel', icon: LayoutDashboard },
        { href: '/players', label: 'Jugadores', icon: Users },
        { href: '/reservations', label: 'Reservas', icon: Calendar },
        { href: '/my-credits', label: 'Créditos', icon: Shield },
        { href: '/chat', label: 'Chat', icon: MessageSquare },
        { href: '/notifications', label: 'Notificaciones', icon: Bell },
        { href: '/settings', label: 'Ajustes', icon: Settings },
      );
    }
    
    return links;
  }, [user, isAdmin, isApproved]);

  const isActive = (path: string) => location.pathname === path;
  const isChatPath = (href: string) => href === '/admin/chat' || href === '/chat';

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-lg border-b border-neon-cyan/20 pt-safe-top md:pt-0">
      <div className="container mx-auto px-3 md:px-4 max-w-full">
        <div className="flex items-center justify-between h-14 md:h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-1.5 md:gap-2 group min-w-0">
            <div className="relative shrink-0">
              <div className="w-9 h-8 md:w-12 md:h-10 rounded-lg bg-gradient-to-br from-neon-cyan to-neon-purple flex items-center justify-center">
                <span className="font-orbitron font-bold text-background text-xs md:text-sm">380</span>
              </div>
              <div className="absolute inset-0 rounded-lg bg-gradient-to-br from-neon-cyan to-neon-purple opacity-50 blur-md group-hover:opacity-80 transition-opacity" />
            </div>
            <div className="flex flex-col min-w-0">
              <span className="font-orbitron font-bold text-sm md:text-lg gradient-text truncate">ELITE 380</span>
              <span className="text-[9px] md:text-[10px] text-muted-foreground uppercase tracking-widest -mt-1 hidden sm:block">Academy</span>
            </div>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-1">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                to={link.href}
                className={cn(
                  'flex items-center gap-2 px-4 py-2 rounded-lg font-rajdhani font-medium transition-all duration-200 relative',
                  isActive(link.href)
                    ? 'bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/30'
                    : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'
                )}
              >
                <link.icon className="w-4 h-4" />
                <span>{link.label}</span>
                {isChatPath(link.href) && totalUnread > 0 && (
                  <span className="min-w-[18px] h-[18px] rounded-full bg-destructive text-destructive-foreground text-[10px] font-bold flex items-center justify-center px-1 animate-pulse">
                    {totalUnread > 99 ? '99+' : totalUnread}
                  </span>
                )}
              </Link>
            ))}
          </div>

          {/* User Actions */}
          <div className="flex items-center gap-1 md:gap-2">
            {user && <NotificationBell />}
            
            {user ? (
              <>
                <div className="hidden md:flex items-center gap-4">
                  <Link
                    to="/profile"
                    className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
                  >
                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center">
                      <User className="w-4 h-4" />
                    </div>
                    <span className="font-rajdhani">{profile?.full_name || 'Perfil'}</span>
                  </Link>
                  <button
                    onClick={handleSignOut}
                    className="flex items-center gap-2 px-3 py-2 text-muted-foreground hover:text-destructive transition-colors"
                  >
                    <LogOut className="w-4 h-4" />
                  </button>
                </div>
                {/* Móvil: botón Cerrar sesión siempre visible */}
                <button
                  onClick={handleSignOut}
                  className="md:hidden p-2.5 rounded-lg text-muted-foreground hover:text-destructive hover:bg-destructive/10 transition-colors"
                  title="Cerrar sesión"
                  aria-label="Cerrar sesión"
                >
                  <LogOut className="w-5 h-5" />
                </button>
              </>
            ) : (
              <div className="hidden md:flex items-center gap-3">
                <Link to="/auth">
                  <NeonButton variant="cyan" size="sm">
                    Ingresar
                  </NeonButton>
                </Link>
              </div>
            )}

            {/* Mobile menu button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden p-2 text-foreground"
              aria-label="Menú"
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile Navigation - scrollable para acceder a todas las opciones */}
        {mobileMenuOpen && (
          <div className="md:hidden py-4 border-t border-neon-cyan/10 max-h-[70vh] overflow-y-auto">
            <div className="flex flex-col gap-2 px-1">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  to={link.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={cn(
                    'flex items-center gap-3 px-4 py-3 rounded-lg font-rajdhani font-medium transition-all',
                    isActive(link.href)
                      ? 'bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/30'
                      : 'text-muted-foreground hover:bg-muted/50'
                  )}
                >
                  <link.icon className="w-5 h-5" />
                  <span>{link.label}</span>
                  {isChatPath(link.href) && totalUnread > 0 && (
                    <span className="ml-auto min-w-[20px] h-[20px] rounded-full bg-destructive text-destructive-foreground text-xs font-bold flex items-center justify-center px-1">
                      {totalUnread > 99 ? '99+' : totalUnread}
                    </span>
                  )}
                </Link>
              ))}
              
              {user ? (
                <>
                  <Link
                    to="/profile"
                    onClick={() => setMobileMenuOpen(false)}
                    className="flex items-center gap-3 px-4 py-3 rounded-lg text-muted-foreground hover:bg-muted/50"
                  >
                    <User className="w-5 h-5" />
                    <span>Mi Perfil</span>
                  </Link>
                  <button
                    onClick={() => {
                      handleSignOut();
                      setMobileMenuOpen(false);
                    }}
                    className="flex items-center gap-3 px-4 py-3 rounded-lg text-destructive hover:bg-destructive/10"
                  >
                    <LogOut className="w-5 h-5" />
                    <span>Cerrar Sesión</span>
                  </button>
                </>
              ) : (
                <Link
                  to="/auth"
                  onClick={() => setMobileMenuOpen(false)}
                  className="mt-2"
                >
                  <NeonButton variant="cyan" size="md" className="w-full">
                    Ingresar
                  </NeonButton>
                </Link>
              )}
            </div>
          </div>
        )}
      </div>
    </nav>
  );
};

export default Navbar;
