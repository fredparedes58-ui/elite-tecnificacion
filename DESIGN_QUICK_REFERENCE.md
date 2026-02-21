# 🎨 GUÍA VISUAL RÁPIDA - DESIGN FROZEN

> **⚠️ DOCUMENTO DE REFERENCIA RÁPIDA**  
> Para especificaciones completas ver: `DESIGN_BLUEPRINT_MASTER.md`

---

## 🎯 COLORES RÁPIDOS

```dart
// PRINCIPAL
primary: Color(0xFFFFD700)          // Amarillo neón
background: Color(0xFF0A0A0A)       // Negro
surface: Color(0xFF1A1A1A)          // Gris oscuro
cardBg: Color(0xFF1A1F3A)           // Azul oscuro

// NAVEGACIÓN (Quick Access)
blue, purple, green, orange, red, teal, pink, indigo, cyan, amber
```

---

## 📐 TAMAÑOS CRÍTICOS

```dart
// TYPOGRAPHY
AppBar: Oswald, 24, bold, spacing: 2
SectionTitle: RobotoCondensed, 16, bold, spacing: 1.5
QuickAccess: Roboto, 11, w600
ActionTitle: Roboto, 16, bold

// SPACING
body: 16
section_gap: 32
card_gap: 24
element_gap: 16

// RADIUS
card: 16
button: 12
modal: 20

// ICON SIZES
header: 32
section: 20
quick_access: 32
action: 24
```

---

## 🏗️ ESTRUCTURA HOME SCREEN

```
AppBar (title: COMMAND CENTER)
├── notifications → SnackBar
└── settings → SettingsScreen

Body:
├── WelcomeHeader (padding: 20, radius: 16)
├── Acceso Rápido (grid 4x3, spacing: 12)
│   ├── Plantilla (blue) → SquadManagementScreen
│   ├── Tácticas (purple) → TacticalBoardScreen  
│   ├── Entrenamientos (green) → SessionPlannerScreen
│   ├── Ejercicios (orange) → DrillsScreen
│   ├── Partidos (red) → MatchesScreen
│   ├── Chat (teal) → TeamChatScreen(coach, Entrenador)
│   ├── Galería (pink) → GalleryScreen
│   ├── Metodología (indigo) → MethodologyScreen
│   ├── Campos (cyan) → FieldScheduleScreen
│   └── Goleadores (amber) → TopScorersScreen
├── Próximo Partido → UpcomingMatchCard
├── Clasificación → LiveStandingsCard (13 equipos)
├── Estado Equipo → SquadStatusCard
└── Gestión Rápida
    ├── Añadir Jugador (blue)
    ├── Subir Archivos (green)
    └── Editar Sesión (orange)

FAB: ACCIONES → Modal (5 opciones)
```

---

## 🎴 WIDGETS PRINCIPALES

### LiveStandingsCard
- Fondo: `Color(0xFF1A1F3A)`
- 10 columnas: #, TEAM, J, G, E, P, GF, GC, DIF, PT
- Colores: wins (green), draws (yellow), losses (red)
- Highlighted: `FFD700` con alpha 0.15

### UpcomingMatchCard
- Shield: 80x80, circle, gradient
- VS: Oswald, 28, bold
- Fecha: RobotoCondensed, 14, bold

### QuickAccessCard
- Gradient: color(0.2) → color(0.05)
- Border: color(0.3)
- Icon: 32px
- Text: Roboto, 11, w600

---

## 🔐 ROLES Y PRIVILEGIOS

```yaml
COACH:
  acceso: ALL
  puede: create, read, update, delete (excepto player)

PLAYER:
  acceso: home, drills, matches, gallery, chat
  puede: read (own_stats), update (own_profile)

PARENT:
  acceso: home, matches, gallery
  puede: read (child_stats)
```

---

## 🗺️ NAVEGACIÓN

| Pantalla | Parámetros | Role |
|----------|------------|------|
| SquadManagementScreen | none | coach |
| TeamChatScreen | userRole, userName | ANY |
| TopScorersScreen | teamId, category, clubId | ANY |
| PlayerCardScreen | playerId, playerName, userRole | ANY |

---

## ⚙️ CONFIGURACIÓN SUPABASE

```sql
Buckets:
- player-photos (public, 5MB, jpg/png/webp)
- app-files (private, 10MB)
- documents (private, 20MB, pdf)

Tables:
- profiles (id, full_name, avatar_url, role)
- team_members (profile_id, team_id, role, is_starter)
- quarterly_reports (player_id, technical, tactical, physical, mental)
```

---

## 🔒 REGLA DE ORO

**❌ NO TOCAR:** Colors, fontSize, padding, borderRadius, opacity  
**✅ MODIFICAR:** onPressed, lógica, navegación, backend  
**🔑 DESBLOQUEAR:** Iniciar prompt con `"MODO REDISEÑO:"`

---

## 📂 ARCHIVOS CLAVE

```
📁 CONGELADOS (UI FREEZE):
- lib/screens/home_screen.dart
- lib/widgets/live_standings_card.dart
- lib/widgets/upcoming_match_card.dart
- lib/theme/theme.dart

📁 CONFIGURACIÓN:
- .cursorrules (reglas AI)
- DESIGN_BLUEPRINT_MASTER.md (949 líneas)
- SETUP_SUPABASE_STORAGE.md

📁 SERVICIOS:
- lib/services/file_management_service.dart
- lib/services/supabase_service.dart

📁 DATOS:
- lib/data/league_data.dart (13 equipos FFCV)
- lib/data/upcoming_matches_data.dart
```

---

## 🚀 COMANDOS FLUTTER

```bash
flutter run -d chrome        # Ejecutar en navegador
r                            # Hot reload (dentro de flutter run)
R                            # Hot restart (dentro de flutter run)
flutter analyze              # Verificar código
flutter clean                # Limpiar cache
```

---

**ÚLTIMA ACTUALIZACIÓN:** 2026-01-08  
**VERSIÓN:** 1.0.0  
**ESTADO:** 🔒 PRODUCCIÓN CONGELADA
