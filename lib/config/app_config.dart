import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración centralizada de la aplicación
/// Lee credenciales desde variables de entorno (.env)
class AppConfig {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? _throwMissingEnvError('SUPABASE_URL');
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? _throwMissingEnvError('SUPABASE_ANON_KEY');

  // N8N Webhook Configuration
  static String get n8nWebhookUrl => dotenv.env['N8N_WEBHOOK_URL'] ?? '';

  // Constructor privado para evitar instanciación
  AppConfig._();

  /// Lanza error si falta una variable de entorno crítica
  static String _throwMissingEnvError(String key) {
    throw Exception(
      '❌ ERROR DE CONFIGURACIÓN:\n'
      'Variable de entorno "$key" no encontrada.\n\n'
      'Solución:\n'
      '1. Copia .env.example a .env\n'
      '2. Rellena las credenciales reales\n'
      '3. Reinicia la app\n\n'
      'Ver: SECURITY_SETUP.md'
    );
  }
}
