# 📋 GUÍA: SISTEMA DE ASISTENCIA PARA PADRES

## 📖 Descripción

Este sistema permite que los padres marquen asistencia entrenamiento por entrenamiento para sus hijos. Los padres pueden indicar si su hijo asistirá, llegará tarde, está lesionado, enfermo o ausente.

---

## 🚀 Configuración Inicial

### Paso 1: Ejecutar Script SQL

Ejecuta el script `SETUP_PARENT_ATTENDANCE.sql` en el SQL Editor de Supabase:

```sql
-- Este script crea:
-- 1. Tabla parent_child_relationships (relación padre-hijo)
-- 2. Columna marked_by en attendance_records
-- 3. Políticas RLS actualizadas para permitir que padres marquen asistencia
-- 4. Funciones helper para obtener hijos y padres
```

### Paso 2: Crear Relación Padre-Hijo

Para vincular un padre con su hijo, ejecuta:

```sql
INSERT INTO parent_child_relationships (parent_id, child_id, team_id)
VALUES (
  'uuid_del_padre',  -- ID del perfil del padre
  'uuid_del_hijo',   -- ID del perfil del hijo (jugador)
  'uuid_del_equipo'  -- ID del equipo
);
```

**Nota:** Un padre puede tener múltiples hijos en diferentes equipos.

---

## 🎯 Funcionalidades

### Para Padres

1. **Ver Entrenamientos**
   - Los padres ven todas las sesiones de entrenamiento del equipo donde tienen hijos
   - Se muestran entrenamientos pasados (últimos 30 días) y futuros (próximos 30 días)
   - Cada entrenamiento muestra fecha, hora y tema

2. **Marcar Asistencia**
   - Los padres pueden marcar asistencia entrenamiento por entrenamiento
   - Estados disponibles:
     - ✅ **Presente**: El hijo asistirá normalmente
     - ❌ **Ausente**: El hijo no asistirá
     - ⏰ **Tarde**: El hijo llegará tarde
     - 🏥 **Lesionado**: El hijo está lesionado
     - 🤒 **Enfermo**: El hijo está enfermo

3. **Actualizar Asistencia**
   - Los padres pueden cambiar la asistencia en cualquier momento
   - Los cambios se guardan inmediatamente

### Para Entrenadores

- Los entrenadores siguen teniendo acceso completo al sistema de asistencia
- Pueden ver quién marcó cada asistencia (campo `marked_by`)
- Pueden modificar cualquier asistencia si es necesario

---

## 📱 Uso de la Aplicación

### Acceso a la Pantalla de Asistencia

1. Desde el **Home Screen**, toca el botón **"Asistencia"** (icono de check verde)
2. El sistema detecta automáticamente si eres padre o entrenador:
   - **Si eres padre**: Te lleva a `ParentAttendanceScreen`
   - **Si eres entrenador/admin**: Te lleva a `AttendanceScreen` (pantalla completa)

### Pantalla de Padres

1. **Seleccionar Hijo**
   - Si tienes múltiples hijos, usa el selector en la parte superior
   - Selecciona el hijo para el que quieres marcar asistencia

2. **Ver Entrenamientos**
   - La lista muestra todos los entrenamientos programados
   - Los entrenamientos de hoy se marcan con una etiqueta "HOY"
   - Cada entrenamiento muestra:
     - Fecha y hora
     - Tema del entrenamiento (si está disponible)
     - Estado actual de asistencia

3. **Marcar/Actualizar Asistencia**
   - Toca en un entrenamiento para cambiar el estado
   - Los estados cambian en ciclo: Presente → Ausente → Tarde → Lesionado → Enfermo → Presente
   - Toca el botón **"Guardar Asistencia"** o **"Actualizar Asistencia"** para confirmar

---

## 🔒 Seguridad y Permisos

### Políticas RLS (Row Level Security)

El sistema asegura que:

1. **Los padres solo pueden:**
   - Ver sesiones de entrenamiento de equipos donde tienen hijos
   - Marcar asistencia solo para sus propios hijos
   - Ver asistencia de sus hijos

2. **Los entrenadores pueden:**
   - Ver todas las sesiones de su equipo
   - Marcar asistencia para cualquier jugador
   - Modificar cualquier asistencia

3. **Los jugadores pueden:**
   - Ver su propia asistencia
   - No pueden modificar asistencia

---

## 📊 Estructura de Datos

### Tabla: `parent_child_relationships`

```sql
CREATE TABLE parent_child_relationships (
  id UUID PRIMARY KEY,
  parent_id UUID REFERENCES profiles(id),
  child_id UUID REFERENCES profiles(id),
  team_id UUID REFERENCES teams(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(parent_id, child_id, team_id)
);
```

### Tabla: `attendance_records` (actualizada)

```sql
ALTER TABLE attendance_records
ADD COLUMN marked_by UUID REFERENCES profiles(id);
```

El campo `marked_by` indica quién marcó la asistencia:
- Si es un padre: `marked_by` = ID del padre
- Si es un entrenador: `marked_by` = ID del entrenador
- Si es el mismo jugador: `marked_by` = ID del jugador

---

## 🛠️ API del Servicio

### Métodos Disponibles

#### `getParentChildren({String? teamId})`
Obtiene todos los hijos de un padre.

```dart
final children = await supabaseService.getParentChildren();
// Retorna: List<Map<String, dynamic>>
// Cada elemento contiene: child_id, child_name, child_avatar_url, team_id, team_name
```

#### `canParentMarkAttendance({required String playerId, String? teamId})`
Verifica si un padre puede marcar asistencia para un jugador.

```dart
final canMark = await supabaseService.canParentMarkAttendance(
  playerId: 'player_uuid',
);
// Retorna: bool
```

#### `getParentTrainingSessions({String? teamId, DateTime? startDate, DateTime? endDate})`
Obtiene sesiones de entrenamiento para padres.

```dart
final sessions = await supabaseService.getParentTrainingSessions(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now().add(Duration(days: 30)),
);
// Retorna: List<TrainingSession>
```

#### `markChildAttendance({required String sessionId, required String playerId, required AttendanceStatus status, String? note})`
Marca asistencia para un solo jugador (método simplificado para padres).

```dart
final success = await supabaseService.markChildAttendance(
  sessionId: 'session_uuid',
  playerId: 'player_uuid',
  status: AttendanceStatus.present,
  note: 'Llegará 10 minutos tarde',
);
// Retorna: bool
```

---

## 🐛 Solución de Problemas

### "No tienes hijos registrados"

**Causa:** No hay relación padre-hijo creada en la base de datos.

**Solución:**
1. Verifica que exista un registro en `parent_child_relationships`
2. Asegúrate de que el `parent_id` coincida con tu ID de usuario
3. Verifica que el `child_id` sea el ID del perfil del jugador

### "No tienes permisos para modificar asistencia"

**Causa:** La relación padre-hijo no existe o el `team_id` no coincide.

**Solución:**
1. Verifica que exista la relación en `parent_child_relationships`
2. Asegúrate de que el `team_id` sea correcto
3. Verifica las políticas RLS en Supabase

### "No hay entrenamientos programados"

**Causa:** No hay sesiones de entrenamiento creadas para el equipo.

**Solución:**
1. Los entrenadores deben crear sesiones usando `AttendanceScreen`
2. Verifica que existan registros en `training_sessions` para el equipo

---

## 📝 Notas Importantes

1. **Un padre puede tener múltiples hijos** en diferentes equipos
2. **Un hijo puede tener múltiples padres** (madre y padre)
3. **Los cambios de asistencia se guardan inmediatamente** al presionar "Guardar"
4. **Los entrenadores pueden modificar** cualquier asistencia marcada por padres
5. **El historial se mantiene** - puedes ver quién marcó cada asistencia

---

## 🔄 Flujo de Trabajo Recomendado

1. **Entrenador crea sesión de entrenamiento**
   - Usa `AttendanceScreen` para crear la sesión
   - Indica fecha, hora y tema

2. **Padres marcan asistencia**
   - Los padres reciben notificación (si está configurada)
   - Marcan asistencia entrenamiento por entrenamiento
   - Pueden actualizar en cualquier momento

3. **Entrenador revisa asistencia**
   - Ve todas las asistencias marcadas
   - Puede modificar si es necesario
   - Genera reportes de asistencia

---

## 📚 Archivos Relacionados

- `SETUP_PARENT_ATTENDANCE.sql` - Script de configuración
- `lib/screens/parent_attendance_screen.dart` - Pantalla para padres
- `lib/screens/attendance_screen.dart` - Pantalla para entrenadores
- `lib/models/attendance_record_model.dart` - Modelo de datos
- `lib/services/supabase_service.dart` - Servicio de backend

---

**Última actualización:** 2026-01-08
