import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/models/alignment_model.dart' as alignment_model;
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/tactical_session_model.dart';
import 'package:myapp/models/formation_model.dart';
import 'package:myapp/models/player_analysis_video_model.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class TacticBoardProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final DataService _dataService = DataService();
  final SupabaseService _supabaseService = SupabaseService();

  TacticBoardProvider() {
    _initializeData();
  }

  // State
  List<Player> _allPlayers = [];
  List<alignment_model.Alignment> _alignments = [];
  alignment_model.Alignment? _selectedAlignment;
  List<Player> _starters = [];
  List<Player> _substitutes = [];
  Map<String, Offset> _starterPositions = {};
  Offset _ballPosition = const Offset(180, 350);
  bool _isDrawingMode = false;
  List<List<Offset?>> _lines = [];
  List<Offset?> _currentLine = [];
  List<TacticalSession> _sessions = [];
  TacticalSession? _selectedSession;
  final List<Formation> _formations = [];
  bool _isLoading = true;

  // Estado para sustituciones
  Player? _selectedPlayerForSubstitution;
  bool _isSubstitutionMode = false;

  // Configuración de movilidad mejorada
  bool _enableSnapping = true;
  final double _snapDistance = 20.0; // Distancia para activar el snap magnético

  // Getters
  bool get isLoading => _isLoading;
  List<Player> get allPlayers => _allPlayers;
  List<alignment_model.Alignment> get alignments => _alignments;
  alignment_model.Alignment? get selectedAlignment => _selectedAlignment;
  List<Player> get starters => _starters;
  List<Player> get substitutes => _substitutes;
  Map<String, Offset> get starterPositions => _starterPositions;
  Offset get ballPosition => _ballPosition;
  bool get isDrawingMode => _isDrawingMode;
  List<List<Offset?>> get lines => _lines;
  List<Offset?> get currentLine => _currentLine;
  List<TacticalSession> get sessions => _sessions;
  TacticalSession? get selectedSession => _selectedSession;
  List<Formation> get formations => _formations;
  Player? get selectedPlayerForSubstitution => _selectedPlayerForSubstitution;
  bool get isSubstitutionMode => _isSubstitutionMode;

  // --- INICIALIZACIÓN ROBUSTA ---
  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadPlayersFromSupabase();
      await _loadAlignmentsFromSupabase(); // Cargar alineaciones
      _loadSampleData();
      _autoLoadStartersAndSubs();
    } catch (e, s) {
      developer.log(
        'Error fatal durante la inicialización',
        error: e,
        stackTrace: s,
        name: 'TacticBoardProvider',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene el teamId del usuario actual
  Future<String?> _getCurrentTeamId() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabaseService.client
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
      developer.log(
        'Error obteniendo teamId',
        error: e,
        name: 'TacticBoardProvider',
      );
      return null;
    }
  }

  /// Carga alineaciones desde Supabase
  Future<void> _loadAlignmentsFromSupabase() async {
    try {
      final teamId = await _getCurrentTeamId();
      if (teamId == null) {
        developer.log(
          'No se pudo obtener teamId, usando alineaciones por defecto',
          name: 'TacticBoardProvider',
        );
        _alignments = _getDefaultAlignments();
        return;
      }

      final alignmentsData = await _supabaseService.getAlignments(teamId);
      _alignments = alignmentsData
          .map((data) => alignment_model.Alignment.fromJson(data))
          .toList();
      developer.log(
        'Alineaciones cargadas desde Supabase: ${_alignments.length}',
        name: 'TacticBoardProvider',
      );
    } catch (e, s) {
      developer.log(
        'Error cargando alineaciones',
        error: e,
        stackTrace: s,
        name: 'TacticBoardProvider',
      );
      // Si falla, crear alineaciones por defecto
      _alignments = _getDefaultAlignments();
    }
  }

  List<alignment_model.Alignment> _getDefaultAlignments() {
    return [
      alignment_model.Alignment(
        id: '1',
        name: 'Formación 4-4-2',
        formation: '4-4-2',
      ),
      alignment_model.Alignment(
        id: '2',
        name: 'Formación 4-3-3',
        formation: '4-3-3',
      ),
      alignment_model.Alignment(
        id: '3',
        name: 'Formación 3-5-2',
        formation: '3-5-2',
      ),
    ];
  }

  /// Carga automática de titulares y suplentes según su estado en la base de datos
  void _autoLoadStartersAndSubs() {
    _starters.clear();
    _substitutes.clear();
    _starterPositions.clear();

    // Separar jugadores por estado
    final starterPlayers = _allPlayers
        .where((p) => p.matchStatus == MatchStatus.starter)
        .toList();
    final subPlayers = _allPlayers
        .where((p) => p.matchStatus == MatchStatus.sub)
        .toList();

    // Posiciones predeterminadas en formación 4-4-2
    final defaultPositions = [
      const Offset(180, 600), // Portero
      const Offset(80, 480), // Defensa 1
      const Offset(140, 500), // Defensa 2
      const Offset(220, 500), // Defensa 3
      const Offset(280, 480), // Defensa 4
      const Offset(80, 340), // Medio 1
      const Offset(140, 360), // Medio 2
      const Offset(220, 360), // Medio 3
      const Offset(280, 340), // Medio 4
      const Offset(140, 200), // Delantero 1
      const Offset(220, 200), // Delantero 2
    ];

    // Colocar titulares en el campo
    for (int i = 0; i < starterPlayers.length && i < 11; i++) {
      _starters.add(starterPlayers[i]);
      _starterPositions[starterPlayers[i].name] = defaultPositions[i];
    }

    // Colocar suplentes en el banquillo
    _substitutes = subPlayers;

    notifyListeners();
  }

  // --- GESTIÓN DE ALINEACIONES Y SESIONES ---
  void selectAlignment(String alignmentId) {
    final selected = _alignments.firstWhere((a) => a.id == alignmentId);
    _selectedAlignment = selected;
    _selectedSession = null; // Anulamos la sesión para evitar conflictos

    _starters.clear();
    _starterPositions.clear();

    // Si la alineación tiene jugadores asignados a posiciones específicas
    if (selected.playerPositions.isNotEmpty) {
      developer.log(
        'Cargando alineación con ${selected.playerPositions.length} jugadores asignados',
        name: 'TacticBoardProvider',
      );

      for (var entry in selected.playerPositions.entries) {
        final playerId = entry.key;
        final position = entry.value;

        // Buscar jugador por ID
        final player = _allPlayers.firstWhere(
          (p) => p.id == playerId,
          orElse: () => Player(name: '', isStarter: false, image: ''),
        );

        if (player.name.isNotEmpty) {
          _starters.add(player);
          _starterPositions[player.name] = position.offset;
        }
      }

      // Actualizar suplentes (jugadores no asignados)
      _substitutes = _allPlayers
          .where(
            (p) =>
                !_starters.any((s) => s.id == p.id) &&
                p.matchStatus != MatchStatus.unselected,
          )
          .toList();
    } else {
      // Alineación sin jugadores asignados: usar formación por defecto
      developer.log(
        'Cargando alineación con formación por defecto: ${selected.formation}',
        name: 'TacticBoardProvider',
      );
      _loadDefaultFormation(selected.formation);
    }

    notifyListeners();
  }

  /// Carga formación por defecto sin jugadores específicos
  void _loadDefaultFormation(String formation) {
    // Obtener posiciones según la formación
    final positions = _getPositionsForFormation(formation);

    // Priorizar jugadores con estado "starter", pero si no hay suficientes, usar otros
    final starterPlayers = _allPlayers
        .where((p) => p.matchStatus == MatchStatus.starter)
        .toList();

    final otherPlayers = _allPlayers
        .where(
          (p) =>
              p.matchStatus != MatchStatus.starter &&
              p.matchStatus != MatchStatus.unselected,
        )
        .toList();

    // Combinar: primero titulares, luego otros si faltan
    final playersToPlace = [
      ...starterPlayers,
      ...otherPlayers,
    ].take(11).toList();

    // Colocar jugadores en las posiciones de la formación
    for (int i = 0; i < playersToPlace.length && i < positions.length; i++) {
      final player = playersToPlace[i];
      _starters.add(player);
      _starterPositions[player.name] = positions[i];
    }

    // Suplentes = todos los jugadores EXCEPTO los que ya están en el campo
    _substitutes = _allPlayers
        .where(
          (p) =>
              !_starters.any((s) => s.id == p.id || s.name == p.name) &&
              p.matchStatus != MatchStatus.unselected,
        )
        .toList();

    developer.log(
      'Formación $formation cargada: ${_starters.length} titulares, ${_substitutes.length} suplentes',
      name: 'TacticBoardProvider',
    );
  }

  /// Obtiene las posiciones según la formación (ajustadas para campo grande ~1300x700px)
  List<Offset> _getPositionsForFormation(String formation) {
    // Dimensiones aproximadas del campo visual (ajustables)
    const fieldWidth = 1300.0;
    const fieldHeight = 700.0;

    // Márgenes desde los bordes
    const marginSide = 100.0;
    const marginTop = 80.0;
    const marginBottom = 80.0;

    // Alto útil para distribuir jugadores
    const usableHeight = fieldHeight - marginTop - marginBottom;

    // Centro horizontal
    const centerX = fieldWidth / 2;

    // Posiciones verticales (de arriba hacia abajo: atacantes, medios, defensas, portero)
    const attackY = marginTop + usableHeight * 0.15; // 15% desde arriba
    const midY = marginTop + usableHeight * 0.45; // 45% desde arriba
    const defenseY = marginTop + usableHeight * 0.75; // 75% desde arriba
    const goalkeeperY =
        fieldHeight - marginBottom - 30; // Cerca del borde inferior

    switch (formation) {
      case '4-3-3':
        return [
          Offset(centerX, goalkeeperY), // Portero (centro)
          Offset(marginSide + 80, defenseY), // Defensa 1 (izq)
          Offset(centerX - 100, defenseY + 20), // Defensa 2 (centro-izq)
          Offset(centerX + 100, defenseY + 20), // Defensa 3 (centro-der)
          Offset(fieldWidth - marginSide - 80, defenseY), // Defensa 4 (der)
          Offset(marginSide + 120, midY), // Medio 1 (izq)
          Offset(centerX, midY + 20), // Medio 2 (centro)
          Offset(fieldWidth - marginSide - 120, midY), // Medio 3 (der)
          Offset(marginSide + 80, attackY), // Delantero 1 (izq)
          Offset(centerX, attackY - 20), // Delantero 2 (centro)
          Offset(fieldWidth - marginSide - 80, attackY), // Delantero 3 (der)
        ];
      case '3-5-2':
        return [
          Offset(centerX, goalkeeperY), // Portero (centro)
          Offset(marginSide + 150, defenseY + 20), // Defensa 1 (izq)
          Offset(centerX, defenseY + 40), // Defensa 2 (centro)
          Offset(
            fieldWidth - marginSide - 150,
            defenseY + 20,
          ), // Defensa 3 (der)
          Offset(marginSide + 80, midY), // Medio 1 (extremo izq)
          Offset(marginSide + 220, midY + 20), // Medio 2 (izq)
          Offset(centerX, midY + 20), // Medio 3 (centro)
          Offset(fieldWidth - marginSide - 220, midY + 20), // Medio 4 (der)
          Offset(fieldWidth - marginSide - 80, midY), // Medio 5 (extremo der)
          Offset(centerX - 150, attackY), // Delantero 1 (izq)
          Offset(centerX + 150, attackY), // Delantero 2 (der)
        ];
      default: // 4-4-2
        return [
          Offset(centerX, goalkeeperY), // Portero (centro)
          Offset(marginSide + 80, defenseY), // Defensa 1 (izq)
          Offset(centerX - 100, defenseY + 20), // Defensa 2 (centro-izq)
          Offset(centerX + 100, defenseY + 20), // Defensa 3 (centro-der)
          Offset(fieldWidth - marginSide - 80, defenseY), // Defensa 4 (der)
          Offset(marginSide + 80, midY), // Medio 1 (izq)
          Offset(centerX - 100, midY + 20), // Medio 2 (centro-izq)
          Offset(centerX + 100, midY + 20), // Medio 3 (centro-der)
          Offset(fieldWidth - marginSide - 80, midY), // Medio 4 (der)
          Offset(centerX - 150, attackY + 20), // Delantero 1 (izq)
          Offset(centerX + 150, attackY + 20), // Delantero 2 (der)
        ];
    }
  }

  void loadTacticalSession(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    _selectedSession = session;
    _selectedAlignment = null; // Anulamos la alineación para evitar conflictos

    _starters = List.from(session.starters);
    _substitutes = List.from(session.substitutes);
    _starterPositions = Map.from(session.starterPositions);
    _ballPosition = session.ballPosition;
    _lines = List.from(session.lines.map((line) => List.from(line)));
    notifyListeners();
  }

  void saveTacticalSession(String name) {
    final newSession = TacticalSession(
      id: _uuid.v4(),
      name: name,
      starters: List.from(_starters),
      substitutes: List.from(_substitutes),
      starterPositions: Map.from(_starterPositions),
      ballPosition: _ballPosition,
      lines: List.from(_lines.map((line) => List.from(line))),
    );
    _sessions.add(newSession);
    _selectedSession = newSession;
    notifyListeners();
  }

  // --- GESTIÓN DE FORMACIONES ---
  void saveFormation(String name) {
    final newFormation = Formation(
      id: _uuid.v4(),
      name: name,
      playerPositions: Map.from(_starterPositions),
    );
    _formations.add(newFormation);
    notifyListeners();
  }

  void loadFormation(String formationId) {
    final formation = _formations.firstWhere((f) => f.id == formationId);
    _starterPositions = Map.from(formation.playerPositions);
    notifyListeners();
  }

  // --- GESTIÓN DE ALINEACIONES PERSONALIZADAS ---

  /// Guarda una alineación personalizada
  Future<bool> saveAlignment(alignment_model.Alignment alignment) async {
    try {
      final teamId = await _getCurrentTeamId();
      if (teamId == null) {
        developer.log(
          'No se pudo obtener teamId para guardar alineación',
          name: 'TacticBoardProvider',
        );
        return false;
      }

      final alignmentData = alignment.toJson();
      alignmentData['team_id'] = teamId;
      final alignmentId = await _supabaseService.saveAlignment(alignmentData);
      if (alignmentId.isNotEmpty) {
        // Actualizar lista de alineaciones
        final updatedAlignment = alignment.copyWith(id: alignmentId);
        final index = _alignments.indexWhere((a) => a.id == alignment.id);
        if (index >= 0) {
          _alignments[index] = updatedAlignment;
        } else {
          _alignments.add(updatedAlignment);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      developer.log(
        'Error guardando alineación',
        error: e,
        name: 'TacticBoardProvider',
      );
      return false;
    }
  }

  /// Elimina una alineación personalizada
  Future<bool> deleteAlignment(String alignmentId) async {
    try {
      final success = await _supabaseService.deleteAlignment(alignmentId);
      if (success) {
        _alignments.removeWhere((a) => a.id == alignmentId);
        if (_selectedAlignment?.id == alignmentId) {
          _selectedAlignment = null;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      developer.log(
        'Error eliminando alineación',
        error: e,
        name: 'TacticBoardProvider',
      );
      return false;
    }
  }

  /// Crea una nueva alineación desde la configuración actual del campo
  alignment_model.Alignment createAlignmentFromCurrentSetup(
    String name,
    String formation,
  ) {
    final playerPositions = <String, alignment_model.PlayerPosition>{};

    for (var player in _starters) {
      if (player.id != null && _starterPositions.containsKey(player.name)) {
        playerPositions[player.id!] = alignment_model.PlayerPosition(
          offset: _starterPositions[player.name]!,
          role: player.role,
        );
      }
    }

    return alignment_model.Alignment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      formation: formation,
      playerPositions: playerPositions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCustom: true,
    );
  }

  // --- GESTIÓN DE JUGADORES ---
  void addStarter(Player player, Offset position) {
    if (!_starters.any((p) => p.name == player.name)) {
      _starters.add(player);
      _substitutes.removeWhere((p) => p.name == player.name);
      _starterPositions[player.name] = position;
      notifyListeners();
    }
  }

  void removeStarter(Player player) {
    if (_starters.any((p) => p.name == player.name)) {
      _starters.remove(player);
      if (!_substitutes.any((sub) => sub.name == player.name)) {
        _substitutes.add(player);
      }
      _starterPositions.remove(player.name);
      notifyListeners();
    }
  }

  void updateStarterPosition(Player player, Offset newPosition) {
    if (_starterPositions.containsKey(player.name)) {
      // Aplicar snapping magnético si está habilitado
      final finalPosition = _enableSnapping
          ? _applySnapping(newPosition)
          : newPosition;
      _starterPositions[player.name] = finalPosition;
      notifyListeners();
    }
  }

  /// Sistema de Snapping Magnético (Ayuda de Alineación)
  Offset _applySnapping(Offset position) {
    // Posiciones clave en una formación típica (snap points)
    final snapPoints = [
      // DEFENSA
      const Offset(80, 480), const Offset(140, 500),
      const Offset(220, 500), const Offset(280, 480),
      const Offset(180, 520), // Defensa central
      // MEDIO CAMPO
      const Offset(80, 340), const Offset(140, 360),
      const Offset(180, 360), const Offset(220, 360),
      const Offset(280, 340),

      // ATAQUE
      const Offset(80, 180), const Offset(140, 200),
      const Offset(180, 180), const Offset(220, 200),
      const Offset(280, 180),

      // PORTERO
      const Offset(180, 600),
    ];

    // Buscar el snap point más cercano
    Offset? closestSnapPoint;
    double minDistance = double.infinity;

    for (final snapPoint in snapPoints) {
      final distance = (position - snapPoint).distance;
      if (distance < minDistance && distance < _snapDistance) {
        minDistance = distance;
        closestSnapPoint = snapPoint;
      }
    }

    // Si hay un snap point cercano, usarlo. Si no, usar la posición original
    return closestSnapPoint ?? position;
  }

  /// Activar/Desactivar snapping magnético
  void toggleSnapping() {
    _enableSnapping = !_enableSnapping;
    notifyListeners();
  }

  bool get enableSnapping => _enableSnapping;

  // --- MÉTODOS DE DIBUJO ---
  void toggleDrawingMode() {
    _isDrawingMode = !_isDrawingMode;
    notifyListeners();
  }

  void clearDrawing() {
    _lines.clear();
    _currentLine.clear();
    notifyListeners();
  }

  void onPanStart(Offset position) {
    if (!_isDrawingMode) return;
    _currentLine = [position];
    notifyListeners();
  }

  void onPanUpdate(Offset position) {
    if (!_isDrawingMode) return;
    _currentLine.add(position);
    notifyListeners();
  }

  void onPanEnd() {
    if (!_isDrawingMode) return;
    _lines.add(List.from(_currentLine));
    _currentLine = [];
    notifyListeners();
  }

  void updateBallPosition(Offset newPosition) {
    _ballPosition = newPosition;
    notifyListeners();
  }

  // --- CARGA DE DATOS ---
  Future<void> _loadPlayers() async {
    final teams = await _dataService.loadTeams();
    _allPlayers = teams.expand((team) => team.players).toList();
  }

  /// Carga jugadores desde Supabase con sus estados de convocatoria
  Future<void> _loadPlayersFromSupabase() async {
    try {
      final teamId = await _getCurrentTeamId();
      if (teamId == null) {
        developer.log(
          'No se pudo obtener teamId, usando datos locales',
          name: 'TacticBoardProvider',
        );
        await _loadPlayers();
        return;
      }

      final playersData = await _supabaseService.getTeamPlayers(teamId);
      _allPlayers = playersData
          .map((data) => Player.fromJson(data))
          .toList();
      developer.log(
        'Jugadores cargados desde Supabase: ${_allPlayers.length}',
        name: 'TacticBoardProvider',
      );
    } catch (e, s) {
      developer.log(
        'Error cargando jugadores desde Supabase, usando datos locales',
        error: e,
        stackTrace: s,
        name: 'TacticBoardProvider',
      );
      // Fallback a datos locales si falla Supabase
      await _loadPlayers();
    }
  }

  void _loadSampleData() {
    // Solo cargar alineaciones de ejemplo si no hay ninguna cargada desde Supabase
    if (_alignments.isEmpty) {
      _alignments = [
        alignment_model.Alignment(
          id: _uuid.v4(),
          name: '4-3-3 Ofensivo',
          formation: '4-3-3',
        ),
        alignment_model.Alignment(
          id: _uuid.v4(),
          name: '4-4-2 Clásico',
          formation: '4-4-2',
        ),
        alignment_model.Alignment(
          id: _uuid.v4(),
          name: '5-4-1 Defensivo',
          formation: '5-4-1',
        ),
        alignment_model.Alignment(
          id: _uuid.v4(),
          name: '3-5-2 Moderno',
          formation: '3-5-2',
        ),
      ];
    }

    if (_allPlayers.length >= 2) {
      final sampleStarters = _allPlayers.take(2).toList();
      final sampleSubstitutes = _allPlayers
          .where((p) => !sampleStarters.contains(p))
          .toList();

      _sessions = [
        TacticalSession(
          id: _uuid.v4(),
          name: 'Jugada de Córner',
          starters: sampleStarters,
          substitutes: sampleSubstitutes,
          starterPositions: {
            sampleStarters[0].name: const Offset(50, 100),
            sampleStarters[1].name: const Offset(150, 200),
          },
          ballPosition: const Offset(50, 50),
          lines: [
            [
              const Offset(55, 55),
              const Offset(100, 120),
              const Offset(155, 205),
            ],
          ],
        ),
      ];
    }
  }

  // ==========================================
  // SISTEMA DE SUSTITUCIONES
  // ==========================================

  /// Activa el modo de sustitución y selecciona un jugador
  void selectPlayerForSubstitution(Player player) {
    if (_selectedPlayerForSubstitution?.name == player.name) {
      // Si se vuelve a tocar el mismo jugador, se deselecciona
      _selectedPlayerForSubstitution = null;
      _isSubstitutionMode = false;
    } else {
      _selectedPlayerForSubstitution = player;
      _isSubstitutionMode = true;
    }
    notifyListeners();
  }

  /// Realiza el intercambio entre dos jugadores
  Future<void> substitutePlayer(Player targetPlayer) async {
    if (_selectedPlayerForSubstitution == null) return;
    if (_selectedPlayerForSubstitution!.name == targetPlayer.name) return;

    final player1 = _selectedPlayerForSubstitution!;
    final player2 = targetPlayer;

    // Verificar que uno sea titular y otro suplente
    final isPlayer1Starter = _starters.any((p) => p.name == player1.name);
    final isPlayer2Starter = _starters.any((p) => p.name == player2.name);

    if (isPlayer1Starter == isPlayer2Starter) {
      // Ambos son titulares o ambos son suplentes, no se puede hacer el cambio
      developer.log(
        'No se puede sustituir: ambos jugadores tienen el mismo estado',
        name: 'TacticBoardProvider',
      );
      _selectedPlayerForSubstitution = null;
      _isSubstitutionMode = false;
      notifyListeners();
      return;
    }

    // Determinar quién sale y quién entra
    final playerOut = isPlayer1Starter ? player1 : player2;
    final playerIn = isPlayer1Starter ? player2 : player1;

    // Guardar la posición del jugador que sale
    final savedPosition =
        _starterPositions[playerOut.name] ?? const Offset(180, 350);

    // Realizar el cambio localmente
    _starters.removeWhere((p) => p.name == playerOut.name);
    _substitutes.removeWhere((p) => p.name == playerIn.name);

    _starters.add(playerIn);
    _substitutes.add(playerOut);

    _starterPositions.remove(playerOut.name);
    _starterPositions[playerIn.name] = savedPosition;

    // Actualizar en Supabase
    if (playerIn.id != null && playerOut.id != null) {
      try {
        await _supabaseService.updatePlayerMatchStatus(
          playerIn.id!,
          'starter',
        );
        await _supabaseService.updatePlayerMatchStatus(
          playerOut.id!,
          'sub',
        );
        developer.log(
          'Sustitución actualizada en Supabase: ${playerIn.name} entra por ${playerOut.name}',
          name: 'TacticBoardProvider',
        );
      } catch (e) {
        developer.log(
          'Error actualizando sustitución en Supabase',
          error: e,
          name: 'TacticBoardProvider',
        );
      }
    }

    // Reiniciar el modo de sustitución
    _selectedPlayerForSubstitution = null;
    _isSubstitutionMode = false;
    notifyListeners();
  }

  /// Cancela el modo de sustitución
  void cancelSubstitution() {
    _selectedPlayerForSubstitution = null;
    _isSubstitutionMode = false;
    notifyListeners();
  }

  /// Refresca los jugadores desde la base de datos
  Future<void> refreshPlayers() async {
    _isLoading = true;
    notifyListeners();

    await _loadPlayersFromSupabase();
    _autoLoadStartersAndSubs();

    _isLoading = false;
    notifyListeners();
  }

  // ==========================================
  // GESTIÓN DE VIDEOS TÁCTICOS
  // ==========================================

  /// Obtiene los videos adjuntos a la sesión táctica actual
  Future<List<TacticalVideo>> getCurrentSessionVideos() async {
    if (_selectedSession == null) return [];
    try {
      final videosData = await _supabaseService.getTacticalSessionVideos(
        _selectedSession!.id,
      );
      return videosData
          .map((data) => TacticalVideo.fromJson(data))
          .toList();
    } catch (e) {
      developer.log(
        'Error obteniendo videos de la sesión',
        error: e,
        name: 'TacticBoardProvider',
      );
      return [];
    }
  }

  /// Obtiene los videos adjuntos a la alineación actual
  Future<List<TacticalVideo>> getCurrentAlignmentVideos() async {
    if (_selectedAlignment == null) return [];
    try {
      final videosData = await _supabaseService.getAlignmentVideos(
        _selectedAlignment!.id,
      );
      return videosData
          .map((data) => TacticalVideo.fromJson(data))
          .toList();
    } catch (e) {
      developer.log(
        'Error obteniendo videos de la alineación',
        error: e,
        name: 'TacticBoardProvider',
      );
      return [];
    }
  }
}
