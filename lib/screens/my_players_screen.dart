// ============================================================
// Mis jugadores (padre). Usa MyPlayersRepository.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/my_players_repository.dart';
import 'package:myapp/widgets/loading_widget.dart';
import 'package:myapp/widgets/empty_state_widget.dart';

class MyPlayersScreen extends StatefulWidget {
  const MyPlayersScreen({super.key});

  @override
  State<MyPlayersScreen> createState() => _MyPlayersScreenState();
}

class _MyPlayersScreenState extends State<MyPlayersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<MyPlayersRepository>();
      repo.fetch();
      repo.subscribeRealtime();
    });
  }

  @override
  void dispose() {
    context.read<MyPlayersRepository>().unsubscribeRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<MyPlayersRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis jugadores', style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
      ),
      body: repo.loading && repo.players.isEmpty
          ? const LoadingWidget(message: 'Cargando jugadores...')
          : repo.players.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: 'Sin jugadores',
                  subtitle: 'Añade un jugador para gestionar su ficha.',
                )
              : RefreshIndicator(
                  onRefresh: () => repo.fetch(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: repo.players.length,
                    itemBuilder: (context, i) {
                      final p = repo.players[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text((p.name.isNotEmpty ? p.name[0] : '?').toUpperCase()),
                          ),
                          title: Text(p.name),
                          subtitle: Text('${p.category} · ${p.level}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'delete') {
                                final ok = await repo.delete(p.id);
                                if (context.mounted && ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jugador eliminado')));
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'delete', child: ListTile(title: Text('Eliminar'))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlayer(context, repo),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddPlayer(BuildContext context, MyPlayersRepository repo) async {
    final nameController = TextEditingController();
    String category = 'u8';
    String level = 'beginner';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo jugador'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: ['u8', 'u10', 'u12', 'u14', 'u16'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => category = v ?? category),
              ),
              DropdownButtonFormField<String>(
                value: level,
                decoration: const InputDecoration(labelText: 'Nivel'),
                items: ['beginner', 'intermediate', 'advanced', 'elite'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => level = v ?? level),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final created = await repo.create(name: nameController.text.trim(), category: category, level: level);
              if (ctx.mounted) Navigator.pop(ctx, created != null);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jugador creado')));
    }
  }
}
