import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/player_stats.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:myapp/data/team_rosters.dart';
import 'package:myapp/services/file_management_service.dart';
import 'package:myapp/screens/player_profile_screen.dart';

class SquadManagementScreen extends StatefulWidget {
  const SquadManagementScreen({super.key});

  @override
  State<SquadManagementScreen> createState() => _SquadManagementScreenState();
}

class _SquadManagementScreenState extends State<SquadManagementScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final FileManagementService _fileService = FileManagementService();
  List<Player> _players = [];
  bool _loading = true;
  final Map<String, bool> _uploadingPlayers =
      {}; // Map para trackear jugadores con upload en progreso
  Map<String, int> _statusCounts = {
    'starters': 0,
    'substitutes': 0,
    'unselected': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

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

  // Verificar si el equipo actual es San Marcelino
  bool _isSanMarcelinoTeam = false;
  String? _currentTeamName;

  Future<void> _loadPlayers() async {
    setState(() => _loading = true);
    try {
      // Obtener plantilla de San Marcelino por defecto
      final sanMarcelinoRoster = allTeamRosters.firstWhere(
        (roster) => roster.teamName.contains('San Marcelino'),
        orElse: () => allTeamRosters.first,
      );

      // Intentar cargar de Supabase primero
      final teamId = await _getCurrentTeamId();
      List<Player> players = [];
      Map<String, int> counts = {
        'starters': 0,
        'substitutes': 0,
        'unselected': 0,
      };
      bool isSanMarcelino = false;

      if (teamId != null) {
        debugPrint('✅ TeamId obtenido: $teamId');

        // Obtener nombre del equipo para verificar si es San Marcelino
        try {
          final teamData = await Supabase.instance.client
              .from('teams')
              .select('name')
              .eq('id', teamId)
              .maybeSingle();

          if (teamData != null) {
            _currentTeamName = teamData['name'] as String?;
            isSanMarcelino =
                _currentTeamName?.contains('San Marcelino') ?? false;
            debugPrint(
              '📋 Nombre del equipo: $_currentTeamName (Es San Marcelino: $isSanMarcelino)',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error obteniendo nombre del equipo: $e');
        }

        final playersData = await _supabaseService.getTeamPlayers(teamId);
        debugPrint('📊 Jugadores obtenidos de BD: ${playersData.length}');

        if (playersData.isNotEmpty) {
          // Usar datos de Supabase si hay jugadores
          players = playersData.map((data) {
            final profile = data['profiles'] as Map<String, dynamic>?;
            if (profile != null) {
              final player = Player.fromSupabaseProfile(
                profile,
                matchStatus: data['match_status'] as String?,
                statusNote: data['status_note'] as String?,
              );
              // Marcar si es de San Marcelino para mostrar ficha completa
              return player;
            } else {
              return Player(
                id: data['user_id'] as String?,
                name: data['user_id'] as String? ?? 'Jugador desconocido',
                image: 'assets/players/default.png',
                isStarter: data['match_status'] == 'starter',
                matchStatus: Player.parseMatchStatus(data['match_status']),
                statusNote: data['status_note'] as String?,
              );
            }
          }).toList();

          counts = await _supabaseService.getPlayersCountByStatus(teamId);
        }
      }

      // Si no hay jugadores en BD, usar plantilla de San Marcelino por defecto
      if (players.isEmpty) {
        debugPrint('📋 Cargando plantilla de San Marcelino por defecto');
        isSanMarcelino = true;

        // Crear jugadores desde la plantilla de San Marcelino con estadísticas completas
        final allSanMarcelinoPlayers = [
          ...sanMarcelinoRoster.starters,
          ...sanMarcelinoRoster.substitutes,
        ];

        players = allSanMarcelinoPlayers.asMap().entries.map((entry) {
          final index = entry.key;
          final playerInfo = entry.value;
          final isInStarters = index < sanMarcelinoRoster.starters.length;

          // Crear jugador con estadísticas por defecto (para San Marcelino)
          return Player(
            id: null, // Datos locales, no tienen ID de BD aún
            name: playerInfo.name,
            role: playerInfo.position,
            image: 'assets/players/default.png',
            isStarter: isInStarters,
            matchStatus: isInStarters ? MatchStatus.starter : MatchStatus.sub,
            number: playerInfo.number,
            stats: PlayerStats(), // Estadísticas por defecto, editables después
          );
        }).toList();

        // Calcular contadores
        final startersCount = sanMarcelinoRoster.starters.length;
        final substitutesCount = sanMarcelinoRoster.substitutes.length;
        counts = {
          'starters': startersCount,
          'substitutes': substitutesCount,
          'unselected': 0,
        };

        debugPrint(
          '📈 Plantilla cargada: $startersCount titulares, $substitutesCount suplentes',
        );
      }

      if (mounted) {
        setState(() {
          _players = players;
          _statusCounts = counts;
          _isSanMarcelinoTeam = isSanMarcelino;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error cargando jugadores: $e');
      debugPrint('Stack trace: $stackTrace');

      // Fallback: cargar plantilla de San Marcelino incluso si hay error
      try {
        final sanMarcelinoRoster = allTeamRosters.firstWhere(
          (roster) => roster.teamName.contains('San Marcelino'),
          orElse: () => allTeamRosters.first,
        );

        final allPlayers = [
          ...sanMarcelinoRoster.starters,
          ...sanMarcelinoRoster.substitutes,
        ];

        final players = allPlayers.asMap().entries.map((entry) {
          final index = entry.key;
          final playerInfo = entry.value;
          final isInStarters = index < sanMarcelinoRoster.starters.length;

          return Player(
            id: null,
            name: playerInfo.name,
            role: playerInfo.position,
            image: 'assets/players/default.png',
            isStarter: isInStarters,
            matchStatus: isInStarters ? MatchStatus.starter : MatchStatus.sub,
            number: playerInfo.number,
            stats: PlayerStats(),
          );
        }).toList();

        final counts = {
          'starters': sanMarcelinoRoster.starters.length,
          'substitutes': sanMarcelinoRoster.substitutes.length,
          'unselected': 0,
        };

        if (mounted) {
          setState(() {
            _players = players;
            _statusCounts = counts;
            _isSanMarcelinoTeam = true;
            _loading = false;
          });
        }
      } catch (fallbackError) {
        debugPrint('❌ Error en fallback: $fallbackError');
        if (mounted) {
          setState(() {
            _players = [];
            _statusCounts = {'starters': 0, 'substitutes': 0, 'unselected': 0};
            _isSanMarcelinoTeam = false;
            _loading = false;
          });
        }
      }
    }
  }

  Future<void> _updatePlayerStatus(
    Player player,
    MatchStatus newStatus, {
    String? note,
  }) async {
    final statusString = newStatus == MatchStatus.starter
        ? 'starter'
        : newStatus == MatchStatus.sub
        ? 'sub'
        : 'unselected';
    final success = await _supabaseService.updatePlayerMatchStatus(
      player.id!,
      statusString,
      statusNote: note,
    );

    if (success) {
      await _loadPlayers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado: ${player.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el estado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImportDialog() {
    // Buscar San Marcelino y seleccionarlo por defecto
    final sanMarcelino = allTeamRosters.firstWhere(
      (roster) => roster.teamName.contains('San Marcelino'),
      orElse: () => allTeamRosters.first,
    );
    TeamRoster? selectedRoster = sanMarcelino;
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Filtrar equipos basándose en la búsqueda
          List<TeamRoster> getFilteredRosters() {
            final query = searchController.text.toLowerCase().trim();
            if (query.isEmpty) {
              // Si no hay búsqueda, mostrar San Marcelino primero y luego el resto
              final rest = allTeamRosters
                  .where((r) => !r.teamName.contains('San Marcelino'))
                  .toList();
              return [sanMarcelino, ...rest];
            } else {
              // Filtrar todos los equipos incluyendo San Marcelino si coincide
              return allTeamRosters
                  .where(
                    (roster) => roster.teamName.toLowerCase().contains(query),
                  )
                  .toList();
            }
          }

          // Lista filtrada inicial
          final filteredRosters = getFilteredRosters();

          // Actualizar lista filtrada cuando cambia la búsqueda
          void updateSearch(String query) {
            setDialogState(() {});
          }

          return AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            title: Text(
              'Importar Plantilla',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo de búsqueda
                  TextField(
                    controller: searchController,
                    autofocus: false,
                    onChanged: updateSearch,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar equipo...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                searchController.clear();
                                updateSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lista de equipos
                  Text(
                    filteredRosters.isEmpty
                        ? 'No se encontraron equipos'
                        : selectedRoster?.teamName == sanMarcelino.teamName
                        ? 'Tu equipo (preseleccionado):'
                        : 'Selecciona un equipo:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: filteredRosters.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No se encontraron equipos',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredRosters.length,
                            itemBuilder: (context, index) {
                              final roster = filteredRosters[index];
                              final totalPlayers =
                                  roster.starters.length +
                                  roster.substitutes.length;
                              final isSelected =
                                  selectedRoster?.teamName == roster.teamName;
                              final logoPath =
                                  roster.logoPath ??
                                  TeamLogoHelper.getDefaultLogo();

                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedRoster = roster;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                              .withValues(alpha: 0.2)
                                        : Colors.grey[900],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.white24,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Logo del equipo
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            logoPath,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[800],
                                                    child: Icon(
                                                      Icons.sports_soccer,
                                                      color: Colors.white54,
                                                      size: 24,
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              roster.teamName,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$totalPlayers jugadores (${roster.starters.length} titulares, ${roster.substitutes.length} suplentes)',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: selectedRoster == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        searchController.dispose();
                        _importTeamRoster(selectedRoster!);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Importar'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      // Limpiar el controlador cuando se cierra el diálogo
      searchController.dispose();
    });
  }

  Future<void> _importTeamRoster(TeamRoster roster) async {
    final teamId = await _getCurrentTeamId();
    if (teamId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se encontró el equipo'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Preparar lista de jugadores con su estado inicial
    final players = <Map<String, dynamic>>[];

    // Agregar titulares
    for (var starter in roster.starters) {
      players.add({
        'name': starter.name,
        'role': 'player',
        'match_status': 'starter', // Importar como titulares
        'number': starter.number,
      });
    }

    // Agregar suplentes
    for (var substitute in roster.substitutes) {
      players.add({
        'name': substitute.name,
        'role': 'player',
        'match_status': 'sub', // Importar como suplentes
        'number': substitute.number,
      });
    }

    // Mostrar indicador de carga
    if (!mounted) return;

    final totalPlayers = players.length;

    final navContext = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Importando $totalPlayers jugadores de ${roster.teamName}...',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    final result = await _supabaseService.importPlayersToTeam(
      teamId: teamId,
      players: players,
    );

    if (!mounted) return;

    navContext.pop(); // Cerrar diálogo de carga

    await _loadPlayers(); // Recargar lista de jugadores

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Importación completada'),
        backgroundColor: result['success'] == true
            ? Colors.green
            : Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showStatusNoteDialog(Player player, MatchStatus newStatus) {
    final TextEditingController noteController = TextEditingController(
      text: player.statusNote ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        title: Text(
          'Razón de Desconvocatoria',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jugador: ${player.name}',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              autofocus: true,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Motivo (ej: Lesión, Sanción, Descanso)',
                labelStyle: TextStyle(color: Colors.white54),
                hintText: 'Escribe el motivo aquí...',
                hintStyle: TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePlayerStatus(
                player,
                newStatus,
                note: noteController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GESTIÓN DE PLANTILLA',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlayers,
            tooltip: 'Recargar plantilla',
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : Column(
              children: [
                _buildStatusCounter(theme),
                const SizedBox(height: 16),
                Expanded(
                  child: _players.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.white24,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay jugadores en el equipo',
                                style: GoogleFonts.roboto(
                                  color: Colors.white54,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toca el botón de importación para agregar tu plantilla',
                                style: GoogleFonts.roboto(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showImportDialog,
                                icon: const Icon(Icons.file_download),
                                label: const Text('Importar Plantilla'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _players.length,
                          itemBuilder: (context, index) {
                            return _buildPlayerCard(_players[index], theme);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCounter(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.2),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCounterItem(
            'TITULARES',
            '${_statusCounts['starters']}/11',
            Colors.green,
            Icons.sports_soccer,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildCounterItem(
            'SUPLENTES',
            '${_statusCounts['substitutes']}',
            Colors.orange,
            Icons.group,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildCounterItem(
            'DESCONVOCADOS',
            '${_statusCounts['unselected']}',
            Colors.red,
            Icons.cancel_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterItem(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          count,
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.robotoCondensed(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Muestra el diálogo para seleccionar fuente de imagen
  void _showImageSourceDialog(Player player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Cambiar avatar de ${player.name}',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tomar Foto'),
                subtitle: const Text('Usar cámara del dispositivo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromCamera(player);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Galería'),
                subtitle: const Text('Seleccionar de galería'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromGallery(player);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.orange),
                title: const Text('Explorador de Archivos'),
                subtitle: const Text('PC, iCloud, Google Drive, etc.'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromFiles(player);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Seleccionar imagen desde la cámara
  Future<void> _pickImageFromCamera(Player player) async {
    final image = await _fileService.pickImageFromCamera();
    if (image != null) {
      await _uploadPlayerImage(player, image);
    }
  }

  /// Seleccionar imagen desde la galería
  Future<void> _pickImageFromGallery(Player player) async {
    final image = await _fileService.pickImageFromGallery();
    if (image != null) {
      await _uploadPlayerImage(player, image);
    }
  }

  /// Seleccionar imagen desde explorador de archivos
  Future<void> _pickImageFromFiles(Player player) async {
    final image = await _fileService.pickFile(type: FileType.image);
    if (image != null && _fileService.isImage(image)) {
      await _uploadPlayerImage(player, image);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona una imagen válida'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Subir imagen del jugador a Supabase Storage y actualizar BD
  Future<void> _uploadPlayerImage(Player player, File imageFile) async {
    if (player.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: El jugador no tiene ID válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _uploadingPlayers[player.id!] = true;
    });

    try {
      // 1. Subir a Supabase Storage (bucket: player-photos)
      final imageUrl = await _fileService.uploadImage(
        image: imageFile,
        folder: 'player-photos',
        imageName:
            'player_${player.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir la imagen'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _uploadingPlayers.remove(player.id);
        });
        return;
      }

      // 2. Actualizar base de datos (tabla: profiles, campo: avatar_url)
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', player.id!);

      // 3. Actualizar lista local de jugadores
      await _loadPlayers();

      // 4. Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar actualizado: ${player.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _uploadingPlayers.remove(player.id);
      });
    }
  }

  Widget _buildPlayerCard(Player player, ThemeData theme) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (player.matchStatus) {
      case MatchStatus.starter:
        statusColor = Colors.green;
        statusLabel = 'TITULAR';
        statusIcon = Icons.star;
        break;
      case MatchStatus.sub:
        statusColor = Colors.orange;
        statusLabel = 'SUPLENTE';
        statusIcon = Icons.people;
        break;
      case MatchStatus.unselected:
        statusColor = Colors.red;
        statusLabel = 'DESCONVOCADO';
        statusIcon = Icons.cancel;
        break;
    }

    final isUnselected = player.matchStatus == MatchStatus.unselected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar del jugador (clickeable solo para San Marcelino)
              Opacity(
                opacity: isUnselected ? 0.5 : 1.0,
                child: GestureDetector(
                  onTap:
                      _isSanMarcelinoTeam &&
                          player.id != null &&
                          !_uploadingPlayers.containsKey(player.id)
                      ? () => _showImageSourceDialog(player)
                      : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: player.image.startsWith('http')
                            ? NetworkImage(player.image)
                            : (player.image.startsWith('assets/')
                                  ? AssetImage(player.image) as ImageProvider
                                  : null),
                        backgroundColor: theme.colorScheme.surface,
                        child:
                            player.image.isEmpty ||
                                (!player.image.startsWith('http') &&
                                    !player.image.startsWith('assets/'))
                            ? Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.white54,
                              )
                            : null,
                      ),
                      // Indicador de carga
                      if (_uploadingPlayers.containsKey(player.id))
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Icono de cámara solo para San Marcelino
                      if (_isSanMarcelinoTeam &&
                          !_uploadingPlayers.containsKey(player.id) &&
                          player.id != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Información del jugador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Solo San Marcelino tiene ficha completa clickeable
                    if (_isSanMarcelinoTeam)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlayerProfileScreen(player: player),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                player.name,
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isUnselected
                                      ? Colors.white54
                                      : Colors.white,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: isUnselected
                                  ? Colors.white38
                                  : Colors.white54,
                            ),
                          ],
                        ),
                      )
                    else
                      // Otros equipos solo muestran nombre
                      Text(
                        player.name,
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isUnselected ? Colors.white54 : Colors.white,
                        ),
                      ),
                    if (player.role != null)
                      Text(
                        player.role!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isUnselected ? Colors.white38 : Colors.white70,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Selector de estado
          Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  context,
                  player,
                  MatchStatus.starter,
                  'Titular',
                  Colors.green,
                  Icons.star,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusButton(
                  context,
                  player,
                  MatchStatus.sub,
                  'Suplente',
                  Colors.orange,
                  Icons.people,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusButton(
                  context,
                  player,
                  MatchStatus.unselected,
                  'Descartado',
                  Colors.red,
                  Icons.cancel,
                ),
              ),
            ],
          ),
          // Nota de desconvocatoria
          if (player.statusNote != null && player.statusNote!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.statusNote!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    Player player,
    MatchStatus status,
    String label,
    Color color,
    IconData icon,
  ) {
    final isSelected = player.matchStatus == status;

    return InkWell(
      onTap: () {
        if (status == MatchStatus.unselected) {
          // Si selecciona "Desconvocado", pedir motivo
          _showStatusNoteDialog(player, status);
        } else {
          // Para Titular y Suplente, actualizar directamente
          _updatePlayerStatus(player, status);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.white54),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
