// ============================================================
// Admin: Gestión de reservas. Lista todas, aprobar/rechazar.
// Paridad simplificada con React AdminReservations.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/reservations_repository.dart';
import 'package:myapp/utils/snackbar_helper.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationsRepository>().fetchAll();
    });
  }

  String _formatDateTime(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<ReservationsRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Reservas',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
      ),
      body: repo.loading && repo.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : repo.items.isEmpty
              ? Center(
                  child: Text(
                    'No hay reservas',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => repo.fetchAll(forceRefresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: repo.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = repo.items[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(r.status),
                                    backgroundColor: r.status == 'approved'
                                        ? theme.colorScheme.primaryContainer
                                        : r.status == 'rejected'
                                            ? theme.colorScheme.errorContainer
                                            : theme.colorScheme.surfaceContainerHighest,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDateTime(r.startTime)} – ${_formatDateTime(r.endTime)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Usuario: ${r.userId} · ${r.creditCost} créd.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (r.status == 'pending') ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        final ok = await repo.updateStatus(r.id, 'rejected');
                                        if (mounted) {
                                          SnackBarHelper.showSuccess(
                                            context,
                                            ok ? 'Reserva rechazada' : 'Error',
                                          );
                                        }
                                      },
                                      child: const Text('Rechazar'),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        final ok = await repo.updateStatus(r.id, 'approved');
                                        if (mounted) {
                                          SnackBarHelper.showSuccess(
                                            context,
                                            ok ? 'Reserva aprobada' : 'Error',
                                          );
                                        }
                                      },
                                      child: const Text('Aprobar'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: repo.loading == false && repo.items.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => repo.fetchAll(forceRefresh: true),
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}
