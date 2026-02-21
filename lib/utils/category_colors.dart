import 'package:flutter/material.dart';

/// Colores por categoría para identificar a simple vista U8, U10, U12, etc.
/// Incluye nomenclatura numérica (U6, U8...) y por nombre (Prebenjamín, Alevín...).
class CategoryColors {
  CategoryColors._();

  /// Neón verde estilo FIFA usado en bordes de la carta
  static const Color neonBorder = Color(0xFF39FF14);

  /// Mapa de categoría → color. Cualquier categoría usada en la app
  /// puede añadirse aquí para tener un color fijo e identificable.
  static const Map<String, Color> _categoryColorMap = {
    // Nomenclatura por edad (U6, U8, ...)
    'U6': Color(0xFFE91E63),   // Rosa
    'U7': Color(0xFF9C27B0),  // Púrpura
    'U8': Color(0xFF673AB7),  // Violeta
    'U9': Color(0xFF3F51B5),  // Índigo
    'U10': Color(0xFF2196F3), // Azul
    'U11': Color(0xFF03A9F4), // Azul claro
    'U12': Color(0xFF00BCD4), // Cian
    'U13': Color(0xFF009688), // Teal
    'U14': Color(0xFF4CAF50), // Verde
    'U15': Color(0xFF8BC34A), // Verde claro
    'U16': Color(0xFFCDDC39), // Lima
    'U17': Color(0xFFFFEB3B), // Amarillo
    'U18': Color(0xFFFFC107), // Ámbar
    'U19': Color(0xFFFF9800), // Naranja
    // Nomenclatura por nombre (español)
    'Prebenjamín': Color(0xFFE91E63),
    'Prebenjamin': Color(0xFFE91E63),
    'Benjamín': Color(0xFF673AB7),
    'Benjamin': Color(0xFF673AB7),
    'Alevín': Color(0xFF2196F3),
    'Alevin': Color(0xFF2196F3),
    'Infantil': Color(0xFF00BCD4),
    'Cadete': Color(0xFF4CAF50),
    'Juvenil': Color(0xFFFFC107),
    // Sub-X por si se usan
    'Sub-7': Color(0xFF9C27B0),
    'Sub-9': Color(0xFF673AB7),
    'Sub-11': Color(0xFF2196F3),
    'Sub-13': Color(0xFF00BCD4),
    'Sub-15': Color(0xFF4CAF50),
    'Sub-17': Color(0xFFFFEB3B),
    'Sub-18': Color(0xFFFFC107),
  };

  /// Color por defecto cuando la categoría no está en el mapa
  static const Color fallbackCategoryColor = Color(0xFF607D8B);

  /// Devuelve el color asociado a [category]. Si no existe, usa un color
  /// derivado del hash del nombre para que categorías dinámicas sean siempre
  /// el mismo color.
  static Color forCategory(String? category) {
    if (category == null || category.isEmpty) return fallbackCategoryColor;
    final normalized = category.trim();
    return _categoryColorMap[normalized] ??
        _categoryColorMap[normalized.toUpperCase()] ??
        _colorFromString(normalized);
  }

  /// Genera un color consistente a partir del nombre (para categorías no predefinidas).
  static Color _colorFromString(String s) {
    final hash = s.hashCode.abs();
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.7, 0.5).toColor();
  }

  /// Lista de categorías conocidas (para selectores o badges).
  static List<String> get knownCategories => _categoryColorMap.keys.toList()..sort();
}
