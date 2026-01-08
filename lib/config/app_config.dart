/// Configuración centralizada de la aplicación
class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://bqqjqasqmuyjnvmiuqvl.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxcWpxYXNxbXV5am52bWl1cXZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ1NzE5MzEsImV4cCI6MjA4MDE0NzkzMX0.pTl7TKI81QXLCY8j0bi2oO9LTbh88VhJXFa5BFG1GTg';

  // N8N Webhook Configuration
  static const String n8nWebhookUrl =
      'https://pedro08.app.n8n.cloud/webhook/cronica';

  // Constructor privado para evitar instanciación
  AppConfig._();
}
