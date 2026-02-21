import 'package:go_router/go_router.dart';
import 'package:myapp/auth/auth_gate_redirect.dart';
import 'package:myapp/auth/app_auth_state.dart';
import 'package:myapp/screens/auth_screen.dart';
import 'package:myapp/screens/admin_dashboard_screen.dart';
import 'package:myapp/screens/admin_notifications_screen.dart';
import 'package:myapp/screens/admin_player_approval_screen.dart';
import 'package:myapp/screens/admin_players_screen.dart';
import 'package:myapp/screens/admin_reservations_screen.dart';
import 'package:myapp/screens/admin_settings_screen.dart';
import 'package:myapp/screens/admin_users_screen.dart';
import 'package:myapp/screens/chat_list_screen.dart';
import 'package:myapp/screens/compare_players_screen.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/my_credits_screen.dart';
import 'package:myapp/screens/my_players_screen.dart';
import 'package:myapp/screens/notifications_screen.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/screens/reservations_list_screen.dart';
import 'package:myapp/screens/scouting_screen.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/screens/not_found_screen.dart';
import 'package:myapp/screens/reset_password_screen.dart';
import 'package:myapp/screens/waiting_approval_screen.dart';
import 'package:myapp/widgets/screen_layout_wrapper.dart';

/// Crea el [GoRouter] con todas las rutas (paridad con React App.tsx).
GoRouter createAppRouter(AppAuthState appAuthState) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: appAuthState,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const AuthGateRedirect(),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/waiting-approval',
        builder: (_, __) => const WaitingApprovalScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, _) {
          final auth = appAuthState;
          if (auth.userId == null) {
            return const AuthGateRedirect();
          }
          return ScreenLayoutWrapper(
            child: HomeScreen(
              userRole: auth.userRole ?? 'coach',
              userName: auth.userName ?? 'Usuario',
            ),
          );
        },
      ),
      GoRoute(
        path: '/players',
        builder: (_, __) => ScreenLayoutWrapper(child: const MyPlayersScreen()),
      ),
      GoRoute(
        path: '/reservations',
        builder: (_, __) => ScreenLayoutWrapper(child: const ReservationsListScreen()),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, _) => ScreenLayoutWrapper(
          child: ChatListScreen(
            userRole: appAuthState.userRole ?? 'coach',
            userName: appAuthState.userName ?? 'Usuario',
          ),
        ),
      ),
      GoRoute(
        path: '/my-credits',
        builder: (_, __) => ScreenLayoutWrapper(child: const MyCreditsScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => ScreenLayoutWrapper(child: const ProfileScreen()),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => ScreenLayoutWrapper(child: const NotificationsScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => ScreenLayoutWrapper(child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/scouting',
        builder: (_, __) => ScreenLayoutWrapper(child: const ScoutingScreen()),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => ScreenLayoutWrapper(child: const AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => ScreenLayoutWrapper(
          child: AdminUsersScreen(initialTab: state.uri.queryParameters['tab']),
        ),
      ),
      GoRoute(
        path: '/admin/reservations',
        builder: (_, __) => ScreenLayoutWrapper(child: const AdminReservationsScreen()),
      ),
      GoRoute(
        path: '/admin/chat',
        builder: (context, _) => ScreenLayoutWrapper(
          child: ChatListScreen(
            userRole: appAuthState.userRole ?? 'admin',
            userName: appAuthState.userName ?? 'Admin',
          ),
        ),
      ),
      GoRoute(
        path: '/admin/notifications',
        builder: (_, __) => ScreenLayoutWrapper(child: const AdminNotificationsScreen()),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (_, __) => ScreenLayoutWrapper(child: const AdminSettingsScreen()),
      ),
      GoRoute(
        path: '/admin/player-approval',
        builder: (_, __) => ScreenLayoutWrapper(child: const AdminPlayerApprovalScreen()),
      ),
      GoRoute(
        path: '/admin/players',
        builder: (_, __) => ScreenLayoutWrapper(child: const AdminPlayersScreen()),
      ),
      GoRoute(
        path: '/admin/compare-players',
        builder: (_, __) => ScreenLayoutWrapper(child: const ComparePlayersScreen()),
      ),
      GoRoute(
        path: '/:path*',
        builder: (_, __) => const NotFoundScreen(),
      ),
    ],
  );
}
