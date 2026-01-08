import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myapp/widgets/bunny_video_player.dart';
import 'package:myapp/widgets/telestration_layer.dart';
import 'package:myapp/models/analysis_event_model.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/services/voice_tagging_service.dart';
import 'package:myapp/services/media_upload_service.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:myapp/screens/video_sync_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// PANTALLA: ProMatchAnalysisScreen
/// ============================================================
/// Suite completa de análisis profesional con:
/// - Video Bunny Stream
/// - Comandos de voz (Speech-to-Text)
/// - Telestration (Dibujo táctico)
/// - Timeline de eventos
/// ============================================================

class ProMatchAnalysisScreen extends StatefulWidget {
  final String videoUrl;
  final String? videoGuid;
  final String? matchId;
  final String? teamId;

  const ProMatchAnalysisScreen({
    super.key,
    required this.videoUrl,
    this.videoGuid,
    this.matchId,
    this.teamId,
  });

  @override
  State<ProMatchAnalysisScreen> createState() => _ProMatchAnalysisScreenState();
}

class _ProMatchAnalysisScreenState extends State<ProMatchAnalysisScreen> {
  // Controladores
  final BunnyVideoPlayerController _videoController = BunnyVideoPlayerController();
  final TelestrationController _telestrationController = TelestrationController();
  final VoiceTaggingService _voiceService = voiceTaggingService;
  final MediaUploadService _mediaService = MediaUploadService();
  final SupabaseService _supabaseService = SupabaseService();

  // Estado
  bool _isDrawingMode = false;
  bool _isRecording = false;
  bool _isInitialized = false;
  int _currentVideoSeconds = 0;

  // Datos
  List<AnalysisEvent> _events = [];
  List<Player> _teamPlayers = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _telestrationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  /// Inicializa todos los servicios
  Future<void> _initialize() async {
    try {
      // 1. Inicializar servicio de voz
      await _voiceService.initialize();

      // 2. Cargar jugadores del equipo
      if (widget.teamId != null) {
        _teamPlayers = await _supabaseService.getTeamPlayers(teamId: widget.teamId);
        _voiceService.setTeamPlayers(_teamPlayers);
      }

      // 3. Cargar eventos existentes
      if (widget.matchId != null) {
        await _loadEvents();
        
        // 4. Verificar si hay eventos Live sin sincronizar
        await _checkUnsyncedEvents();
      }

      setState(() {
        _isInitialized = true;
      });

      debugPrint('✅ ProMatchAnalysisScreen inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando: $e');
      _showError('Error al inicializar el análisis');
    }
  }
  
  /// Verifica si hay eventos Live sin sincronizar y ofrece sincronizarlos
  Future<void> _checkUnsyncedEvents() async {
    if (widget.matchId == null) return;
    
    try {
      final hasUnsynced = await _supabaseService.hasUnsyncedLiveEvents(widget.matchId!);
      
      if (hasUnsynced) {
        // Obtener estadísticas
        final stats = await _supabaseService.getLiveEventsStats(widget.matchId!);
        final unsyncedCount = stats['unsynced_events'] as int? ?? 0;
        
        if (unsyncedCount > 0 && mounted) {
          // Mostrar diálogo de sincronización después de un breve delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showSyncDialog(unsyncedCount);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error verificando eventos sin sincronizar: $e');
    }
  }
  
  /// Muestra un diálogo para sincronizar eventos Live
  void _showSyncDialog(int unsyncedCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.sync, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text(
              'Sincronizar Eventos',
              style: GoogleFonts.oswald(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este partido tiene $unsyncedCount evento${unsyncedCount > 1 ? 's' : ''} registrado${unsyncedCount > 1 ? 's' : ''} en modo Live.',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Deseas sincronizarlos con el video para poder ver exactamente dónde ocurrieron?',
              style: GoogleFonts.roboto(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ahora No',
              style: GoogleFonts.roboto(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSync();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(
              'Sincronizar',
              style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Navega a la pantalla de sincronización
  Future<void> _navigateToSync() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoSyncScreen(
          matchId: widget.matchId!,
          videoUrl: widget.videoUrl,
          videoGuid: widget.videoGuid,
        ),
      ),
    );
    
    // Si se sincronizó correctamente, recargar eventos
    if (result == true) {
      await _loadEvents();
      _showSuccess('Eventos sincronizados correctamente');
    }
  }

  /// Carga los eventos existentes del partido
  Future<void> _loadEvents() async {
    try {
      final response = await Supabase.instance.client
          .from('analysis_events_detailed')
          .select()
          .eq('match_id', widget.matchId!)
          .order('match_timestamp', ascending: true);

      setState(() {
        _events = (response as List)
            .map((json) => AnalysisEvent.fromJson(json))
            .toList();
      });

      debugPrint('📋 Eventos cargados: ${_events.length}');
    } catch (e) {
      debugPrint('❌ Error cargando eventos: $e');
    }
  }

  // ==========================================
  // MODO DIBUJO
  // ==========================================

  /// Activa/desactiva el modo dibujo
  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
    });

    if (_isDrawingMode) {
      // Pausar video al entrar en modo dibujo
      _videoController.pause();
    }
  }

  /// Guarda el dibujo actual
  Future<void> _saveDrawing() async {
    try {
      _showLoading('Guardando dibujo...');

      // 1. Capturar imagen del dibujo
      final imageBytes = await _telestrationController.captureAsImage();
      if (imageBytes == null) {
        throw Exception('No se pudo capturar el dibujo');
      }

      // 2. Guardar temporalmente en disco
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/telestration_$timestamp.png');
      await tempFile.writeAsBytes(imageBytes);

      // 3. Subir a R2 usando MediaUploadService
      final drawingUrl = await _mediaService.uploadPhoto(tempFile);

      // 4. Crear evento en Supabase
      final currentSeconds = _videoController.getCurrentSeconds() ?? 0;
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await Supabase.instance.client.from('analysis_events').insert({
        'match_id': widget.matchId,
        'team_id': widget.teamId,
        'coach_id': userId,
        'video_guid': widget.videoGuid,
        'match_timestamp': currentSeconds,
        'video_timestamp': currentSeconds,
        'event_type': 'custom',
        'event_title': 'Dibujo Táctico',
        'drawing_url': drawingUrl,
      });

      // 5. Limpiar dibujo
      _telestrationController.clear();

      // 6. Recargar eventos
      await _loadEvents();

      // 7. Salir del modo dibujo
      setState(() {
        _isDrawingMode = false;
      });

      Navigator.of(context).pop(); // Cerrar loading
      _showSuccess('Dibujo guardado exitosamente');

      debugPrint('✅ Dibujo guardado: $drawingUrl');
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading
      debugPrint('❌ Error guardando dibujo: $e');
      _showError('Error al guardar el dibujo');
    }
  }

  // ==========================================
  // VOZ
  // ==========================================

  /// Inicia la grabación de voz
  Future<void> _startVoiceRecording() async {
    setState(() {
      _isRecording = true;
    });

    await _voiceService.startListening(
      onResult: (result) {
        _handleVoiceResult(result);
      },
    );
  }

  /// Detiene la grabación de voz
  Future<void> _stopVoiceRecording() async {
    setState(() {
      _isRecording = false;
    });

    await _voiceService.stopListening();
  }

  /// Procesa el resultado del reconocimiento de voz
  Future<void> _handleVoiceResult(VoiceTagResult result) async {
    try {
      // Mostrar lo detectado
      String message = 'Detectado: "${result.transcript}"';
      if (result.detectedEventType != null) {
        message += '\nEvento: ${result.detectedEventType}';
      }
      if (result.detectedPlayerName != null) {
        message += '\nJugador: ${result.detectedPlayerName}';
      }

      _showInfo(message);

      // Guardar evento
      final currentSeconds = _videoController.getCurrentSeconds() ?? 0;
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await Supabase.instance.client.from('analysis_events').insert({
        'match_id': widget.matchId,
        'team_id': widget.teamId,
        'coach_id': userId,
        'player_id': result.detectedPlayerId,
        'video_guid': widget.videoGuid,
        'match_timestamp': currentSeconds,
        'video_timestamp': currentSeconds,
        'event_type': result.detectedEventType ?? 'voice_note',
        'event_title': result.transcript,
        'voice_transcript': result.transcript,
        'voice_confidence': result.confidence,
        'tags': result.suggestedTags,
      });

      // Recargar eventos
      await _loadEvents();

      debugPrint('✅ Evento de voz guardado');
    } catch (e) {
      debugPrint('❌ Error guardando evento de voz: $e');
      _showError('Error al guardar el evento');
    }
  }

  // ==========================================
  // TIMELINE
  // ==========================================

  /// Salta a un evento en el video
  void _jumpToEvent(AnalysisEvent event) {
    // Usar videoTimestamp si está disponible, o matchTimestamp como fallback
    final timestamp = event.videoTimestamp ?? event.matchTimestamp;
    _videoController.seekToSeconds(timestamp);
  }

  // ==========================================
  // UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: !_isInitialized
          ? _buildLoadingState()
          : Column(
              children: [
                // Video + Capa de Dibujo
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      // Video de fondo
                      BunnyVideoPlayer(
                        videoUrl: widget.videoUrl,
                        controller: _videoController,
                        showControls: !_isDrawingMode,
                        onPositionChanged: (position) {
                          setState(() {
                            _currentVideoSeconds = position.inSeconds;
                          });
                        },
                      ),

                      // Capa de dibujo encima
                      if (_isDrawingMode)
                        TelestrationLayer(
                          controller: _telestrationController,
                          isActive: _isDrawingMode,
                        ),

                      // Indicador de modo dibujo
                      if (_isDrawingMode)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _buildDrawingModeIndicator(),
                        ),

                      // Timestamp actual
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildTimestampIndicator(),
                      ),
                    ],
                  ),
                ),

                // Barra de herramientas de dibujo
                if (_isDrawingMode)
                  TelestrationToolbar(
                    controller: _telestrationController,
                    onClear: () => _telestrationController.clear(),
                    onSave: _saveDrawing,
                    onClose: () => setState(() => _isDrawingMode = false),
                  ),

                // Timeline de eventos
                if (!_isDrawingMode) _buildEventsTimeline(),
              ],
            ),
      floatingActionButton: !_isDrawingMode ? _buildFloatingActions() : null,
    );
  }

  /// AppBar personalizado
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'ANÁLISIS PROMATCH',
        style: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isDrawingMode ? Icons.videocam : Icons.edit,
            color: _isDrawingMode ? Colors.cyan : Colors.white70,
          ),
          onPressed: _toggleDrawingMode,
        ),
      ],
    );
  }

  /// Estado de carga
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.cyan),
          SizedBox(height: 16),
          Text(
            'Inicializando análisis...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// Indicador de modo dibujo activo
  Widget _buildDrawingModeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            'MODO DIBUJO',
            style: GoogleFonts.robotoCondensed(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Indicador de timestamp actual
  Widget _buildTimestampIndicator() {
    final minutes = _currentVideoSeconds ~/ 60;
    final seconds = _currentVideoSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 1),
      ),
      child: Text(
        timeString,
        style: GoogleFonts.robotoMono(
          color: Colors.cyan,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  /// Timeline de eventos
  Widget _buildEventsTimeline() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black,
          ],
        ),
        border: Border(
          top: BorderSide(color: Colors.cyan.withOpacity(0.3), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.timeline, color: Colors.cyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  'TIMELINE DE EVENTOS (${_events.length})',
                  style: GoogleFonts.robotoCondensed(
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _events.isEmpty
                ? Center(
                    child: Text(
                      'Sin eventos marcados',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(_events[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Card de evento individual
  Widget _buildEventCard(AnalysisEvent event) {
    return GestureDetector(
      onTap: () => _jumpToEvent(event),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan.withOpacity(0.2),
              Colors.blue.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Timestamp
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                event.formattedTimestamp,
                style: GoogleFonts.robotoMono(
                  color: Colors.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Tipo de evento
            Text(
              event.eventTitle ?? event.eventType.toUpperCase(),
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Jugador si existe
            if (event.playerName != null)
              Text(
                event.playerName!,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            // Icono según tipo
            Row(
              children: [
                Icon(
                  event.drawingUrl != null
                      ? Icons.draw
                      : event.voiceTranscript != null
                          ? Icons.mic
                          : Icons.circle,
                  color: Colors.cyan.withOpacity(0.6),
                  size: 14,
                ),
                if (event.drawingUrl != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.image,
                    color: Colors.yellow.withOpacity(0.6),
                    size: 14,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Botones flotantes
  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de Voz
        GestureDetector(
          onLongPressStart: (_) => _startVoiceRecording(),
          onLongPressEnd: (_) => _stopVoiceRecording(),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isRecording
                    ? [Colors.red, Colors.redAccent]
                    : [Colors.cyan, Colors.blue],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : Colors.cyan).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _isRecording ? 'GRABANDO...' : 'Mantén pulsado',
          style: GoogleFonts.robotoCondensed(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.cyan),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.cyan.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
