# Scripts para ejecutar en Supabase (orden correcto)

Ejecuta en **Supabase Dashboard → SQL Editor** en este orden. Copia cada script, pégalo en el editor y pulsa **Run**.

---

## Orden de ejecución

| Orden | Archivo | Cuándo ejecutarlo |
|-------|---------|-------------------|
| **1** | `supabase/sql_scripts/01_elite_performance.sql` | Solo si es proyecto **nuevo** (sin tablas `profiles`, `players`, `sessions`, etc.). Si ya las tienes, **omite** y pasa al 2. |
| **2** | `supabase/sql_scripts/02_notifications.sql` | Siempre (crea la tabla `notifications` si no existe). |
| **3** | `supabase/sql_scripts/03_device_tokens.sql` | Opcional; solo si vas a usar **push notifications** (FCM). |
| **4** | `supabase/sql_scripts/04_notification_triggers.sql` | Siempre (triggers que llaman a las Edge Functions). |

---

## Opción: todo en uno

Si quieres ejecutar **todo seguido** en un proyecto nuevo, usa:

**`supabase/sql_scripts/TODO_EN_ORDEN.sql`**

Ese archivo contiene los 4 scripts en el orden correcto. Cópialo entero en el SQL Editor y ejecuta una sola vez.

---

## Después del SQL

1. **Desplegar Edge Functions** (en tu máquina, con Supabase CLI):
   ```bash
   supabase functions deploy notify_on_registration
   supabase functions deploy session_management
   supabase functions deploy low_credits_alert
   supabase functions deploy daily_report_generator
   ```
2. **Configurar secretos** en Supabase: **Project Settings → Edge Functions → Secrets**  
   Añade: `RESEND_API_KEY`, y si usas push: `FCM_SERVER_KEY`.
