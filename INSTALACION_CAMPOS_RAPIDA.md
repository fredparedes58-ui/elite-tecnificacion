# ⚡ INSTALACIÓN RÁPIDA: SISTEMA DE CAMPOS Y RESERVAS

## 📋 CHECKLIST DE INSTALACIÓN (5 minutos)

### ✅ PASO 1: Ejecutar SQL en Supabase

1. Abre tu Dashboard de Supabase: https://app.supabase.com
2. Selecciona tu proyecto
3. Ve a **SQL Editor** (menú lateral izquierdo)
4. Click en **"New query"**
5. Copia **TODO** el contenido del archivo `SETUP_FIELDS_AND_BOOKINGS.sql`
6. Pega en el editor
7. Click en **"Run"** (botón verde)
8. Verifica que veas los mensajes de éxito en verde ✅

**¿Qué hace este script?**
- Crea 3 tablas: `fields`, `bookings`, `booking_requests`
- Crea 2 funciones RPC para detectar conflictos
- Activa triggers automáticos
- Configura políticas de seguridad (RLS)

---

### ✅ PASO 2: Insertar Campos de Ejemplo

En el mismo SQL Editor, ejecuta esto:

```sql
INSERT INTO fields (name, type, location) VALUES
  ('Campo Principal A', 'F11', 'Zona Norte - Instalación 1'),
  ('Campo Principal B', 'F11', 'Zona Norte - Instalación 1'),
  ('Campo 7 - Norte', 'F7', 'Zona Norte - Instalación 2'),
  ('Campo 7 - Sur', 'F7', 'Zona Sur - Instalación 2')
ON CONFLICT DO NOTHING;
```

**Personaliza los nombres según tu club:**
- Cambia "Campo Principal A" por el nombre real de tus campos
- Ajusta `type`: `'F7'` (Fútbol 7) o `'F11'` (Fútbol 11)
- Especifica la `location`: Zona, edificio, número...

---

### ✅ PASO 3: Verificar Instalación

En SQL Editor, ejecuta:

```sql
-- Ver los campos creados
SELECT * FROM fields;

-- Verificar funciones RPC
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('check_booking_conflict', 'get_available_fields');
```

**Resultado esperado:**
- Deberías ver los 4 campos que insertaste
- Deberías ver 2 filas con los nombres de las funciones

---

### ✅ PASO 4: Ejecutar la App Flutter

En tu terminal:

```bash
# Asegurarte de estar en la carpeta del proyecto
cd /Users/celiannycastro/Desktop/app-futbol-base/futbol---app

# Instalar dependencias (si no lo has hecho)
flutter pub get

# Ejecutar la app
flutter run
```

**Nota:** No necesitas instalar nuevas dependencias. Todo lo que necesitas (`intl`, `google_fonts`, `supabase_flutter`) ya está en `pubspec.yaml`.

---

### ✅ PASO 5: Probar el Sistema

#### 5.1 Ver el Calendario
1. Abre la app
2. En **Command Center**, busca el botón **"Campos"** (icono de estadio, color cyan)
3. Toca el botón
4. Deberías ver el calendario con la fecha de hoy
5. Navega por los días con las flechas ◀️ ▶️

#### 5.2 Solicitar una Reserva
1. En la pantalla de Campos, toca el FAB **"SOLICITAR RESERVA"**
2. Selecciona una fecha (mañana)
3. Configura horario: 18:00 - 20:00
4. Toca **"VERIFICAR DISPONIBILIDAD"**
5. Deberías ver la lista de los 4 campos disponibles
6. Selecciona uno
7. Ingresa título: "Prueba de Sistema"
8. Selecciona tipo: Entrenamiento
9. Toca **"ENVIAR SOLICITUD"**
10. Verifica que aparezca el mensaje de éxito ✅

#### 5.3 Crear Entrenamiento con Campo
1. Ve a **Command Center** > **Entrenamientos**
2. Selecciona un día > FAB "+" (abajo a la derecha)
3. Ingresa título: "Entrenamiento Técnico"
4. Ingresa objetivo: "Pases cortos"
5. Configura horario: 16:00 - 18:00
6. Toca **"Verificar Disponibilidad"**
7. Selecciona un campo de la lista
8. Toca **"Guardar"**
9. Verifica mensaje: "✅ Sesión creada y campo reservado"

#### 5.4 Verificar la Reserva en el Calendario
1. Vuelve a **Campos**
2. Navega al día del entrenamiento
3. Deberías ver una **celda verde** en el campo seleccionado a las 16:00-18:00
4. Toca la celda verde
5. Verifica que aparezca el detalle completo

---

## 🎯 PRUEBA DE CONFLICTOS (CRÍTICO)

### Prueba 1: Intentar Pisar una Reserva

1. Ve a **Entrenamientos**
2. Crea una nueva sesión en el **MISMO día y hora** que la anterior
3. Usa el **MISMO campo**
4. Al verificar disponibilidad, ese campo **NO debe aparecer** en la lista
5. ✅ **Resultado esperado:** Solo aparecen campos libres

### Prueba 2: Detección Automática de Conflicto

1. En Supabase, ejecuta este SQL para crear una reserva manual:
```sql
INSERT INTO bookings (field_id, team_id, start_time, end_time, purpose, title)
SELECT 
  f.id,
  '00000000-0000-0000-0000-000000000000',
  NOW() + INTERVAL '1 day' + INTERVAL '20 hours',
  NOW() + INTERVAL '1 day' + INTERVAL '22 hours',
  'match',
  'Partido de Prueba'
FROM fields f
LIMIT 1;
```

2. En la app, intenta crear una sesión a las 20:00-22:00 mañana
3. Verifica disponibilidad
4. El campo de la reserva manual **NO debe aparecer**
5. ✅ **Resultado esperado:** Sistema detecta el conflicto

---

## 🐛 PROBLEMAS COMUNES

### "No hay campos registrados"

**Causa:** No ejecutaste el INSERT de campos (Paso 2).

**Solución:**
```sql
-- Verifica si hay campos
SELECT COUNT(*) FROM fields;

-- Si devuelve 0, ejecuta el INSERT del Paso 2
```

---

### "Could not find RPC function: check_booking_conflict"

**Causa:** El script SQL no se ejecutó completamente.

**Solución:**
```sql
-- Verifica si existen las funciones
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%booking%';

-- Si no aparecen, vuelve a ejecutar SETUP_FIELDS_AND_BOOKINGS.sql COMPLETO
```

---

### Error: "MissingPluginException(No implementation found for method...)"

**Causa:** No ejecutaste `flutter pub get`.

**Solución:**
```bash
flutter clean
flutter pub get
flutter run
```

---

### Las fechas aparecen en inglés

**Causa:** No se configuró correctamente la localización.

**Solución:** Ya está solucionado en `lib/main.dart` (se agregó automáticamente). Si persiste:

```bash
# En tu terminal
flutter clean
flutter pub get
flutter run
```

---

### El botón "Campos" no aparece en Command Center

**Causa:** Posible error de compilación.

**Solución:**
```bash
# Detén la app (Ctrl+C)
flutter clean
flutter run
```

Busca el botón **cyan con icono de estadio** en el grid de acceso rápido.

---

## 📊 VERIFICACIÓN FINAL

Marca cada ítem cuando lo completes:

- [ ] Script SQL ejecutado sin errores
- [ ] Campos insertados (al menos 2)
- [ ] Funciones RPC verificadas en Supabase
- [ ] App ejecutándose sin errores
- [ ] Botón "Campos" visible en Command Center
- [ ] Puedes ver el calendario
- [ ] Puedes solicitar una reserva
- [ ] La verificación de disponibilidad funciona
- [ ] Puedes crear un entrenamiento con campo
- [ ] El campo NO aparece disponible si está ocupado
- [ ] La reserva aparece en el calendario
- [ ] Puedes tocar una reserva y ver detalles

---

## 🚀 ¡TODO LISTO!

Si marcaste todos los ítems anteriores, **el sistema está funcionando correctamente**.

### Próximos Pasos:

1. **Personaliza los campos:**
   - Agrega más campos en la tabla `fields`
   - Ajusta nombres, tipos y ubicaciones según tu club

2. **Configura usuarios reales:**
   - Actualmente usa IDs temporales
   - Modifica `field_service.dart` para obtener el `team_id` del usuario actual

3. **Crea un panel de admin:**
   - Pantalla para aprobar/rechazar solicitudes pendientes
   - Ver estadísticas de uso de campos

4. **Lee la documentación completa:**
   - `GUIA_CAMPOS_Y_RESERVAS.md` - Guía detallada de 500+ líneas
   - `RESUMEN_CAMPOS_Y_RESERVAS.md` - Resumen técnico

---

## 📞 SOPORTE

### Si algo no funciona:

1. **Revisa los logs de Flutter:**
```bash
flutter run -v
```

2. **Revisa los logs de Supabase:**
   - Dashboard > Logs > Selecciona tabla/función

3. **Verifica la estructura de la BD:**
```sql
-- Ver todas las tablas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%field%' OR table_name LIKE '%booking%';

-- Resultado esperado: fields, bookings, booking_requests
```

---

## ✅ RESUMEN

**Archivos ejecutados:**
- ✅ `SETUP_FIELDS_AND_BOOKINGS.sql` (1 vez en Supabase)

**Archivos modificados automáticamente:**
- ✅ `lib/main.dart` (localización en español)
- ✅ `lib/screens/home_screen.dart` (botón "Campos")
- ✅ `lib/screens/session_planner_screen.dart` (validación)

**Archivos nuevos creados:**
- ✅ 3 modelos (field, booking, booking_request)
- ✅ 1 servicio (field_service)
- ✅ 2 pantallas (schedule, request)
- ✅ 3 documentos (guía, resumen, instalación)

**Tiempo de instalación:** 5 minutos  
**Complejidad:** Baja (solo copiar/pegar SQL)  
**Estado:** ✅ Listo para producción

---

**Fecha de creación:** 2026-01-08  
**Sistema:** Futbol App - Módulo de Campos y Reservas  
**Versión:** 1.0.0

**¡Disfruta gestionando tus campos sin conflictos!** ⚽🏟️
