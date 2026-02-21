import 'package:flutter/material.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/utils/email_validator.dart';
import 'package:myapp/utils/snackbar_helper.dart';

/// Pantalla para que los admins gestionen correos con rol admin y coach.
/// Cualquier correo que no esté en esta lista se considera padre al registrarse.
class AdminCoachEmailsScreen extends StatefulWidget {
  const AdminCoachEmailsScreen({super.key});

  @override
  State<AdminCoachEmailsScreen> createState() => _AdminCoachEmailsScreenState();
}

class _AdminCoachEmailsScreenState extends State<AdminCoachEmailsScreen> {
  List<Map<String, dynamic>> _emails = [];
  bool _loading = true;
  bool _adding = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadEmails() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('admin_coach_emails')
          .select('email, created_at')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _emails = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando admin_coach_emails: $e');
      if (mounted) {
        setState(() => _loading = false);
        SnackBarHelper.showError(context, 'Error al cargar la lista: $e');
      }
    }
  }

  Future<void> _addEmail() async {
    final email = EmailValidator.normalize(_emailController.text);
    if (email.isEmpty) return;
    if (!EmailValidator.isValid(email)) {
      SnackBarHelper.showError(context, 'Introduce un correo válido');
      return;
    }

    setState(() => _adding = true);
    try {
      await Supabase.instance.client.from('admin_coach_emails').insert({'email': email});
      await Supabase.instance.client.rpc('sync_admin_coach_roles');
      _emailController.clear();
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Correo agregado como admin y coach. Roles sincronizados.');
        _loadEmails();
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        SnackBarHelper.showError(context, 'Ese correo ya está en la lista');
      } else {
        SnackBarHelper.showError(context, 'Error: ${e.message}');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error al agregar: $e');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _removeEmail(String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar admin/coach'),
        content: Text(
          '¿Quitar "$email" de la lista? Esa cuenta pasará a ser padre si no tiene otro rol.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('admin_coach_emails')
          .delete()
          .eq('email', email);
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Correo quitado de la lista');
        _loadEmails();
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Error al quitar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildAppBarWithBack(
        context,
        title: Text(
          'Admins y coaches',
          style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Los correos de esta lista tienen rol de administrador y entrenador. Cualquier otro correo se registra como padre.',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Agregar correo (admin y coach)',
                            style: GoogleFonts.robotoCondensed(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              hintText: 'ejemplo@correo.com',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => EmailValidator.validate(v),
                            onFieldSubmitted: (_) => _addEmail(),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _adding ? null : _addEmail,
                            icon: _adding
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: Text(_adding ? 'Agregando…' : 'Agregar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'LISTA ACTUAL',
                  style: GoogleFonts.robotoCondensed(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_emails.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No hay correos configurados. Agrega uno arriba.',
                          style: GoogleFonts.roboto(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        for (int i = 0; i < _emails.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.admin_panel_settings,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(
                              _emails[i]['email'] as String? ?? '',
                              style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: theme.colorScheme.error,
                              onPressed: () => _removeEmail(
                                _emails[i]['email'] as String,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}
