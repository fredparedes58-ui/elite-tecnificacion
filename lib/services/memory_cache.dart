// ============================================================
// Caché en memoria con TTL (estilo React Query / TanStack Query).
// Uso: repos guardan datos por clave y opcionalmente invalidan o expiran.
// ============================================================

/// Entrada de caché con valor y timestamp para TTL.
class _CacheEntry<T> {
  _CacheEntry(this.value, {Duration? ttl})
      : expiresAt = ttl != null ? DateTime.now().add(ttl) : null;

  final T value;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Caché en memoria por clave (String). Soporta TTL opcional.
class MemoryCache {
  MemoryCache({this.defaultTtl});

  final Duration? defaultTtl;
  final Map<String, _CacheEntry<dynamic>> _store = {};

  /// Obtiene el valor si existe y no ha expirado. Devuelve null si no hay entrada o expiró.
  T? get<T>(String key) {
    final entry = _store[key] as _CacheEntry<T>?;
    if (entry == null || entry.isExpired) {
      if (entry != null && entry.isExpired) {
        _store.remove(key);
      }
      return null;
    }
    return entry.value;
  }

  /// Guarda el valor con la clave. Si [ttl] es null, usa [defaultTtl].
  void set<T>(String key, T value, {Duration? ttl}) {
    _store[key] = _CacheEntry(value, ttl: ttl ?? defaultTtl);
  }

  /// Invalida una clave (la elimina).
  void invalidate(String key) {
    _store.remove(key);
  }

  /// Invalida todas las claves que empiezan por [prefix]. Si prefix es null, limpia todo.
  void invalidatePrefix(String? prefix) {
    if (prefix == null || prefix.isEmpty) {
      _store.clear();
      return;
    }
    _store.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// Elimina entradas expiradas (opcional, para no crecer sin límite).
  void evictExpired() {
    _store.removeWhere((_, entry) => entry.isExpired);
  }
}
