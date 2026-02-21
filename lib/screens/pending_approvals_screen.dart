import 'package:flutter/material.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/utils/snackbar_helper.dart';

/// Pantalla para que Pedro (admin) apruebe cuentas de padres pendientes.
/// Lista perfiles con is_approved = false y permite aprobar con un toque.
class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, email, full_name, created_at')
          .eq('is_approved', false)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _pending = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando pendientes: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _approve(String profileId, String displayName) async {
    try {
      await Supabase.instance.client.rpc('approve_parent', params: {'profile_id': profileId});
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Cuenta de $displayName aprobada. Se ha enviado el correo de bienvenida.');
      _loadPending();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error al aprobar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildAppBarWithBack(
        context,
        title: Text(
          'Cuentas pendientes de aprobación',
          style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadPending,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadPending,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _pending.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.6)),
                          const SizedBox(height: 16),
                          Text(
                            'No hay cuentas pendientes',
                            style: GoogleFonts.roboto(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cuando un padre se registre, aparecerá aquí.',
                            style: GoogleFonts.roboto(color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPending,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pending.length,
                        itemBuilder: (context, index) {
                          final p = _pending[index];
                          final id = p['id'] as String?;
                          final email = p['email'] as String? ?? '';
                          final fullName = p['full_name'] as String? ?? email;
                          final createdAt = p['created_at'] != null
                              ? DateTime.tryParse(p['created_at'].toString())
                              : null;
                          final dateStr = createdAt != null
                              ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                              : '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: Text(
                                      (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase(),
                                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          fullName.isNotEmpty ? fullName : 'Sin nombre',
                                          style: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: GoogleFonts.roboto(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                        if (dateStr.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Registrado: $dateStr',
                                              style: GoogleFonts.roboto(fontSize: 12, color: theme.colorScheme.outline),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: id == null
                                        ? null
                                        : () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Aprobar cuenta'),
                                                content: Text(
                                                  '¿Aprobar a $fullName? Se enviará un correo de bienvenida.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text('Aprobar'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await _approve(id, fullName.isNotEmpty ? fullName : email);
                                            }
                                          },
                                    icon: const Icon(Icons.check, size: 20),
                                    label: const Text('Aprobar'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      ),
    );
  }
}
