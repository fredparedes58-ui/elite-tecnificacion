import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/services/supabase_service.dart';

class SquadManagementScreen extends StatefulWidget {
  const SquadManagementScreen({super.key});

  @override
  State<SquadManagementScreen> createState() => _SquadManagementScreenState();
}

class _SquadManagementScreenState extends State<SquadManagementScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Player> _players = [];
  bool _loading = true;
  Map<String, int> _statusCounts = {'starters': 0, 'substitutes': 0, 'unselected': 0};

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _loading = true);
    // TODO: Get teamId from user
    final teamId = 'default-team-id'; // Placeholder
    final playersData = await _supabaseService.getTeamPlayers(teamId);
    final players = playersData.map((data) => Player.fromJson(data)).toList();
    final counts = await _supabaseService.getPlayersCountByStatus(teamId);
    if (mounted) {
      setState(() {
        _players = players;
        _statusCounts = counts;
        _loading = false;
      });
    }
  }

  Future<void> _updatePlayerStatus(Player player, MatchStatus newStatus, {String? note}) async {
    final statusString = newStatus == MatchStatus.starter
        ? 'starter'
        : newStatus == MatchStatus.sub
            ? 'sub'
            : 'unselected';
    final success = await _supabaseService.updatePlayerMatchStatus(
      player.id!,
      statusString,
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

  void _showStatusNoteDialog(Player player, MatchStatus newStatus) {
    final TextEditingController noteController = TextEditingController(text: player.statusNote ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
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
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
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
              _updatePlayerStatus(player, newStatus, note: noteController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            tooltip: 'Recargar',
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
                          child: Text(
                            'No hay jugadores en el equipo',
                            style: TextStyle(color: Colors.white54, fontSize: 16),
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
            theme.colorScheme.primary.withOpacity(0.2),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
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
          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
          ),
          _buildCounterItem(
            'SUPLENTES',
            '${_statusCounts['substitutes']}',
            Colors.orange,
            Icons.group,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
          ),
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

  Widget _buildCounterItem(String label, String count, Color color, IconData icon) {
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
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar del jugador
              Opacity(
                opacity: isUnselected ? 0.5 : 1.0,
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: player.image.startsWith('http')
                      ? NetworkImage(player.image)
                      : AssetImage(player.image) as ImageProvider,
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(width: 16),
              // Información del jugador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
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
          color: isSelected ? color.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : Colors.white54,
            ),
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
