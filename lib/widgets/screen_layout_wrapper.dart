import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/auth/app_auth_state.dart';

/// Breakpoint para mostrar Sidebar (web/tablet) vs BottomNav (móvil).
const double kLayoutBreakpoint = 800;

/// Envuelve el contenido de las pantallas con navegación: Sidebar en web/pantalla ancha,
/// BottomNav en móvil. Paridad con React Layout (Navbar + BottomNav).
class ScreenLayoutWrapper extends StatelessWidget {
  const ScreenLayoutWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthState>();
    final width = MediaQuery.sizeOf(context).width;
    final useSidebar = kIsWeb || width >= kLayoutBreakpoint;
    final location = GoRouterState.of(context).matchedLocation;
    final items = _navItems(auth.isAdmin, auth.isCoach, auth.isParent);

    return Scaffold(
      body: useSidebar
          ? Row(
              children: [
                NavigationRail(
                  extended: width >= 900,
                  destinations: items
                      .map((e) => NavigationRailDestination(
                            icon: Icon(e.icon),
                            label: Text(e.label),
                          ))
                      .toList(),
                  selectedIndex: _selectedIndex(items, location),
                  onDestinationSelected: (i) => context.go(items[i].path),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: useSidebar ? null : _BottomNavBar(items: items, currentPath: location),
    );
  }

  /// Navegación por rol: admin, coach y padres tienen vistas propias.
  static List<_NavItem> _navItems(bool isAdmin, bool isCoach, bool isParent) {
    // 1) Vista Admin
    if (isAdmin) {
      return [
        _NavItem(path: '/admin', label: 'Inicio Admin', icon: Icons.shield),
        _NavItem(path: '/admin/reservations', label: 'Reservas', icon: Icons.calendar_today),
        _NavItem(path: '/admin/users', label: 'Usuarios', icon: Icons.people),
        _NavItem(path: '/scouting', label: 'Scouting', icon: Icons.track_changes),
        _NavItem(path: '/admin/chat', label: 'Chat', icon: Icons.chat),
        _NavItem(path: '/admin/player-approval', label: 'Aprobación', icon: Icons.person_add),
        _NavItem(path: '/admin/notifications', label: 'Notificaciones', icon: Icons.notifications),
        _NavItem(path: '/admin/settings', label: 'Configuración', icon: Icons.settings),
      ];
    }
    // 2) Vista Coach: incluye Scouting y Comparar (entrenador ve plantilla/scouting).
    if (isCoach) {
      return [
        _NavItem(path: '/dashboard', label: 'Inicio', icon: Icons.home),
        _NavItem(path: '/scouting', label: 'Scouting', icon: Icons.track_changes),
        _NavItem(path: '/admin/players', label: 'Plantilla', icon: Icons.people),
        _NavItem(path: '/admin/compare-players', label: 'Comparar', icon: Icons.compare_arrows),
        _NavItem(path: '/reservations', label: 'Reservas', icon: Icons.calendar_today),
        _NavItem(path: '/chat', label: 'Chat', icon: Icons.chat),
        _NavItem(path: '/notifications', label: 'Notificaciones', icon: Icons.notifications),
        _NavItem(path: '/profile', label: 'Perfil', icon: Icons.person),
        _NavItem(path: '/settings', label: 'Ajustes', icon: Icons.settings),
      ];
    }
    // 3) Vista Padres: mis jugadores, reservas, créditos, chat, etc. (sin Scouting ni Comparar).
    return [
      _NavItem(path: '/dashboard', label: 'Inicio', icon: Icons.home),
      _NavItem(path: '/players', label: 'Mis jugadores', icon: Icons.people),
      _NavItem(path: '/reservations', label: 'Reservas', icon: Icons.calendar_today),
      _NavItem(path: '/my-credits', label: 'Créditos', icon: Icons.account_balance_wallet),
      _NavItem(path: '/chat', label: 'Chat', icon: Icons.chat),
      _NavItem(path: '/notifications', label: 'Notificaciones', icon: Icons.notifications),
      _NavItem(path: '/profile', label: 'Perfil', icon: Icons.person),
      _NavItem(path: '/settings', label: 'Ajustes', icon: Icons.settings),
    ];
  }

  static int _selectedIndex(List<_NavItem> items, String location) {
    if (location == '/dashboard' || location == '/admin') {
      return 0;
    }
    for (var i = 0; i < items.length; i++) {
      if (location == items[i].path || (items[i].path != '/' && location.startsWith('${items[i].path}/'))) {
        return i;
      }
    }
    return 0;
  }
}

class _NavItem {
  const _NavItem({required this.path, required this.label, required this.icon});
  final String path;
  final String label;
  final IconData icon;
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.items, required this.currentPath});

  final List<_NavItem> items;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final selected = ScreenLayoutWrapper._selectedIndex(items, currentPath);
    return BottomNavigationBar(
      currentIndex: selected,
      onTap: (i) => context.go(items[i].path),
      type: BottomNavigationBarType.fixed,
      items: items
          .map((e) => BottomNavigationBarItem(
                icon: Icon(e.icon),
                label: e.label.length > 8 ? e.label.substring(0, 8) : e.label,
              ))
          .toList(),
    );
  }
}
