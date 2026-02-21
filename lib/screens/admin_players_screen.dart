// ============================================================
// Admin: Directorio de jugadores. Lista todos con padre, búsqueda y filtros.
// Paridad con React AdminPlayers + PlayerDirectory.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/players_repository.dart';

class AdminPlayersScreen extends StatefulWidget {
  const AdminPlayersScreen({super.key});

  @override
  State<AdminPlayersScreen> createState() => _AdminPlayersScreenState();
}

class _AdminPlayersScreenState extends State<AdminPlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _categoryFilter = 'all';
  String _positionFilter = 'all';

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
          (p.parentName?.toLowerCase().contains(q) ?? false) ||
          (p.parentEmail?.toLowerCase().contains(q) ?? false) ||
          (p.currentClub?.toLowerCase().contains(q) ?? false);
      final matchCategory = _categoryFilter == 'all' || p.category == _categoryFilter;
      final matchPosition = _positionFilter == 'all' || p.position == _positionFilter;
      return matchSearch && matchCategory && matchPosition;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<PlayersRepository>();
    final filtered = _filtered(repo.players);
    final categories = repo.players.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList()..sort();
    final positions = repo.players.map((p) => p.position).whereType<String>().where((p) => p.isNotEmpty).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jugadores',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, padre, email, club...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _categoryFilter,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('Todas categorías')),
                        ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (v) => setState(() => _categoryFilter = v ?? 'all'),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _positionFilter,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('Todas posiciones')),
                        ...positions.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                      ],
                      onChanged: (v) => setState(() => _positionFilter = v ?? 'all'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: repo.loading && repo.players.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No hay jugadores',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: p.photoUrl != null && p.photoUrl!.isNotEmpty
                                    ? NetworkImage(p.photoUrl!)
                                    : null,
                                child: p.photoUrl == null || p.photoUrl!.isEmpty
                                    ? Icon(Icons.person, color: theme.colorScheme.primary)
                                    : null,
                              ),
                              title: Text(p.name),
                              subtitle: Text(
                                [
                                  p.category,
                                  p.position ?? '',
                                  if (p.parentName != null) 'Padre: ${p.parentName}',
                                ].where((e) => e.isNotEmpty).join(' · '),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: repo.loading == false && repo.players.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => repo.fetch(forceRefresh: true),
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}
