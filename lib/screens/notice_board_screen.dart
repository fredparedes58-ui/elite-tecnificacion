// ============================================================
// PANTALLA: TABLÓN DE ANUNCIOS OFICIALES
// ============================================================
// Comunicados unidireccionales con confirmación de lectura
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/notice_board_post_model.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:myapp/screens/notice_detail_screen.dart';
import 'package:myapp/screens/create_notice_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  late TabController _tabController;
  List<NoticeBoardPost> _teamNotices = [];
  List<NoticeBoardPost> _clubNotices = [];
  bool _isLoading = true;
  bool _isCoach = false;
  String? _currentTeamId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
    _loadCurrentTeamId();
    _loadNotices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTeamId() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _currentTeamId = response['team_id'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error obteniendo teamId: $e');
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
      }
    } catch (e) {
      debugPrint('Error verificando rol: $e');
    }
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);
    try {
      final notices = await _supabaseService.getNotices(teamId: _currentTeamId);
      if (mounted) {
        setState(() {
          // Separar comunicados de equipo y de club
          _teamNotices = notices.where((n) => n.teamId != null).toList();
          _clubNotices = notices.where((n) => n.teamId == null).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando comunicados: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<NoticeBoardPost> get _currentNotices {
    if (_tabController.index == 0) {
      return _teamNotices;
    } else {
      return _clubNotices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TABLÓN DE ANUNCIOS',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: _isCoach
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateNoticeScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadNotices();
                    }
                  },
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // TabBar
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.3),
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: colorScheme.primary,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: GoogleFonts.roboto(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group, size: 18),
                            const SizedBox(width: 8),
                            Text('Equipo'),
                            if (_teamNotices.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_teamNotices.length}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business, size: 18),
                            const SizedBox(width: 8),
                            Text('Club'),
                            if (_clubNotices.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_clubNotices.length}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido de los tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab de Equipo
                      _currentNotices.isEmpty && !_isLoading
                          ? _buildEmptyState(
                              colorScheme,
                              'No hay comunicados de equipo',
                              'Los anuncios de tu equipo aparecerán aquí',
                              Icons.group_outlined,
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotices,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _teamNotices.length,
                                itemBuilder: (context, index) {
                                  return _buildNoticeCard(
                                    _teamNotices[index],
                                    colorScheme,
                                    isTeamNotice: true,
                                  );
                                },
                              ),
                            ),
                      // Tab de Club
                      _currentNotices.isEmpty && !_isLoading
                          ? _buildEmptyState(
                              colorScheme,
                              'No hay comunicados del club',
                              'Los anuncios del club aparecerán aquí',
                              Icons.business_outlined,
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotices,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _clubNotices.length,
                                itemBuilder: (context, index) {
                                  return _buildNoticeCard(
                                    _clubNotices[index],
                                    colorScheme,
                                    isTeamNotice: false,
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(
    ColorScheme colorScheme, [
    String title = 'No hay comunicados',
    String subtitle = 'Los anuncios oficiales aparecerán aquí',
    IconData icon = Icons.announcement_outlined,
  ]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(
    NoticeBoardPost notice,
    ColorScheme colorScheme, {
    bool isTeamNotice = true,
  }) {
    final isUrgent = notice.priority == NoticePriority.urgent;
    final hasAttachment =
        notice.attachmentUrl != null && notice.attachmentUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isUrgent
          ? Colors.red.withOpacity(0.1)
          : colorScheme.surface.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUrgent
              ? Colors.red.withOpacity(0.5)
              : colorScheme.primary.withOpacity(0.3),
          width: isUrgent ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          // Marcar como leído automáticamente
          await _supabaseService.markNoticeAsRead(notice.id);
          
          // Navegar al detalle
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoticeDetailScreen(notice: notice),
            ),
          );
          
          // Recargar para actualizar estadísticas
          _loadNotices();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con tipo, título y prioridad
              Row(
                children: [
                  // Badge de tipo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isTeamNotice
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isTeamNotice
                            ? Colors.blue.withOpacity(0.5)
                            : Colors.purple.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTeamNotice ? Icons.group : Icons.business,
                          size: 12,
                          color: isTeamNotice ? Colors.blue : Colors.purple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isTeamNotice ? 'EQUIPO' : 'CLUB',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isTeamNotice ? Colors.blue : Colors.purple,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isUrgent) ...[
                    Icon(
                      Icons.priority_high,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      notice.title,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Contenido preview
              Text(
                notice.content,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Footer con fecha y estadísticas
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(notice.createdAt),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  if (hasAttachment) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Adjunto',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Estadísticas de lectura (solo para coaches)
                  if (_isCoach && notice.readCount != null && notice.totalUsers != null)
                    _buildReadStats(notice.readCount!, notice.totalUsers!, colorScheme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadStats(int readCount, int totalUsers, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            size: 12,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$readCount/$totalUsers',
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
