-- ============================================================
-- ASIGNACIÓN RÁPIDA DE CATEGORÍAS
-- ============================================================
-- Ejecutar en Supabase SQL Editor después de SETUP_MATCH_STATS.sql
-- Categorías: Prebenjamín → Juvenil
-- ============================================================

-- PASO 1: Ver tus equipos actuales
-- ============================================================
SELECT 
    id, 
    name, 
    category,
    CASE 
        WHEN category IS NULL THEN '❌ Sin categoría'
        ELSE '✅ ' || category
    END as status
FROM teams
ORDER BY name;

-- PASO 2: Asignar categorías por nombre de equipo
-- ============================================================
-- Reemplaza 'Nombre del Equipo' con el nombre real de cada equipo

-- PREBENJAMÍN (Sub-7) - 6 y 7 años
UPDATE teams SET category = 'Prebenjamín' WHERE name ILIKE '%prebenjamin%';
UPDATE teams SET category = 'Prebenjamín' WHERE name ILIKE '%sub-7%';
UPDATE teams SET category = 'Prebenjamín' WHERE name ILIKE '%sub 7%';
-- UPDATE teams SET category = 'Prebenjamín' WHERE name = 'NOMBRE-EXACTO-EQUIPO-1';

-- BENJAMÍN (Sub-9) - 8 y 9 años
UPDATE teams SET category = 'Benjamín' WHERE name ILIKE '%benjamin%';
UPDATE teams SET category = 'Benjamín' WHERE name ILIKE '%sub-9%';
UPDATE teams SET category = 'Benjamín' WHERE name ILIKE '%sub 9%';
-- UPDATE teams SET category = 'Benjamín' WHERE name = 'NOMBRE-EXACTO-EQUIPO-2';

-- ALEVÍN (Sub-11) - 10 y 11 años
UPDATE teams SET category = 'Alevín' WHERE name ILIKE '%alevin%';
UPDATE teams SET category = 'Alevín' WHERE name ILIKE '%sub-11%';
UPDATE teams SET category = 'Alevín' WHERE name ILIKE '%sub 11%';
-- UPDATE teams SET category = 'Alevín' WHERE name = 'NOMBRE-EXACTO-EQUIPO-3';

-- INFANTIL (Sub-13) - 12 y 13 años
UPDATE teams SET category = 'Infantil' WHERE name ILIKE '%infantil%';
UPDATE teams SET category = 'Infantil' WHERE name ILIKE '%sub-13%';
UPDATE teams SET category = 'Infantil' WHERE name ILIKE '%sub 13%';
-- UPDATE teams SET category = 'Infantil' WHERE name = 'NOMBRE-EXACTO-EQUIPO-4';

-- CADETE (Sub-15) - 14 y 15 años
UPDATE teams SET category = 'Cadete' WHERE name ILIKE '%cadete%';
UPDATE teams SET category = 'Cadete' WHERE name ILIKE '%sub-15%';
UPDATE teams SET category = 'Cadete' WHERE name ILIKE '%sub 15%';
-- UPDATE teams SET category = 'Cadete' WHERE name = 'NOMBRE-EXACTO-EQUIPO-5';

-- JUVENIL (Sub-18) - 16 y 17 años
UPDATE teams SET category = 'Juvenil' WHERE name ILIKE '%juvenil%';
UPDATE teams SET category = 'Juvenil' WHERE name ILIKE '%sub-18%';
UPDATE teams SET category = 'Juvenil' WHERE name ILIKE '%sub 18%';
-- UPDATE teams SET category = 'Juvenil' WHERE name = 'NOMBRE-EXACTO-EQUIPO-6';

-- PASO 3: Verificar que todas las categorías se asignaron correctamente
-- ============================================================
SELECT 
    category,
    COUNT(*) as cantidad_equipos,
    STRING_AGG(name, ', ') as equipos
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
        ELSE 7
    END;

-- PASO 4: Ver equipos que aún no tienen categoría asignada
-- ============================================================
SELECT 
    id,
    name,
    '❌ Necesita categoría' as status
FROM teams
WHERE category IS NULL;

-- ============================================================
-- ASIGNACIÓN MANUAL POR ID (Si lo prefieres)
-- ============================================================
/*
-- Si conoces los IDs exactos de tus equipos:
UPDATE teams SET category = 'Prebenjamín' WHERE id = 'tu-uuid-team-1';
UPDATE teams SET category = 'Benjamín' WHERE id = 'tu-uuid-team-2';
UPDATE teams SET category = 'Alevín' WHERE id = 'tu-uuid-team-3';
UPDATE teams SET category = 'Infantil' WHERE id = 'tu-uuid-team-4';
UPDATE teams SET category = 'Cadete' WHERE id = 'tu-uuid-team-5';
UPDATE teams SET category = 'Juvenil' WHERE id = 'tu-uuid-team-6';
*/

-- ============================================================
-- CORRECCIONES RÁPIDAS
-- ============================================================
/*
-- Si te equivocaste y necesitas cambiar una categoría:
UPDATE teams SET category = 'Alevín' WHERE id = 'team-uuid-aqui';

-- Si quieres resetear todas las categorías:
UPDATE teams SET category = NULL;

-- Si quieres eliminar una categoría específica:
UPDATE teams SET category = NULL WHERE category = 'Prebenjamín';
*/

-- ============================================================
-- RESUMEN FINAL
-- ============================================================
SELECT 
    '📊 RESUMEN DE CATEGORÍAS' as titulo,
    COUNT(DISTINCT category) as categorias_usadas,
    COUNT(*) as total_equipos,
    COUNT(CASE WHEN category IS NULL THEN 1 END) as sin_categoria
FROM teams;

-- Ver distribución completa
SELECT 
    COALESCE(category, '❌ Sin categoría') as categoria,
    COUNT(*) as equipos,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as porcentaje
FROM teams
GROUP BY category
ORDER BY 
    CASE category
        WHEN 'Prebenjamín' THEN 1
        WHEN 'Benjamín' THEN 2
        WHEN 'Alevín' THEN 3
        WHEN 'Infantil' THEN 4
        WHEN 'Cadete' THEN 5
        WHEN 'Juvenil' THEN 6
        ELSE 7
    END;

-- ============================================================
-- ✅ LISTO - Tus equipos ahora tienen categorías asignadas
-- ============================================================
-- Siguiente paso: Usa el sistema de goleadores en la app
-- Rankings disponibles: Mi Equipo | Categoría | Club Global
-- ============================================================
