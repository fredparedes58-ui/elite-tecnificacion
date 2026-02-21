// ============================================================
// Admin: Comparativa de dos jugadores (estilo FIFA).
// Paridad con React ComparePlayers + usePlayers.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/players_repository.dart';

class ComparePlayersScreen extends StatefulWidget {
  const ComparePlayersScreen({super.key});

  @override
  State<ComparePlayersScreen> createState() => _ComparePlayersScreenState();
}

class _ComparePlayersScreenState extends State<ComparePlayersScreen> {
  String? _playerAId;
  String? _playerBId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayersRepository>().fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<PlayersRepository>();
    final playerA = _playerAId != null ? repo.getById(_playerAId!) : null;
    final playerB = _playerBId != null ? repo.getById(_playerBId!) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comparar jugadores',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige dos jugadores para comparar (estilo FIFA).',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _playerAId,
                    decoration: const InputDecoration(
                      labelText: 'Jugador A',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Seleccionar...')),
                      ...repo.players.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.name} (${p.category})'),
                          )),
                    ],
                    onChanged: (v) => setState(() => _playerAId = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _playerBId,
                    decoration: const InputDecoration(
                      labelText: 'Jugador B',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Seleccionar...')),
                      ...repo.players.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.name} (${p.category})'),
                          )),
                    ],
                    onChanged: (v) => setState(() => _playerBId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (repo.loading && repo.players.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: playerA != null
                        ? _PlayerCard(player: playerA)
                        : Card(
                            child: SizedBox(
                              height: 280,
                              child: Center(
                                child: Text(
                                  'Selecciona jugador A',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: playerB != null
                        ? _PlayerCard(player: playerB)
                        : Card(
                            child: SizedBox(
                              height: 280,
                              child: Center(
                                child: Text(
                                  'Selecciona jugador B',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player});

  final PlayerWithParent player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.photoUrl != null && player.photoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  player.photoUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.person, size: 48, color: theme.colorScheme.primary),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, size: 48, color: theme.colorScheme.primary),
              ),
            const SizedBox(height: 12),
            Text(
              player.name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              player.position ?? 'Sin posición',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              '${player.category} · ${player.level}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (player.currentClub != null)
              Text(
                player.currentClub!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            if (player.stats != null && player.stats!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: player.stats!.entries.take(6).map((e) => Chip(
                  label: Text('${e.key}: ${e.value}'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
