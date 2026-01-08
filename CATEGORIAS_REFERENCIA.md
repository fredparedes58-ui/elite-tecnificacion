# ⚽ CATEGORÍAS DE FÚTBOL BASE - REFERENCIA

## 📋 Sistema de Categorías: Prebenjamín → Juvenil

Este documento define las categorías oficiales utilizadas en el sistema de goleadores y rankings del club.

---

## 🏆 CATEGORÍAS OFICIALES

### 1️⃣ PREBENJAMÍN (Sub-7)
- **Edades:** 6-7 años
- **Características:**
  - Primer contacto con el fútbol organizado
  - Enfoque en diversión y coordinación básica
  - Partidos: 5v5 o 7v7 (según región)
  - Duración: 2 tiempos de 20 minutos

**Ejemplo en SQL:**
```sql
UPDATE teams SET category = 'Prebenjamín' WHERE name = 'Tu Equipo Sub-7';
```

---

### 2️⃣ BENJAMÍN (Sub-9)
- **Edades:** 8-9 años
- **Características:**
  - Desarrollo de habilidades técnicas básicas
  - Introducción a conceptos tácticos simples
  - Partidos: 7v7
  - Duración: 2 tiempos de 25 minutos

**Ejemplo en SQL:**
```sql
UPDATE teams SET category = 'Benjamín' WHERE name = 'Tu Equipo Sub-9';
```

---

### 3️⃣ ALEVÍN (Sub-11)
- **Edades:** 10-11 años
- **Características:**
  - Consolidación técnica
  - Desarrollo táctico colectivo
  - Partidos: 8v8 o 9v9
  - Duración: 2 tiempos de 30 minutos

**Ejemplo en SQL:**
```sql
UPDATE teams SET category = 'Alevín' WHERE name = 'Tu Equipo Sub-11';
```

---

### 4️⃣ INFANTIL (Sub-13)
- **Edades:** 12-13 años
- **Características:**
  - Transición al fútbol 11
  - Mayor énfasis en táctica
  - Partidos: 11v11
  - Duración: 2 tiempos de 35 minutos

**Ejemplo en SQL:**
```sql
UPDATE teams SET category = 'Infantil' WHERE name = 'Tu Equipo Sub-13';
```

---

### 5️⃣ CADETE (Sub-15)
- **Edades:** 14-15 años
- **Características:**
  - Especialización por posiciones
  - Desarrollo físico intenso
  - Partidos: 11v11
  - Duración: 2 tiempos de 35-40 minutos

**Ejemplo en SQL:**
```sql
UPDATE teams SET category = 'Cadete' WHERE name = 'Tu Equipo Sub-15';
```

---

### 6️⃣ JUVENIL (Sub-18)
- **Edades:** 16-17 años
- **Características:**
  - Pre-senior, alto nivel competitivo
  - Entrenamiento profesional
  - Partidos: 11v11
  - Duración: 2 tiempos de 45 minutos

**Ejemplo en SQL:**
```sql
UPDATE teams SET category = 'Juvenil' WHERE name = 'Tu Equipo Sub-18';
```

---

## 📊 TABLA RESUMEN

| Categoría    | Edades | Formato | Duración Partido | Jugadores |
|-------------|--------|---------|------------------|-----------|
| Prebenjamín | 6-7    | 5v5/7v7 | 2 × 20 min       | ~10-12    |
| Benjamín    | 8-9    | 7v7     | 2 × 25 min       | ~12-14    |
| Alevín      | 10-11  | 8v8/9v9 | 2 × 30 min       | ~14-16    |
| Infantil    | 12-13  | 11v11   | 2 × 35 min       | ~16-20    |
| Cadete      | 14-15  | 11v11   | 2 × 35-40 min    | ~18-22    |
| Juvenil     | 16-17  | 11v11   | 2 × 45 min       | ~20-25    |

---

## 🎯 USO EN LA APP

### En la Base de Datos
```sql
-- Ver todas las categorías asignadas
SELECT category, COUNT(*) as equipos 
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

### En Flutter (TopScorersScreen)
```dart
// La pantalla filtra automáticamente por categoría
TopScorersScreen(
  teamId: 'tu-team-id',
  category: 'Alevín',  // ← Una de las 6 categorías
  clubId: 'tu-club-id',
)
```

### Rankings por Categoría
- **TAB "MI EQUIPO":** Ver solo tu equipo (ej: Alevín A)
- **TAB "CATEGORÍA":** Ver todos los Alevines del club (A, B, C, etc.)
- **TAB "CLUB GLOBAL":** Ver todas las categorías juntas

---

## 🔧 ASIGNACIÓN RÁPIDA

### Opción 1: Por Nombre (Automático)
```sql
-- El sistema detecta automáticamente
UPDATE teams SET category = 'Alevín' WHERE name ILIKE '%alevin%';
UPDATE teams SET category = 'Benjamín' WHERE name ILIKE '%benjamin%';
-- etc.
```

### Opción 2: Por ID (Manual)
```sql
UPDATE teams SET category = 'Prebenjamín' WHERE id = 'uuid-1';
UPDATE teams SET category = 'Benjamín' WHERE id = 'uuid-2';
UPDATE teams SET category = 'Alevín' WHERE id = 'uuid-3';
-- etc.
```

### Opción 3: Desde la App (Futuro)
```dart
await StatsService().updateTeamCategory(
  teamId: 'tu-team-id',
  category: 'Alevín',
);
```

---

## 📈 VENTAJAS DEL SISTEMA

### 1. Comparación Justa
Los Prebenjamines (6-7 años) compiten entre sí, no contra Juveniles (16-17 años).

### 2. Motivación por Etapas
Cada categoría tiene su propio "Pichichi", lo que mantiene la motivación alta en todas las edades.

### 3. Identificación de Talento
Puedes ver fácilmente quién destaca en cada categoría y hacer seguimiento a largo plazo.

### 4. Rankings Globales
El TAB "Club Global" permite soñar: ¿Puede un Alevín superar a un Juvenil en goles?

---

## 🐛 TROUBLESHOOTING

### "Mi categoría no aparece en el dropdown"
- Asegúrate de escribir la categoría exactamente como está en esta guía (con tildes y mayúsculas).
- Las categorías válidas son: `Prebenjamín`, `Benjamín`, `Alevín`, `Infantil`, `Cadete`, `Juvenil`

### "El ranking de categoría está vacío"
- Verifica que otros equipos de la misma categoría tengan estadísticas guardadas
- Usa: `SELECT * FROM match_stats WHERE team_id IN (SELECT id FROM teams WHERE category = 'Alevín');`

### "Quiero cambiar la categoría de un equipo"
```sql
UPDATE teams SET category = 'Nueva Categoría' WHERE id = 'team-uuid';
```

---

## 📝 NOTAS IMPORTANTES

1. **Categorías Fijas:** El sistema usa exactamente estas 6 categorías. Si necesitas agregar más (ej: "Senior"), deberás modificar el código.

2. **Case-Sensitive:** Las categorías son sensibles a mayúsculas/minúsculas. Usa siempre la primera letra en mayúscula: `Alevín`, no `alevin` ni `ALEVIN`.

3. **Acentos:** Los acentos son importantes: `Benjamín` y `Alevín` llevan tilde.

4. **Sin Categoría:** Los equipos sin categoría asignada no aparecerán en el TAB "Categoría" ni "Club Global".

---

## 🎓 RECURSOS RELACIONADOS

- **Asignar categorías:** `ASIGNAR_CATEGORIAS.sql`
- **Guía completa del sistema:** `GUIA_SISTEMA_GOLEADORES.md`
- **Instalación rápida:** `INSTALACION_GOLEADORES_RAPIDA.md`

---

## ✅ CHECKLIST DE CONFIGURACIÓN

- [ ] Ejecuté `SETUP_MATCH_STATS.sql` en Supabase
- [ ] Asigné categorías a todos mis equipos
- [ ] Verifiqué que las categorías se guardaron correctamente
- [ ] Probé el sistema de goleadores en la app
- [ ] Los rankings muestran datos en las 3 pestañas

---

**¡Sistema de categorías configurado! Ahora cada edad tiene su propio camino al título de Pichichi 🏆⚽**
