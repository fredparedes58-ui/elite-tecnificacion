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
import { motion, AnimatePresence } from 'framer-motion';

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
        { href: '/admin', label: 'Dashboard Admin', icon: Shield },
        { href: '/admin/users', label: 'Usuarios', icon: Users },
        { href: '/admin/chat', label: 'Chats', icon: MessageSquare },
        { href: '/scouting', label: 'Scouting', icon: Target },
      );
    } else if (isApproved) {
      links.push(
        { href: '/dashboard', label: 'Mi Panel', icon: LayoutDashboard },
        { href: '/players', label: 'Jugadores', icon: Users },
        { href: '/reservations', label: 'Reservas', icon: Calendar },
        { href: '/my-credits', label: 'Créditos', icon: Shield },
        { href: '/chat', label: 'Chat', icon: MessageSquare },
      );
    }
    
    return links;
  }, [user, isAdmin, isApproved]);

  const isActive = (path: string) => location.pathname === path;
  const isChatPath = (href: string) => href === '/admin/chat' || href === '/chat';

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-background/90 backdrop-blur-xl border-b border-neon-cyan/15 pt-safe-top md:pt-0">
      {/* Subtle glow line at top */}
      <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-neon-cyan/40 to-transparent" />
      
      <div className="container mx-auto px-3 md:px-6 max-w-full">
        <div className="flex items-center justify-between h-14 md:h-16">
          {/* Logo - with proper spacing */}
          <Link to="/" className="flex items-center gap-2 md:gap-3 group shrink-0 mr-6">
            <div className="relative">
              <div className="w-9 h-8 md:w-11 md:h-9 rounded-lg bg-gradient-to-br from-neon-cyan via-neon-purple to-neon-cyan flex items-center justify-center shadow-lg shadow-neon-cyan/20">
                <span className="font-orbitron font-black text-background text-xs md:text-sm">380</span>
              </div>
              <div className="absolute inset-0 rounded-lg bg-gradient-to-br from-neon-cyan to-neon-purple opacity-0 blur-lg group-hover:opacity-60 transition-opacity duration-500" />
            </div>
            <div className="flex flex-col">
              <span className="font-orbitron font-bold text-sm md:text-base leading-tight">
                <span className="text-neon-cyan">ELITE</span>{' '}
                <span className="text-neon-pink">380</span>
              </span>
              <span className="text-[8px] md:text-[9px] text-muted-foreground uppercase tracking-[0.25em] -mt-0.5 hidden sm:block font-medium">Academy</span>
            </div>
          </Link>

          {/* Desktop Navigation - compact pills */}
          <div className="hidden md:flex items-center gap-1 flex-1 justify-center">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                to={link.href}
                className={cn(
                  'flex items-center gap-1.5 px-3 py-1.5 rounded-full font-rajdhani font-semibold text-sm transition-all duration-300 relative whitespace-nowrap',
                  isActive(link.href)
                    ? 'bg-neon-cyan/15 text-neon-cyan border border-neon-cyan/40 shadow-sm shadow-neon-cyan/10'
                    : 'text-muted-foreground hover:text-foreground hover:bg-white/5'
                )}
              >
                <link.icon className="w-4 h-4" />
                <span>{link.label}</span>
                {isChatPath(link.href) && totalUnread > 0 && (
                  <span className="min-w-[16px] h-[16px] rounded-full bg-neon-pink text-white text-[9px] font-bold flex items-center justify-center px-1 animate-pulse shadow-lg shadow-neon-pink/30">
                    {totalUnread > 99 ? '99+' : totalUnread}
                  </span>
                )}
              </Link>
            ))}
          </div>

          {/* User Actions */}
          <div className="flex items-center gap-1.5 md:gap-2 shrink-0">
            {user && <NotificationBell />}
            
            {user ? (
              <>
                <div className="hidden md:flex items-center gap-3">
                  <Link
                    to="/profile"
                    className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-all duration-200 group"
                  >
                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center group-hover:border-neon-cyan/60 group-hover:shadow-sm group-hover:shadow-neon-cyan/20 transition-all">
                      <User className="w-4 h-4" />
                    </div>
                    <span className="font-rajdhani font-medium text-sm">{profile?.full_name || 'Perfil'}</span>
                  </Link>
                  <button
                    onClick={handleSignOut}
                    className="p-2 rounded-lg text-muted-foreground hover:text-neon-pink hover:bg-neon-pink/10 transition-all duration-200"
                    title="Cerrar sesión"
                  >
                    <LogOut className="w-4 h-4" />
                  </button>
                </div>
                <button
                  onClick={handleSignOut}
                  className="md:hidden p-2 rounded-lg text-muted-foreground hover:text-neon-pink hover:bg-neon-pink/10 transition-colors"
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
              className="md:hidden p-2 text-foreground hover:bg-white/5 rounded-lg transition-colors"
              aria-label="Menú"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* Mobile Navigation */}
        <AnimatePresence>
          {mobileMenuOpen && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="md:hidden overflow-hidden border-t border-neon-cyan/10"
            >
              <div className="flex flex-col gap-1 py-3 px-1">
                {navLinks.map((link) => (
                  <Link
                    key={link.href}
                    to={link.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className={cn(
                      'flex items-center gap-3 px-4 py-3 rounded-xl font-rajdhani font-semibold transition-all',
                      isActive(link.href)
                        ? 'bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/20'
                        : 'text-muted-foreground hover:bg-white/5 active:bg-white/10'
                    )}
                  >
                    <link.icon className="w-5 h-5" />
                    <span>{link.label}</span>
                    {isChatPath(link.href) && totalUnread > 0 && (
                      <span className="ml-auto min-w-[20px] h-[20px] rounded-full bg-neon-pink text-white text-xs font-bold flex items-center justify-center px-1">
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
                      className="flex items-center gap-3 px-4 py-3 rounded-xl text-muted-foreground hover:bg-white/5"
                    >
                      <User className="w-5 h-5" />
                      <span>Mi Perfil</span>
                    </Link>
                    <button
                      onClick={() => {
                        handleSignOut();
                        setMobileMenuOpen(false);
                      }}
                      className="flex items-center gap-3 px-4 py-3 rounded-xl text-neon-pink hover:bg-neon-pink/10"
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
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </nav>
  );
};

export default Navbar;
