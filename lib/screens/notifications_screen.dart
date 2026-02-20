import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/screens/notice_detail_screen.dart';
import 'package:myapp/models/notice_board_post_model.dart';
import 'package:myapp/widgets/empty_state_widget.dart';
import 'package:myapp/widgets/loading_widget.dart';
import 'package:myapp/widgets/error_state_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Usuario no autenticado';
        });
        return;
      }

      // Obtener team_id del usuario
      final teamMember = await Supabase.instance.client
          .from('team_members')
          .select('team_id, role')
          .eq('user_id', user.id)
          .maybeSingle();

      if (teamMember == null) {
        setState(() {
          _isLoading = false;
          _notifications = [];
        });
        return;
      }

      final teamId = teamMember['team_id'];
      final userRole = teamMember['role'];

      // Cargar notificaciones desde notices (avisos del tablón)
      final noticesResponse = await Supabase.instance.client
          .from('notices')
          .select('*, created_by_user:profiles!created_by(full_name)')
          .eq('team_id', teamId)
          .order('created_at', ascending: false)
          .limit(50);

      final notices = List<Map<String, dynamic>>.from(noticesResponse);

      // Filtrar por rol del usuario
      final filteredNotices = notices.where((notice) {
        final targetRoles = List<String>.from(notice['target_roles'] ?? []);
        return targetRoles.isEmpty || 
               targetRoles.contains(userRole) || 
               targetRoles.contains('all');
      }).toList();

      // Convertir a formato de notificaciones
      final notifications = filteredNotices.map((notice) {
        String? authorName;
        if (notice['created_by_user'] != null) {
          final createdByUser = notice['created_by_user'];
          if (createdByUser is Map<String, dynamic>) {
            authorName = createdByUser['full_name'] as String?;
          }
        }

        return {
          'id': notice['id'],
          'type': notice['priority'] == 'urgent' ? 'urgent' : 'info',
          'title': notice['title'],
          'content': notice['content'],
          'author': authorName ?? 'Sistema',
          'created_at': notice['created_at'],
          'is_read': false, // TODO: Implementar lectura
          'notice_data': notice, // Para navegación
        };
      }).toList();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar notificaciones';
        _notifications = [];
      });
    }
  }

  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'Ahora';
      }
    } catch (e) {
      return 'Fecha desconocida';
    }
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    final noticeData = notification['notice_data'] as Map<String, dynamic>?;
    if (noticeData != null) {
      // Convertir a NoticeBoardPost para navegación
      String? authorName;
      if (noticeData['created_by_user'] != null) {
        final createdByUser = noticeData['created_by_user'];
        if (createdByUser is Map<String, dynamic>) {
          authorName = createdByUser['full_name'] as String?;
        }
      }

      final notice = NoticeBoardPost(
        id: noticeData['id'],
        teamId: noticeData['team_id'],
        authorId: noticeData['created_by'] ?? '',
        authorName: authorName,
        title: noticeData['title'],
        content: noticeData['content'],
        attachmentUrl: noticeData['attachment_url'],
        priority: noticeData['priority'] == 'urgent' 
            ? NoticePriority.urgent 
            : NoticePriority.normal,
        createdAt: DateTime.parse(noticeData['created_at']),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoticeDetailScreen(notice: notice),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Cargando notificaciones...')
          : _errorMessage != null
              ? ErrorStateWidget(
                  title: _errorMessage!,
                  actionLabel: 'Reintentar',
                  onAction: _loadNotifications,
                )
              : _notifications.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.notifications_none,
                      title: 'No hay notificaciones',
                      subtitle: 'Las notificaciones importantes aparecerán aquí',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final isUrgent = notification['type'] == 'urgent';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: isUrgent
                                ? theme.colorScheme.errorContainer.withOpacity(0.3)
                                : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isUrgent
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                                child: Icon(
                                  isUrgent ? Icons.warning : Icons.info,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                notification['title'] ?? 'Sin título',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.bold,
                                  color: isUrgent
                                      ? theme.colorScheme.error
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['content'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${notification['author']} • ${_formatTimeAgo(notification['created_at'])}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () => _onNotificationTap(notification),
                              ),
                              onTap: () => _onNotificationTap(notification),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
