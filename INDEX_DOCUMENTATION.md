# 📚 ÍNDICE MAESTRO DE DOCUMENTACIÓN
## FUTBOL APP - Guía Completa de Navegación

**Última actualización:** 2026-01-08 (Agregado: Módulo Fútbol Social) 🆕  
**Estado del proyecto:** PRODUCCIÓN ACTIVA 🟢

---

## 📖 DOCUMENTOS PRINCIPALES

### 🎨 DISEÑO Y UI/UX

#### 1. **DESIGN_BLUEPRINT_MASTER.md** (949 líneas) ⭐ CRÍTICO
**Qué contiene:**
- 🎨 Paleta de colores completa (hex codes exactos)
- 📏 Dimensiones, espaciados y tamaños (todos los valores)
- 🏗️ Estructura completa de HomeScreen (jerarquía de widgets)
- 🎴 Especificaciones de TODOS los widgets (LiveStandingsCard, UpcomingMatchCard, etc.)
- 🗺️ Sistema de navegación completo
- 🔐 Privilegios por roles (coach/player/parent)
- 📊 Modelos de datos
- ⚙️ Configuración de Supabase
- 📝 Changelog y versiones

**Cuándo usar:**
- Antes de modificar CUALQUIER aspecto visual
- Para verificar valores exactos de colores/tamaños
- Para entender la arquitectura completa
- Como referencia canónica (fuente de verdad)

---

#### 2. **DESIGN_QUICK_REFERENCE.md** (150 líneas) ⚡ CONSULTA RÁPIDA
**Qué contiene:**
- Resumen visual de colores principales
- Tamaños críticos (typography, spacing, radius)
- Estructura simplificada de HomeScreen
- Tabla de navegación y roles
- Comandos Flutter frecuentes

**Cuándo usar:**
- Consulta rápida durante desarrollo
- Referencia de colores sin abrir archivo grande
- Verificar jerarquía de navegación
- Recordar comandos de Flutter

---

#### 3. **.cursorrules** (reglas de IA)
**Qué contiene:**
- Protocolo UI_FREEZE
- Reglas de inmutabilidad visual
- Frase clave de desbloqueo: "MODO REDISEÑO:"
- Referencia a DESIGN_BLUEPRINT_MASTER.md

**Cuándo usar:**
- Automáticamente cargado por Cursor AI
- Para recordar las restricciones de diseño
- Nunca modificar directamente (a menos que cambien reglas globales)

---

### ⚙️ CONFIGURACIÓN Y SETUP

#### 4. **SETUP_SUPABASE_STORAGE.md**
**Qué contiene:**
- Instrucciones para crear bucket `player-photos`
- Políticas RLS (Row Level Security)
- SQL para configuración de base de datos
- Troubleshooting de errores comunes

**Cuándo usar:**
- Primera configuración de Supabase Storage
- Al crear nuevos buckets
- Solucionar problemas de subida de archivos
- Verificar políticas de seguridad

---

#### 5. **SECURITY_SETUP.md**
**Qué contiene:**
- Configuración de seguridad de Supabase
- Políticas RLS para todas las tablas
- Roles y permisos de usuarios
- Best practices de seguridad

**Cuándo usar:**
- Configuración inicial de seguridad
- Al agregar nuevas tablas
- Auditoría de seguridad
- Resolver problemas de permisos

---

#### 6. **README_CATEGORIAS.md**
**Qué contiene:**
- Estructura de categorías deportivas
- Sistema de clasificación por edad/nivel
- Organización de equipos

**Cuándo usar:**
- Entender la jerarquía de categorías
- Al crear nuevas categorías
- Integrar sistema de clasificación

---

### 🎮 MÓDULOS FUNCIONALES

#### 7. **GUIA_CAMPOS_Y_RESERVAS.md**
**Qué contiene:**
- Sistema de gestión de campos deportivos
- Calendario de reservas
- Solicitudes de reserva
- Integración con Supabase

**Cuándo usar:**
- Implementar gestión de instalaciones deportivas
- Configurar sistema de reservas
- Gestionar disponibilidad de campos

---

#### 8. **GUIA_ALINEACIONES_PERSONALIZADAS.md**
**Qué contiene:**
- Editor de alineaciones y formaciones
- Sistema de tácticas
- Posiciones personalizadas
- Exportación de alineaciones

**Cuándo usar:**
- Configurar sistema táctico
- Crear editor de formaciones
- Gestionar alineaciones por partido

---

#### 9. **GUIA_GESTION_CONVOCATORIA.md**
**Qué contiene:**
- Sistema de convocatorias de partidos
- Confirmación de asistencia
- Gestión de disponibilidad
- Notificaciones a jugadores

**Cuándo usar:**
- Implementar convocatorias
- Gestionar asistencia de jugadores
- Sistema de confirmaciones

---

#### 10. **GUIA_SISTEMA_GOLEADORES.md**
**Qué contiene:**
- Ranking de goleadores
- Estadísticas de jugadores
- Sistema de puntuación
- Tablas comparativas

**Cuándo usar:**
- Implementar sistema de estadísticas
- Crear rankings de jugadores
- Gestionar goles y asistencias

---

#### 11. **GUIA_FUTBOL_SOCIAL.md** ⭐ NUEVO
**Qué contiene:**
- Feed social tipo Instagram/Facebook
- Sistema de posts con fotos/videos
- Sistema de likes en tiempo real
- Paginación y scroll infinito
- Documentación completa de implementación

**Cuándo usar:**
- Implementar red social del equipo
- Compartir momentos y fotos
- Sistema de interacción social
- Configurar feed visual

---

#### 12. **MEDIA_UPLOAD_ENGINE.md**
**Qué contiene:**
- Motor de subida de archivos
- Integración con R2/Bunny/Supabase
- Gestión de imágenes y videos
- Optimización de archivos

**Cuándo usar:**
- Configurar subida de archivos
- Implementar gestión de media
- Optimizar storage

---

### 📋 INSTALACIÓN RÁPIDA

#### 13. **INSTALACION_RAPIDA.md**
**Qué contiene:**
- Setup inicial del proyecto
- Configuración básica
- Primeros pasos

**Cuándo usar:**
- Primera instalación
- Setup de nuevo entorno

---

#### 14. **INSTALACION_CAMPOS_RAPIDA.md**
**Qué contiene:**
- Setup rápido de módulo de campos
- 3 pasos para empezar

**Cuándo usar:**
- Instalar solo módulo de campos
- Testing rápido de reservas

---

#### 15. **INSTALACION_GOLEADORES_RAPIDA.md**
**Qué contiene:**
- Setup rápido de módulo de goleadores
- Configuración express

**Cuándo usar:**
- Instalar solo módulo de estadísticas
- Testing rápido de goleadores

---

#### 16. **INICIO_RAPIDO_GOLEADORES.md**
**Qué contiene:**
- Guía de inicio rápido para goleadores
- Checklist de verificación

**Cuándo usar:**
- Verificar instalación de goleadores
- Primeros pasos en estadísticas

---

#### 17. **INICIO_RAPIDO_SOCIAL.md** ⭐ NUEVO
**Qué contiene:**
- 3 pasos para activar Fútbol Social
- Checklist de verificación
- Troubleshooting común
- Testing rápido

**Cuándo usar:**
- Primera configuración del feed social
- Verificar que todo funcione
- Solucionar problemas iniciales

---

### 📝 SCRIPTS SQL

#### 18. **SETUP_FIELDS_AND_BOOKINGS.sql**
**Qué contiene:**
- Tablas de campos y reservas
- RLS para seguridad
- Triggers y funciones

**Cuándo usar:**
- Configurar BD de campos
- Primera vez instalando módulo

---

#### 19. **SETUP_MATCH_STATS.sql**
**Qué contiene:**
- Tablas de estadísticas de partidos
- Sistema de goleadores
- Funciones de ranking

**Cuándo usar:**
- Configurar BD de estadísticas
- Implementar goleadores

---

#### 20. **SETUP_MATCH_STATUS.sql**
**Qué contiene:**
- Estados de partidos
- Workflow de partidos
- Transiciones de estado

**Cuándo usar:**
- Configurar estados de partidos
- Gestión de ciclo de vida de partidos

---

#### 21. **SETUP_ALIGNMENTS.sql**
**Qué contiene:**
- Tablas de alineaciones
- Formaciones tácticas
- Posiciones de jugadores

**Cuándo usar:**
- Configurar sistema táctico
- Implementar editor de alineaciones

---

#### 22. **SETUP_SOCIAL_FEED.sql** ⭐ NUEVO
**Qué contiene:**
- Tablas de posts sociales
- Sistema de likes
- RLS por equipo
- Triggers de contadores
- Función de paginación

**Cuándo usar:**
- Primera configuración de Fútbol Social
- Implementar feed social
- Configurar sistema de likes

---

#### 23. **EJECUTAR_TODO.sql**
**Qué contiene:**
- Script maestro que ejecuta todos los módulos
- Setup completo del proyecto

**Cuándo usar:**
- Instalación completa desde cero
- Resetear BD completa

---

#### 24. **ASIGNAR_CATEGORIAS.sql**
**Qué contiene:**
- Asignación de categorías
- Clasificación de equipos

**Cuándo usar:**
- Configurar categorías deportivas
- Organizar equipos por nivel

---

### 📖 DOCUMENTOS GENERALES

#### 25. **blueprint.md**
**Qué contiene:**
- Documento original del proyecto
- Visión general de la aplicación

**Cuándo usar:**
- Entender el contexto original del proyecto
- Revisión de objetivos iniciales

---

#### 26. **GEMINI.md**
**Qué contiene:**
- Notas sobre integración con IA
- Configuraciones especiales

---

#### 27. **README.md**
**Qué contiene:**
- Descripción básica del proyecto
- Instrucciones de instalación

**Cuándo usar:**
- Primera vez que alguien clona el repositorio
- Compartir proyecto con nuevos desarrolladores

---

#### 28. **RESUMEN_CAMPOS_Y_RESERVAS.md**
**Qué contiene:**
- Resumen ejecutivo del módulo de campos
- Vista general de funcionalidades

---

#### 29. **RESUMEN_IMPLEMENTACION.md**
**Qué contiene:**
- Resumen de toda la implementación
- Estado actual del proyecto

---

#### 30. **CHECKLIST_INICIO.md**
**Qué contiene:**
- Checklist para nuevo proyecto
- Verificación de configuración

---

#### 31. **COMO_EJECUTAR.md**
**Qué contiene:**
- Instrucciones de ejecución
- Comandos principales

---

#### 32. **CATEGORIAS_REFERENCIA.md**
**Qué contiene:**
- Referencia de categorías deportivas
- Sistema de clasificación

---

#### 33. **LEEME_PRIMERO.txt**
**Qué contiene:**
- Notas importantes iniciales
- Advertencias y consideraciones

---

## 🗂️ ESTRUCTURA DE ARCHIVOS CLAVE

```
futbol---app/
├── 📄 DOCUMENTACIÓN (33 archivos)
│   ├── INDEX_DOCUMENTATION.md ⭐ (ESTE ARCHIVO)
│   ├── DESIGN_BLUEPRINT_MASTER.md ⭐ (REFERENCIA VISUAL)
│   ├── DESIGN_QUICK_REFERENCE.md ⚡ (CONSULTA RÁPIDA)
│   │
│   ├── 🎮 MÓDULOS FUNCIONALES
│   │   ├── GUIA_CAMPOS_Y_RESERVAS.md
│   │   ├── GUIA_ALINEACIONES_PERSONALIZADAS.md
│   │   ├── GUIA_GESTION_CONVOCATORIA.md
│   │   ├── GUIA_SISTEMA_GOLEADORES.md
│   │   ├── GUIA_FUTBOL_SOCIAL.md ⭐ NUEVO
│   │   └── MEDIA_UPLOAD_ENGINE.md
│   │
│   ├── 📝 SCRIPTS SQL
│   │   ├── SETUP_SOCIAL_FEED.sql ⭐ NUEVO
│   │   ├── SETUP_FIELDS_AND_BOOKINGS.sql
│   │   ├── SETUP_MATCH_STATS.sql
│   │   ├── SETUP_MATCH_STATUS.sql
│   │   ├── SETUP_ALIGNMENTS.sql
│   │   ├── EJECUTAR_TODO.sql
│   │   └── ASIGNAR_CATEGORIAS.sql
│   │
│   ├── ⚡ INSTALACIÓN RÁPIDA
│   │   ├── INICIO_RAPIDO_SOCIAL.md ⭐ NUEVO
│   │   ├── INSTALACION_RAPIDA.md
│   │   ├── INSTALACION_CAMPOS_RAPIDA.md
│   │   ├── INSTALACION_GOLEADORES_RAPIDA.md
│   │   └── INICIO_RAPIDO_GOLEADORES.md
│   │
│   └── 📖 OTROS
│       ├── SETUP_SUPABASE_STORAGE.md
│       ├── SECURITY_SETUP.md
│       ├── README_CATEGORIAS.md
│       ├── blueprint.md
│       ├── GEMINI.md
│       └── README.md
│
├── ⚙️ CONFIGURACIÓN
│   ├── .cursorrules (Reglas de IA)
│   ├── pubspec.yaml (Dependencias + Social Feed)
│   ├── analysis_options.yaml (Linter)
│   └── devtools_options.yaml
│
├── 📱 CÓDIGO FUENTE
│   └── lib/
│       ├── screens/ (25+ pantallas)
│       │   ├── home_screen.dart ⭐ CONGELADO
│       │   ├── social_feed_screen.dart ⭐ NUEVO
│       │   ├── create_post_screen.dart ⭐ NUEVO
│       │   ├── squad_management_screen.dart
│       │   ├── tactical_board_screen.dart
│       │   ├── session_planner_screen.dart
│       │   ├── field_schedule_screen.dart
│       │   └── top_scorers_screen.dart
│       ├── widgets/ (20+ widgets)
│       │   ├── live_standings_card.dart ⭐ CONGELADO
│       │   ├── upcoming_match_card.dart ⭐ CONGELADO
│       │   ├── squad_status_card.dart
│       │   └── player_info_card.dart
│       ├── theme/
│       │   └── theme.dart ⭐ COLORES OFICIALES
│       ├── services/
│       │   ├── social_service.dart ⭐ NUEVO
│       │   ├── file_management_service.dart
│       │   ├── supabase_service.dart
│       │   ├── field_service.dart
│       │   ├── stats_service.dart
│       │   └── session_service.dart
│       ├── models/
│       │   ├── social_post_model.dart ⭐ NUEVO
│       │   ├── player_model.dart
│       │   ├── team_model.dart
│       │   ├── match_stats_model.dart
│       │   └── field_model.dart
│       ├── data/
│       │   ├── league_data.dart (13 equipos FFCV)
│       │   └── upcoming_matches_data.dart
│       ├── providers/
│       └── main.dart
│
└── 📦 RECURSOS
    └── assets/
        ├── data/
        ├── images/
        └── players/
```

---

## 🎯 GUÍA DE USO SEGÚN TAREA

### 🎨 Quiero modificar el diseño visual
1. ✅ Lee `.cursorrules` para verificar restricciones
2. ✅ Consulta `DESIGN_BLUEPRINT_MASTER.md` para valores exactos
3. ✅ Si necesitas cambiar algo visual, inicia tu prompt con: **"MODO REDISEÑO:"**
4. ❌ NUNCA cambies colores/tamaños sin esta frase clave

### 🔧 Quiero agregar nueva funcionalidad
1. ✅ Consulta `DESIGN_QUICK_REFERENCE.md` para estructura actual
2. ✅ Verifica roles y privilegios en `DESIGN_BLUEPRINT_MASTER.md`
3. ✅ Modifica solo la lógica (onPressed, funciones, backend)
4. ✅ Mantén el estilo visual exacto de elementos similares

### 📱 Quiero implementar Fútbol Social ⭐ NUEVO
1. ✅ Lee `INICIO_RAPIDO_SOCIAL.md` para setup en 3 pasos
2. ✅ Ejecuta `SETUP_SOCIAL_FEED.sql` en Supabase
3. ✅ Ejecuta `flutter pub get` para instalar dependencias
4. ✅ Consulta `GUIA_FUTBOL_SOCIAL.md` para documentación completa
5. ✅ Verifica el checklist en `INICIO_RAPIDO_SOCIAL.md`

### ⚙️ Quiero configurar Supabase
1. ✅ Sigue `SETUP_SUPABASE_STORAGE.md` para Storage
2. ✅ Sigue `SECURITY_SETUP.md` para políticas RLS
3. ✅ Verifica configuración en `DESIGN_BLUEPRINT_MASTER.md`

### 🏟️ Quiero implementar otros módulos
1. **Campos y Reservas:** `INSTALACION_CAMPOS_RAPIDA.md` → `GUIA_CAMPOS_Y_RESERVAS.md`
2. **Goleadores:** `INSTALACION_GOLEADORES_RAPIDA.md` → `GUIA_SISTEMA_GOLEADORES.md`
3. **Alineaciones:** `SETUP_ALIGNMENTS.sql` → `GUIA_ALINEACIONES_PERSONALIZADAS.md`
4. **Convocatorias:** `GUIA_GESTION_CONVOCATORIA.md`

### 🐛 Tengo un error
1. ✅ Revisa `SETUP_SUPABASE_STORAGE.md` (sección Troubleshooting)
2. ✅ Verifica dependencias en `pubspec.yaml`
3. ✅ Consulta comandos en `DESIGN_QUICK_REFERENCE.md`
4. ✅ Si es del módulo social: `INICIO_RAPIDO_SOCIAL.md` (Troubleshooting)

### 👥 Nuevo desarrollador en el equipo
1. ✅ Lee `README.md` primero
2. ✅ Revisa `DESIGN_QUICK_REFERENCE.md` para entender estructura
3. ✅ Familiarízate con `.cursorrules` (reglas de diseño)
4. ✅ Consulta `DESIGN_BLUEPRINT_MASTER.md` cuando necesites detalles
5. ✅ Explora los módulos en las guías específicas

---

## 🔄 FLUJO DE TRABAJO RECOMENDADO

### Para desarrollar nueva pantalla:
```
1. Diseño: DESIGN_BLUEPRINT_MASTER.md → Copiar estilos existentes
2. Navegación: DESIGN_QUICK_REFERENCE.md → Ver cómo se navega
3. Privilegios: DESIGN_BLUEPRINT_MASTER.md → Verificar roles
4. Backend: SECURITY_SETUP.md → Configurar permisos
5. Storage: SETUP_SUPABASE_STORAGE.md → Si usa archivos
```

### Para modificar pantalla existente:
```
1. .cursorrules → ¿Está congelada?
2. DESIGN_BLUEPRINT_MASTER.md → Valores actuales exactos
3. Si es visual → Usar "MODO REDISEÑO:"
4. Si es lógica → Modificar directamente
```

### Para implementar Fútbol Social (Feed Instagram): ⭐ NUEVO
```
1. BD: Ejecutar SETUP_SOCIAL_FEED.sql en Supabase
2. Dependencias: flutter pub get (ya están en pubspec.yaml)
3. Testing: Seguir INICIO_RAPIDO_SOCIAL.md
4. Configuración: Obtener team_id del usuario actual
5. Expansión: Ver GUIA_FUTBOL_SOCIAL.md (Fase 2 y 3)
```

### Para implementar módulo de Campos:
```
1. BD: Ejecutar SETUP_FIELDS_AND_BOOKINGS.sql
2. Guía: Seguir INSTALACION_CAMPOS_RAPIDA.md
3. Documentación: GUIA_CAMPOS_Y_RESERVAS.md
```

### Para implementar módulo de Goleadores:
```
1. BD: Ejecutar SETUP_MATCH_STATS.sql
2. Guía: Seguir INSTALACION_GOLEADORES_RAPIDA.md
3. Documentación: GUIA_SISTEMA_GOLEADORES.md
```

---

## ⚠️ ARCHIVOS CRÍTICOS (NO BORRAR)

```
🔴 CRÍTICO:
- DESIGN_BLUEPRINT_MASTER.md (fuente de verdad)
- .cursorrules (reglas de IA)
- lib/theme/theme.dart (colores oficiales)
- lib/screens/home_screen.dart (pantalla principal)

🟡 IMPORTANTE:
- DESIGN_QUICK_REFERENCE.md (consulta rápida)
- SETUP_SUPABASE_STORAGE.md (configuración)
- SECURITY_SETUP.md (seguridad)
- pubspec.yaml (dependencias)

🟢 INFORMATIVO:
- Este archivo (INDEX_DOCUMENTATION.md)
- README.md
- blueprint.md
```

---

## 📊 ESTADÍSTICAS DEL PROYECTO

```yaml
Pantallas: 25+
Widgets personalizados: 20+
Líneas de documentación: 3500+
Archivos de configuración: 5
Scripts SQL: 7
Servicios: 6 (Supabase, Social, FileManagement, Field, Stats, Session)
Modelos de datos: 12+
Dependencias: 17 (incluyendo video_player, chewie, cached_network_image)
Guías de módulos: 6

Módulos implementados:
- ✅ Command Center funcional
- ✅ Navegación completa
- ✅ Diseño congelado y documentado
- ✅ Sistema de permisos configurado
- ✅ Gestión de archivos multiplataforma
- ✅ Fútbol Social (Feed tipo Instagram) ⭐ NUEVO
- ✅ Gestión de campos y reservas
- ✅ Sistema de goleadores
- ✅ Alineaciones personalizadas
- ✅ Gestión de convocatorias
- 🔄 Chat en tiempo real (pendiente)
- 🔄 Notificaciones push (pendiente)
- 🔄 Video player completo (pendiente)
- 🔄 Comentarios en posts (pendiente)
```

---

## 🚀 COMANDOS RÁPIDOS

```bash
# Desarrollo
flutter run -d chrome              # Ejecutar en navegador
flutter run                        # Ejecutar en dispositivo
r                                  # Hot reload (en consola flutter)
R                                  # Hot restart (en consola flutter)

# Mantenimiento
flutter clean                      # Limpiar cache
flutter pub get                    # Instalar dependencias
flutter analyze                    # Verificar código
flutter doctor                     # Diagnóstico del entorno

# Construcción
flutter build web                  # Build para web
flutter build apk                  # Build para Android
flutter build ios                  # Build para iOS
```

---

## 💡 TIPS Y BEST PRACTICES

1. **Antes de codear:** Consulta siempre `DESIGN_QUICK_REFERENCE.md`
2. **Duda de diseño:** Abre `DESIGN_BLUEPRINT_MASTER.md`
3. **Cambio visual:** USA la frase clave `"MODO REDISEÑO:"`
4. **Nuevo archivo:** Agrega entrada en este índice
5. **Nueva pantalla:** Documenta en `DESIGN_BLUEPRINT_MASTER.md`

---

## 📞 CONTACTO Y SOPORTE

**Responsable:** Celiannycastro  
**Framework:** Flutter 3.9+  
**Última actualización:** 2026-01-08

---

**🎯 RECUERDA:** Este índice es tu punto de partida. Siempre revisa la documentación antes de hacer cambios importantes.

---

## 🆕 NOVEDADES (2026-01-08)

### ⭐ Módulo Fútbol Social - Feed tipo Instagram

**Nuevo módulo implementado hoy:**
- 📱 Feed social tipo Instagram/Facebook
- 📸 Compartir fotos y videos del equipo
- ❤️ Sistema de likes en tiempo real
- 📄 Paginación y scroll infinito
- 🔐 Seguridad por equipo (RLS)
- 📊 Estadísticas de engagement

**Archivos nuevos:**
- `lib/screens/social_feed_screen.dart`
- `lib/screens/create_post_screen.dart`
- `lib/services/social_service.dart`
- `lib/models/social_post_model.dart`
- `SETUP_SOCIAL_FEED.sql`
- `GUIA_FUTBOL_SOCIAL.md`
- `INICIO_RAPIDO_SOCIAL.md`

**Para empezar:**
1. Lee `INICIO_RAPIDO_SOCIAL.md` (3 pasos)
2. Ejecuta `SETUP_SOCIAL_FEED.sql` en Supabase
3. Ejecuta `flutter pub get`
4. ¡Empieza a compartir momentos! 🎉

---

_Última actualización: 2026-01-08 (Módulo Fútbol Social agregado)_
