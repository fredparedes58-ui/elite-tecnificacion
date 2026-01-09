// ============================================================
// COMMUNITY HUB SCREEN - Ecosistema Social con Niveles
// ============================================================
// Pantalla principal con tabs para:
// - Tab 1: "Mi Equipo" (scope: team)
// - Tab 2: "Club [Nombre]" (scope: school)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social_post_model.dart';
import '../services/social_service.dart';
import 'create_post_screen.dart';
import 'social_feed_screen.dart'; // Reutilizar componentes

class CommunityHubScreen extends StatefulWidget {
  final String teamId;
  final String? schoolName; // Nombre del club/escuela (opcional)

  const CommunityHubScreen({
    super.key,
    required this.teamId,
    this.schoolName,
  });

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _socialService = SocialService();
  final ScrollController _teamScrollController = ScrollController();
  final ScrollController _schoolScrollController = ScrollController();

  List<SocialPost> _teamPosts = [];
  List<SocialPost> _schoolPosts = [];
  bool _isLoadingTeam = true;
  bool _isLoadingSchool = true;
  bool _isLoadingMoreTeam = false;
  bool _isLoadingMoreSchool = false;
  int _teamPage = 0;
  int _schoolPage = 0;
  static const int _pageSize = 20;

  String? _userRole;
  bool _isCoach = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
    _loadInitialTeamPosts();
    _loadInitialSchoolPosts();
    _teamScrollController.addListener(_onTeamScroll);
    _schoolScrollController.addListener(_onSchoolScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teamScrollController.dispose();
    _schoolScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('team_members')
          .select('role')
          .eq('team_id', widget.teamId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _userRole = response['role'] as String?;
          _isCoach = ['coach', 'admin'].contains(_userRole);
        });
      }
    } catch (e) {
      debugPrint('Error verificando rol: $e');
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.position.pixels >=
        _teamScrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMoreTeam) {
        _loadMoreTeamPosts();
      }
    }
  }

  void _onSchoolScroll() {
    if (_schoolScrollController.position.pixels >=
        _schoolScrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMoreSchool) {
        _loadMoreSchoolPosts();
      }
    }
  }

  Future<void> _loadInitialTeamPosts() async {
    setState(() => _isLoadingTeam = true);
    try {
      final posts = await _socialService.getTeamFeed(
        teamId: widget.teamId,
        scope: 'team',
        limit: _pageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _teamPosts = posts;
          _teamPage = 1;
          _isLoadingTeam = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTeam = false);
        _showError('Error cargando posts del equipo: $e');
      }
    }
  }

  Future<void> _loadMoreTeamPosts() async {
    setState(() => _isLoadingMoreTeam = true);
    try {
      final newPosts = await _socialService.getTeamFeed(
        teamId: widget.teamId,
        scope: 'team',
        limit: _pageSize,
        offset: _teamPage * _pageSize,
      );
      if (newPosts.isNotEmpty && mounted) {
        setState(() {
          _teamPosts.addAll(newPosts);
          _teamPage++;
        });
      }
    } catch (e) {
      _showError('Error cargando más posts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMoreTeam = false);
      }
    }
  }

  Future<void> _loadInitialSchoolPosts() async {
    setState(() => _isLoadingSchool = true);
    try {
      final posts = await _socialService.getSchoolFeed(
        limit: _pageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _schoolPosts = posts;
          _schoolPage = 1;
          _isLoadingSchool = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSchool = false);
        _showError('Error cargando posts del club: $e');
      }
    }
  }

  Future<void> _loadMoreSchoolPosts() async {
    setState(() => _isLoadingMoreSchool = true);
    try {
      final newPosts = await _socialService.getSchoolFeed(
        limit: _pageSize,
        offset: _schoolPage * _pageSize,
      );
      if (newPosts.isNotEmpty && mounted) {
        setState(() {
          _schoolPosts.addAll(newPosts);
          _schoolPage++;
        });
      }
    } catch (e) {
      _showError('Error cargando más posts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMoreSchool = false);
      }
    }
  }

  Future<void> _refreshTeamFeed() async {
    await _loadInitialTeamPosts();
  }

  Future<void> _refreshSchoolFeed() async {
    await _loadInitialSchoolPosts();
  }

  Future<void> _handleLikeToggle(SocialPost post) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final isLiked = await _socialService.toggleLike(
        postId: post.id,
        userId: userId,
      );

      // Actualizar estado local
      if (mounted) {
        setState(() {
          if (post.scope == SocialPostScope.team) {
            final index = _teamPosts.indexWhere((p) => p.id == post.id);
            if (index != -1) {
              _teamPosts[index] = post.copyWith(
                isLikedByMe: isLiked,
                likesCount: isLiked ? post.likesCount + 1 : post.likesCount - 1,
              );
            }
          } else {
            final index = _schoolPosts.indexWhere((p) => p.id == post.id);
            if (index != -1) {
              _schoolPosts[index] = post.copyWith(
                isLikedByMe: isLiked,
                likesCount: isLiked ? post.likesCount + 1 : post.likesCount - 1,
              );
            }
          }
        });
      }
    } catch (e) {
      _showError('Error al dar like: $e');
    }
  }

  Future<void> _handleDelete(String postId, SocialPostScope scope) async {
    try {
      await _socialService.deletePost(postId: postId);
      if (mounted) {
        setState(() {
          if (scope == SocialPostScope.team) {
            _teamPosts.removeWhere((p) => p.id == postId);
          } else {
            _schoolPosts.removeWhere((p) => p.id == postId);
          }
        });
      }
    } catch (e) {
      _showError('Error al eliminar post: $e');
    }
  }

  Future<void> _navigateToCreatePost(SocialPostScope scope) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          teamId: widget.teamId,
          defaultScope: scope,
        ),
      ),
    );

    if (result == true && mounted) {
      // Recargar feeds
      if (scope == SocialPostScope.team) {
        await _refreshTeamFeed();
      } else {
        await _refreshSchoolFeed();
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schoolName = widget.schoolName ?? 'Club';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'COMUNIDAD',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: theme.primaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => _showCreatePostDialog(),
            tooltip: 'Crear Post',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.white54,
          indicatorColor: theme.primaryColor,
          labelStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: [
            const Tab(
              icon: Icon(Icons.groups),
              text: 'Mi Equipo',
            ),
            Tab(
              icon: const Icon(Icons.school),
              text: schoolName,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamTab(),
          _buildSchoolTab(),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    if (_isLoadingTeam) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teamPosts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.groups_outlined,
        title: 'No hay publicaciones aún',
        subtitle: 'Sé el primero en compartir un momento',
        onAction: () => _navigateToCreatePost(SocialPostScope.team),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTeamFeed,
      child: ListView.builder(
        controller: _teamScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _teamPosts.length + (_isLoadingMoreTeam ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _teamPosts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return SocialPostCard(
            post: _teamPosts[index],
            onLikeToggle: () => _handleLikeToggle(_teamPosts[index]),
            onDelete: () => _handleDelete(
              _teamPosts[index].id,
              SocialPostScope.team,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchoolTab() {
    if (_isLoadingSchool) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_schoolPosts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.school_outlined,
        title: 'No hay publicaciones del club',
        subtitle: _isCoach
            ? 'Comparte noticias del club'
            : 'Las publicaciones del club aparecerán aquí',
        onAction: _isCoach
            ? () => _navigateToCreatePost(SocialPostScope.school)
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshSchoolFeed,
      child: ListView.builder(
        controller: _schoolScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _schoolPosts.length + (_isLoadingMoreSchool ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _schoolPosts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final post = _schoolPosts[index];
          return SocialPostCard(
            post: post,
            onLikeToggle: () => _handleLikeToggle(post),
            onDelete: () => _handleDelete(post.id, SocialPostScope.school),
            showTeamName: true, // Mostrar nombre del equipo en posts del club
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('COMPARTIR MOMENTO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.groups, color: Colors.blue),
                title: Text(
                  'Publicar en Mi Equipo',
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
                subtitle: Text(
                  'Solo visible para tu equipo',
                  style: GoogleFonts.roboto(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToCreatePost(SocialPostScope.team);
                },
              ),
              if (_isCoach)
                ListTile(
                  leading: const Icon(Icons.school, color: Colors.purple),
                  title: Text(
                    'Publicar en Todo el Club',
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Visible para todos los equipos',
                    style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToCreatePost(SocialPostScope.school);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
