# 🏟️ GUÍA COMPLETA: SISTEMA DE GESTIÓN DE CAMPOS Y RESERVAS

## 📋 ÍNDICE
1. [Instalación Base de Datos](#instalación-base-de-datos)
2. [Funcionalidades del Sistema](#funcionalidades-del-sistema)
3. [Cómo Usar](#cómo-usar)
4. [Arquitectura Técnica](#arquitectura-técnica)
5. [Resolución de Problemas](#resolución-de-problemas)

---

## 🚀 INSTALACIÓN BASE DE DATOS

### PASO 1: Ejecutar el Script SQL

1. Abre tu **Dashboard de Supabase**
2. Ve a `SQL Editor` en el menú lateral
3. Crea un nuevo query
4. Copia y pega **TODO** el contenido del archivo `SETUP_FIELDS_AND_BOOKINGS.sql`
5. Haz clic en **"Run"**
6. Verifica que veas los mensajes de éxito:
   ```
   ✅ Tablas creadas: fields, bookings, booking_requests
   ✅ Funciones creadas: check_booking_conflict, get_available_fields
   ✅ Triggers activados: validación de conflictos y updated_at
   ✅ Políticas RLS aplicadas
   🚀 Sistema de Gestión de Campos listo para usar
   ```

### PASO 2: Insertar Campos de Ejemplo

Ejecuta este SQL para crear campos de prueba (ajusta los nombres según tu instalación):

```sql
INSERT INTO fields (name, type, location) VALUES
  ('Campo Principal A', 'F11', 'Zona Norte - Instalación 1'),
  ('Campo Principal B', 'F11', 'Zona Norte - Instalación 1'),
  ('Campo 7 - Norte', 'F7', 'Zona Norte - Instalación 2'),
  ('Campo 7 - Sur', 'F7', 'Zona Sur - Instalación 2'),
  ('Campo Indoor', 'F7', 'Polideportivo Cubierto')
ON CONFLICT DO NOTHING;
```

### PASO 3: Verificar la Instalación

Ejecuta este query para confirmar que todo está correcto:

```sql
-- Ver campos creados
SELECT * FROM fields;

-- Ver funciones instaladas
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('check_booking_conflict', 'get_available_fields');

-- Verificar triggers
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

---

## 🎯 FUNCIONALIDADES DEL SISTEMA

### 1. Vista de Calendario (FieldScheduleScreen)

**Acceso:** Command Center > Botón "Campos" (icono de estadio, color cyan)

**Características:**
- 📅 **Selector de Fecha:** Navega por días con botones de adelante/atrás + botón "Hoy"
- 🕐 **Vista Timetable:** Grid visual de 16:00 a 22:00 con bloques de 30 minutos
- 🎨 **Código de Colores:**
  - 🟢 Verde = Entrenamiento
  - 🔴 Rojo = Partido
  - 🟣 Morado = Sesión Táctica
  - ⚪ Gris = Disponible
- 📊 **Vista por Campo:** Columnas con cada campo mostrando ocupación en tiempo real
- 👆 **Toca una Reserva:** Ver detalles completos (campo, horario, duración, descripción)

### 2. Formulario de Solicitud (BookingRequestScreen)

**Acceso:** Desde FieldScheduleScreen > FAB "SOLICITAR RESERVA"

**Flujo Inteligente:**
1. **Selecciona Fecha y Horario:**
   - Picker de fecha (hasta 90 días adelante)
   - Picker de hora de inicio y fin
   
2. **Verifica Disponibilidad:**
   - Botón "VERIFICAR DISPONIBILIDAD"
   - El sistema consulta la BD y muestra **SOLO** campos libres
   - Si hay conflicto, te lo indica inmediatamente
   
3. **Selecciona Campo:**
   - Lista visual con campos disponibles
   - Muestra tipo (F7/F11) y ubicación
   - Selección única con radio button
   
4. **Completa Detalles:**
   - Título de la reserva
   - Tipo: Entrenamiento / Partido / Táctica
   - Motivo (opcional)
   
5. **Envía Solicitud:**
   - Validación automática de conflictos antes de guardar
   - La reserva queda en estado "pending" (puedes cambiar a automática)

### 3. Validación en Entrenamientos

**Acceso:** Command Center > Entrenamientos > Añadir Sesión

**Mejoras Integradas:**
- Al crear una sesión, ahora debes seleccionar:
  - ⏰ Hora de inicio y fin
  - 🔍 Verificar disponibilidad de campos
  - 🏟️ Seleccionar campo disponible
- **Protección Automática:** No puedes crear dos entrenamientos en el mismo campo/horario
- **Feedback Visual:** Muestra alerta si no hay campos libres

---

## 📖 CÓMO USAR

### Caso de Uso 1: Revisar la Semana de Entrenamientos

```
1. Command Center > Campos
2. Navega por los días con las flechas
3. Visualiza en el grid qué equipo usa qué campo a qué hora
4. Toca cualquier reserva para ver detalles
```

### Caso de Uso 2: Solicitar un Cambio de Horario

```
1. Campos > FAB "SOLICITAR RESERVA"
2. Selecciona el nuevo día y horario deseado
3. Click "VERIFICAR DISPONIBILIDAD"
4. Si hay campos libres, selecciona uno
5. Ingresa el motivo del cambio
6. Enviar solicitud (pendiente de aprobación por admin)
```

### Caso de Uso 3: Crear Entrenamiento con Campo Asignado

```
1. Command Center > Entrenamientos
2. Selecciona un día > FAB "+"
3. Ingresa título y objetivo
4. Configura horario (ej: 18:00 - 20:00)
5. Click "Verificar Disponibilidad"
6. Selecciona un campo de los disponibles
7. Guardar → El sistema reserva automáticamente el campo
```

### Caso de Uso 4: Detectar y Resolver Conflictos

**Escenario:** Intentas crear una sesión a las 18:00 pero el Campo 1 ya está ocupado.

**El sistema:**
1. ⚠️ Te muestra alerta: "Ya existe una reserva 'Entrenamiento Sub-17' en ese horario"
2. 🔍 Al verificar disponibilidad, el Campo 1 NO aparece en la lista
3. ✅ Solo ves campos realmente disponibles
4. No puedes pisar reservas de otros equipos

---

## 🏗️ ARQUITECTURA TÉCNICA

### Tablas Creadas

#### `fields` (Campos)
```sql
- id (UUID, PK)
- name (VARCHAR) - Nombre del campo
- type (VARCHAR) - 'F7' o 'F11'
- location (VARCHAR) - Ubicación física
- is_active (BOOLEAN) - Si está disponible para reservas
- created_at, updated_at (TIMESTAMPTZ)
```

#### `bookings` (Reservas)
```sql
- id (UUID, PK)
- field_id (UUID, FK → fields)
- team_id (UUID)
- start_time, end_time (TIMESTAMPTZ)
- purpose (VARCHAR) - 'training', 'match', 'tactical', 'other'
- title (VARCHAR)
- description (TEXT)
- created_by (UUID, FK → auth.users)
- created_at, updated_at (TIMESTAMPTZ)
```

#### `booking_requests` (Solicitudes)
```sql
- id (UUID, PK)
- requester_id (UUID, FK → auth.users)
- requester_name (VARCHAR)
- desired_field_id (UUID, FK → fields)
- desired_start_time, desired_end_time (TIMESTAMPTZ)
- purpose, title, reason (VARCHAR/TEXT)
- status (VARCHAR) - 'pending', 'approved', 'rejected'
- reviewed_by (UUID, FK → auth.users)
- reviewed_at (TIMESTAMPTZ)
- review_notes (TEXT)
- created_at, updated_at (TIMESTAMPTZ)
```

### Funciones RPC

#### `check_booking_conflict()`
**Propósito:** Detectar si existe un conflicto de horario en un campo específico.

**Parámetros:**
- `p_field_id` (UUID)
- `p_start_time` (TIMESTAMPTZ)
- `p_end_time` (TIMESTAMPTZ)
- `p_exclude_booking_id` (UUID, opcional)

**Retorna:**
```json
{
  "conflict_exists": true/false,
  "conflicting_booking_id": "uuid",
  "conflicting_team_id": "uuid",
  "conflicting_title": "Nombre de la reserva",
  "conflicting_start": "2026-01-10T18:00:00Z",
  "conflicting_end": "2026-01-10T20:00:00Z"
}
```

**Lógica de Detección:**
Detecta solapamientos con tres casos:
1. La nueva reserva **empieza** durante una existente
2. La nueva reserva **termina** durante una existente
3. La nueva reserva **engloba** completamente una existente

#### `get_available_fields()`
**Propósito:** Devolver campos libres en un horario específico.

**Parámetros:**
- `p_start_time` (TIMESTAMPTZ)
- `p_end_time` (TIMESTAMPTZ)

**Retorna:**
```json
[
  {
    "field_id": "uuid",
    "field_name": "Campo Principal A",
    "field_type": "F11",
    "field_location": "Zona Norte"
  }
]
```

### Triggers Instalados

#### `trg_validate_booking`
**Tabla:** `bookings`  
**Evento:** BEFORE INSERT OR UPDATE  
**Función:** `validate_booking_before_save()`  
**Acción:** Valida automáticamente que no existan conflictos antes de guardar. Si detecta conflicto, **ABORTA** la operación con un error descriptivo.

#### `trg_update_*_updated_at`
**Tablas:** `fields`, `bookings`, `booking_requests`  
**Evento:** BEFORE UPDATE  
**Función:** `update_updated_at_column()`  
**Acción:** Actualiza automáticamente el campo `updated_at` a la fecha/hora actual.

### Políticas RLS (Row Level Security)

**Fields:**
- ✅ Todos pueden VER campos activos
- 🔒 Solo admins pueden crear/editar campos

**Bookings:**
- ✅ Todos pueden VER reservas
- 🔒 Solo el creador o admins pueden crear/editar

**Booking Requests:**
- ✅ Todos pueden VER solicitudes
- ✅ Usuarios pueden crear sus propias solicitudes
- 🔒 Solo admins pueden aprobar/rechazar

---

## 🐛 RESOLUCIÓN DE PROBLEMAS

### Error: "Could not find RPC function"

**Causa:** El script SQL no se ejecutó completamente.

**Solución:**
```sql
-- Verificar que existan las funciones
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%booking%';

-- Si no aparecen, volver a ejecutar SETUP_FIELDS_AND_BOOKINGS.sql
```

### Error: "No hay campos registrados"

**Causa:** No has insertado registros en la tabla `fields`.

**Solución:**
```sql
INSERT INTO fields (name, type, location) VALUES
  ('Campo 1', 'F11', 'Instalación Principal');
```

### La verificación de disponibilidad devuelve campos ocupados

**Causa:** Posible desincronización entre Flutter y Supabase.

**Solución:**
1. Verifica en Supabase directamente:
```sql
SELECT * FROM bookings 
WHERE field_id = 'TU_FIELD_ID' 
AND start_time::date = '2026-01-10';
```

2. Actualiza la pantalla (botón refresh en AppBar)

### Error al crear reserva: "CONFLICTO DE HORARIO"

**Causa:** Alguien creó una reserva en ese horario mientras verificabas disponibilidad.

**Solución:**
1. Vuelve a verificar disponibilidad
2. Selecciona otro campo u otro horario

### Las solicitudes no se aprueban automáticamente

**Comportamiento Esperado:** Por defecto, las solicitudes quedan en estado "pending" hasta que un admin las apruebe.

**Si quieres aprobación automática:**
Modifica `field_service.dart`, función `createBookingRequest()`:
```dart
// Línea actual:
final response = await _client.from('booking_requests').insert({
  'requester_id': userId,
  'status': 'pending',  // ← Cambia a 'approved'
  ...
});

// También llama automáticamente a createBooking() después de insertar
```

---

## 🎨 PERSONALIZACIÓN

### Cambiar el rango de horarios (actualmente 16:00 - 22:00)

**Archivo:** `lib/screens/field_schedule_screen.dart`

```dart
// Líneas 20-22
final int _startHour = 16;  // ← Cambia a tu hora de inicio (ej: 8)
final int _endHour = 22;    // ← Cambia a tu hora de fin (ej: 23)
final int _slotDuration = 30; // ← Duración de cada bloque en minutos
```

### Cambiar los colores de los propósitos

**Archivo:** `lib/models/booking_model.dart`

```dart
static String getPurposeColor(String purpose) {
  switch (purpose) {
    case 'training':
      return 'green';  // ← Cambia aquí
    case 'match':
      return 'red';
    case 'tactical':
      return 'purple';
    default:
      return 'blue';
  }
}
```

### Agregar más tipos de actividad

1. **En SQL:**
```sql
ALTER TABLE bookings 
DROP CONSTRAINT bookings_purpose_check;

ALTER TABLE bookings 
ADD CONSTRAINT bookings_purpose_check 
CHECK (purpose IN ('training', 'match', 'tactical', 'other', 'friendly')); -- Añade 'friendly'
```

2. **En Flutter (`booking_request_screen.dart`):**
```dart
_buildPurposeChip('friendly', 'Amistoso', Icons.handshake, Colors.teal, colorScheme),
```

---

## 📊 ESTADÍSTICAS Y MÉTRICAS (Futuras Mejoras)

### Ideas para Implementar:

**Dashboard de Ocupación:**
```sql
-- Query de ejemplo
SELECT 
  f.name AS campo,
  COUNT(b.id) AS total_reservas,
  SUM(EXTRACT(EPOCH FROM (b.end_time - b.start_time))/3600) AS horas_totales
FROM fields f
LEFT JOIN bookings b ON f.id = b.field_id
WHERE b.start_time >= NOW() - INTERVAL '30 days'
GROUP BY f.id, f.name
ORDER BY horas_totales DESC;
```

**Campos más usados:**
```sql
SELECT 
  f.name,
  b.purpose,
  COUNT(*) AS cantidad
FROM fields f
JOIN bookings b ON f.id = b.field_id
GROUP BY f.id, f.name, b.purpose
ORDER BY cantidad DESC;
```

---

## 🤝 SOPORTE

### Archivos Creados por este Sistema:

```
📁 futbol---app/
├── 📄 SETUP_FIELDS_AND_BOOKINGS.sql          ← Script de instalación BD
├── 📄 GUIA_CAMPOS_Y_RESERVAS.md              ← Este archivo
├── 📁 lib/
│   ├── 📁 models/
│   │   ├── field_model.dart                   ← Modelo de campos
│   │   ├── booking_model.dart                 ← Modelo de reservas
│   │   └── booking_request_model.dart         ← Modelo de solicitudes
│   ├── 📁 services/
│   │   └── field_service.dart                 ← Lógica de negocio completa
│   └── 📁 screens/
│       ├── field_schedule_screen.dart         ← Vista de calendario
│       ├── booking_request_screen.dart        ← Formulario de solicitud
│       ├── home_screen.dart                   ← Modificado (integración)
│       └── session_planner_screen.dart        ← Modificado (validación)
```

---

## ✅ CHECKLIST DE VERIFICACIÓN

Antes de usar en producción, confirma:

- [ ] Script SQL ejecutado sin errores
- [ ] Al menos 2 campos insertados en `fields`
- [ ] Funciones RPC visibles en Supabase Dashboard
- [ ] Políticas RLS activadas (pestaña Authentication > Policies)
- [ ] Botón "Campos" visible en Command Center
- [ ] Puedes verificar disponibilidad y ver campos libres
- [ ] La creación de entrenamientos solicita campo
- [ ] Al intentar crear una reserva en horario ocupado, aparece error

---

## 🚀 PRÓXIMOS PASOS

1. **Configura un Team ID real:**
   - Actualmente usa `'TEAM_ID_TEMPORAL'`
   - Modifica `field_service.dart` para obtener el team_id del usuario actual

2. **Panel de Aprobación de Solicitudes:**
   - Crea una pantalla para que admins vean y aprueben solicitudes pendientes
   - Usa `_fieldService.getPendingRequests()`

3. **Notificaciones Push:**
   - Cuando una solicitud es aprobada/rechazada
   - Cuando alguien reserva un campo que tú querías

4. **Exportar Calendario a PDF/iCal:**
   - Genera un reporte semanal con todas las reservas

---

**Documentación creada:** 2026-01-08  
**Sistema:** Futbol App v1.0  
**Autor:** Sistema de Gestión de Campos  
**Última actualización:** 2026-01-08

---

¿Necesitas ayuda? Consulta los logs de Flutter con `flutter run -v` o revisa los errores de Supabase en el Dashboard > Logs.
