// ============================================================
// Admin: Centro de notificaciones. Tabs por tipo (usuarios, reservas, mensajes, sistema).
// Paridad con React AdminNotifications + useNotificationsCenter.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/in_app_notifications_repository.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InAppNotificationsRepository? _repo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = context.read<InAppNotificationsRepository>();
      _repo!.fetch();
      _repo!.subscribeRealtime();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _repo?.unsubscribeRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<InAppNotificationsRepository>();
    final all = repo.items;
    final userN = all.where((n) => n.type == 'new_user' || n.type == 'new_player_pending').toList();
    final resN = all.where((n) => n.type == 'new_reservation_request').toList();
    final msgN = all.where((n) => n.type == 'new_message').toList();
    final sysN = all.where((n) => n.type.contains('system') || n.type.contains('alert')).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Centro de Notificaciones',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Todas${repo.unreadCount > 0 ? ' (${repo.unreadCount})' : ''}'),
            Tab(text: 'Usuarios'),
            Tab(text: 'Reservas'),
            Tab(text: 'Mensajes'),
            Tab(text: 'Sistema'),
          ],
        ),
        actions: [
          if (repo.unreadCount > 0)
            TextButton.icon(
              onPressed: () async {
                await repo.markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Todas marcadas como leídas')),
                  );
                }
              },
              icon: const Icon(Icons.done_all, size: 20),
              label: const Text('Marcar leídas'),
            ),
          if (repo.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpiar todo'),
                    content: const Text('¿Eliminar todas las notificaciones?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                );
                if (ok == true) await repo.clearAll();
              },
            ),
        ],
      ),
      body: repo.loading && repo.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _NotificationList(items: all, repo: repo),
                _NotificationList(items: userN, repo: repo),
                _NotificationList(items: resN, repo: repo),
                _NotificationList(items: msgN, repo: repo),
                _NotificationList(items: sysN, repo: repo),
              ],
            ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.repo,
  });

  final List<InAppNotification> items;
  final InAppNotificationsRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No hay notificaciones',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final n = items[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: n.isRead ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
            child: Icon(
              _iconForType(n.type),
              color: n.isRead ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
            ),
          ),
          title: Text(
            n.title,
            style: TextStyle(
              fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: Text(
            n.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _timeAgo(n.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => repo.delete(n.id),
              ),
            ],
          ),
          onTap: () => repo.markAsRead(n.id),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    if (type.contains('user') || type.contains('player')) return Icons.person_add;
    if (type.contains('reservation')) return Icons.calendar_today;
    if (type.contains('message')) return Icons.message;
    return Icons.info_outline;
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return 'Hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes}m';
    return 'Ahora';
  }
}
