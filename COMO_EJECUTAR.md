# 🚀 CÓMO EJECUTAR TODO - GUÍA PASO A PASO

## ⚡ INSTALACIÓN EN 3 MINUTOS

---

## 📋 PASO 1: Abrir Supabase SQL Editor

1. Ve a tu dashboard de Supabase: https://supabase.com/dashboard
2. Selecciona tu proyecto
3. En el menú lateral izquierdo, haz clic en **"SQL Editor"**
4. Haz clic en el botón **"New query"** (arriba a la derecha)

```
┌─────────────────────────────────────┐
│  Supabase Dashboard                 │
├─────────────────────────────────────┤
│  ☰ Menu                             │
│     📊 Table Editor                 │
│     🔍 Database                     │
│  ►  💻 SQL Editor  ← CLIC AQUÍ     │
│     📝 API                          │
└─────────────────────────────────────┘
```

---

## 📋 PASO 2: Copiar el Script

1. **En tu computadora**, abre el archivo:
   ```
   EJECUTAR_TODO.sql
   ```

2. **Selecciona TODO** el contenido del archivo (Cmd+A en Mac / Ctrl+A en Windows)

3. **Copia** el contenido (Cmd+C / Ctrl+C)

---

## 📋 PASO 3: Pegar y Ejecutar en Supabase

1. En el **SQL Editor** de Supabase, pega el contenido (Cmd+V / Ctrl+V)

2. Verás algo como esto:
   ```sql
   -- ============================================================
   -- 🚀 SCRIPT CONSOLIDADO - SISTEMA DE GOLEADORES COMPLETO
   -- ============================================================
   ...
   ```

3. Haz clic en el botón **"RUN"** (esquina inferior derecha)

```
┌─────────────────────────────────────────────────┐
│  SQL Editor                                     │
├─────────────────────────────────────────────────┤
│  -- Script pegado aquí...                       │
│                                                  │
│                                                  │
│                              [Cancel] [▶ RUN]  │
└─────────────────────────────────────────────────┘
```

4. **ESPERA** unos segundos (2-5 segundos)

---

## 📋 PASO 4: Ver los Resultados

Si todo salió bien, verás en la consola de Supabase:

```
✅ Campo category agregado a tabla teams
✅ Tabla match_stats creada correctamente
✅ Índices creados para optimización
✅ Políticas de seguridad RLS configuradas
✅ Trigger de updated_at configurado
✅ Vista top_scorers creada
✅ Función get_team_top_scorers creada
✅ Función get_category_top_scorers creada
✅ Función get_club_top_scorers creada
✅ Categorías asignadas automáticamente

════════════════════════════════════════════════
🎉 INSTALACIÓN COMPLETADA EXITOSAMENTE
════════════════════════════════════════════════

📊 RESUMEN:
   • Total de equipos: 6
   • Con categoría: 5
   • Sin categoría: 1

📋 DISTRIBUCIÓN POR CATEGORÍA:
   • Prebenjamín: 1 equipo(s)
   • Benjamín: 2 equipo(s)
   • Alevín: 2 equipo(s)

⚠️  EQUIPOS SIN CATEGORÍA:
   • Mi Equipo Sin Nombre

💡 Para asignar manualmente:
   UPDATE teams SET category = 'Alevín' WHERE name = 'Nombre del Equipo';

✅ TABLAS CREADAS:
   • match_stats (con RLS habilitado)
   • Vista: top_scorers

✅ FUNCIONES RPC CREADAS:
   • get_team_top_scorers()
   • get_category_top_scorers()
   • get_club_top_scorers()

🎯 PRÓXIMOS PASOS:
   1. Si hay equipos sin categoría, asígnalas manualmente
   2. Ejecuta la app de Flutter
   3. Registra estadísticas de partidos
   4. ¡Disfruta del sistema de goleadores!

════════════════════════════════════════════════
```

---

## ✅ VERIFICACIÓN RÁPIDA

### Verificar que todo se creó correctamente:

1. En el **SQL Editor**, ejecuta esta consulta:

```sql
-- Ver tus equipos y sus categorías
SELECT 
    id,
    name,
    category,
    CASE 
        WHEN category IS NULL THEN '❌ Sin categoría'
        ELSE '✅ ' || category
    END as status
FROM teams
ORDER BY 
    CASE category
        WHEN 'Prebenjamín' THEN 1
        WHEN 'Benjamín' THEN 2
        WHEN 'Alevín' THEN 3
        WHEN 'Infantil' THEN 4
        WHEN 'Cadete' THEN 5
        WHEN 'Juvenil' THEN 6
        ELSE 7
    END,
    name;
```

2. Deberías ver una tabla con tus equipos y sus categorías asignadas.

---

## 🔧 SI ALGUNOS EQUIPOS NO TIENEN CATEGORÍA

Si hay equipos que no se asignaron automáticamente, puedes hacerlo manualmente:

```sql
-- Asignar categoría manualmente (reemplaza con tu info)
UPDATE teams SET category = 'Alevín' WHERE name = 'Nombre Exacto del Equipo';
UPDATE teams SET category = 'Benjamín' WHERE name = 'Otro Equipo';

-- O por ID:
UPDATE teams SET category = 'Infantil' WHERE id = 'tu-uuid-aqui';
```

---

## ❌ SI HAY ERRORES

### Error: "relation 'matches' does not exist"
**Solución:** Tu base de datos no tiene la tabla `matches`. Crea primero esa tabla o ejecuta el script que crea tu esquema base.

### Error: "relation 'players' does not exist"
**Solución:** Tu base de datos no tiene la tabla `players`. Crea primero esa tabla o ejecuta el script que crea tu esquema base.

### Error: "permission denied"
**Solución:** Asegúrate de estar conectado como administrador en Supabase.

### Otros errores
**Solución:** Copia el mensaje de error completo y revisa la línea que lo causa.

---

## 🎯 PRÓXIMOS PASOS DESPUÉS DE LA INSTALACIÓN

### 1. Verificar en la App

```bash
# En tu terminal (dentro del proyecto Flutter)
flutter run
```

### 2. Probar el Sistema

1. Abre la app
2. Ve a **"Command Center"** → Botón **"Goleadores"** (dorado)
3. Deberías ver 3 pestañas:
   - MI EQUIPO
   - CATEGORÍA
   - CLUB GLOBAL

### 3. Registrar Primer Partido

1. Ve a **"Partidos"**
2. Selecciona un partido **FINALIZADO**
3. Presiona **"REGISTRAR ESTADÍSTICAS"**
4. Usa los botones +/- para contar goles
5. Presiona **"GUARDAR ESTADÍSTICAS"**

### 4. Ver Rankings

1. Vuelve a **"Goleadores"**
2. Deberías ver los goleadores con sus stats

---

## 📊 CONSULTAS ÚTILES DESPUÉS DE LA INSTALACIÓN

### Ver todas las categorías y equipos
```sql
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

### Ver estadísticas guardadas
```sql
SELECT 
    p.name as jugador,
    t.name as equipo,
    t.category,
    ms.goals,
    ms.assists,
    ms.minutes_played
FROM match_stats ms
JOIN players p ON p.id = ms.player_id
JOIN teams t ON t.id = ms.team_id
ORDER BY ms.goals DESC
LIMIT 10;
```

### Ver top scorers
```sql
SELECT * FROM top_scorers LIMIT 10;
```

---

## 🎉 ¡LISTO!

Una vez que veas el mensaje de **"INSTALACIÓN COMPLETADA EXITOSAMENTE"**, tu sistema de goleadores está listo para usar.

**¿Necesitas ayuda?** Revisa:
- `README_CATEGORIAS.md` - Guía visual de categorías
- `GUIA_SISTEMA_GOLEADORES.md` - Documentación completa
- `CATEGORIAS_REFERENCIA.md` - Detalles de cada categoría

---

## 📞 CHECKLIST FINAL

- [ ] Ejecuté `EJECUTAR_TODO.sql` en Supabase
- [ ] Vi el mensaje "INSTALACIÓN COMPLETADA EXITOSAMENTE"
- [ ] Verifiqué que mis equipos tienen categorías asignadas
- [ ] Asigné manualmente las categorías faltantes (si hubo)
- [ ] Ejecuté la app de Flutter
- [ ] El botón "Goleadores" aparece en el Command Center
- [ ] Puedo abrir la pantalla de goleadores y ver 3 pestañas
- [ ] Puedo registrar estadísticas de un partido

**Si todos los checkboxes están marcados: ¡Felicidades! El sistema está 100% operativo 🏆⚽**
