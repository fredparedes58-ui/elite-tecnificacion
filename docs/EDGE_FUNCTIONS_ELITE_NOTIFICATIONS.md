# Edge Functions: Lógica de Notificaciones (Elite Performance)

Resumen de las Edge Functions de TypeScript para notificaciones y reportes.

---

## 1. `notify_on_registration`

**Qué hace:** Al crear un perfil de padre, envía correo de confirmación de bienvenida.

**Invocación:**
- **Automática:** Trigger en `public.profiles` (INSERT con `role = 'parent'`) vía pg_net (migración `20260220100000_elite_notification_triggers.sql`).
- **Manual:** `POST /functions/v1/notify_on_registration` con body `{ "profile_id": "uuid" }`.

**Body (manual):**
```json
{ "profile_id": "uuid-del-perfil" }
```

**Variables de entorno:** `RESEND_API_KEY` (para enviar el email).

---

## 2. `session_management`

**Qué hace:** Cuando el admin (Pedro) asigna, modifica o cancela una sesión, envía notificación push y crea filas en `notifications` para los padres con reserva en esa sesión y para el coach asignado.

**Invocación:** Desde el cliente (Flutter) después de crear/actualizar/cancelar una sesión.

**Body:**
```json
{
  "action": "assigned" | "updated" | "cancelled",
  "session_id": "uuid-de-la-sesion"
}
```

**Requisitos:** Tablas `sessions`, `bookings`, `players`, `profiles`, `notifications`. Opcional: `device_tokens` y `FCM_SERVER_KEY` para push.

**Ejemplo desde Flutter:**
```dart
await Supabase.instance.client.functions.invoke(
  'session_management',
  body: { 'action': 'updated', 'session_id': sessionId },
);
```

---

## 3. `low_credits_alert`

**Qué hace:** Cuando `credit_balance` en `wallets` llega a **1**, notifica al padre (email + push + notificación in-app) y a todos los perfiles con `role = 'admin'` (Pedro).

**Invocación:**
- **Automática:** Trigger en `public.wallets` (UPDATE con `NEW.credit_balance = 1`) vía pg_net.
- **Manual:** `POST /functions/v1/low_credits_alert` con body `{ "parent_id": "uuid" }`.

**Variables de entorno:** `RESEND_API_KEY` (opcional, para email), `FCM_SERVER_KEY` (opcional, para push).

---

## 4. `daily_report_generator`

**Qué hace:** Genera el reporte **semanal** o **mensual** de créditos consumidos por familia (sesiones con asistencia marcada en el periodo).

**Invocación:** Por cron (semanal/mensual) o manual.

**Body:**
```json
{
  "period": "weekly" | "monthly",
  "date": "YYYY-MM-DD"   // opcional; por defecto hoy
}
```

- **weekly:** últimos 7 días hasta ayer.
- **monthly:** mes anterior completo.

**Respuesta:** JSON con `summary` (total créditos, número de familias) y `by_family` (parent_id, full_name, email, credits_consumed, players).

**Ejemplo de respuesta:**
```json
{
  "success": true,
  "period": "weekly",
  "start": "2026-02-10",
  "end": "2026-02-16",
  "summary": { "total_credits_consumed": 12, "families": 5 },
  "by_family": [
    {
      "parent_id": "...",
      "full_name": "María García",
      "email": "maria@example.com",
      "credits_consumed": 3,
      "players": [{ "name": "Juan" }]
    }
  ]
}
```

---

## Variables de entorno (Supabase Dashboard → Edge Functions → Secrets)

| Variable             | Uso                                      |
|----------------------|------------------------------------------|
| `RESEND_API_KEY`     | Email (notify_on_registration, low_credits_alert) |
| `FCM_SERVER_KEY`     | Push (session_management, low_credits_alert)       |
| `SUPABASE_URL`       | Automática                               |
| `SUPABASE_SERVICE_ROLE_KEY` | Automática                        |

---

## Triggers en base de datos (pg_net)

La migración `supabase/migrations/20260220100000_elite_notification_triggers.sql`:

1. **trg_notify_on_registration** – Después de `INSERT` en `profiles` con `role = 'parent'`, llama a `notify_on_registration`.
2. **trg_low_credits_alert** – Después de `UPDATE` en `wallets` cuando `credit_balance = 1`, llama a `low_credits_alert`.

Ajusta `app.settings.supabase_url` y `app.settings.supabase_anon_key` si usas otro proyecto (o vault) en lugar de los valores por defecto del script.

---

## Llamar a `session_management` desde la app

Donde el admin asigne, modifique o cancele una sesión (por ejemplo en la pantalla de gestión de sesiones), después de hacer el `insert`/`update` en `sessions`:

```dart
// Tras crear sesión
await supabase.functions.invoke('session_management', body: {
  'action': 'assigned',
  'session_id': newSessionId,
});

// Tras modificar sesión
await supabase.functions.invoke('session_management', body: {
  'action': 'updated',
  'session_id': sessionId,
});

// Tras cancelar sesión
await supabase.functions.invoke('session_management', body: {
  'action': 'cancelled',
  'session_id': sessionId,
});
```

---

## Reporte semanal/mensual (cron)

Puedes programar una llamada HTTP a `daily_report_generator` (por ejemplo con Supabase Cron o un servicio externo):

- Semanal (cada lunes):  
  `POST .../functions/v1/daily_report_generator`  
  body: `{ "period": "weekly" }`
- Mensual (día 1):  
  body: `{ "period": "monthly" }`

Usa el header `Authorization: Bearer <SUPABASE_ANON_KEY>` o `SUPABASE_SERVICE_ROLE_KEY` según tu configuración.
