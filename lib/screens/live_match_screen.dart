import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/analysis_event_model.dart';
import 'package:myapp/services/voice_tagging_service.dart';
import 'package:myapp/services/supabase_service.dart';

/// ============================================================
/// PANTALLA: LiveMatchScreen (Modo Banquillo)
/// ============================================================
/// Registro de eventos en tiempo real durante el partido
/// SIN video, usando solo un cronómetro (Stopwatch)
/// Diseño minimalista y alto contraste para visibilidad al sol
/// ============================================================

class LiveMatchScreen extends StatefulWidget {
  final String matchId;
  final String teamId;
  final String? opponentName;

  const LiveMatchScreen({
    super.key,
    required this.matchId,
    required this.teamId,
    this.opponentName,
  });

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  // Servicios
  final VoiceTaggingService _voiceService = voiceTaggingService;
  final SupabaseService _supabaseService = SupabaseService();

  // Cronómetro
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _currentSeconds = 0;

  // Estado
  bool _isRunning = false;
  bool _isRecording = false;
  bool _isInitialized = false;

  // Datos
  List<AnalysisEvent> _events = [];
  List<Player> _teamPlayers = [];

  // Contadores rápidos
  final Map<String, int> _eventCounts = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _voiceService.dispose();
    super.dispose();
  }

  /// Inicializa el servicio
  Future<void> _initialize() async {
    try {
      // Cargar jugadores del equipo
      final playersData = await _supabaseService.getTeamPlayers(widget.teamId);
      _teamPlayers = playersData.map((data) => Player.fromJson(data)).toList();
      _voiceService.setTeamPlayers(_teamPlayers);

      // Inicializar reconocimiento de voz
      await _voiceService.initialize();

      // Cargar eventos existentes (por si se cerró la app)
      await _loadEvents();

      setState(() {
        _isInitialized = true;
      });

      debugPrint('✅ LiveMatchScreen inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando: $e');
      _showError('Error al inicializar');
    }
  }

  /// Carga eventos existentes del partido
  Future<void> _loadEvents() async {
    try {
      final response = await Supabase.instance.client
          .from('analysis_events_detailed')
          .select()
          .eq('match_id', widget.matchId)
          .order('match_timestamp', ascending: true);

      setState(() {
        _events = (response as List)
            .map((json) => AnalysisEvent.fromJson(json))
            .toList();
        _updateEventCounts();
      });

      debugPrint('📋 Eventos cargados: ${_events.length}');
    } catch (e) {
      debugPrint('❌ Error cargando eventos: $e');
    }
  }

  /// Actualiza los contadores de eventos
  void _updateEventCounts() {
    _eventCounts.clear();
    for (final event in _events) {
      _eventCounts[event.eventType] = (_eventCounts[event.eventType] ?? 0) + 1;
    }
  }

  // ==========================================
  // CRONÓMETRO
  // ==========================================

  /// Inicia el cronómetro
  void _startStopwatch() {
    setState(() {
      _isRunning = true;
    });

    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _currentSeconds = _stopwatch.elapsed.inSeconds;
      });
    });

    debugPrint('⏱️ Cronómetro iniciado');
  }

  /// Pausa el cronómetro
  void _pauseStopwatch() {
    setState(() {
      _isRunning = false;
    });

    _stopwatch.stop();
    _timer?.cancel();

    debugPrint('⏸️ Cronómetro pausado en ${_formatTime(_currentSeconds)}');
  }

  /// Reinicia el cronómetro
  void _resetStopwatch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          '⚠️ Reiniciar Cronómetro',
          style: GoogleFonts.oswald(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro? Se perderán los eventos registrados.',
          style: GoogleFonts.roboto(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isRunning = false;
                _currentSeconds = 0;
              });
              _stopwatch.reset();
              _timer?.cancel();
              debugPrint('🔄 Cronómetro reiniciado');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  /// Formatea segundos a mm:ss
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ==========================================
  // REGISTRO DE EVENTOS
  // ==========================================

  /// Registra un evento manualmente
  Future<void> _registerEvent(String eventType, {String? playerId}) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await Supabase.instance.client.from('analysis_events').insert({
        'match_id': widget.matchId,
        'team_id': widget.teamId,
        'coach_id': userId,
        'player_id': playerId,
        'match_timestamp': _currentSeconds,
        'video_timestamp': null, // NULL = Modo Live
        'event_type': eventType,
        'event_title': _getEventTitle(eventType),
      });

      await _loadEvents();

      _showSuccess('Evento registrado: ${_getEventTitle(eventType)}');

      debugPrint('✅ Evento registrado: $eventType en ${_formatTime(_currentSeconds)}');
    } catch (e) {
      debugPrint('❌ Error registrando evento: $e');
      _showError('Error al registrar evento');
    }
  }

  /// Inicia el reconocimiento de voz
  Future<void> _startVoiceRecording() async {
    if (!_isInitialized) return;

    setState(() {
      _isRecording = true;
    });

    await _voiceService.startListening(
      onResult: (result) {
        _handleVoiceResult(result);
      },
    );
  }

  /// Detiene el reconocimiento de voz
  Future<void> _stopVoiceRecording() async {
    setState(() {
      _isRecording = false;
    });

    await _voiceService.stopListening();
  }

  /// Procesa el resultado de voz
  Future<void> _handleVoiceResult(VoiceTagResult result) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await Supabase.instance.client.from('analysis_events').insert({
        'match_id': widget.matchId,
        'team_id': widget.teamId,
        'coach_id': userId,
        'player_id': result.detectedPlayerId,
        'match_timestamp': _currentSeconds,
        'video_timestamp': null, // NULL = Modo Live
        'event_type': result.detectedEventType ?? 'voice_note',
        'event_title': result.transcript,
        'voice_transcript': result.transcript,
        'voice_confidence': result.confidence,
        'tags': result.suggestedTags,
      });

      await _loadEvents();

      String message = '🎤 "${result.transcript}"';
      if (result.detectedPlayerName != null) {
        message += '\n👤 ${result.detectedPlayerName}';
      }
      _showSuccess(message);

      debugPrint('✅ Evento de voz guardado');
    } catch (e) {
      debugPrint('❌ Error guardando evento de voz: $e');
      _showError('Error al registrar');
    }
  }

  /// Obtiene el título de un evento por su tipo
  String _getEventTitle(String eventType) {
    const titles = {
      'gol': 'Gol',
      'tiro': 'Tiro',
      'pase': 'Pase Clave',
      'perdida': 'Pérdida',
      'robo': 'Recuperación',
      'falta': 'Falta',
      'corner': 'Córner',
      'tarjeta_amarilla': 'Tarjeta Amarilla',
      'tarjeta_roja': 'Tarjeta Roja',
      'cambio': 'Sustitución',
      'lesion': 'Lesión',
    };
    return titles[eventType] ?? eventType;
  }

  // ==========================================
  // UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.cyan),
              const SizedBox(height: 16),
              Text(
                'Preparando modo Live...',
                style: GoogleFonts.roboto(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Cronómetro gigante
            _buildStopwatchSection(),

            const Divider(color: Colors.cyan, thickness: 2),

            // Botones de acción rápida
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 24),
                    _buildEventCounters(),
                  ],
                ),
              ),
            ),

            // Botón de voz flotante
            _buildVoiceButton(),
          ],
        ),
      ),
    );
  }

  /// AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MODO LIVE',
            style: GoogleFonts.oswald(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.cyan,
            ),
          ),
          if (widget.opponentName != null)
            Text(
              'vs ${widget.opponentName}',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _resetStopwatch,
          icon: const Icon(Icons.refresh, color: Colors.red),
          tooltip: 'Reiniciar',
        ),
      ],
    );
  }

  /// Sección del cronómetro
  Widget _buildStopwatchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.cyan.withValues(alpha: 0.2),
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          // Tiempo
          Text(
            _formatTime(_currentSeconds),
            style: GoogleFonts.orbitron(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
              shadows: [
                Shadow(
                  blurRadius: 20,
                  color: Colors.cyan.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Controles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause
              ElevatedButton(
                onPressed: _isRunning ? _pauseStopwatch : _startStopwatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.orange : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRunning ? 'PAUSAR' : 'INICIAR',
                      style: GoogleFonts.oswald(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Grid de acciones rápidas
  Widget _buildQuickActionsGrid() {
    final actions = [
      _ActionButton(
        title: 'GOL',
        icon: Icons.sports_soccer,
        color: Colors.green,
        onTap: () => _registerEvent('gol'),
      ),
      _ActionButton(
        title: 'TIRO',
        icon: Icons.adjust,
        color: Colors.blue,
        onTap: () => _registerEvent('tiro'),
      ),
      _ActionButton(
        title: 'PASE',
        icon: Icons.swap_calls,
        color: Colors.cyan,
        onTap: () => _registerEvent('pase'),
      ),
      _ActionButton(
        title: 'PÉRDIDA',
        icon: Icons.warning,
        color: Colors.orange,
        onTap: () => _registerEvent('perdida'),
      ),
      _ActionButton(
        title: 'ROBO',
        icon: Icons.sports_kabaddi,
        color: Colors.purple,
        onTap: () => _registerEvent('robo'),
      ),
      _ActionButton(
        title: 'FALTA',
        icon: Icons.block,
        color: Colors.red,
        onTap: () => _registerEvent('falta'),
      ),
      _ActionButton(
        title: 'CÓRNER',
        icon: Icons.flag,
        color: Colors.amber,
        onTap: () => _registerEvent('corner'),
      ),
      _ActionButton(
        title: 'TARJETA',
        icon: Icons.style,
        color: Colors.yellow,
        onTap: () => _registerEvent('tarjeta_amarilla'),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: actions.map((action) {
        return GestureDetector(
          onTap: action.onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  action.color.withValues(alpha: 0.3),
                  action.color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: action.color.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  size: 32,
                  color: action.color,
                ),
                const SizedBox(height: 4),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Contadores de eventos
  Widget _buildEventCounters() {
    if (_events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Sin eventos registrados',
          style: GoogleFonts.roboto(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTADÍSTICAS DEL PARTIDO',
            style: GoogleFonts.oswald(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.cyan,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _eventCounts.entries.map((entry) {
              return Chip(
                backgroundColor: Colors.grey[850],
                side: BorderSide(color: Colors.cyan.withValues(alpha: 0.3)),
                label: Text(
                  '${_getEventTitle(entry.key)}: ${entry.value}',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Botón de voz flotante
  Widget _buildVoiceButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: GestureDetector(
        onLongPress: _startVoiceRecording,
        onLongPressUp: _stopVoiceRecording,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isRecording
                  ? [Colors.red, Colors.red[800]!]
                  : [Colors.cyan, Colors.blue],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_isRecording ? Colors.red : Colors.cyan).withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                _isRecording ? 'ESCUCHANDO...' : 'MANTÉN PARA HABLAR',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SNACKBARS
  // ==========================================

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// ============================================================
/// CLASE AUXILIAR: ActionButton
/// ============================================================

class _ActionButton {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
