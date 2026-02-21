// ============================================================
// Notificaciones (avisos del tablón). Usa NotificationsRepository.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/notice_board_post_model.dart';
import 'package:myapp/repositories/notifications_repository.dart';
import 'package:myapp/screens/notice_detail_screen.dart';
import 'package:myapp/widgets/empty_state_widget.dart';
import 'package:myapp/widgets/loading_widget.dart';
import 'package:myapp/widgets/error_state_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<NotificationsRepository>();
      repo.fetch();
      repo.subscribeRealtime();
    });
  }

  @override
  void dispose() {
    context.read<NotificationsRepository>().unsubscribeRealtime();
    super.dispose();
  }

  static NoticeBoardPost? _noticeFromRaw(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    String? authorName;
    if (raw['created_by_user'] != null && raw['created_by_user'] is Map) {
      authorName = (raw['created_by_user'] as Map)['full_name']?.toString();
    }
    return NoticeBoardPost(
      id: raw['id']?.toString() ?? '',
      teamId: raw['team_id']?.toString(),
      authorId: raw['created_by']?.toString() ?? '',
      authorName: authorName ?? 'Sistema',
      title: raw['title']?.toString() ?? '',
      content: raw['content']?.toString() ?? '',
      attachmentUrl: raw['attachment_url']?.toString(),
      priority: raw['priority'] == 'urgent' ? NoticePriority.urgent : NoticePriority.normal,
      createdAt: DateTime.tryParse(raw['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: raw['updated_at'] != null ? DateTime.tryParse(raw['updated_at'].toString()) : null,
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} min';
    } else {
      return 'Ahora';
    }
  }

  void _onTap(NotificationItem item) {
    final notice = _noticeFromRaw(item.rawNotice);
    if (notice == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoticeDetailScreen(notice: notice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<NotificationsRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => repo.fetch(forceRefresh: true),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: repo.loading && repo.items.isEmpty
          ? const LoadingWidget(message: 'Cargando notificaciones...')
          : repo.error != null
              ? ErrorStateWidget(
                  title: repo.error!,
                  actionLabel: 'Reintentar',
                  onAction: () => repo.fetch(forceRefresh: true),
                )
              : repo.items.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.notifications_none,
                      title: 'No hay notificaciones',
                      subtitle: 'Las notificaciones importantes aparecerán aquí',
                    )
                  : RefreshIndicator(
                      onRefresh: () => repo.fetch(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: repo.items.length,
                        itemBuilder: (context, index) {
                          final item = repo.items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: item.isUrgent
                                ? theme.colorScheme.errorContainer.withOpacity(0.3)
                                : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: item.isUrgent
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                                child: Icon(
                                  item.isUrgent ? Icons.warning : Icons.info,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.bold,
                                  color: item.isUrgent ? theme.colorScheme.error : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    item.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.author} • ${_formatTimeAgo(item.createdAt)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _onTap(item),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
