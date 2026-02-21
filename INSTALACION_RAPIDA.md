# ⚡ Instalación Rápida - Sistema de Gestión de Convocatoria

## 🎯 Resumen

Este sistema conecta tu base de datos con la pizarra táctica para gestionar convocatorias de forma inteligente.

---

## 📋 Checklist de Instalación

### ✅ Paso 1: Base de Datos (5 minutos)

1. **Abre Supabase Dashboard** → SQL Editor
2. **Copia el contenido de**: `SETUP_MATCH_STATUS.sql`
3. **Pégalo y ejecuta** (Run ▶️)
4. **Verifica** con esta consulta:
   ```sql
   SELECT * FROM team_members LIMIT 5;
   ```
   Debes ver las columnas: `match_status` y `status_note`

### ✅ Paso 2: Código Flutter (Ya completado ✓)

Los siguientes archivos han sido creados/actualizados:

**Nuevos archivos:**
- ✅ `lib/screens/squad_management_screen.dart` - Gestión de plantilla
- ✅ `SETUP_MATCH_STATUS.sql` - Script de base de datos
- ✅ `GUIA_GESTION_CONVOCATORIA.md` - Documentación completa

**Archivos modificados:**
- ✅ `lib/models/player_model.dart` - Añadido MatchStatus enum
- ✅ `lib/services/supabase_service.dart` - Métodos de convocatoria
- ✅ `lib/providers/tactic_board_provider.dart` - Sistema de sustituciones
- ✅ `lib/screens/tactical_board_screen.dart` - Banquillo interactivo
- ✅ `lib/widgets/player_piece.dart` - Indicador de selección
- ✅ `lib/screens/home_screen.dart` - Navegación actualizada

### ✅ Paso 3: Ejecutar la App

```bash
flutter pub get
flutter run
```

---

## 🎮 Prueba Rápida (2 minutos)

### Test 1: Gestión de Plantilla

1. **Abre la app** → Command Center
2. **Toca "Plantilla"** (botón azul 👥)
3. **Marca 11 jugadores** como "Titular" (botón verde ⭐)
4. **Marca algunos** como "Suplente" (botón naranja 👥)
5. **Verifica el contador** superior (debe mostrar X/11 titulares)

✅ **Esperado**: Los botones cambian de color y el contador se actualiza

### Test 2: Pizarra Táctica Automática

1. **Regresa** al Command Center
2. **Toca "Tácticas"** (botón morado 🎯)
3. **Observa**:
   - ✅ Los 11 titulares ya están en el campo (formación 4-4-2)
   - ✅ Los suplentes están en el banquillo inferior
   - ✅ Los desconvocados no aparecen

✅ **Esperado**: ¡Magia! Todo cargado automáticamente 🪄

### Test 3: Sustitución

1. **En la pizarra táctica**:
2. **Toca un jugador** del campo (se ilumina en dorado ⭐)
3. **Toca un jugador** del banquillo
4. **¡BOOM!** Se intercambian 💥

✅ **Esperado**: El suplente entra al campo y el titular va al banquillo

---

## 🐛 Problemas Comunes

### ❌ "No hay jugadores en el equipo"

**Solución rápida**:
```sql
-- En Supabase SQL Editor:
SELECT * FROM team_members WHERE team_id IN (SELECT id FROM teams LIMIT 1);
```

Si no hay datos, necesitas:
1. Crear un equipo en la tabla `teams`
2. Añadir jugadores a la tabla `team_members`

### ❌ "Error de conexión con Supabase"

**Verifica**:
1. `lib/config/app_config.dart` tiene las credenciales correctas
2. Tu conexión a internet funciona
3. El proyecto de Supabase está activo

### ❌ "Los cambios no se guardan"

**Revisa Row Level Security (RLS)**:
```sql
-- En Supabase SQL Editor:
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

-- Crear política permisiva (solo para desarrollo):
CREATE POLICY "Allow all operations for authenticated users"
ON team_members
FOR ALL
USING (auth.role() = 'authenticated');
```

---

## 📊 Estructura de Datos

### Tabla: `team_members`

```sql
CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id),
  user_id UUID REFERENCES auth.users(id),
  match_status TEXT DEFAULT 'sub',  -- ← NUEVA
  status_note TEXT,                  -- ← NUEVA
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Valores de `match_status`:

| Valor | Significado | UI Color |
|-------|-------------|----------|
| `starter` | Titular (jugará desde el inicio) | 🟢 Verde |
| `sub` | Suplente (en el banquillo) | 🟠 Naranja |
| `unselected` | Desconvocado (no disponible) | 🔴 Rojo |

---

## 🚀 Siguiente Paso

**Lee la guía completa**: `GUIA_GESTION_CONVOCATORIA.md`

Incluye:
- ✅ Casos de uso detallados
- ✅ Flujo de trabajo completo
- ✅ Personalización de formaciones
- ✅ Solución avanzada de problemas

---

## 📞 ¿Necesitas Ayuda?

**Archivos de referencia**:
- 📖 **Guía completa**: `GUIA_GESTION_CONVOCATORIA.md`
- 🗃️ **Script SQL**: `SETUP_MATCH_STATUS.sql`
- 💻 **Código fuente**: `lib/screens/squad_management_screen.dart`

**Revisa los logs**:
```bash
flutter run --verbose
```

---

## ✨ Disfruta tu Sistema de Convocatoria

**¿Funcionó todo?** ¡Perfecto! Ahora tienes:

✅ Gestión inteligente de plantilla  
✅ Pizarra táctica con carga automática  
✅ Sistema de sustituciones profesional  
✅ Sincronización en tiempo real  

**¡A jugar!** ⚽🏆

---

**Versión**: 2.0.0  
**Fecha**: Enero 2026  
**Tiempo estimado de instalación**: 5-10 minutos
