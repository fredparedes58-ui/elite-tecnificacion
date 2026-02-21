import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/utils/snackbar_helper.dart';
import 'package:myapp/utils/email_validator.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Límite de intentos para prevenir spam
  int _resetPasswordAttempts = 0;
  static const int _maxResetAttempts = 3;
  DateTime? _lastResetAttempt;
  static const Duration _resetCooldown = Duration(minutes: 15);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      SnackBarHelper.showWarning(context, 'Por favor, completa todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        'Error de autenticación: ${error.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _canRequestPasswordReset() {
    // Si nunca se ha intentado, permitir
    if (_lastResetAttempt == null) return true;

    // Si han pasado más de 15 minutos desde el último intento, resetear contador
    if (DateTime.now().difference(_lastResetAttempt!) > _resetCooldown) {
      _resetPasswordAttempts = 0;
      return true;
    }

    // Si no se ha alcanzado el límite, permitir
    return _resetPasswordAttempts < _maxResetAttempts;
  }

  String? _getResetPasswordCooldownMessage() {
    if (_lastResetAttempt == null) return null;

    final remainingTime = _resetCooldown - DateTime.now().difference(_lastResetAttempt!);
    if (remainingTime.isNegative) return null;

    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;

    if (minutes > 0) {
      return 'Espera $minutes minuto${minutes > 1 ? 's' : ''} antes de intentar de nuevo';
    } else {
      return 'Espera $seconds segundo${seconds > 1 ? 's' : ''} antes de intentar de nuevo';
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    // Verificar si puede hacer la solicitud
    if (!_canRequestPasswordReset()) {
      final cooldownMessage = _getResetPasswordCooldownMessage();
      SnackBarHelper.showWarning(
        context,
        cooldownMessage ?? 'Has alcanzado el límite de intentos. Espera antes de intentar de nuevo.',
        duration: const Duration(seconds: 5),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cooldownMessage = _getResetPasswordCooldownMessage();
            final canRequest = _canRequestPasswordReset();

            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Row(
                children: [
                  Icon(
                    Icons.lock_reset,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    if (_resetPasswordAttempts > 0 && _resetPasswordAttempts < _maxResetAttempts)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Intentos restantes: ${_maxResetAttempts - _resetPasswordAttempts}',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    if (cooldownMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          cooldownMessage,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isSending && canRequest,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'tu@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: EmailValidator.validate,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.roboto(),
                  ),
                ),
                ElevatedButton(
                  onPressed: (isSending || !canRequest)
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final email = EmailValidator.normalize(emailController.text);

                          setDialogState(() {
                            isSending = true;
                          });

                          try {
                            // Configurar redirectTo para que abra la app cuando se haga clic en el enlace
                            // El formato es: com.elitecnificacion.app://reset-password
                            await Supabase.instance.client.auth
                                .resetPasswordForEmail(
                              email,
                              redirectTo: 'com.elitecnificacion.app://reset-password',
                            );

                            // Incrementar contador de intentos
                            setState(() {
                              _resetPasswordAttempts++;
                              _lastResetAttempt = DateTime.now();
                            });

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              SnackBarHelper.showSuccess(
                                context,
                                'Revisa tu correo para restablecer tu contraseña',
                                duration: const Duration(seconds: 5),
                              );
                            }
                          } catch (error) {
                            // Incrementar contador incluso en caso de error
                            setState(() {
                              _resetPasswordAttempts++;
                              _lastResetAttempt = DateTime.now();
                            });

                            if (dialogContext.mounted) {
                              setDialogState(() {
                                isSending = false;
                              });
                              // No revelamos si el email existe o no por seguridad
                              SnackBarHelper.showError(
                                dialogContext,
                                'Error al enviar el email. Verifica que el email sea correcto e intenta de nuevo.',
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Enviar',
                          style: GoogleFonts.roboto(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Futbol AI',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'Entrar',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
