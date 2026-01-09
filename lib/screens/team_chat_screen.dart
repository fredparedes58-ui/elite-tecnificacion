import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/chat_channel_model.dart';
import 'package:myapp/models/chat_message_model.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:myapp/services/media_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// PANTALLA: TeamChatScreen
/// ============================================================
/// Sistema de chat con dos tipos de canales:
/// - Tab 1: "Avisos Oficiales" (solo lectura para padres)
/// - Tab 2: "Vestuario" (chat libre)
/// ============================================================

class TeamChatScreen extends StatefulWidget {
  final String userRole;
  final String userName;

  const TeamChatScreen({
    super.key,
    required this.userRole,
    required this.userName,
  });

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  final MediaUploadService _mediaService = MediaUploadService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatChannel? _announcementChannel;
  ChatChannel? _generalChannel;
  bool _loadingChannels = true;
  bool _sendingMessage = false;
  String? _currentTeamId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChannels();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    setState(() => _loadingChannels = true);
    try {
      // Obtener team_id del usuario
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final teamMember = await Supabase.instance.client
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (teamMember == null) return;

      _currentTeamId = teamMember['team_id'] as String;

      // Asegurar que existan los canales por defecto
      await _supabaseService.ensureDefaultChannels(teamId: _currentTeamId);

      // Cargar canales
      final channels = await _supabaseService.getTeamChatChannels(
        teamId: _currentTeamId,
      );

      if (mounted) {
        setState(() {
          _announcementChannel = channels.firstWhere(
            (c) => c.type == ChatChannelType.announcement,
            orElse: () => channels.first,
          );
          _generalChannel = channels.firstWhere(
            (c) => c.type == ChatChannelType.general,
            orElse: () => channels.first,
          );
          _loadingChannels = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando canales: $e');
      if (mounted) {
        setState(() => _loadingChannels = false);
      }
    }
  }

  ChatChannel? get _currentChannel {
    if (_tabController.index == 0) {
      return _announcementChannel;
    } else {
      return _generalChannel;
    }
  }

  bool get _canWrite {
    final channel = _currentChannel;
    if (channel == null) return false;
    return channel.canUserWrite(widget.userRole);
  }

  Future<void> _sendMessage({File? mediaFile, ChatMediaType? mediaType}) async {
    final channel = _currentChannel;
    if (channel == null || !_canWrite) return;

    final content = _messageController.text.trim();
    if (content.isEmpty && mediaFile == null) return;

    setState(() => _sendingMessage = true);

    try {
      String? mediaUrl;

      // Subir media si existe
      if (mediaFile != null && mediaType != null) {
        if (mediaType == ChatMediaType.image) {
          mediaUrl = await _mediaService.uploadPhoto(mediaFile);
        } else if (mediaType == ChatMediaType.video) {
          final result = await _mediaService.uploadVideo(mediaFile);
          mediaUrl = result.directPlayUrl;
        }
      }

      // Crear mensaje
      final message = CreateChatMessageDto(
        channelId: channel.id,
        content: content.isEmpty ? (mediaType == ChatMediaType.image ? '📷 Foto' : '🎥 Video') : content,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );

      final sent = await _supabaseService.sendMessage(message);
      if (sent != null && mounted) {
        _messageController.clear();
        // Scroll al final después de un breve delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error enviando mensaje: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingMessage = false);
      }
    }
  }

  Future<void> _pickMedia(ChatMediaType type) async {
    final ImagePicker picker = ImagePicker();
    XFile? file;

    if (type == ChatMediaType.image) {
      file = await picker.pickImage(source: ImageSource.gallery);
    } else {
      file = await picker.pickVideo(source: ImageSource.gallery);
    }

    if (file != null) {
      await _sendMessage(
        mediaFile: File(file.path),
        mediaType: type,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat del Equipo',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.announcement),
              text: 'Avisos Oficiales',
            ),
            Tab(
              icon: Icon(Icons.chat_bubble),
              text: 'Vestuario',
            ),
          ],
          labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loadingChannels
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAnnouncementTab(),
                      _buildGeneralChatTab(),
                    ],
                  ),
                ),
                if (_canWrite) _buildMessageInput(),
              ],
            ),
    );
  }

  /// Tab 1: Avisos Oficiales (UI tipo noticias)
  Widget _buildAnnouncementTab() {
    final channel = _announcementChannel;
    if (channel == null) {
      return const Center(child: Text('Canal no disponible'));
    }

    return StreamBuilder<List<ChatMessage>>(
      stream: _supabaseService.streamChannelMessages(channel.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.announcement_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay avisos aún',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                if (_canWrite)
                  Text(
                    'Sé el primero en publicar un aviso',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildAnnouncementCard(messages[index]);
          },
        );
      },
    );
  }

  /// Card de anuncio (estilo noticia)
  Widget _buildAnnouncementCard(ChatMessage message) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCoach = ['coach', 'admin'].contains(message.userRole);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  child: message.userAvatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            message.userAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      : Icon(
                          isCoach ? Icons.sports_soccer : Icons.person,
                          color: colorScheme.primary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.userName ?? 'Usuario',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        message.getRelativeTime(),
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCoach)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ENTRENADOR',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Media (si existe)
          if (message.hasMedia) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
              ),
              child: message.isImage
                  ? Image.network(
                      message.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.play_circle_outline, size: 48),
                    ),
            ),
          ],
          // Contenido
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message.content,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Vestuario (Chat estilo WhatsApp)
  Widget _buildGeneralChatTab() {
    final channel = _generalChannel;
    if (channel == null) {
      return const Center(child: Text('Canal no disponible'));
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return StreamBuilder<List<ChatMessage>>(
      stream: _supabaseService.streamChannelMessages(channel.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay mensajes aún',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  'Sé el primero en escribir',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.userId == currentUserId;
            return _buildChatBubble(message, isMe);
          },
        );
      },
    );
  }

  /// Burbuja de chat (estilo WhatsApp)
  Widget _buildChatBubble(ChatMessage message, bool isMe) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  message.userName ?? 'Usuario',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : null,
                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media
                  if (message.hasMedia) ...[
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: message.isImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                message.mediaUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image,
                                ),
                              ),
                            )
                          : Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    if (message.content.isNotEmpty) const SizedBox(height: 8),
                  ],
                  // Texto
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: isMe
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Text(
                message.getRelativeTime(),
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Input de mensaje con botones de media
  Widget _buildMessageInput() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón de foto
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _sendingMessage
                ? null
                : () => _pickMedia(ChatMediaType.image),
            color: colorScheme.primary,
          ),
          // Botón de video
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _sendingMessage
                ? null
                : () => _pickMedia(ChatMediaType.video),
            color: colorScheme.primary,
          ),
          // Campo de texto
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_sendingMessage,
              decoration: InputDecoration(
                hintText: _canWrite
                    ? 'Escribe tu mensaje...'
                    : 'Solo lectura',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          // Botón de enviar
          _sendingMessage
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                  color: colorScheme.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                  ),
                ),
        ],
      ),
    );
  }
}
