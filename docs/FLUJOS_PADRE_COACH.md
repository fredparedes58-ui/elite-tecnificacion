# Flujos de comunicación y funcionamiento: Padre ↔ Coach

Documento de referencia para QA y producto: qué hace cada rol y cómo se relacionan Coach y Padre en la app.

---

## 1. Resumen de roles

| Rol   | Descripción breve | Identificación en app |
|-------|--------------------|------------------------|
| **Coach / Admin** | Gestiona equipo, sesiones, partidos, asistencias y comunicaciones. | `team_members.role` = `coach` o `admin` |
| **Padre**        | Ve información de sus hijos, marca asistencia y consume avisos/chat oficial. | Relación en `parent_child_relationships`; puede no estar en `team_members` como coach |

---

## 2. Flujos por área

### 2.1 Chat de equipo (TeamChatScreen)

**Canales:**
- **Avisos Oficiales** (`announcement`): mensajes del entrenador al equipo.
- **Vestuario** (`general`): chat grupal del equipo.

| Acción | Coach / Admin | Padre |
|--------|----------------|-------|
| Ver **Avisos Oficiales** | ✅ | ✅ (solo lectura) |
| Escribir en **Avisos Oficiales** | ✅ | ❌ |
| Ver **Vestuario** | ✅ | ✅ |
| Escribir en **Vestuario** | ✅ | ✅ |
| Crear aviso rápido (si existe UI) | ✅ | ❌ |

**Flujo de comunicación:**
1. Coach publica en Avisos → todos (incluidos padres) ven el mensaje.
2. Coach y padres/jugadores pueden hablar en Vestuario.
3. Padre solo lee Avisos; no puede editar ni borrar mensajes del coach.

**Dato técnico:** `ChatChannel.canUserWrite(userRole)` devuelve `true` para Avisos solo si `userRole` es `coach` o `admin`.

---

### 2.2 Asistencia

| Pantalla | Rol | Qué hace |
|----------|-----|----------|
| **AttendanceScreen** | Coach / Admin | Pasar lista por sesión/entrenamiento, marcar presentes/ausentes. |
| **ParentAttendanceScreen** | Padre | Ver sesiones de sus hijos y **marcar asistencia** (asistirá / no asistirá, etc.) por sesión. |

**Flujo:**
1. Coach define sesiones de entrenamiento (SessionPlanner / datos en Supabase).
2. Coach puede pasar lista en **AttendanceScreen** (registro oficial).
3. Padre entra por Home → Asistencia; la app comprueba `parent_child_relationships` y redirige a **ParentAttendanceScreen**.
4. Padre elige hijo (si tiene varios) y marca asistencia para las sesiones mostradas.

**Condición para ver Asistencia como padre:** tener al menos un registro en `parent_child_relationships` con su `user_id` como `parent_id`.

---

### 2.3 Tablón de avisos (NoticeBoardScreen)

| Acción | Coach / Admin | Padre |
|--------|----------------|-------|
| Ver avisos | ✅ | ✅ (si tienen acceso a la pantalla) |
| Filtrar por rol (ej. "parent") | ✅ | ✅ |
| Crear aviso | ✅ | ❌ (solo coach/admin) |
| Editar / eliminar aviso | ✅ | ❌ |

**Flujo:** Coach publica en el Tablón → padres (y otros roles) ven y filtran por "parent" si la UI lo ofrece. Es unidireccional: coach escribe, padre lee.

---

### 2.4 Fútbol Social (SocialFeedScreen)

Feed de equipo (fotos, momentos, comentarios).

| Acción | Coach | Padre |
|--------|--------|-------|
| Ver feed | ✅ | ✅ (si tienen acceso al equipo) |
| Crear post / compartir momento | ✅ | Depende de permisos en backend/UI |
| Like / comentar | Según implementación | Según implementación |

**Flujo:** Comunicación horizontal (todos los que tienen acceso pueden participar, salvo restricciones que se definan por rol en la app).

---

### 2.5 Otras áreas (solo Coach o compartidas)

| Área | Coach | Padre |
|------|--------|-------|
| **Plantilla (SquadManagement)** | Gestionar jugadores, perfiles | Normalmente no accede o solo lectura (según navegación) |
| **Partidos (MatchesScreen)** | Crear partidos, reportes, live | Solo lectura si se le da acceso |
| **Entrenamientos / Sesiones** | Crear y editar sesiones | Solo ver (si hay pantalla para padres) |
| **Tácticas, Ejercicios, Metodología, Campos, Goleadores** | Uso completo | No o solo lectura según diseño |
| **Galería** | Subir y ver | Ver (compartida en Dashboard) |
| **Notificaciones** | Recibir y gestionar | Recibir (compartida en Dashboard) |

---

## 3. Cómo se decide “Padre” vs “Coach” en la app

1. **Asistencia (Home → Asistencia):**
   - Se obtiene `user_id` del usuario actual.
   - Si existe al menos un hijo en `parent_child_relationships` → **ParentAttendanceScreen**.
   - Si no, se consulta `team_members` por `user_id`; si `role` es `coach` o `admin` → **AttendanceScreen**.
   - Si no es padre ni coach → mensaje “No tienes permisos” o redirección por defecto.

2. **Chat:**
   - Se pasa `userRole` al **TeamChatScreen** (desde Dashboard o Home).
   - Ese valor suele venir de perfil o `team_members.role`. Para padres puede ser `parent` o similar; para coach/admin se usa `coach`/`admin` para permitir escribir en Avisos.

3. **Auth actual:** En el código, `AuthGate` lleva directo al Dashboard con `userRole: 'coach'`. Para probar como **Padre** hace falta:
   - Login real leyendo rol desde Supabase, o
   - Cambiar temporalmente a `userRole: 'parent'` y tener datos en `parent_child_relationships` para que Asistencia y demás flujos de padre tengan sentido.

---

## 4. Diagrama de flujo resumido (Padre ↔ Coach)

```
                    COACH
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
    ▼                 ▼                 ▼
 Avisos          Asistencia         Tablón
 (escribe)       (pasar lista)      (crear avisos)
    │                 │                 │
    │                 │                 │
    └────────┬────────┴────────┬────────┘
             │                 │
             ▼                 ▼
          PADRE (lee/participa según canal)
             │
    ┌────────┼────────┐
    ▼        ▼        ▼
 Avisos   Asistencia  Tablón
 (solo    (marca      (solo
  lectura)  hijo)       lectura)
```

---

## 5. Checklist QA por flujo Padre–Coach

- [ ] **Chat – Avisos:** Coach escribe → Padre ve mensaje y no ve botón/enviar en Avisos.
- [ ] **Chat – Vestuario:** Coach y Padre pueden enviar mensajes.
- [ ] **Asistencia – Coach:** Pasar lista y guardar en Supabase.
- [ ] **Asistencia – Padre:** Solo usuario con hijos en `parent_child_relationships` ve ParentAttendanceScreen; puede marcar asistencia del hijo.
- [ ] **Tablón:** Coach crea aviso; Padre (si tiene acceso) ve y puede filtrar por “parent”.
- [ ] **Sin rol coach ni padre:** Asistencia muestra mensaje de permisos o redirección coherente.

Usar **QA_PROMPT.md** para ejecutar la pasada completa por pantalla y anotar qué funciona y qué no en cada área.
