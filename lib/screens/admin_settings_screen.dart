// ============================================================
// Admin: Configuración del sistema (horarios, capacidad, días, alertas, cancelación).
// Paridad con React AdminSettings + useSystemConfig.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/system_config_repository.dart';
import 'package:myapp/utils/snackbar_helper.dart';

const _daysOfWeek = [
  (1, 'Lun'),
  (2, 'Mar'),
  (3, 'Mié'),
  (4, 'Jue'),
  (5, 'Vie'),
  (6, 'Sáb'),
  (7, 'Dom'),
];

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SystemConfigRepository>().fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<SystemConfigRepository>();
    final c = repo.config;

    if (repo.loading && c.sessionStart == 8 && c.activeDays.length == 6) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración del Sistema',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajusta los parámetros operativos de la academia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Horario de sesiones',
              icon: Icons.access_time,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: '${c.sessionStart}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hora inicio (0-23)',
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (v) async {
                          final n = int.tryParse(v);
                          if (n != null && n >= 0 && n <= 23) {
                            final ok = await repo.updateSessionHours(n, c.sessionEnd);
                            if (mounted) SnackBarHelper.showSuccess(context, ok ? 'Guardado' : 'Error');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: '${c.sessionEnd}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hora fin (0-23)',
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (v) async {
                          final n = int.tryParse(v);
                          if (n != null && n >= 0 && n <= 23) {
                            final ok = await repo.updateSessionHours(c.sessionStart, n);
                            if (mounted) SnackBarHelper.showSuccess(context, ok ? 'Guardado' : 'Error');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Capacidad máxima',
              icon: Icons.groups,
              children: [
                TextFormField(
                  initialValue: '${c.maxCapacity}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jugadores por sesión',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (v) async {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) {
                      final ok = await repo.updateMaxCapacity(n);
                      if (mounted) SnackBarHelper.showSuccess(context, ok ? 'Guardado' : 'Error');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Días activos',
              icon: Icons.calendar_today,
              children: [
                Wrap(
                  spacing: 8,
                  children: _daysOfWeek.map((e) {
                    final active = c.activeDays.contains(e.$1);
                    return FilterChip(
                      label: Text(e.$2),
                      selected: active,
                      onSelected: (sel) async {
                        final newDays = sel
                            ? [...c.activeDays, e.$1]..sort()
                            : c.activeDays.where((d) => d != e.$1).toList();
                        final ok = await repo.updateActiveDays(newDays);
                        if (mounted) SnackBarHelper.showSuccess(context, ok ? 'Guardado' : 'Error');
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Umbral de créditos (alerta)',
              icon: Icons.account_balance_wallet,
              children: [
                TextFormField(
                  initialValue: '${c.creditAlertThreshold}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Avisar cuando créditos <',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (v) async {
                    final n = int.tryParse(v);
                    if (n != null && n >= 0) {
                      final ok = await repo.updateCreditAlertThreshold(n);
                      if (mounted) SnackBarHelper.showSuccess(context, ok ? 'Guardado' : 'Error');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Ventana de cancelación',
              icon: Icons.event_busy,
              children: [
                TextFormField(
                  initialValue: '${c.cancellationHours}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Horas antes para cancelar sin penalización',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (v) async {
                    final n = int.tryParse(v);
                    if (n != null && n >= 0) {
                      final ok = await repo.updateCancellationHours(n);
                      if (mounted) SnackBarHelper.showSuccess(context, ok ? 'Guardado' : 'Error');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
