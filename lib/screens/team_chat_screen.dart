import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
// TODO: Implementar reproducción de audio
// import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/models/chat_channel_model.dart';
import 'package:myapp/models/chat_message_model.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:myapp/services/media_upload_service.dart';
import 'package:myapp/services/file_management_service.dart';
import 'package:myapp/screens/create_notice_screen.dart';
import 'package:myapp/screens/add_team_member_screen.dart';
import 'package:myapp/screens/select_chat_recipient_screen.dart';
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
  ChatChannel? _currentPrivateChannel;
  bool _loadingChannels = true;
  bool _sendingMessage = false;
  String? _currentTeamId;
  bool _isCoach = false;
  bool _isRecording = false;
  String? _currentRecipientId; // Para mensajes privados
  String? _currentRecipientName; // Nombre del destinatario
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
    _loadChannels();
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

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _selectRecipient() async {
    if (_currentTeamId == null) return;
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectChatRecipientScreen(
          teamId: _currentTeamId!,
          currentUserId: userId,
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        if (selected == 'group') {
          _currentRecipientId = null;
          _currentRecipientName = null;
          _currentPrivateChannel = null;
        } else {
          _currentRecipientId = selected;
          // Obtener nombre del destinatario
          _loadRecipientName(selected);
          // Crear o obtener chat privado
          _getOrCreatePrivateChannel(selected);
        }
      });
    }
  }

  Future<void> _loadRecipientName(String recipientId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', recipientId)
          .maybeSingle();
      
      if (response != null && mounted) {
        setState(() {
          _currentRecipientName = response['full_name'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre del destinatario: $e');
    }
  }

  Future<void> _getOrCreatePrivateChannel(String recipientId) async {
    if (_currentTeamId == null) return;
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Usar la función de Supabase para crear/obtener chat privado
      final response = await Supabase.instance.client.rpc(
        'get_or_create_private_chat',
        params: {
          'p_user1_id': userId,
          'p_user2_id': recipientId,
          'p_team_id': _currentTeamId,
        },
      );

      if (response != null && mounted) {
        final channelId = response as String;
        // Cargar el canal
        final channelData = await Supabase.instance.client
            .from('chat_channels')
            .select()
            .eq('id', channelId)
            .maybeSingle();

        if (channelData != null) {
          setState(() {
            _currentPrivateChannel = ChatChannel.fromJson(channelData);
          });
        }
      }
    } catch (e) {
      debugPrint('Error creando/obteniendo chat privado: $e');
    }
  }

  Future<void> _loadChannels() async {
    setState(() => _loadingChannels = true);
    try {
      // Obtener team_id del usuario
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() => _loadingChannels = false);
        }
        return;
      }

      final teamMember = await Supabase.instance.client
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (teamMember == null) {
        if (mounted) {
          setState(() => _loadingChannels = false);
        }
        return;
      }

      final teamId = teamMember['team_id'] as String;
      _currentTeamId = teamId;

      // Asegurar que existan los canales por defecto
      await _supabaseService.ensureDefaultChannels(teamId);

      // Cargar canales
      final channelsData = await _supabaseService.getTeamChatChannels(teamId);
      final channels = channelsData
          .map((data) => ChatChannel.fromJson(data))
          .toList();

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
      // Si hay un destinatario seleccionado, usar el canal privado
      if (_currentRecipientId != null && _currentPrivateChannel != null) {
        return _currentPrivateChannel;
      }
      return _generalChannel;
    }
  }

  bool get _canWrite {
    final channel = _currentChannel;
    if (channel == null) return false;
    return channel.canUserWrite(widget.userRole);
  }

  Future<void> _sendMessage({
    File? mediaFile, 
    ChatMediaType? mediaType,
    double? latitude,
    double? longitude,
  }) async {
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
        } else if (mediaType == ChatMediaType.audio || mediaType == ChatMediaType.document) {
          // Subir audio o documento usando FileManagementService a Supabase Storage
          final fileService = FileManagementService();
          final folder = mediaType == ChatMediaType.audio ? 'chat-audio' : 'chat-documents';
          mediaUrl = await fileService.uploadFile(
            file: mediaFile,
            folder: folder,
          );
          if (mediaUrl == null) {
            throw Exception('Error al subir ${mediaType == ChatMediaType.audio ? "audio" : "documento"}');
          }
        }
      }

      // Crear mensaje con soporte para mensajes privados y ubicación
      String defaultContent = content;
      if (content.isEmpty && mediaType != null) {
        switch (mediaType) {
          case ChatMediaType.image:
            defaultContent = '📷 Foto';
            break;
          case ChatMediaType.video:
            defaultContent = '🎥 Video';
            break;
          case ChatMediaType.audio:
            defaultContent = '🎤 Audio';
            break;
          case ChatMediaType.document:
            defaultContent = '📄 Documento';
            break;
          case ChatMediaType.location:
            defaultContent = '📍 Ubicación';
            break;
        }
      }

      final message = CreateChatMessageDto(
        channelId: channel.id,
        content: defaultContent,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        recipientId: _currentRecipientId,
        isPrivate: _currentRecipientId != null,
        latitude: latitude,
        longitude: longitude,
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
    } else if (type == ChatMediaType.video) {
      file = await picker.pickVideo(source: ImageSource.gallery);
    }

    if (file != null) {
      await _sendMessage(
        mediaFile: File(file.path),
        mediaType: type,
      );
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Adjuntar',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('Foto'),
              subtitle: const Text('Desde galería'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ChatMediaType.image);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam, color: Colors.purple),
              ),
              title: const Text('Video'),
              subtitle: const Text('Desde galería'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ChatMediaType.video);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description, color: Colors.orange),
              ),
              title: const Text('Documento'),
              subtitle: const Text('PDF, DOC, XLS, etc.'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: Colors.red),
              ),
              title: const Text('Ubicación'),
              subtitle: const Text('Compartir mi ubicación actual'),
              onTap: () {
                Navigator.pop(context);
                _shareLocation();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se necesita permiso de micrófono')),
          );
        }
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/audio_$timestamp.m4a';

      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath!,
        );

        if (mounted) {
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      debugPrint('Error iniciando grabación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al grabar: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() => _isRecording = false);
      }

      if (path != null) {
        await _sendAudio(File(path));
        _recordingPath = null;
      }
    } catch (e) {
      debugPrint('Error deteniendo grabación: $e');
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al detener grabación: $e')),
        );
      }
    }
  }

  Future<void> _sendAudio(File audioFile) async {
    await _sendMessage(
      mediaFile: audioFile,
      mediaType: ChatMediaType.audio,
    );
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _sendMessage(
          mediaFile: file,
          mediaType: ChatMediaType.document,
        );
      }
    } catch (e) {
      debugPrint('Error seleccionando documento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar documento: $e')),
        );
      }
    }
  }

  Future<void> _shareLocation() async {
    try {
      // Solicitar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Se necesita permiso de ubicación')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Los permisos de ubicación están deshabilitados permanentemente'),
            ),
          );
        }
        return;
      }

      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El servicio de ubicación está deshabilitado. Por favor, actívalo en la configuración.'),
            ),
          );
        }
        return;
      }

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Obteniendo ubicación...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Enviar ubicación
      await _sendMessage(
        latitude: position.latitude,
        longitude: position.longitude,
        mediaType: ChatMediaType.location,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentRecipientName ?? 'Chat del Equipo',
              style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            if (_currentRecipientName != null)
              Text(
                'Privado',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          // Botón para seleccionar destinatario (solo en Vestuario)
          if (_tabController.index == 1 && _currentTeamId != null)
            IconButton(
              icon: Icon(_currentRecipientId == null ? Icons.group : Icons.person),
              tooltip: _currentRecipientId == null 
                  ? 'Seleccionar destinatario' 
                  : 'Cambiar destinatario',
              onPressed: _selectRecipient,
            ),
          if (_isCoach) ...[
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Agregar miembro',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTeamMemberScreen(),
                  ),
                );
                if (result == true) {
                  // Recargar si se agregó un miembro
                  _loadChannels();
                }
              },
            ),
          ],
        ],
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
          : _currentTeamId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No estás asignado a ningún equipo',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contacta a un administrador para ser agregado',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                )
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
          itemCount: messages.length + (_isCoach ? 1 : 0),
          itemBuilder: (context, index) {
            // Mostrar tarjeta de crear anuncio primero si es entrenador
            if (_isCoach && index == 0) {
              return _buildCreateAnnouncementCard();
            }
            // Ajustar índice para los mensajes
            final messageIndex = _isCoach ? index - 1 : index;
            return _buildAnnouncementCard(messages[messageIndex]);
          },
        );
      },
    );
  }

  /// Tarjeta para crear nuevo anuncio (solo para entrenadores)
  Widget _buildCreateAnnouncementCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.3),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateNoticeScreen(),
            ),
          );
          if (result == true) {
            // Recargar mensajes después de crear anuncio
            setState(() {});
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creación de Anuncios',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca para crear un nuevo comunicado oficial',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
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
          color: colorScheme.primary.withValues(alpha: 0.2),
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
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
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
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                      color: colorScheme.primary.withValues(alpha: 0.2),
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
                color: colorScheme.surfaceContainerHighest,
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
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
                    _buildMediaWidget(message),
                    if (message.content.isNotEmpty && 
                        !message.content.startsWith('📷') && 
                        !message.content.startsWith('🎥') &&
                        !message.content.startsWith('🎤') &&
                        !message.content.startsWith('📄') &&
                        !message.content.startsWith('📍')) 
                      const SizedBox(height: 8),
                  ],
                  // Ubicación
                  if (message.isLocation && message.latitude != null && message.longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildLocationWidget(message),
                    ),
                  // Texto
                  if (message.content.isNotEmpty &&
                      !message.content.startsWith('📷') &&
                      !message.content.startsWith('🎥') &&
                      !message.content.startsWith('🎤') &&
                      !message.content.startsWith('📄') &&
                      !message.content.startsWith('📍'))
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
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar diferentes tipos de media
  Widget _buildMediaWidget(ChatMessage message) {
    if (message.isImage) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.mediaUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: Colors.white54,
            ),
          ),
        ),
      );
    } else if (message.isVideo) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 48,
            color: Colors.white,
          ),
        ),
      );
    } else if (message.isAudio) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.graphic_eq, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎤 Audio',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Colors.white24,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                // TODO: Implementar reproducción de audio
                debugPrint('Reproducir audio: ${message.mediaUrl}');
              },
              color: Colors.white70,
            ),
          ],
        ),
      );
    } else if (message.isDocument) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.description, size: 32, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📄 Documento',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _getFileNameFromUrl(message.mediaUrl ?? ''),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                if (message.mediaUrl != null) {
                  launchUrl(Uri.parse(message.mediaUrl!));
                }
              },
              color: Colors.white70,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLocationWidget(ChatMessage message) {
    return InkWell(
      onTap: () {
        final lat = message.latitude!;
        final lon = message.longitude!;
        final url = 'https://www.google.com/maps?q=$lat,$lon';
        launchUrl(Uri.parse(url));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 32, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Ubicación',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Toca para abrir en el mapa',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
      return 'Documento';
    } catch (e) {
      return 'Documento';
    }
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
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de grabación
          if (_isRecording)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Grabando audio... Toca para detener',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Botón de adjuntos (menú estilo WhatsApp)
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _sendingMessage || _isRecording
                    ? null
                    : () => _showAttachmentMenu(),
                color: colorScheme.primary,
              ),
              // Campo de texto
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: !_sendingMessage && !_isRecording,
                  decoration: InputDecoration(
                    hintText: _canWrite
                        ? 'Escribe tu mensaje...'
                        : 'Solo lectura',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onTap: _isRecording ? () => _stopRecording() : null,
                ),
              ),
              const SizedBox(width: 8),
              // Botón de micrófono/audio o enviar
              if (_messageController.text.trim().isEmpty && !_isRecording)
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: _sendingMessage
                      ? null
                      : () => _startRecording(),
                  color: colorScheme.primary,
                )
              else if (_isRecording)
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.red),
                  onPressed: () => _stopRecording(),
                  color: Colors.red,
                )
              else
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendingMessage
                      ? null
                      : () => _sendMessage(),
                  color: colorScheme.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
