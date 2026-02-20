import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/screens/create_notice_screen.dart';
import 'package:myapp/screens/notice_detail_screen.dart';
import 'package:myapp/models/notice_board_post_model.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final _supabase = SupabaseService();
  List<NoticeBoardPost> _notices = [];
  bool _isLoading = true;
  String _filterPriority = 'all';
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get user's team and role
      final teamMember = await _supabase.client
          .from('team_members')
          .select('team_id, role')
          .eq('user_id', user.id)
          .single();

      final teamId = teamMember['team_id'];
      final userRole = teamMember['role'];

      // Fetch notices
      var query = _supabase.client
          .from('notices')
          .select('*, created_by_user:profiles!created_by(full_name)')
          .eq('team_id', teamId);

      if (_filterPriority != 'all') {
        query = query.eq('priority', _filterPriority);
      }

      final response = await query.order('created_at', ascending: false);

      final notices = List<Map<String, dynamic>>.from(response);

      // Filter by role
      final filteredNotices = notices.where((notice) {
        if (_filterRole == 'all') return true;
        final targetRoles = List<String>.from(notice['target_roles'] ?? []);
        return targetRoles.contains(_filterRole) ||
            targetRoles.contains(userRole);
      }).toList();

      // Convert to NoticeBoardPost objects
      final noticeObjects = filteredNotices.map((data) {
        // Extract author name from the created_by_user relation
        String? authorName;
        if (data['created_by_user'] != null) {
          final createdByUser = data['created_by_user'];
          if (createdByUser is Map<String, dynamic>) {
            authorName = createdByUser['full_name'] as String?;
          }
        }

        return NoticeBoardPost(
          id: data['id'],
          teamId: data['team_id'],
          authorId: data['created_by'] ?? '',
          authorName: authorName,
          title: data['title'],
          content: data['content'],
          attachmentUrl: null,
          priority: _mapPriority(data['priority']),
          createdAt: DateTime.parse(data['created_at']),
        );
      }).toList();

      setState(() {
        _notices = noticeObjects;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notices: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TABLÓN DE ANUNCIOS',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotices),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNotices,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notices.length,
                itemBuilder: (context, index) {
                  return _buildNoticeCard(_notices[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateNoticeScreen()),
          );
          if (result == true) {
            _loadNotices();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('NUEVO ANUNCIO'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.announcement_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay anuncios',
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Los anuncios del equipo aparecerán aquí',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  NoticePriority _mapPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'high':
        return NoticePriority.urgent;
      default:
        return NoticePriority.normal;
    }
  }

  Widget _buildNoticeCard(NoticeBoardPost notice) {
    final theme = Theme.of(context);
    final priority = notice.priorityString;
    final title = notice.title;
    final content = notice.content;
    final createdBy = notice.authorName ?? 'Equipo';
    final createdAt = notice.createdAt;

    Color priorityColor;
    IconData priorityIcon;

    switch (priority) {
      case 'urgent':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'high':
        priorityColor = Colors.orange;
        priorityIcon = Icons.warning_amber;
        break;
      case 'medium':
        priorityColor = Colors.blue;
        priorityIcon = Icons.info;
        break;
      default:
        priorityColor = Colors.green;
        priorityIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: priorityColor.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoticeDetailScreen(notice: notice),
            ),
          );
          if (result == true) {
            _loadNotices();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                priorityColor.withValues(alpha: 0.1),
                priorityColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(priorityIcon, color: priorityColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              createdBy,
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(createdAt),
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: priorityColor),
                ],
              ),
              const SizedBox(height: 16),
              // Content preview
              Text(
                content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filtrar Anuncios',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prioridad',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: _filterPriority == 'all',
                  onSelected: (selected) {
                    setState(() => _filterPriority = 'all');
                    Navigator.pop(context);
                    _loadNotices();
                  },
                ),
                FilterChip(
                  label: const Text('Urgente'),
                  selected: _filterPriority == 'urgent',
                  onSelected: (selected) {
                    setState(() => _filterPriority = 'urgent');
                    Navigator.pop(context);
                    _loadNotices();
                  },
                ),
                FilterChip(
                  label: const Text('Alta'),
                  selected: _filterPriority == 'high',
                  onSelected: (selected) {
                    setState(() => _filterPriority = 'high');
                    Navigator.pop(context);
                    _loadNotices();
                  },
                ),
                FilterChip(
                  label: const Text('Media'),
                  selected: _filterPriority == 'medium',
                  onSelected: (selected) {
                    setState(() => _filterPriority = 'medium');
                    Navigator.pop(context);
                    _loadNotices();
                  },
                ),
                FilterChip(
                  label: const Text('Baja'),
                  selected: _filterPriority == 'low',
                  onSelected: (selected) {
                    setState(() => _filterPriority = 'low');
                    Navigator.pop(context);
                    _loadNotices();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Rol', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _filterRole == 'all',
                  onSelected: (selected) {
                    setState(() => _filterRole = 'all');
                    Navigator.pop(context);
                    _loadNotices();
                  },
                ),
                FilterChip(
                  label: const Text('Entrenadores'),
                  selected: _filterRole == 'coach',
                  onSelected: (selected) {
                    setState(() => _filterRole = 'coach');
                    Navigator.pop(context);
                    _loadNotices();
                  },
                ),
                FilterChip(
                  label: const Text('Jugadores'),
                  selected: _filterRole == 'player',
                  onSelected: (selected) {
                    setState(() => _filterRole = 'player');
                    Navigator.pop(context);
                    _loadNotices();
                  },
                ),
                FilterChip(
                  label: const Text('Padres'),
                  selected: _filterRole == 'parent',
                  onSelected: (selected) {
                    setState(() => _filterRole = 'parent');
                    Navigator.pop(context);
                    _loadNotices();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }
}
