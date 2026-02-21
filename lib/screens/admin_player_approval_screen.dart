// ============================================================
// Admin: Aprobación de jugadores. Lista pendientes, aprobar/rechazar.
// Paridad con React AdminPlayerApproval + PendingPlayersPanel.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/pending_players_repository.dart';
import 'package:myapp/utils/snackbar_helper.dart';

class AdminPlayerApprovalScreen extends StatefulWidget {
  const AdminPlayerApprovalScreen({super.key});

  @override
  State<AdminPlayerApprovalScreen> createState() => _AdminPlayerApprovalScreenState();
}

class _AdminPlayerApprovalScreenState extends State<AdminPlayerApprovalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PendingPlayersRepository? _pendingRepo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingRepo = context.read<PendingPlayersRepository>();
      _pendingRepo!.fetchPending();
      _pendingRepo!.subscribeRealtime();
    });
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pendingRepo?.unsubscribeRealtime();
    super.dispose();
  }

  List<PendingPlayer> _filtered(List<PendingPlayer> players) {
    if (_searchQuery.trim().isEmpty) return players;
    final q = _searchQuery.toLowerCase();
    return players.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.parentName?.toLowerCase().contains(q) ?? false) ||
          (p.category?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _approve(PendingPlayer p) async {
    final repo = context.read<PendingPlayersRepository>();
    final ok = await repo.approve(p.id);
    if (!mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(context, '${p.name} aprobado.');
    } else {
      SnackBarHelper.showError(context, 'Error al aprobar.');
    }
  }

  Future<void> _confirmReject(PendingPlayer p, String reason) async {
    final repo = context.read<PendingPlayersRepository>();
    final ok = await repo.reject(p.id, rejectionReason: reason.isEmpty ? null : reason);
    if (!mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(context, '${p.name} rechazado.');
    } else {
      SnackBarHelper.showError(context, 'Error al rechazar.');
    }
  }

  void _openRejectDialog(PendingPlayer p) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('¿Rechazar jugador?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vas a rechazar a ${p.name}. El padre será notificado.'),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo del rechazo (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _confirmReject(p, c.text.trim());
              },
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<PendingPlayersRepository>();
    final filtered = _filtered(repo.players);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aprobación de Jugadores',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (repo.players.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text('${repo.players.length} pendientes'),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (repo.players.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar jugador o padre...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          Expanded(
            child: repo.loading && repo.players.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.check_circle_outline,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No se encontraron jugadores'
                                  : 'No hay jugadores pendientes de aprobación',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => repo.fetchPending(forceRefresh: true),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final p = filtered[i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage: p.photoUrl != null && p.photoUrl!.isNotEmpty
                                          ? NetworkImage(p.photoUrl!)
                                          : null,
                                      child: p.photoUrl == null || p.photoUrl!.isEmpty
                                          ? Icon(Icons.person, color: theme.colorScheme.primary)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (p.category != null || p.position != null)
                                            Text(
                                              [
                                                p.category,
                                                p.position ?? 'Sin posición',
                                                if (p.currentClub != null) p.currentClub,
                                              ].where((e) => e != null && e.isNotEmpty).join(' · '),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          if (p.parentName != null)
                                            Text(
                                              'Padre: ${p.parentName}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          if (p.createdAt != null)
                                            Text(
                                              'Registrado ${_formatDate(p.createdAt!)}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () => _approve(p),
                                          icon: const Icon(Icons.check, size: 18),
                                          label: const Text('Aprobar'),
                                        ),
                                        const SizedBox(height: 6),
                                        OutlinedButton.icon(
                                          onPressed: () => _openRejectDialog(p),
                                          icon: const Icon(Icons.close, size: 18),
                                          label: const Text('Rechazar'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.colorScheme.error,
                                            side: BorderSide(color: theme.colorScheme.error),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: repo.loading == false && repo.players.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => repo.fetchPending(forceRefresh: true),
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
