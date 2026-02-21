// ============================================================
// Mis reservas (tabla reservations). Usa ReservationsRepository.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/reservations_repository.dart';
import 'package:myapp/screens/field_schedule_screen.dart';
import 'package:myapp/widgets/loading_widget.dart';
import 'package:myapp/widgets/empty_state_widget.dart';

class ReservationsListScreen extends StatefulWidget {
  const ReservationsListScreen({super.key});

  @override
  State<ReservationsListScreen> createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends State<ReservationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<ReservationsRepository>();
      repo.fetch();
      repo.subscribeRealtime();
    });
  }

  @override
  void dispose() {
    context.read<ReservationsRepository>().unsubscribeRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<ReservationsRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis reservas', style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
      ),
      body: repo.loading && repo.items.isEmpty
          ? const LoadingWidget(message: 'Cargando reservas...')
          : repo.items.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.calendar_today,
                  title: 'Sin reservas',
                  subtitle: 'Solicita una reserva desde el calendario.',
                )
              : RefreshIndicator(
                  onRefresh: () => repo.fetch(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: repo.items.length,
                    itemBuilder: (context, i) {
                      final r = repo.items[i];
                      final statusColor = r.status == 'approved'
                          ? Colors.green
                          : r.status == 'rejected'
                              ? Colors.red
                              : theme.colorScheme.primary;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(r.title),
                          subtitle: Text(
                            '${DateFormat('d/M/yyyy HH:mm').format(r.startTime)} · ${r.creditCost} crédito(s)\nEstado: ${r.status}',
                          ),
                          trailing: r.status == 'pending'
                              ? TextButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Cancelar reserva'),
                                        content: const Text('¿Cancelar esta reserva?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await repo.cancel(r.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada')));
                                      }
                                    }
                                  },
                                  child: const Text('Cancelar'),
                                )
                              : Chip(label: Text(r.status, style: TextStyle(color: statusColor, fontSize: 12))),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldScheduleScreen()));
          if (result == true && mounted) context.read<ReservationsRepository>().fetch(forceRefresh: true);
        },
        icon: const Icon(Icons.add),
        label: const Text('Solicitar reserva'),
      ),
    );
  }
}
