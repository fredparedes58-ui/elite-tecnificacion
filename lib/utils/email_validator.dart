// ============================================================
// UTILIDAD: VALIDADOR DE EMAIL
// ============================================================
// Validación robusta de email usando regex
// ============================================================

class EmailValidator {
  // Regex para validar formato de email según RFC 5322
  // Patrón más robusto que el básico
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&'\''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Valida si un email tiene un formato válido
  /// 
  /// Retorna `true` si el email es válido, `false` en caso contrario
  static bool isValid(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Valida un email y retorna un mensaje de error si es inválido
  /// 
  /// Retorna `null` si el email es válido, o un mensaje de error si no lo es
  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return 'Por favor, ingresa tu email';
    }

    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return 'Por favor, ingresa tu email';
    }

    if (!isValid(trimmedEmail)) {
      return 'Por favor, ingresa un email válido';
    }

    return null;
  }

  /// Normaliza un email (trim y lowercase)
  static String normalize(String email) {
    return email.trim().toLowerCase();
  }
}
