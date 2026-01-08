# ⚡ INICIO RÁPIDO - SISTEMA DE GOLEADORES

## 🎯 ¿Por dónde empiezo?

---

## ⚡ OPCIÓN RÁPIDA (5 minutos)

### 1️⃣ Ejecutar el Script Todo-en-Uno

**📄 Archivo a usar:** `EJECUTAR_TODO.sql`

**📖 Instrucciones:** `COMO_EJECUTAR.md`

**Pasos:**
1. Abre `COMO_EJECUTAR.md` y sigue las instrucciones
2. Ejecuta `EJECUTAR_TODO.sql` en Supabase SQL Editor
3. ¡Listo! Sistema instalado

```
EJECUTAR_TODO.sql  ←  EJECUTA ESTE ARCHIVO
      ⬇️
  Supabase SQL Editor
      ⬇️
  Click "RUN"
      ⬇️
  ✅ Sistema Listo
```

---

## 📚 ARCHIVOS PRINCIPALES

### 🔧 Scripts SQL (Ejecutar en Supabase)

| Archivo | Propósito | ¿Cuándo usarlo? |
|---------|-----------|-----------------|
| **`EJECUTAR_TODO.sql`** | Script consolidado con TODO | ✅ **EMPIEZA AQUÍ** - Ejecuta todo en un solo paso |
| `SETUP_MATCH_STATS.sql` | Solo crea tablas y funciones | Solo si quieres ejecutar paso a paso |
| `ASIGNAR_CATEGORIAS.sql` | Solo asigna categorías | Solo si ya ejecutaste SETUP_MATCH_STATS.sql |

### 📖 Documentación

| Archivo | Contenido | ¿Para qué? |
|---------|-----------|------------|
| **`COMO_EJECUTAR.md`** | Guía paso a paso con capturas | ✅ **LEE PRIMERO** - Te dice cómo ejecutar |
| `README_CATEGORIAS.md` | Guía visual de categorías | Entiende las 6 categorías |
| `CATEGORIAS_REFERENCIA.md` | Detalles técnicos de categorías | Consulta técnica completa |
| `GUIA_SISTEMA_GOLEADORES.md` | Documentación completa del sistema | Manual técnico avanzado |
| `INSTALACION_GOLEADORES_RAPIDA.md` | Guía de instalación alternativa | Otra forma de instalar |

---

## 🎬 FLUJO COMPLETO DE INSTALACIÓN

```
┌─────────────────────────────────────────────────────────┐
│  PASO 1: LEER INSTRUCCIONES                            │
│  📄 Archivo: COMO_EJECUTAR.md                          │
└─────────────────────────────────────────────────────────┘
                        ⬇️
┌─────────────────────────────────────────────────────────┐
│  PASO 2: EJECUTAR SCRIPT EN SUPABASE                   │
│  📄 Archivo: EJECUTAR_TODO.sql                         │
│  🌐 Lugar: Supabase SQL Editor                         │
└─────────────────────────────────────────────────────────┘
                        ⬇️
┌─────────────────────────────────────────────────────────┐
│  PASO 3: VERIFICAR RESULTADOS                          │
│  ✅ Mensaje: "INSTALACIÓN COMPLETADA EXITOSAMENTE"    │
│  ✅ Ver categorías asignadas                           │
└─────────────────────────────────────────────────────────┘
                        ⬇️
┌─────────────────────────────────────────────────────────┐
│  PASO 4 (Opcional): ASIGNAR CATEGORÍAS MANUALMENTE     │
│  Si algunos equipos no tienen categoría asignada       │
│  UPDATE teams SET category = 'Alevín' WHERE...         │
└─────────────────────────────────────────────────────────┘
                        ⬇️
┌─────────────────────────────────────────────────────────┐
│  PASO 5: USAR LA APP                                   │
│  flutter run                                            │
│  → Command Center → Goleadores                          │
│  → Registrar estadísticas de partidos                   │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ CHECKLIST DE 5 MINUTOS

```
[ ] 1. Abrir COMO_EJECUTAR.md
[ ] 2. Ir a Supabase Dashboard → SQL Editor
[ ] 3. Abrir EJECUTAR_TODO.sql y copiar TODO el contenido
[ ] 4. Pegar en Supabase SQL Editor
[ ] 5. Click en "RUN"
[ ] 6. Esperar mensaje "INSTALACIÓN COMPLETADA EXITOSAMENTE"
[ ] 7. Verificar categorías asignadas
[ ] 8. Asignar manualmente categorías faltantes (si hay)
[ ] 9. flutter run
[ ] 10. ¡Usar el sistema de goleadores! 🏆
```

---

## 🎓 DESPUÉS DE LA INSTALACIÓN

### Aprender sobre las Categorías
📄 Lee: `README_CATEGORIAS.md`

```
Prebenjamín → Benjamín → Alevín → Infantil → Cadete → Juvenil
   6-7 años    8-9 años   10-11    12-13     14-15    16-17
```

### Entender el Sistema Completo
📄 Lee: `GUIA_SISTEMA_GOLEADORES.md`

### Registrar tu Primer Partido

1. **En la App:**
   - Ve a "Partidos"
   - Selecciona un partido FINALIZADO
   - Presiona "REGISTRAR ESTADÍSTICAS"
   - Cuenta goles con botones +/−
   - Guarda

2. **Ver Rankings:**
   - Ve a "Goleadores"
   - Explora las 3 pestañas:
     - **MI EQUIPO:** Solo tu equipo
     - **CATEGORÍA:** Todos los equipos de tu edad
     - **CLUB GLOBAL:** Todos los equipos del club

---

## 🎯 ARCHIVOS POR PROPÓSITO

### 🚀 Quiero instalar rápido
```
1. COMO_EJECUTAR.md       ← Lee esto primero
2. EJECUTAR_TODO.sql      ← Ejecuta esto en Supabase
```

### 📚 Quiero entender las categorías
```
1. README_CATEGORIAS.md         ← Visual y fácil
2. CATEGORIAS_REFERENCIA.md     ← Detalles técnicos
```

### 🔧 Quiero instalar paso a paso
```
1. SETUP_MATCH_STATS.sql        ← Paso 1: Crea tablas
2. ASIGNAR_CATEGORIAS.sql       ← Paso 2: Asigna categorías
```

### 📖 Quiero documentación completa
```
GUIA_SISTEMA_GOLEADORES.md      ← Todo el sistema explicado
```

---

## 💡 TIPS RÁPIDOS

### ¿No sabes si ya ejecutaste el script?
```sql
-- Ejecuta esto en Supabase para verificar:
SELECT COUNT(*) as existe 
FROM information_schema.tables 
WHERE table_name = 'match_stats';

-- Si regresa 0: No está instalado, ejecuta EJECUTAR_TODO.sql
-- Si regresa 1: Ya está instalado ✅
```

### ¿Quieres ver tus categorías?
```sql
SELECT name, category FROM teams;
```

### ¿Quieres cambiar una categoría?
```sql
UPDATE teams SET category = 'Alevín' WHERE name = 'Tu Equipo';
```

---

## 🐛 PROBLEMAS COMUNES

### "No aparece el botón Goleadores en la app"
- Verifica que ejecutaste `EJECUTAR_TODO.sql` completo
- Reinicia la app (hot reload no es suficiente)
- Verifica que no haya errores en la consola

### "Las pestañas de ranking están vacías"
- Necesitas registrar estadísticas primero
- Ve a "Partidos" → "REGISTRAR ESTADÍSTICAS"
- Cuenta algunos goles y guarda

### "Error: relation 'matches' does not exist"
- Tu base de datos no tiene la tabla `matches`
- Ejecuta primero el script que crea tu esquema base

---

## 📞 AYUDA

Si tienes problemas:

1. **Revisa la consola de Supabase** al ejecutar el script
2. **Lee el mensaje de error completo**
3. **Busca en la sección de Troubleshooting** de los archivos .md
4. **Verifica que ejecutaste TODO el script** `EJECUTAR_TODO.sql`

---

## 🎉 ¡LISTO PARA EMPEZAR!

```
┌──────────────────────────────────────────┐
│                                          │
│     🏆 SISTEMA DE GOLEADORES 🏆          │
│                                          │
│  Prebenjamín → Benjamín → Alevín →      │
│  Infantil → Cadete → Juvenil            │
│                                          │
│  ¡Que gane el mejor Pichichi! ⚽         │
│                                          │
└──────────────────────────────────────────┘
```

**👉 Empieza aquí:** `COMO_EJECUTAR.md`
