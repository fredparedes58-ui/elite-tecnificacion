# 🎨 BLUEPRINT MAESTRO - DISEÑO COMPLETO CONGELADO
## FUTBOL APP - ESTADO ACTUAL Y VERDAD ABSOLUTA

**FECHA DE CONGELACIÓN:** 2026-01-08  
**VERSIÓN:** 1.0.0  
**ESTADO:** 🔒 BLOQUEADO - Solo modificable con "MODO REDISEÑO:"

---

## 📐 PALETA DE COLORES OFICIAL

### Tema Oscuro (Principal)
```dart
// Colores de Texto
primaryText: Color(0xFFFFFFFF)           // Blanco puro
secondaryText: Color(0xFFB0B0B0)         // Gris claro

// Fondos
background: Color(0xFF0A0A0A)            // Negro profundo
surface: Color(0xFF1A1A1A)               // Gris muy oscuro
cardBackground: Color(0xFF1A1F3A)        // Azul oscuro para cards

// Acentos/Neón
accent: Color(0xFFFFD700)                // Amarillo neón (primary)
accentGreen: Color(0xFF00FF00)           // Verde neón
accentBlue: Color(0xFF00FFFF)            // Azul neón

// Estados
error: Colors.redAccent
success: Colors.green.shade300
warning: Colors.yellow.shade300
info: Colors.blue.shade300
```

### Tema Claro (Secundario)
```dart
lightPrimaryText: Color(0xFF000000)      // Negro
lightSecondaryText: Color(0xFF555555)    // Gris oscuro
lightBackground: Color(0xFFF5F5F5)       // Gris muy claro
lightSurface: Color(0xFFFFFFFF)          // Blanco
lightAccent: Color(0xFF0052D4)           // Azul corporativo
```

---

## 🎯 COLORES POR FUNCIONALIDAD (SISTEMA DE NAVEGACIÓN)

### Quick Access Grid - Botones Principales
```yaml
Plantilla: Colors.blue
Tácticas: Colors.purple
Entrenamientos: Colors.green
Ejercicios: Colors.orange
Partidos: Colors.red
Chat Equipo: Colors.teal
Galería: Colors.pink
Metodología: Colors.indigo
Campos: Colors.cyan
Goleadores: Colors.amber
```

### Action Buttons - Gestión Rápida
```yaml
Añadir Jugador: Colors.blue
Subir Archivos: Colors.green
Editar Sesión: Colors.orange
```

### Modal Bottom Sheet - Acciones Flotantes
```yaml
Añadir Jugador: Colors.blue
Nueva Sesión: Colors.green
Subir Archivo: Colors.orange
Editar Elemento: Colors.purple
Eliminar Elemento: Colors.red
```

---

## 📏 DIMENSIONES Y ESPACIADOS OFICIALES

### Typography (GoogleFonts)
```yaml
# AppBar Title
font: GoogleFonts.oswald
fontSize: 24
fontWeight: FontWeight.bold
letterSpacing: 2.0

# Welcome Header - Subtitle
font: GoogleFonts.roboto
fontSize: 14
color: textTheme.bodySmall.color

# Welcome Header - Title
font: GoogleFonts.oswald
fontSize: 24
fontWeight: FontWeight.bold

# Section Titles
font: GoogleFonts.robotoCondensed
fontSize: 16
fontWeight: FontWeight.bold
letterSpacing: 1.5
transform: toUpperCase()

# Quick Access Cards - Text
font: GoogleFonts.roboto
fontSize: 11
fontWeight: FontWeight.w600
maxLines: 2

# Action Buttons - Title
font: GoogleFonts.roboto
fontSize: 16
fontWeight: FontWeight.bold

# Action Buttons - Subtitle
font: GoogleFonts.roboto
fontSize: 12

# Modal ListTile
font: GoogleFonts.roboto
fontSize: default (16)
```

### Espaciados Globales
```yaml
# Body Padding
body_padding: EdgeInsets.all(16.0)

# Vertical Spacing
section_spacing: 32
card_spacing: 24
element_spacing: 16
small_spacing: 12
mini_spacing: 8

# Welcome Header
padding: 20
borderRadius: 16
icon_padding: 12
icon_size: 32
gap_after: 24

# Section Title
icon_size: 20
icon_gap: 8
line_margin_left: 16
gap_after: 16

# Quick Access Grid
crossAxisCount: 4
crossAxisSpacing: 12
mainAxisSpacing: 12
childAspectRatio: 1.0
gap_after: 32

# Action Buttons
padding: 16
icon_padding: 12
icon_size: 24
borderRadius: 12
gap_between: 12
```

### Border Radius
```yaml
cards: 16
buttons: 12
quick_access: 16
action_buttons: 12
modal_sheet_top: 20
modal_handle: 2
elevated_buttons: 30
input_fields: 30 (dark) / 12 (light)
```

### Borders & Strokes
```yaml
welcome_header_border: 1px
quick_access_border: 1px
action_button_border: 1px
modal_border: 1px
card_border: 1px (alpha: 204 en dark theme)
```

### Opacidades (withOpacity)
```yaml
gradient_start: 0.2
gradient_end: 0.1 o 0.05
border_opacity: 0.3
icon_container: 0.2
modal_handle: 0.3
divider: 0.5
```

---

## 🏗️ ESTRUCTURA DE HOME SCREEN (Command Center)

### Jerarquía Visual Completa
```
Scaffold
├── AppBar
│   ├── title: "COMMAND CENTER" (Oswald, 24, bold, spacing: 2)
│   ├── centerTitle: true
│   ├── elevation: 0
│   ├── backgroundColor: Colors.transparent
│   └── actions
│       ├── IconButton(notifications_outlined) → primary color
│       └── IconButton(settings_outlined) → SettingsScreen
│
├── body: SingleChildScrollView
│   └── padding: EdgeInsets.all(16)
│       └── Column
│           ├── _buildWelcomeHeader (gap: 24)
│           │   ├── Container (padding: 20, borderRadius: 16)
│           │   │   ├── gradient: [primary.opacity(0.2), secondary.opacity(0.1)]
│           │   │   ├── border: primary.opacity(0.3), width: 1
│           │   │   └── Row
│           │   │       ├── Icon Container (circle, padding: 12, size: 32)
│           │   │       └── Column (gap: 16)
│           │   │           ├── Text "Bienvenido de nuevo" (Roboto, 14)
│           │   │           └── Text "Entrenador" (Oswald, 24, bold)
│           │
│           ├── SECCIÓN 1: ACCESO RÁPIDO (gap: 32)
│           │   ├── _buildSectionTitle("Acceso Rápido", dashboard) (gap: 16)
│           │   └── _buildQuickAccessGrid (4 columnas, spacing: 12)
│           │       ├── Plantilla (blue) → SquadManagementScreen
│           │       ├── Tácticas (purple) → TacticalBoardScreen
│           │       ├── Entrenamientos (green) → SessionPlannerScreen
│           │       ├── Ejercicios (orange) → DrillsScreen
│           │       ├── Partidos (red) → MatchesScreen
│           │       ├── Chat Equipo (teal) → TeamChatScreen(coach, Entrenador)
│           │       ├── Galería (pink) → GalleryScreen
│           │       ├── Metodología (indigo) → MethodologyScreen
│           │       ├── Campos (cyan) → FieldScheduleScreen
│           │       └── Goleadores (amber) → TopScorersScreen(demo-team-id)
│           │
│           ├── SECCIÓN 2: PRÓXIMO PARTIDO (gap: 32)
│           │   ├── _buildSectionTitle("Próximo Partido", sports_soccer) (gap: 16)
│           │   └── UpcomingMatchCard (widget externo)
│           │
│           ├── SECCIÓN 3: CLASIFICACIÓN (gap: 32)
│           │   ├── _buildSectionTitle("Clasificación en Vivo", leaderboard) (gap: 16)
│           │   └── LiveStandingsCard (widget externo)
│           │
│           ├── SECCIÓN 4: ESTADO DEL EQUIPO (gap: 32)
│           │   ├── _buildSectionTitle("Estado del Equipo", groups) (gap: 16)
│           │   └── SquadStatusCard (widget externo)
│           │
│           └── SECCIÓN 5: GESTIÓN RÁPIDA (gap: 32)
│               ├── _buildSectionTitle("Gestión Rápida", bolt) (gap: 16)
│               └── _buildQuickActions
│                   ├── Añadir Jugador (blue, gap: 12) → SnackBar
│                   ├── Subir Archivos (green, gap: 12) → SnackBar
│                   └── Editar Sesión (orange) → SessionPlannerScreen
│
└── floatingActionButton: FloatingActionButton.extended
    ├── icon: Icons.add
    ├── label: "ACCIONES"
    ├── backgroundColor: primary
    └── onPressed: _showQuickActionMenu
        └── ModalBottomSheet (borderRadius top: 20)
            ├── handle (width: 40, height: 4, margin: 12/20)
            ├── ListTile: Añadir Jugador (blue) → SnackBar
            ├── ListTile: Nueva Sesión (green) → SessionPlannerScreen
            ├── ListTile: Subir Archivo (orange) → SnackBar
            ├── ListTile: Editar Elemento (purple) → SnackBar
            └── ListTile: Eliminar Elemento (red) → SnackBar
```

---

## 🎴 WIDGETS PRINCIPALES - DISEÑO DETALLADO

### 1. LiveStandingsCard
```yaml
Container:
  backgroundColor: Color(0xFF1A1F3A)
  borderRadius: 16
  padding: 20

Title:
  text: "LIVE STANDINGS"
  font: GoogleFonts.roboto
  fontSize: 14
  fontWeight: bold
  color: Colors.white
  letterSpacing: 1.5
  margin_bottom: 16

Table:
  scroll: horizontal
  minWidth: screen_width - 72

Headers:
  font: GoogleFonts.roboto
  fontSize: 10
  fontWeight: bold
  color: Colors.grey.shade400
  letterSpacing: 1.0
  columns:
    - # (width: 32)
    - TEAM (width: 140)
    - J (width: 28, center)
    - G (width: 28, center)
    - E (width: 28, center)
    - P (width: 28, center)
    - GF (width: 32, center)
    - GC (width: 32, center)
    - DIF (width: 38, center)
    - PT (width: 38, right)

Rows:
  padding: vertical(8), horizontal(4)
  borderRadius: 8
  highlighted_bg: Color(0xFFFFD700).withAlpha(38) # 0.15 opacity
  gap_between: 6

Position_Indicator:
  width: 6
  height: 6
  shape: circle
  colors:
    top_3: Color(0xFFFFD700)  # Amarillo
    4-6: Colors.blue
    rest: Colors.grey.shade400

Team_Shield:
  width: 24
  height: 24
  shape: circle
  gradient: [white.alpha(50), white.alpha(30)]
  border: white.alpha(80), width: 1
  font: GoogleFonts.robotoCondensed
  fontSize: 9
  fontWeight: bold

Team_Name:
  width: 120
  font: GoogleFonts.roboto
  fontSize: 11
  fontWeight: w600
  color: Colors.white
  maxLines: 1

Stats:
  font: GoogleFonts.roboto
  fontSize: 11
  fontWeight: w500
  colors:
    wins: Colors.green.shade300
    draws: Colors.yellow.shade300
    losses: Colors.red.shade300
    positive_diff: Colors.green.shade300
    negative_diff: Colors.red.shade300
    default: Colors.white70

Points:
  fontSize: 12
  fontWeight: bold
  color: Colors.white

Divider:
  height: 1
  color: Colors.grey.shade700
  margin_bottom: 8
```

### 2. UpcomingMatchCard
```yaml
Card:
  elevation: 8
  shadowColor: Colors.black.withAlpha(128)
  borderRadius: 20
  padding: 20

Container:
  gradient: 
    dark: [primary.alpha(26), Colors.black.alpha(102)]
    light: [primary.alpha(204), primary]
  borderRadius: 20

Team_Display:
  shield:
    height: 80
    width: 80
    shape: circle
    gradient: [white.alpha(40), white.alpha(20)]
    border: white.alpha(100), width: 2
    shadow: [black.alpha(50), blur: 8, offset: (0,4)]
    initials:
      font: GoogleFonts.robotoCondensed
      fontSize: 24
      fontWeight: bold
      letterSpacing: 1.0
  name:
    font: GoogleFonts.robotoCondensed
    fontSize: 14
    fontWeight: bold
    letterSpacing: 0.5
    transform: toUpperCase()
    margin_top: 12
    maxLines: 2

VS_Text:
  font: GoogleFonts.oswald
  fontSize: 28
  fontWeight: bold
  color: Colors.white

Divider:
  color: Colors.white.withAlpha(51)
  thickness: 1
  indent: 20
  endIndent: 20
  margin: 24 / 16

Match_Info:
  date:
    font: GoogleFonts.robotoCondensed
    fontSize: 14
    fontWeight: bold
    color: Colors.white.withAlpha(204)
    letterSpacing: 1.0
  location:
    font: GoogleFonts.roboto
    fontSize: 14
    color: Colors.white.withAlpha(179)
    margin_top: 8
```

### 3. QuickAccessCard (Grid Items)
```yaml
InkWell:
  borderRadius: 16

Container:
  gradient: [color.opacity(0.2), color.opacity(0.05)]
  borderRadius: 16
  border: color.opacity(0.3), width: 1

Column:
  mainAxisAlignment: center
  icon:
    size: 32
    color: item.color
  gap: 8
  text:
    font: GoogleFonts.roboto
    fontSize: 11
    fontWeight: w600
    textAlign: center
    maxLines: 2
    overflow: ellipsis
```

### 4. ActionButton (Gestión Rápida)
```yaml
InkWell:
  borderRadius: 12

Container:
  padding: 16
  borderRadius: 12
  backgroundColor: color.opacity(0.1)
  border: color.opacity(0.3), width: 1

Row:
  icon_container:
    padding: 12
    borderRadius: 8
    backgroundColor: color.opacity(0.2)
    icon:
      size: 24
      color: color
  gap: 16
  text_column:
    title:
      font: GoogleFonts.roboto
      fontSize: 16
      fontWeight: bold
    subtitle:
      font: GoogleFonts.roboto
      fontSize: 12
  arrow:
    icon: arrow_forward_ios
    size: 16
    color: color
```

---

## 🗺️ SISTEMA DE NAVEGACIÓN COMPLETO

### Mapa de Rutas y Privilegios
```yaml
HomeScreen (Command Center):
  role: ANY
  params: none
  routes:
    - SquadManagementScreen (role: coach)
    - TacticalBoardScreen (role: coach)
    - SessionPlannerScreen (role: coach)
    - DrillsScreen (role: coach/player)
    - MatchesScreen (role: ANY)
    - TeamChatScreen (role: coach, userName: "Entrenador")
    - GalleryScreen (role: ANY)
    - MethodologyScreen (role: coach)
    - FieldScheduleScreen (role: ANY)
    - TopScorersScreen (teamId, category, clubId)
    - SettingsScreen (role: ANY)

SquadManagementScreen:
  role_required: coach
  params: none
  can:
    - view_all_players
    - add_player
    - edit_player
    - delete_player
    - update_photo

TeamChatScreen:
  params_required:
    - userRole: string (coach/player)
    - userName: string
  can:
    - send_message
    - view_messages
    - delete_own_message (if owner)

TopScorersScreen:
  params_required:
    - teamId: string
    - category: string
    - clubId: string
  can:
    - view_scorers
    - view_stats

PlayerCardScreen:
  params_required:
    - playerId: string
    - playerName: string
    - userRole: string
  can:
    - view_player_details
    - update_photo (if coach)
    - view_stats
    - view_radar_chart
```

### Privilegios por Rol
```yaml
COACH:
  can:
    - access_all_screens
    - create: [player, session, drill, tactic]
    - read: [all_data]
    - update: [player, session, drill, tactic, photo]
    - delete: [session, drill, tactic]
  cannot:
    - delete: [player] # Solo desactivar

PLAYER:
  can:
    - access: [home, drills, matches, gallery, chat]
    - read: [own_stats, team_schedule, standings]
    - update: [own_photo, own_profile]
  cannot:
    - create: [anything]
    - update: [others_data]
    - delete: [anything]
    - access: [squad_management, tactics, session_planner]

PARENT:
  can:
    - access: [home, matches, gallery]
    - read: [own_child_stats, team_schedule]
    - view: [photos, videos]
  cannot:
    - create/update/delete: [anything]
    - access: [management_screens]
```

---

## 🎨 COMPONENTES REUTILIZABLES - ESPECIFICACIONES

### Modal Bottom Sheet (Patrón Estándar)
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content (ListTiles)
          // ...
          SizedBox(height: 20),
        ],
      ),
    );
  },
);
```

### Section Title (Patrón Estándar)
```dart
Row(
  children: [
    Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
    SizedBox(width: 8),
    Text(
      title.toUpperCase(),
      style: GoogleFonts.robotoCondensed(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    Expanded(
      child: Container(
        height: 1,
        margin: EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ),
  ],
);
```

### Team Shield/Logo Generator
```dart
Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withAlpha(50),
        Colors.white.withAlpha(30),
      ],
    ),
    shape: BoxShape.circle,
    border: Border.all(
      color: Colors.white.withAlpha(80),
      width: borderWidth,
    ),
  ),
  child: Center(
    child: Text(
      initials,
      style: GoogleFonts.robotoCondensed(
        fontSize: initialsFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  ),
);
```

---

## 📊 DATOS Y MODELOS

### TeamStanding (league_data.dart)
```dart
TeamStanding(
  position: int,
  club: String,           // Nombre completo con formato oficial
  games: int,             // J
  wins: int,              // G
  draws: int,             // E
  losses: int,            // P
  goalsFor: int,          // GF
  goalsAgainst: int,      // GC
  goalDifference: int,    // DIF
  points: int,            // PT
)

// Team destacado:
highlightedTeam: "C.F. Fundació VCF 'A'"
```

### UpcomingMatch (upcoming_matches_data.dart)
```dart
UpcomingMatch(
  homeTeam: String,       // Equipo local
  awayTeam: String,       // Equipo visitante
  date: String,           // "SÁBADO, 11 DE ENERO"
  time: String,           // "16:00"
  location: String,       // "Ciutat Esportiva de Paterna"
)

// Actual:
homeTeam: "C.F. Fundació VCF 'A'"
awayTeam: "F.B.U.E. Atlètic Amistat 'A'"
```

---

## 🔐 CONFIGURACIÓN DE SUPABASE

### Storage Buckets
```yaml
player-photos:
  public: true
  size_limit: 5MB
  mime_types: [image/jpeg, image/png, image/webp]
  policies:
    - public_read
    - authenticated_write
    - authenticated_update
    - authenticated_delete

app-files:
  public: false
  size_limit: 10MB
  policies:
    - authenticated_full_access

documents:
  public: false
  size_limit: 20MB
  mime_types: [application/pdf]
  policies:
    - coach_full_access
    - player_read_only
```

### Database Tables
```sql
profiles:
  id: uuid (PK)
  full_name: text
  avatar_url: text (default: 'assets/players/default.png')
  role: text (coach/player/parent)
  created_at: timestamp

team_members:
  id: uuid (PK)
  profile_id: uuid (FK → profiles)
  team_id: uuid (FK → teams)
  role: text (starter/substitute/reserve)
  is_starter: boolean
  position: text

quarterly_reports:
  id: uuid (PK)
  player_id: uuid (FK → profiles)
  technical: int
  tactical: int
  physical: int
  mental: int
  created_at: timestamp
```

---

## ⚙️ CONFIGURACIÓN DE ARCHIVOS

### pubspec.yaml - Dependencias Críticas
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  url_launcher: ^6.3.2
  fl_chart: ^1.1.1
  intl: ^0.19.0
  file_picker: ^9.0.0
  provider: ^6.1.5+1
  google_fonts: ^6.3.3
  uuid: ^4.5.2
  supabase_flutter: ^2.12.0
  image_picker: ^1.2.1
  csv: ^6.0.0
  table_calendar: ^3.1.3

assets:
  - assets/data/teams_data.json
  - assets/players/
  - assets/images/
```

### .cursorrules - Reglas de UI Freeze
```
PROTOCOL: UI_FREEZE
STATUS: BLOQUEADO
FILES: home_screen.dart, live_standings_card.dart, upcoming_match_card.dart
UNLOCK_KEY: "MODO REDISEÑO:"
```

---

## 📝 CHANGELOG Y VERSIONES

### v1.0.0 (2026-01-08) - ACTUAL
- ✅ Command Center con 10 botones de navegación
- ✅ LiveStandingsCard con 13 equipos completos
- ✅ UpcomingMatchCard con escudos dinámicos
- ✅ Sistema de gestión de fotos multiplataforma
- ✅ FileManagementService completo
- ✅ Navegación a SquadManagementScreen
- ✅ Integración con FieldScheduleScreen
- ✅ Integración con TopScorersScreen
- ✅ Privilegios por roles (coach/player)
- ✅ Tema oscuro elite con neón

### Próximas Versiones (NO IMPLEMENTADAS)
- [ ] v1.1.0: Formulario real de añadir jugador
- [ ] v1.2.0: Uploader visual de archivos
- [ ] v1.3.0: Notificaciones push
- [ ] v1.4.0: Chat en tiempo real
- [ ] v1.5.0: Dashboard de analíticas

---

## 🚨 REGLAS DE MODIFICACIÓN

### ❌ PROHIBIDO CAMBIAR SIN "MODO REDISEÑO:"
- Colores (Colors.*, Color(0x...))
- Tamaños de fuente (fontSize)
- Espaciados (SizedBox, Padding, EdgeInsets)
- BorderRadius
- Opacidades (withOpacity, withAlpha)
- Estilos de texto (fontWeight, letterSpacing)
- Gradientes (LinearGradient)
- Iconos (size, color)
- Estructura del árbol de widgets

### ✅ PERMITIDO CAMBIAR LIBREMENTE
- Lógica de onPressed
- Funciones de navegación
- Conexiones a base de datos
- Estados y providers
- Validaciones de formularios
- Llamadas a APIs
- Manejo de errores
- Logging y debugging

### 🔑 CÓMO DESBLOQUEAR
```
Prompt debe iniciar con:
"MODO REDISEÑO: [instrucción específica]"

Ejemplos válidos:
- "MODO REDISEÑO: Cambia el botón de Plantilla a color verde"
- "MODO REDISEÑO: Aumenta el padding del AppBar a 24"
- "MODO REDISEÑO: Reorganiza el grid a 3 columnas"
```

---

## 📚 REFERENCIAS RÁPIDAS

### Archivos Clave
```
lib/
├── screens/
│   ├── home_screen.dart ⭐ (CONGELADO)
│   ├── squad_management_screen.dart
│   ├── tactical_board_screen.dart
│   ├── session_planner_screen.dart
│   ├── field_schedule_screen.dart
│   └── top_scorers_screen.dart
├── widgets/
│   ├── live_standings_card.dart ⭐ (CONGELADO)
│   ├── upcoming_match_card.dart ⭐ (CONGELADO)
│   ├── squad_status_card.dart
│   └── player_info_card.dart
├── theme/
│   └── theme.dart ⭐ (COLORES OFICIALES)
├── services/
│   ├── file_management_service.dart
│   └── supabase_service.dart
└── data/
    ├── league_data.dart (13 equipos FFCV)
    └── upcoming_matches_data.dart
```

### Comandos de Flutter
```bash
# Hot reload (aplicar cambios de lógica)
r

# Hot restart (reiniciar app completa)
R

# Ejecutar en Chrome
flutter run -d chrome

# Ejecutar en móvil
flutter run

# Análisis de código
flutter analyze

# Limpiar build
flutter clean
```

---

**🔒 ESTE DOCUMENTO ES LA ÚNICA VERDAD ABSOLUTA**  
**Cualquier cambio visual debe actualizarse aquí primero**  
**Versión controlada en: .cursorrules + DESIGN_BLUEPRINT_MASTER.md**

---

_Última actualización: 2026-01-08 01:45 UTC_  
_Responsable: Celiannycastro_  
_Framework: Flutter 3.9+_  
_Estado: PRODUCCIÓN CONGELADA_ 🧊
