import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/utils/snackbar_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    setState(() => _isSigningOut = true);

    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      
      // Navegar a AuthGate o pantalla de login
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      debugPrint('Error cerrando sesión: $e');
      if (!mounted) return;
      
      SnackBarHelper.showError(context, 'Error al cerrar sesión: $e');
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajustes',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de cuenta
          _buildSectionTitle(context, 'Cuenta'),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              title: Text(
                user?.email ?? 'Usuario',
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Ver perfil',
                style: GoogleFonts.roboto(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Sección de preferencias
          _buildSectionTitle(context, 'Preferencias'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Modo oscuro',
                    style: GoogleFonts.roboto(),
                  ),
                  subtitle: Text(
                    'Activar tema oscuro',
                    style: GoogleFonts.roboto(fontSize: 12),
                  ),
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    // TODO: Implementar cambio de tema si se requiere
                    SnackBarHelper.showInfo(context, 'Cambio de tema próximamente');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Notificaciones',
                    style: GoogleFonts.roboto(),
                  ),
                  subtitle: Text(
                    'Gestionar notificaciones push',
                    style: GoogleFonts.roboto(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    SnackBarHelper.showInfo(context, 'Configuración de notificaciones próximamente');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección de información
          _buildSectionTitle(context, 'Información'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Acerca de',
                    style: GoogleFonts.roboto(),
                  ),
                  subtitle: Text(
                    'Versión 1.0.0',
                    style: GoogleFonts.roboto(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Futbol AI',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 Futbol AI',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.help_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Ayuda y soporte',
                    style: GoogleFonts.roboto(),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    SnackBarHelper.showInfo(context, 'Centro de ayuda próximamente');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Botón de cerrar sesión
          Card(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Cerrar sesión',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              trailing: _isSigningOut
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.error,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.error,
                    ),
              onTap: _isSigningOut ? null : _signOut,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.robotoCondensed(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
