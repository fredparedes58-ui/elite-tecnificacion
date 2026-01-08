# 🏆 SISTEMA INTEGRAL DE GOLEADORES (PICHICHI)

## 📋 Descripción General

Sistema completo que permite a los entrenadores registrar las estadísticas de goles, asistencias y minutos jugados de cada jugador, y visualizar rankings de goleadores a tres niveles: equipo, categoría y club global.

---

## 🗂️ Estructura del Sistema

### 1. BASE DE DATOS (Supabase)

**Archivo:** `SETUP_MATCH_STATS.sql`

#### Tabla Principal: `match_stats`
```sql
- id (UUID, PK)
- match_id (UUID, FK → matches)
- player_id (UUID, FK → players)
- team_id (UUID, FK → teams)
- goals (INTEGER, default 0)
- assists (INTEGER, default 0)
- minutes_played (INTEGER, default 0)
- yellow_cards (INTEGER, default 0)
- red_cards (INTEGER, default 0)
- created_at / updated_at (TIMESTAMP)
```

#### Actualización en Tabla Teams
```sql
- category (VARCHAR(50)) - Ejemplos: "Prebenjamín", "Benjamín", "Alevín", "Infantil", "Cadete", "Juvenil", "Senior"
```

#### Vistas y Funciones Creadas
- **Vista `top_scorers`:** Rankings agregados con SUM(goals), SUM(assists), COUNT(matches)
- **Función `get_team_top_scorers()`:** Top goleadores de un equipo específico
- **Función `get_category_top_scorers()`:** Top goleadores de una categoría (ej: todos los Alevines)
- **Función `get_club_top_scorers()`:** Top goleadores de todo el club

---

## 📱 PANTALLAS CREADAS

### 1. **MatchReportScreen** (Entrada de Datos)

**Archivo:** `lib/screens/match_report_screen.dart`

**Funcionalidad:**
- Lista de jugadores convocados para el partido
- Contadores +/- para:
  - **Goles** (verde) 🟢
  - **Asistencias** (azul) 🔵
  - **Minutos jugados** (naranja, incrementos de 5) 🟠
- Botón "GUARDAR ESTADÍSTICAS" que hace upsert en Supabase
- Carga estadísticas existentes si el partido ya fue reportado

**Navegación desde:**
- `MatchesScreen` → Botón "REGISTRAR ESTADÍSTICAS" (solo en partidos FINISHED)

**Parámetros requeridos:**
```dart
MatchReportScreen(
  matchId: String,
  teamId: String,
  convocatedPlayers: List<Player>,
)
```

---

### 2. **TopScorersScreen** (Rankings de Goleadores)

**Archivo:** `lib/screens/top_scorers_screen.dart`

**Funcionalidad:**
Pantalla con **3 pestañas (TabBar):**

#### TAB 1: "MI EQUIPO"
- Muestra los top 10 goleadores del equipo actual
- Incluye: foto, nombre, dorsal, posición, goles, asistencias, partidos jugados

#### TAB 2: "CATEGORÍA"
- Muestra los top 20 goleadores de todos los equipos de la misma categoría
- Ejemplo: Si tu equipo es "Alevín", muestra todos los goleadores Alevines del club
- Muestra además el nombre del equipo de cada jugador

#### TAB 3: "CLUB GLOBAL"
- Ranking absoluto: los top 50 goleadores de todas las categorías
- Muestra equipo y categoría de cada jugador
- Permite comparar quién es el máximo goleador de toda la escuela

**Diseño Especial:**
- **Top 3:** Tarjetas con colores especiales:
  - 🥇 **1º lugar:** Oro (#FFD700)
  - 🥈 **2º lugar:** Plata (#C0C0C0)
  - 🥉 **3º lugar:** Bronce (#CD7F32)
- Resto: Números #4, #5, etc.

**Navegación desde:**
- `HomeScreen` → Grid "Acceso Rápido" → Botón "Goleadores" (color: amber)

**Parámetros requeridos:**
```dart
TopScorersScreen(
  teamId: String,
  category: String?, // Puede ser null
  clubId: String,
)
```

---

## 🔧 SERVICIOS Y MODELOS

### StatsService (`lib/services/stats_service.dart`)

Métodos principales:
```dart
// CRUD
getMatchStats(String matchId)
saveMatchStats({matchId, teamId, playersStats})
updatePlayerMatchStats({...})
deleteMatchStats(String matchId)

// Rankings
getTeamTopScorers({teamId, limit})
getCategoryTopScorers({category, clubId, limit})
getClubTopScorers({clubId, limit})

// Utilidades
getPlayerTotalStats(String playerId)
matchHasStats(String matchId)
getTeamTopScorer(String teamId)
getClubCategories(String clubId)
updateTeamCategory({teamId, category})
```

### Modelos (`lib/models/match_stats_model.dart`)

```dart
class MatchStats {
  String id, matchId, playerId, teamId;
  int goals, assists, minutesPlayed;
  // ...
}

class TopScorer {
  String playerId, playerName;
  String? photoUrl, position, teamName, category;
  int totalGoals, totalAssists, matchesPlayed;
  double goalsPerMatch;
  // ...
}

class PlayerStatsInput {
  String playerId, playerName;
  int goals, assists, minutesPlayed;
  // Usado para la entrada de datos en MatchReportScreen
}
```

---

## 🚀 INSTALACIÓN Y CONFIGURACIÓN

### PASO 1: Ejecutar Script SQL en Supabase

1. Abre Supabase Dashboard → SQL Editor
2. Copia y pega el contenido de `SETUP_MATCH_STATS.sql`
3. Ejecuta el script completo
4. Verifica que se hayan creado:
   - Tabla `match_stats`
   - Vista `top_scorers`
   - Funciones RPC (get_team_top_scorers, get_category_top_scorers, get_club_top_scorers)

### PASO 2: Asignar Categorías a los Equipos

Si tus equipos aún no tienen categoría asignada:

```sql
UPDATE teams SET category = 'Alevín' WHERE id = 'tu-team-id-1';
UPDATE teams SET category = 'Benjamín' WHERE id = 'tu-team-id-2';
-- etc...
```

O desde la app:
```dart
await StatsService().updateTeamCategory(
  teamId: 'tu-team-id',
  category: 'Alevín',
);
```

### PASO 3: Integrar IDs Reales

**IMPORTANTE:** Los siguientes lugares tienen IDs de demostración que debes reemplazar:

#### En `home_screen.dart` (línea ~286):
```dart
TopScorersScreen(
  teamId: 'REEMPLAZAR-CON-ID-REAL', // Obtener del provider/contexto
  category: 'REEMPLAZAR-CON-CATEGORIA-REAL',
  clubId: 'REEMPLAZAR-CON-ID-REAL',
)
```

#### En `matches_screen.dart` (línea ~340):
```dart
MatchReportScreen(
  matchId: match['id'],
  teamId: 'REEMPLAZAR-CON-ID-REAL', // Del contexto
  convocatedPlayers: listaRealDeJugadores, // De Supabase
)
```

**Recomendación:** Usa un `Provider` o servicio de autenticación para mantener:
- `currentTeamId`
- `currentTeamCategory`
- `currentClubId`
- `currentUserId`

---

## 📊 FLUJO DE USO

### Escenario 1: Registrar Estadísticas de un Partido

1. Usuario va a "Partidos" (desde Home)
2. Ve lista de partidos
3. En un partido **FINALIZADO**, presiona "REGISTRAR ESTADÍSTICAS"
4. Se abre `MatchReportScreen` con la lista de jugadores
5. Entrenador usa botones +/- para contar goles, asistencias y minutos
6. Presiona "GUARDAR ESTADÍSTICAS"
7. Los datos se guardan en `match_stats` en Supabase
8. Sistema muestra confirmación y vuelve a la lista

### Escenario 2: Ver Rankings de Goleadores

1. Usuario va a "Goleadores" (desde Home → Grid)
2. Se abre `TopScorersScreen` con 3 pestañas
3. **TAB "MI EQUIPO":**
   - Ve a sus propios jugadores ordenados por goles
   - Puede motivar a los que tienen pocos goles
4. **TAB "CATEGORÍA":**
   - Ve cómo se compara su equipo con otros de la misma edad
   - Identifica a los mejores jugadores de la categoría
5. **TAB "CLUB GLOBAL":**
   - Ve quién es el máximo goleador de toda la escuela
   - Los niños sueñan con llegar al Top 3 🏆

---

## 🎨 DISEÑO Y ESTÉTICA

**PROTOCOL: UI_FREEZE Respetado ✅**

Todos los elementos visuales siguen el estilo Elite del Command Center:
- ✅ Paleta de colores neón/oscura original
- ✅ `GoogleFonts.oswald()` para títulos
- ✅ `GoogleFonts.roboto()` para texto secundario
- ✅ Gradientes con opacidades 0.2 → 0.05
- ✅ Bordes con opacidad 0.3
- ✅ BorderRadius de 12/16px
- ✅ Iconos con tamaño 20-32px

**Colores Específicos:**
- Goles: `Colors.green` 🟢
- Asistencias: `Colors.blue` 🔵
- Minutos: `Colors.orange` 🟠
- Goleadores: `Colors.amber` 🟡
- Top 1: `#FFD700` (Oro)
- Top 2: `#C0C0C0` (Plata)
- Top 3: `#CD7F32` (Bronce)

---

## 🔒 SEGURIDAD (RLS)

Las políticas de Row Level Security permiten:
- ✅ Ver estadísticas de partidos de tus equipos
- ✅ Insertar/actualizar estadísticas solo de tus equipos
- ✅ Eliminar estadísticas solo de tus equipos
- ❌ No puedes modificar estadísticas de otros clubes

---

## 📈 CONSULTAS ÚTILES PARA DEBUG

### Ver todas las estadísticas de un partido
```sql
SELECT * FROM match_stats WHERE match_id = 'tu-match-id';
```

### Ver el ranking de goleadores (vista)
```sql
SELECT * FROM top_scorers ORDER BY total_goals DESC LIMIT 10;
```

### Probar las funciones RPC
```sql
-- Top scorers de un equipo
SELECT * FROM get_team_top_scorers('tu-team-id', 10);

-- Top scorers de una categoría
SELECT * FROM get_category_top_scorers('Alevín', 'tu-club-id', 20);

-- Top scorers del club
SELECT * FROM get_club_top_scorers('tu-club-id', 50);
```

### Ver equipos sin categoría asignada
```sql
SELECT id, name, category FROM teams WHERE category IS NULL;
```

---

## 🐛 TROUBLESHOOTING

### Problema: "No aparecen goleadores"
**Solución:**
1. Verifica que existan estadísticas guardadas: `SELECT * FROM match_stats;`
2. Asegúrate de que `goals > 0` (la vista filtra jugadores sin goles)
3. Verifica que los `team_id` y `club_id` coincidan

### Problema: "Tab 'Categoría' está vacío"
**Solución:**
1. Asigna una categoría al equipo: `UPDATE teams SET category = 'Alevín' WHERE id = 'team-id';`
2. Asegúrate de que otros equipos de la misma categoría tengan estadísticas

### Problema: "Error al guardar estadísticas"
**Solución:**
1. Verifica las políticas RLS en Supabase
2. Confirma que `match_id`, `player_id` y `team_id` existan en sus tablas
3. Revisa la consola de Flutter para ver el error exacto

### Problema: "IDs de demostración en producción"
**Solución:**
1. Implementa un `Provider` o servicio global que almacene:
   - `currentTeamId`
   - `currentClubId`
   - `currentTeamCategory`
2. Reemplaza todos los `'demo-team-id'` con las variables reales

---

## 🎯 PRÓXIMAS MEJORAS (Opcional)

- [ ] Agregar tarjetas amarillas y rojas en MatchReportScreen
- [ ] Gráficos de evolución de goles por jugador (línea de tiempo)
- [ ] Exportar rankings a PDF para compartir con padres
- [ ] Notificaciones push cuando un jugador llega al Top 3
- [ ] Sistema de "Jugador del Mes" automático
- [ ] Integración con redes sociales para celebrar goleadores

---

## 👨‍💻 CRÉDITOS

**Desarrollado para:** Futbol App - Command Center Elite  
**Fecha:** 2026-01-08  
**Framework:** Flutter 3.9+ con Supabase  
**Estilo:** UI Elite con tema oscuro/neón  

---

## 📞 SOPORTE

Si tienes dudas o necesitas ayuda con el sistema:
1. Revisa la sección de Troubleshooting
2. Verifica los logs de Supabase Dashboard
3. Consulta la documentación de los modelos y servicios

**¡Ahora tus jugadores pueden competir por ser el máximo goleador! 🏆⚽**
