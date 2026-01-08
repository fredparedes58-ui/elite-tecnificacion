// ============================================================
// SOCIAL FEED SCREEN - Estilo Instagram/Facebook
// ============================================================
// Feed visual para compartir momentos del equipo
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/social_post_model.dart';
import '../services/social_service.dart';
import 'create_post_screen.dart';
import 'victory_share_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  final String teamId;

  const SocialFeedScreen({super.key, required this.teamId});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final SocialService _socialService = SocialService();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  List<SocialPost> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadInitialPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _socialService.getTeamFeed(
        teamId: widget.teamId,
        limit: _pageSize,
        offset: 0,
      );
      setState(() {
        _posts = posts;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando posts: $e');
    }
  }

  Future<void> _loadMorePosts() async {
    setState(() => _isLoadingMore = true);
    try {
      final newPosts = await _socialService.getTeamFeed(
        teamId: widget.teamId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      if (newPosts.isNotEmpty) {
        setState(() {
          _posts.addAll(newPosts);
          _currentPage++;
        });
      }
    } catch (e) {
      _showError('Error cargando más posts: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refreshFeed() async {
    await _loadInitialPosts();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(teamId: widget.teamId),
      ),
    );

    if (result == true) {
      _refreshFeed();
    }
  }

  Future<void> _navigateToVictoryShare() async {
    // Mostrar selector de fuente (cámara o galería)
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VictoryShareScreen(
              imageFile: File(image.path),
            ),
          ),
        );

        if (result == true) {
          _refreshFeed();
        }
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: Text(
                  'Galería de Fotos',
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: Text(
                  'Tomar Foto',
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'FÚTBOL SOCIAL',
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
            onPressed: _navigateToCreatePost,
            tooltip: 'Crear Post',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshFeed,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return SocialPostCard(
                        post: _posts[index],
                        onLikeToggle: () => _handleLikeToggle(_posts[index]),
                        onDelete: () => _handleDelete(_posts[index].id),
                      );
                    },
                  ),
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón Victory Share
          FloatingActionButton(
            heroTag: 'victory_share',
            onPressed: _navigateToVictoryShare,
            backgroundColor: Colors.green,
            child: const Icon(Icons.emoji_events, color: Colors.white),
          ),
          const SizedBox(height: 12),
          // Botón Compartir Normal
          FloatingActionButton.extended(
            heroTag: 'create_post',
            onPressed: _navigateToCreatePost,
            backgroundColor: theme.primaryColor,
            icon: const Icon(Icons.add),
            label: Text(
              'COMPARTIR',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no hay publicaciones',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Sé el primero en compartir un momento!',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreatePost,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('CREAR POST'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLikeToggle(SocialPost post) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final newLikeState = await _socialService.toggleLike(
        postId: post.id,
        userId: userId,
      );

      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = _posts[index].copyWith(
            likesCount: newLikeState
                ? _posts[index].likesCount + 1
                : _posts[index].likesCount - 1,
            isLikedByMe: newLikeState,
          );
        }
      });
    } catch (e) {
      _showError('Error al dar like: $e');
    }
  }

  Future<void> _handleDelete(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(
          '¿Eliminar publicación?',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        content: Text(
          'Esta acción no se puede deshacer',
          style: GoogleFonts.roboto(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _socialService.deletePost(postId: postId);
        setState(() {
          _posts.removeWhere((p) => p.id == postId);
        });
      } catch (e) {
        _showError('Error al eliminar: $e');
      }
    }
  }
}

// ============================================================
// SOCIAL POST CARD - Componente individual de post
// ============================================================

class SocialPostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback onLikeToggle;
  final VoidCallback onDelete;

  const SocialPostCard({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isAuthor = currentUserId == post.userId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Nombre + Fecha
          _PostHeader(
            authorName: post.authorName ?? 'Usuario',
            authorRole: post.authorRole ?? 'Miembro',
            relativeTime: post.getRelativeTime(),
            isAuthor: isAuthor,
            onDelete: onDelete,
          ),

          // Media Content (Imagen o Video)
          _PostMedia(post: post),

          // Footer: Likes + Descripción
          _PostFooter(
            post: post,
            onLikeToggle: onLikeToggle,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// POST HEADER - Cabecera del post
// ============================================================

class _PostHeader extends StatelessWidget {
  final String authorName;
  final String authorRole;
  final String relativeTime;
  final bool isAuthor;
  final VoidCallback onDelete;

  const _PostHeader({
    required this.authorName,
    required this.authorRole,
    required this.relativeTime,
    required this.isAuthor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Avatar circular
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            child: Text(
              authorName[0].toUpperCase(),
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nombre y rol
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$authorRole • $relativeTime',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Botón de eliminar (solo si es el autor)
          if (isAuthor)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.withOpacity(0.7),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// POST MEDIA - Contenido multimedia
// ============================================================

class _PostMedia extends StatelessWidget {
  final SocialPost post;

  const _PostMedia({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.mediaType == MediaType.image) {
      return _buildImageContent();
    } else {
      return _buildVideoThumbnail();
    }
  }

  Widget _buildImageContent() {
    return CachedNetworkImage(
      imageUrl: post.mediaUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 400,
      placeholder: (context, url) => Container(
        height: 400,
        color: Colors.black26,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 400,
        color: Colors.black26,
        child: const Icon(Icons.error_outline, color: Colors.red, size: 50),
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Thumbnail del video
        if (post.thumbnailUrl != null)
          CachedNetworkImage(
            imageUrl: post.thumbnailUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 400,
            placeholder: (context, url) => Container(
              height: 400,
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 400,
              color: Colors.black26,
              child: const Icon(Icons.video_library, color: Colors.white54, size: 80),
            ),
          )
        else
          Container(
            height: 400,
            color: Colors.black26,
            child: const Icon(Icons.video_library, color: Colors.white54, size: 80),
          ),

        // Botón de Play
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 50,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// POST FOOTER - Likes y descripción
// ============================================================

class _PostFooter extends StatelessWidget {
  final SocialPost post;
  final VoidCallback onLikeToggle;

  const _PostFooter({
    required this.post,
    required this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedByMe ?? false;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón de like
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_outline,
                  color: isLiked ? Colors.red : Colors.white70,
                ),
                onPressed: onLikeToggle,
              ),
              Text(
                '${post.likesCount}',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.chat_bubble_outline,
                size: 24,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                '${post.commentsCount}',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),

          // Descripción del post
          if (post.contentText != null && post.contentText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                post.contentText!,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
