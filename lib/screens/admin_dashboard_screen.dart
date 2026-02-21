// ============================================================
// Panel administrador (paridad con React Index AdminDashboardContent).
// Grid de accesos: Usuarios, Scouting, Reservas, Chat, Aprobación (badge), Créditos, Compare.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/pending_players_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<PendingPlayersRepository>();
      repo.fetchPending();
      repo.subscribeRealtime();
    });
  }

  @override
  void dispose() {
    context.read<PendingPlayersRepository>().unsubscribeRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = context.watch<PendingPlayersRepository>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PANEL ADMINISTRADOR',
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenido. Accesos rápidos al sistema.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AdminCard(
                title: 'Usuarios',
                subtitle: 'Aprobar y gestionar usuarios',
                icon: Icons.people,
                onTap: () => context.go('/admin/users'),
              ),
              _AdminCard(
                title: 'Scouting',
                subtitle: 'Ver todos los jugadores',
                icon: Icons.track_changes,
                onTap: () => context.go('/scouting'),
              ),
              _AdminCard(
                title: 'Jugadores',
                subtitle: 'Directorio y gestión',
                icon: Icons.person,
                onTap: () => context.go('/admin/players'),
              ),
              _AdminCard(
                title: 'Reservas',
                subtitle: 'Calendario y aprobaciones',
                icon: Icons.calendar_today,
                onTap: () => context.go('/admin/reservations'),
              ),
              _AdminCard(
                title: 'Chats',
                subtitle: 'Consola de mensajes',
                icon: Icons.chat,
                onTap: () => context.go('/admin/chat'),
              ),
              _AdminCard(
                title: 'Aprobación jugadores',
                subtitle: 'Jugadores pendientes',
                icon: Icons.person_add,
                onTap: () => context.go('/admin/player-approval'),
                badge: pending.pendingCount > 0 ? pending.pendingCount : null,
              ),
              _AdminCard(
                title: 'Créditos',
                subtitle: 'Cartera de jugadores',
                icon: Icons.account_balance_wallet,
                onTap: () => context.go('/admin/users?tab=credits'),
              ),
              _AdminCard(
                title: 'Comparar jugadores',
                subtitle: 'Comparativa estilo FIFA',
                icon: Icons.compare,
                onTap: () => context.go('/admin/compare-players'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge! > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 32, color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
