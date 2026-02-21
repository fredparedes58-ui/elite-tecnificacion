import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/widgets/live_standings_card.dart';
import 'package:myapp/widgets/squad_status_card.dart';
import 'package:myapp/widgets/upcoming_match_card.dart';
import 'package:myapp/screens/squad_management_screen.dart';
import 'package:myapp/screens/tactical_board_screen.dart';
import 'package:myapp/screens/session_planner_screen.dart';
import 'package:myapp/screens/training_categories_screen.dart';
import 'package:myapp/screens/matches_screen.dart';
import 'package:myapp/screens/drills_screen.dart';
import 'package:myapp/screens/team_chat_screen.dart';
import 'package:myapp/screens/gallery_screen.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/screens/methodology_screen.dart';
import 'package:myapp/screens/field_schedule_screen.dart';
import 'package:myapp/screens/top_scorers_screen.dart';
import 'package:myapp/screens/test_upload_screen.dart';
import 'package:myapp/screens/social_feed_screen.dart';
import 'package:myapp/screens/attendance_screen.dart';
import 'package:myapp/screens/parent_attendance_screen.dart';
import 'package:myapp/screens/notice_board_screen.dart';
import 'package:myapp/screens/add_team_member_screen.dart';
import 'package:myapp/screens/school_calendar_screen.dart';
import 'package:myapp/screens/credit_report_screen.dart';
import 'package:myapp/widgets/credits_realtime_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;
  final String userName;

  const HomeScreen({
    super.key,
    this.userRole = 'coach',
    this.userName = 'Usuario',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<String?> _getCurrentTeamId() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await Supabase.instance.client
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return response['team_id'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo teamId: $e');
      return null;
    }
  }

  Future<Map<String, String?>> _getTeamInfo() async {
    try {
      final teamId = await _getCurrentTeamId();
      if (teamId == null) {
        return {
          'teamId': null,
          'category': null,
          'clubId': null,
        };
      }

      final teamResponse = await Supabase.instance.client
          .from('teams')
          .select('id, category, club_id')
          .eq('id', teamId)
          .maybeSingle();

      if (teamResponse != null) {
        return {
          'teamId': teamId,
          'category': teamResponse['category'] as String? ?? 'Alevín',
          'clubId': teamResponse['club_id'] as String?,
        };
      }

      return {
        'teamId': teamId,
        'category': 'Alevín',
        'clubId': null,
      };
    } catch (e) {
      debugPrint('Error obteniendo información del equipo: $e');
      return {
        'teamId': null,
        'category': null,
        'clubId': null,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'COMMAND CENTER',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: colorScheme.primary,
            ),
            onPressed: () {
              // Ya está implementado en el tab de Notificaciones
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colorScheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 700 ? 5 : (width > 500 ? 4 : (width > 360 ? 3 : 2));
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(context),
            const SizedBox(height: 24),

            if (widget.userRole == 'parent') ...[
              const CreditsRealtimeWidget(),
              const SizedBox(height: 12),
              _buildSectionTitle(context, 'Tus créditos', Icons.account_balance_wallet),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreditReportScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Descargar historial (PDF)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Calendario Escolar', Icons.calendar_today),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
                title: const Text('Ver calendario (eventos, cierres, entrenamientos)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SchoolCalendarScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],

            _buildSectionTitle(context, 'Acceso Rápido', Icons.dashboard),
            const SizedBox(height: 16),
            _buildQuickAccessGrid(context, crossAxisCount: crossAxisCount),
            const SizedBox(height: 32),

            if (widget.userRole != 'parent') ...[
              _buildSectionTitle(context, 'Próximo Partido', Icons.sports_soccer),
              const SizedBox(height: 16),
              const UpcomingMatchCard(),
              const SizedBox(height: 32),
              _buildSectionTitle(
                context,
                'Clasificación en Vivo',
                Icons.leaderboard,
              ),
              const SizedBox(height: 16),
              const LiveStandingsCard(),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Estado del Equipo', Icons.groups),
              const SizedBox(height: 16),
              const SquadStatusCard(),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Gestión Rápida', Icons.bolt),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 32),
            ],
          ],
        ),
            );
          },
        ),
      ),
      floatingActionButton: widget.userRole == 'parent' ? null : _buildFloatingMenu(context),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido de nuevo',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  widget.userRole == 'parent' ? 'Familia' : 'Entrenador',
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                if (widget.userRole == 'parent' && widget.userName != 'Usuario')
                  Text(
                    widget.userName,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.robotoCondensed(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, {int crossAxisCount = 4}) {
    final quickAccessItems = [
      _QuickAccessItem(
        title: 'Plantilla',
        icon: Icons.groups,
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SquadManagementScreen(),
          ),
        ),
      ),
      _QuickAccessItem(
        title: 'Tácticas',
        icon: Icons.grid_on,
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TacticalBoardScreen()),
        ),
      ),
      _QuickAccessItem(
        title: 'Entrenamientos',
        icon: Icons.calendar_today,
        color: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrainingCategoriesScreen()),
        ),
      ),
      _QuickAccessItem(
        title: 'Ejercicios',
        icon: Icons.fitness_center,
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DrillsScreen()),
        ),
      ),
      _QuickAccessItem(
        title: 'Partidos',
        icon: Icons.sports_soccer,
        color: Colors.red,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MatchesScreen()),
        ),
      ),
      _QuickAccessItem(
        title: 'Chat Equipo',
        icon: Icons.chat_bubble_outline,
        color: Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const TeamChatScreen(userRole: 'coach', userName: 'Entrenador'),
          ),
        ),
      ),
      _QuickAccessItem(
        title: 'Fútbol Social',
        icon: Icons.photo_camera,
        color: Colors.deepOrange,
        onTap: () async {
          final teamId = await _getCurrentTeamId() ?? 'demo-team-id';
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SocialFeedScreen(
                teamId: teamId,
              ),
            ),
          );
        },
      ),
      _QuickAccessItem(
        title: 'Galería',
        icon: Icons.photo_library,
        color: Colors.pink,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GalleryScreen()),
        ),
      ),
      _QuickAccessItem(
        title: 'Metodología',
        icon: Icons.book,
        color: Colors.indigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MethodologyScreen()),
        ),
      ),
      _QuickAccessItem(
        title: 'Campos',
        icon: Icons.stadium,
        color: Colors.cyan,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FieldScheduleScreen()),
        ),
      ),
      _QuickAccessItem(
        title: 'Goleadores',
        icon: Icons.emoji_events,
        color: Colors.amber,
        onTap: () async {
          final teamInfo = await _getTeamInfo();
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopScorersScreen(
                teamId: teamInfo['teamId'] ?? 'demo-team-id',
                category: teamInfo['category'] ?? 'Alevín',
                clubId: teamInfo['clubId'] ?? 'demo-club-id',
              ),
            ),
          );
        },
      ),
      _QuickAccessItem(
        title: 'Asistencia',
        icon: Icons.check_circle_outline,
        color: Colors.lime,
        onTap: () async {
          // Verificar si el usuario es padre
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            try {
              // Verificar si tiene hijos registrados
              final children = await Supabase.instance.client
                  .from('parent_child_relationships')
                  .select('id')
                  .eq('parent_id', userId)
                  .limit(1);

              if (children.isNotEmpty) {
                // Es padre, navegar a pantalla de padres
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParentAttendanceScreen(),
                    ),
                  );
                }
              } else {
                // No es padre, verificar si es coach/admin
                final memberCheck = await Supabase.instance.client
                    .from('team_members')
                    .select('role')
                    .eq('user_id', userId)
                    .maybeSingle();

                if (memberCheck != null &&
                    ['coach', 'admin'].contains(memberCheck['role'])) {
                  // Es coach/admin, navegar a pantalla normal
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendanceScreen(),
                      ),
                    );
                  }
                } else {
                  // No tiene permisos
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No tienes permisos para acceder a la asistencia',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              }
            } catch (e) {
              debugPrint('Error verificando rol: $e');
              // Por defecto, intentar pantalla normal
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceScreen(),
                  ),
                );
              }
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AttendanceScreen()),
            );
          }
        },
      ),
      _QuickAccessItem(
        title: 'Tablón',
        icon: Icons.announcement,
        color: Colors.deepPurple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NoticeBoardScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: quickAccessItems.length,
      itemBuilder: (context, index) {
        final item = quickAccessItems[index];
        return _buildQuickAccessCard(context, item);
      },
    );
  }

  Widget _buildQuickAccessCard(BuildContext context, _QuickAccessItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [item.color.withValues(alpha: 0.2), item.color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 32, color: item.color),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          context,
          icon: Icons.person_add,
          title: 'Añadir Jugador',
          subtitle: 'Gestionar plantilla',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTeamMemberScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          icon: Icons.upload_file,
          title: 'Subir Archivos',
          subtitle: 'Imágenes, PDFs, documentos',
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TestUploadScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          icon: Icons.edit_note,
          title: 'Editar Sesión',
          subtitle: 'Modificar entrenamientos',
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SessionPlannerScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMenu(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        _showQuickActionMenu(context);
      },
      icon: const Icon(Icons.add),
      label: const Text('ACCIONES'),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person_add, color: Colors.blue),
                title: Text('Añadir Jugador', style: GoogleFonts.roboto()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTeamMemberScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.event, color: Colors.green),
                title: Text('Nueva Sesión', style: GoogleFonts.roboto()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SessionPlannerScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.upload_file, color: Colors.orange),
                title: Text('Subir Archivo', style: GoogleFonts.roboto()),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subir archivo')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Colors.deepOrange),
                title: Text('Compartir Momento', style: GoogleFonts.roboto()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) => FutureBuilder<String?>(
                      future: _getCurrentTeamId(),
                      builder: (context, snapshot) {
                        return SocialFeedScreen(
                          teamId: snapshot.data ?? 'demo-team-id',
                        );
                      },
                    ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAccessItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAccessItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
