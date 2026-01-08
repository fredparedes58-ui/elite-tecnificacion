# ⚽ SISTEMA DE CATEGORÍAS - PREBENJAMÍN A JUVENIL

## 🎯 Vista Rápida

```
┌─────────────────────────────────────────────────────────────┐
│  SISTEMA DE GOLEADORES POR CATEGORÍAS                       │
│  Desde Prebenjamín (6 años) hasta Juvenil (17 años)        │
└─────────────────────────────────────────────────────────────┘

🏆 PREBENJAMÍN (Sub-7)  →  👶 6-7 años   →  ⚽ 5v5/7v7
🏆 BENJAMÍN    (Sub-9)  →  👦 8-9 años   →  ⚽ 7v7
🏆 ALEVÍN      (Sub-11) →  🧒 10-11 años →  ⚽ 8v8/9v9
🏆 INFANTIL    (Sub-13) →  👨 12-13 años →  ⚽ 11v11
🏆 CADETE      (Sub-15) →  👨‍🦱 14-15 años →  ⚽ 11v11
🏆 JUVENIL     (Sub-18) →  🧑 16-17 años →  ⚽ 11v11
```

---

## 📊 PIRÁMIDE DE EDADES

```
                    JUVENIL (16-17)
                   ╱              ╲
                CADETE (14-15)
               ╱                  ╲
            INFANTIL (12-13)
           ╱                      ╲
        ALEVÍN (10-11)
       ╱                          ╲
    BENJAMÍN (8-9)
   ╱                              ╲
PREBENJAMÍN (6-7)
═══════════════════════════════════
     FÚTBOL BASE - CLUB
```

---

## 🎮 CÓMO FUNCIONA EN LA APP

### 1️⃣ Registro de Goles (MatchReportScreen)
```
Entrenador de Alevín termina partido
         ↓
Abre "Partidos" → "REGISTRAR ESTADÍSTICAS"
         ↓
Cuenta goles: Juan (2), Pedro (1), Carlos (1)
         ↓
Presiona "GUARDAR" → Supabase
         ↓
✅ Goles registrados para categoría Alevín
```

### 2️⃣ Ver Rankings (TopScorersScreen)
```
Jugador abre "Goleadores"
         ↓
Ve 3 pestañas:

┌──────────────────────────────────────┐
│ MI EQUIPO │ CATEGORÍA │ CLUB GLOBAL │
├──────────────────────────────────────┤
│ Solo mi   │ Todos los │ Todas las   │
│ equipo    │ Alevines  │ categorías  │
│ Alevín A  │ del club  │ del club    │
└──────────────────────────────────────┘
```

---

## 💡 EJEMPLOS REALES

### Ejemplo 1: Club con 6 equipos (uno por categoría)

```sql
-- Tus equipos
INSERT INTO teams (name, category) VALUES
  ('Leones Prebenjamín', 'Prebenjamín'),
  ('Tigres Benjamín', 'Benjamín'),
  ('Águilas Alevín', 'Alevín'),
  ('Lobos Infantil', 'Infantil'),
  ('Halcones Cadete', 'Cadete'),
  ('Panteras Juvenil', 'Juvenil');
```

**Resultado en la app:**
- Cada equipo ve su propio ranking en "MI EQUIPO"
- TAB "CATEGORÍA" muestra solo 1 equipo (el suyo)
- TAB "CLUB GLOBAL" muestra los 6 equipos mezclados

---

### Ejemplo 2: Club con múltiples equipos por categoría

```sql
-- Varios equipos de la misma categoría
INSERT INTO teams (name, category) VALUES
  ('Alevín A', 'Alevín'),
  ('Alevín B', 'Alevín'),
  ('Alevín C', 'Alevín'),
  ('Benjamín A', 'Benjamín'),
  ('Benjamín B', 'Benjamín');
```

**Resultado en la app:**
- **"MI EQUIPO":** Solo ves tu Alevín A
- **"CATEGORÍA":** Ves goleadores de Alevín A, B y C mezclados
- **"CLUB GLOBAL":** Ves Alevines + Benjamines + todas las demás

---

## 🏅 EJEMPLO DE RANKING

### TAB "CLUB GLOBAL" - Todas las Categorías

```
┌─────┬───────────────────┬──────┬─────────┬──────────┐
│ POS │ JUGADOR           │ GOLES│ EQUIPO  │ CATEGORÍA│
├─────┼───────────────────┼──────┼─────────┼──────────┤
│ 🥇  │ Carlos Ruiz       │  25  │ Cadete A│ Cadete   │
│ 🥈  │ Juan Pérez        │  22  │ Alevín B│ Alevín   │
│ 🥉  │ Pedro García      │  20  │ Juvenil │ Juvenil  │
│ #4  │ Luis Martínez     │  18  │ Infantil│ Infantil │
│ #5  │ Miguel Torres     │  15  │ Benjamín│ Benjamín │
│ #6  │ David López       │  12  │ Prebenjamín│ Prebenjamín│
└─────┴───────────────────┴──────┴─────────┴──────────┘
```

### TAB "CATEGORÍA" - Solo Alevines

```
┌─────┬───────────────────┬──────┬──────────┐
│ POS │ JUGADOR           │ GOLES│ EQUIPO   │
├─────┼───────────────────┼──────┼──────────┤
│ 🥇  │ Juan Pérez        │  22  │ Alevín B │
│ 🥈  │ Carlos Gómez      │  18  │ Alevín A │
│ 🥉  │ Pedro Sánchez     │  15  │ Alevín C │
│ #4  │ Luis Ramírez      │  12  │ Alevín B │
│ #5  │ Diego Fernández   │  10  │ Alevín A │
└─────┴───────────────────┴──────┴──────────┘
```

---

## 🚀 CONFIGURACIÓN RÁPIDA

### Paso 1: Ejecutar SQL
```bash
# En Supabase SQL Editor
1. SETUP_MATCH_STATS.sql     ← Crea las tablas
2. ASIGNAR_CATEGORIAS.sql    ← Asigna categorías a tus equipos
```

### Paso 2: Verificar
```sql
-- Ver tus categorías asignadas
SELECT 
    category,
    COUNT(*) as equipos
FROM teams
WHERE category IS NOT NULL
GROUP BY category
ORDER BY 
    CASE category
        WHEN 'Prebenjamín' THEN 1
        WHEN 'Benjamín' THEN 2
        WHEN 'Alevín' THEN 3
        WHEN 'Infantil' THEN 4
        WHEN 'Cadete' THEN 5
        WHEN 'Juvenil' THEN 6
    END;
```

### Paso 3: Usar la App
```dart
// En home_screen.dart (reemplaza con tus IDs reales)
TopScorersScreen(
  teamId: 'tu-team-id-aqui',
  category: 'Alevín',  // ← Una de las 6 categorías
  clubId: 'tu-club-id-aqui',
)
```

---

## 🎯 BENEFICIOS POR CATEGORÍA

### PREBENJAMÍN (6-7 años)
✅ Primeros goles = Celebración máxima  
✅ Motivación desde el inicio  
✅ Construir confianza temprana  

### BENJAMÍN (8-9 años)
✅ Competencia sana entre amigos  
✅ Aprender a contar estadísticas  
✅ Desarrollar espíritu competitivo  

### ALEVÍN (10-11 años)
✅ Compararse con otros equipos  
✅ Identificar fortalezas individuales  
✅ Aspirar a ser el mejor de la categoría  

### INFANTIL (12-13 años)
✅ Transición a competencia seria  
✅ Stats como motivación para entrenar  
✅ Preparación para categorías superiores  

### CADETE (14-15 años)
✅ Estadísticas profesionales  
✅ Portfolio personal de jugador  
✅ Identificación de talentos para juvenil  

### JUVENIL (16-17 años)
✅ Preparación pre-senior  
✅ Stats para scouts y ojeadores  
✅ Historial completo desde Prebenjamín  

---

## 📚 DOCUMENTACIÓN COMPLETA

1. **`CATEGORIAS_REFERENCIA.md`** - Guía detallada de cada categoría
2. **`ASIGNAR_CATEGORIAS.sql`** - Script para asignar categorías
3. **`GUIA_SISTEMA_GOLEADORES.md`** - Sistema completo de estadísticas
4. **`INSTALACION_GOLEADORES_RAPIDA.md`** - Setup en 3 pasos

---

## ❓ FAQ

**P: ¿Puedo tener equipos sin categoría?**  
R: Sí, pero no aparecerán en rankings de categoría ni club global.

**P: ¿Puedo cambiar la categoría de un equipo?**  
R: Sí, con: `UPDATE teams SET category = 'Nueva' WHERE id = 'team-id';`

**P: ¿Puedo agregar más categorías (ej: Senior)?**  
R: Sí, pero necesitarás modificar el código de la app para incluirlas.

**P: ¿Las categorías son case-sensitive?**  
R: Sí. Usa siempre: `Prebenjamín`, `Benjamín`, `Alevín`, etc. (con mayúscula inicial y tildes).

**P: ¿Qué pasa si un jugador sube de categoría?**  
R: Sus estadísticas antiguas se mantienen. Cuando empiece en la nueva categoría, tendrá nuevas estadísticas.

---

## 🎉 ¡SISTEMA LISTO!

```
Prebenjamín → Benjamín → Alevín → Infantil → Cadete → Juvenil
    🏆         🏆         🏆        🏆         🏆        🏆
Cada categoría tiene su propio camino al título de Pichichi
```

**¡Que gane el mejor! ⚽**
