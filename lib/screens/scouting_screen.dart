// ============================================================
// Scouting: grid de jugadores con filtros y modal detalle.
// Paridad con React Scouting + usePlayers, ScoutingFilters, PlayerGrid, PlayerDetailModal.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/players_repository.dart';

/// Categorías y niveles igual que React (ScoutingFilters).
const _categories = [
  ('all', 'Todas las categorías'),
  ('U8', 'U8 (Sub-8)'),
  ('U10', 'U10 (Sub-10)'),
  ('U12', 'U12 (Sub-12)'),
  ('U14', 'U14 (Sub-14)'),
  ('U16', 'U16 (Sub-16)'),
  ('U18', 'U18 (Sub-18)'),
];

const _levels = [
  ('all', 'Todos los niveles'),
  ('beginner', 'Principiante'),
  ('intermediate', 'Intermedio'),
  ('advanced', 'Avanzado'),
  ('elite', 'Élite'),
];

class ScoutingScreen extends StatefulWidget {
  const ScoutingScreen({super.key});

  @override
  State<ScoutingScreen> createState() => _ScoutingScreenState();
}

class _ScoutingScreenState extends State<ScoutingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _category = 'all';
  String _level = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayersRepository>().fetch();
    });
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PlayerWithParent> _filtered(List<PlayerWithParent> players) {
    final q = _searchController.text.trim().toLowerCase();
    return players.where((p) {
      final matchSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          (p.position?.toLowerCase().contains(q) ?? false) ||
          (p.currentClub?.toLowerCase().contains(q) ?? false) ||
          (p.parentName?.toLowerCase().contains(q) ?? false);
      final matchCategory = _category == 'all' || p.category == _category;
      final matchLevel = _level == 'all' || p.level == _level;
      return matchSearch && matchCategory && matchLevel;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<PlayersRepository>();
    final filtered = _filtered(repo.players);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SCOUTING',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtros (paridad ScoutingFilters)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar jugador...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories
                                .map((e) => DropdownMenuItem(
                                      value: e.$1,
                                      child: Text(e.$2),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _category = v ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _level,
                            decoration: const InputDecoration(
                              labelText: 'Nivel',
                              border: OutlineInputBorder(),
                            ),
                            items: _levels
                                .map((e) => DropdownMenuItem(
                                      value: e.$1,
                                      child: Text(e.$2),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _level = v ?? 'all'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Resumen
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  repo.loading && repo.players.isEmpty
                      ? 'Cargando...'
                      : '${filtered.length} jugadores encontrados',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (_category != 'all')
                      Chip(
                        label: Text(_category),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (_level != 'all')
                      Chip(
                        label: Text(_level),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (repo.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    repo.error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: repo.loading && repo.players.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron jugadores',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta ajustar los filtros de búsqueda',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          return _ScoutingPlayerCard(
                            player: p,
                            onTap: () => _showPlayerDetail(context, p),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showPlayerDetail(BuildContext context, PlayerWithParent player) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _PlayerDetailSheet(
        player: player,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

class _ScoutingPlayerCard extends StatelessWidget {
  const _ScoutingPlayerCard({
    required this.player,
    required this.onTap,
  });

  final PlayerWithParent player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: player.photoUrl != null && player.photoUrl!.isNotEmpty
                  ? Image.network(
                      player.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(theme),
                    )
                  : _placeholder(theme),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${player.category} · ${player.level}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (player.position != null && player.position!.isNotEmpty)
                    Text(
                      player.position!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: 48,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _PlayerDetailSheet extends StatelessWidget {
  const _PlayerDetailSheet({
    required this.player,
    required this.onClose,
  });

  final PlayerWithParent player;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Detalle',
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Center(
                    child: player.photoUrl != null && player.photoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              player.photoUrl!,
                              height: 160,
                              width: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _photoPlaceholder(theme),
                            ),
                          )
                        : _photoPlaceholder(theme),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    player.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      Chip(label: Text(player.category)),
                      Chip(label: Text(player.level)),
                      if (player.position != null && player.position!.isNotEmpty)
                        Chip(label: Text(player.position!)),
                    ],
                  ),
                  if (player.birthDate != null) ...[
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.cake_outlined),
                      title: const Text('Fecha de nacimiento'),
                      subtitle: Text(player.birthDate!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                  if (player.currentClub != null && player.currentClub!.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.sports_soccer_outlined),
                      title: const Text('Club actual'),
                      subtitle: Text(player.currentClub!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                  if (player.dominantLeg != null && player.dominantLeg!.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.directions_walk_outlined),
                      title: const Text('Pierna dominante'),
                      subtitle: Text(player.dominantLeg!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  if (player.stats != null && player.stats!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Estadísticas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: player.stats!.entries
                          .map((e) => Chip(
                                label: Text('${e.key}: ${e.value}'),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                  if (player.notes != null && player.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (player.parentName != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Padre / tutor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        player.parentName,
                        player.parentEmail,
                        player.parentPhone,
                      ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _photoPlaceholder(ThemeData theme) {
    return Container(
      height: 160,
      width: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.person,
        size: 64,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
