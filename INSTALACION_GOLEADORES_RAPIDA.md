# ⚽ INSTALACIÓN RÁPIDA - SISTEMA DE GOLEADORES

## 🚀 3 PASOS PARA ACTIVAR EL SISTEMA

### PASO 1️⃣: Ejecutar SQL en Supabase (2 minutos)

1. Abre **Supabase Dashboard** → **SQL Editor**
2. Copia TODO el contenido de `SETUP_MATCH_STATS.sql`
3. Pega y presiona **"RUN"**
4. Verifica que se crearon:
   - ✅ Tabla `match_stats`
   - ✅ Vista `top_scorers`
   - ✅ 3 Funciones RPC

---

### PASO 2️⃣: Asignar Categorías a tus Equipos (1 minuto)

**Opción Fácil:** Usa el archivo `ASIGNAR_CATEGORIAS.sql`

1. Abre **Supabase Dashboard** → **SQL Editor**
2. Copia TODO el contenido de `ASIGNAR_CATEGORIAS.sql`
3. Ejecuta y sigue las instrucciones del script

**Opción Manual:** Ejecuta esto (reemplaza con tus nombres):

```sql
-- Ver tus equipos primero
SELECT id, name, category FROM teams;

-- Asignar categorías (reemplaza 'Nombre Equipo X' con tus nombres reales)
UPDATE teams SET category = 'Prebenjamín' WHERE name = 'Nombre Equipo 1';
UPDATE teams SET category = 'Benjamín' WHERE name = 'Nombre Equipo 2';
UPDATE teams SET category = 'Alevín' WHERE name = 'Nombre Equipo 3';
UPDATE teams SET category = 'Infantil' WHERE name = 'Nombre Equipo 4';
UPDATE teams SET category = 'Cadete' WHERE name = 'Nombre Equipo 5';
UPDATE teams SET category = 'Juvenil' WHERE name = 'Nombre Equipo 6';

-- Verifica que se guardaron
SELECT category, COUNT(*) as equipos FROM teams 
WHERE category IS NOT NULL 
GROUP BY category;
```

**📚 Categorías oficiales del club (Prebenjamín → Juvenil):**

| Categoría    | Edades | Sub  |
|-------------|--------|------|
| Prebenjamín | 6-7    | Sub-7 |
| Benjamín    | 8-9    | Sub-9 |
| Alevín      | 10-11  | Sub-11 |
| Infantil    | 12-13  | Sub-13 |
| Cadete      | 14-15  | Sub-15 |
| Juvenil     | 16-17  | Sub-18 |

> 💡 **Tip:** Ver la guía completa en `CATEGORIAS_REFERENCIA.md`

---

### PASO 3️⃣: Conectar IDs Reales en Flutter (5 minutos)

#### Opción A: Usar IDs Hardcoded (rápido para demo)

**En `home_screen.dart` línea ~286:**
```dart
_QuickAccessItem(
  title: 'Goleadores',
  icon: Icons.emoji_events,
  color: Colors.amber,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const TopScorersScreen(
      teamId: 'PEGA-AQUI-TU-TEAM-ID',  // ← Obtener de Supabase
      category: 'Alevín',                // ← Tu categoría
      clubId: 'PEGA-AQUI-TU-CLUB-ID',  // ← Tu club ID (auth.uid())
    )),
  ),
),
```

**En `matches_screen.dart` línea ~370:**
```dart
MatchReportScreen(
  matchId: match['id'] as String,
  teamId: 'PEGA-AQUI-TU-TEAM-ID',  // ← Tu team ID
  convocatedPlayers: demoPlayers,   // ← Después conectar a Supabase
)
```

**¿Cómo obtener tus IDs?**
```sql
-- En Supabase SQL Editor
SELECT id, name FROM teams;
SELECT auth.uid() AS club_id; -- Tu user ID
```

---

#### Opción B: Usar Provider (recomendado para producción)

1. **Crea un AppStateProvider:**

```dart
// lib/providers/app_state_provider.dart
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String? currentTeamId;
  String? currentTeamCategory;
  String? currentClubId;
  
  void setTeam(String teamId, String category) {
    currentTeamId = teamId;
    currentTeamCategory = category;
    notifyListeners();
  }
  
  void setClub(String clubId) {
    currentClubId = clubId;
    notifyListeners();
  }
}
```

2. **En `main.dart`:**

```dart
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';

runApp(
  ChangeNotifierProvider(
    create: (_) => AppState(),
    child: MyApp(),
  ),
);
```

3. **Usa el Provider en tus pantallas:**

```dart
// En home_screen.dart
final appState = Provider.of<AppState>(context);

TopScorersScreen(
  teamId: appState.currentTeamId!,
  category: appState.currentTeamCategory,
  clubId: appState.currentClubId!,
)
```

---

## ✅ VERIFICACIÓN

### ¿Funcionó correctamente?

1. **Ejecuta la app** (Flutter Run)
2. Ve a **"Command Center"** → Botón **"Goleadores"** (color dorado)
3. Deberías ver 3 pestañas: **MI EQUIPO** | **CATEGORÍA** | **CLUB GLOBAL**
4. Ve a **"Partidos"** → Selecciona un partido **FINALIZADO**
5. Presiona **"REGISTRAR ESTADÍSTICAS"**
6. Deberías ver la lista de jugadores con contadores de goles

---

## 🧪 PRUEBA CON DATOS DE EJEMPLO

Si quieres probar con datos ficticios antes de usarlo en real:

```sql
-- Insertar un partido de ejemplo
INSERT INTO matches (id, team_home, team_away, goals_home, goals_away, status, match_date)
VALUES (
  gen_random_uuid(),
  'Equipo Local',
  'Equipo Visitante',
  3,
  1,
  'FINISHED',
  NOW()
);

-- Insertar estadísticas de ejemplo (reemplaza los IDs)
INSERT INTO match_stats (match_id, player_id, team_id, goals, assists, minutes_played)
VALUES 
  ('TU-MATCH-ID', 'TU-PLAYER-ID-1', 'TU-TEAM-ID', 2, 1, 90),
  ('TU-MATCH-ID', 'TU-PLAYER-ID-2', 'TU-TEAM-ID', 1, 0, 75);
```

---

## 🎯 FLUJO DE USO REAL

### Registrar Estadísticas después de un Partido

1. Entrenador termina el partido
2. Abre la app → **"Partidos"**
3. Busca el partido que acaba de finalizar
4. Presiona **"REGISTRAR ESTADÍSTICAS"**
5. Usa los botones **+/−** para contar:
   - **Goles** (verde)
   - **Asistencias** (azul)
   - **Minutos jugados** (naranja)
6. Presiona **"GUARDAR ESTADÍSTICAS"**
7. ✅ Los datos se guardan en Supabase

### Ver Rankings

1. Desde el Command Center, presiona **"Goleadores"**
2. **TAB 1 - "MI EQUIPO":**
   - Ve a los goleadores de tu equipo
   - Ideal para motivar a los que tienen pocos goles
3. **TAB 2 - "CATEGORÍA":**
   - Ve cómo se compara tu equipo con otros de la misma edad
   - Identifica a los mejores jugadores de la categoría
4. **TAB 3 - "CLUB GLOBAL":**
   - Ranking absoluto de todo el club
   - Los niños sueñan con llegar al Top 3 🏆

---

## 🐛 TROUBLESHOOTING RÁPIDO

### Error: "No aparecen goleadores"
```sql
-- Verifica que hay estadísticas guardadas
SELECT * FROM match_stats LIMIT 10;

-- Verifica que los equipos tienen categoría
SELECT id, name, category FROM teams;
```

### Error: "No se puede guardar estadísticas"
1. Verifica las políticas RLS en Supabase → Authentication → Policies
2. Asegúrate de que el usuario está autenticado
3. Revisa la consola de Flutter para el error exacto

### Error: "Tab 'Categoría' vacío"
- Asegúrate de que otros equipos de la misma categoría tengan estadísticas guardadas
- Verifica que la categoría esté escrita igual en todos los equipos (case-sensitive)

---

## 📚 DOCUMENTACIÓN COMPLETA

Para más detalles, consulta:
- **`GUIA_SISTEMA_GOLEADORES.md`** - Documentación completa
- **`SETUP_MATCH_STATS.sql`** - Script SQL con comentarios

---

## 🎉 ¡LISTO!

Ahora tienes un sistema profesional para:
- ✅ Registrar goles y asistencias en 30 segundos
- ✅ Motivar a los jugadores con rankings
- ✅ Comparar rendimiento entre equipos
- ✅ Identificar talentos en el club

**¡Que gane el mejor Pichichi! ⚽🏆**
