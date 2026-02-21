// ============================================================
// PANTALLA: DETALLE DE COMUNICADO
// ============================================================
// Muestra el contenido completo del comunicado y permite descargar adjuntos
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/notice_board_post_model.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeDetailScreen extends StatefulWidget {
  final NoticeBoardPost notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic>? _readStats;
  List<Map<String, dynamic>> _unreadUsers = [];
  bool _loadingStats = false;
  bool _isCoach = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    if (_isCoach) {
      _loadStats();
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('team_members')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _isCoach = ['coach', 'admin'].contains(response['role']);
        });
        if (_isCoach) {
          _loadStats();
        }
      }
    } catch (e) {
      debugPrint('Error verificando rol: $e');
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _supabaseService.getNoticeReadStats(widget.notice.id);
      final unread = await _supabaseService.getUnreadUsers(widget.notice.id);
      if (mounted) {
        setState(() {
          _readStats = stats;
          _unreadUsers = unread;
          _loadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  Future<void> _downloadAttachment() async {
    final url = widget.notice.attachmentUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el archivo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUrgent = widget.notice.priority == NoticePriority.urgent;
    final hasAttachment = widget.notice.attachmentUrl != null &&
        widget.notice.attachmentUrl!.isNotEmpty;

    return Scaffold(
      appBar: buildAppBarWithBack(
        context,
        title: Text(
          'Comunicado',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y prioridad
            Row(
              children: [
                if (isUrgent) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.priority_high,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.notice.title,
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fecha
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(widget.notice.createdAt),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contenido
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.notice.content,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de descarga de adjunto
            if (hasAttachment)
              Card(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: InkWell(
                  onTap: _downloadAttachment,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_file,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Archivo Adjunto',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toca para descargar',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.download,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Estadísticas de lectura (solo para coaches)
            if (_isCoach) ...[
              const SizedBox(height: 32),
              _buildReadStatsSection(colorScheme),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildReadStatsSection(ColorScheme colorScheme) {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_readStats == null) return const SizedBox.shrink();

    final totalUsers = _readStats!['total_users'] as int? ?? 0;
    final readCount = _readStats!['read_count'] as int? ?? 0;
    final unreadCount = _readStats!['unread_count'] as int? ?? 0;
    final readPercentage = (_readStats!['read_percentage'] as num?)?.toDouble() ?? 0.0;

    return Card(
      color: colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas de Lectura',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Leído', readCount.toString(), Colors.green),
                _buildStatItem('Sin leer', unreadCount.toString(), Colors.red),
                _buildStatItem('Total', totalUsers.toString(), Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: readPercentage / 100,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  readPercentage >= 80 ? Colors.green : Colors.orange,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${readPercentage.toStringAsFixed(1)}% de lectura',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
            if (_unreadUsers.isNotEmpty) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _showUnreadUsersDialog(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ver quién NO ha leído ($unreadCount)',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  void _showUnreadUsersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Usuarios sin leer',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _unreadUsers.length,
            itemBuilder: (context, index) {
              final user = _unreadUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: Colors.red),
                ),
                title: Text(
                  user['full_name'] ?? 'Usuario',
                  style: GoogleFonts.roboto(),
                ),
                subtitle: Text(
                  user['email'] ?? '',
                  style: GoogleFonts.roboto(fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
