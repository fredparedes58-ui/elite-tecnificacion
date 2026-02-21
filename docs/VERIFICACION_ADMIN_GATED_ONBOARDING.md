# Verificación: flujo Admin-Gated (aprobación por la academia)

## ✅ Implementación en código

| Componente | Archivo | Estado |
|------------|---------|--------|
| Columna `is_approved` | `EJECUTAR_ADMIN_GATED_ONBOARDING.sql` | OK – añadida a `profiles`, default false |
| Trigger notificar admin | Mismo script | OK – INSERT en `profiles` con `is_approved = false` → notificación in-app + Edge Function |
| Trigger bienvenida al aprobar | Mismo script | OK – UPDATE `is_approved` false→true → Edge Function correo al padre |
| RPC `approve_parent` | Mismo script | OK – solo admins, actualiza `is_approved` y dispara trigger |
| AuthGate | `lib/auth/auth_gate.dart` | OK – lee `is_approved`, si padre y no aprobado → WaitingApprovalScreen |
| Pantalla espera | `lib/screens/waiting_approval_screen.dart` | OK – mensaje y cerrar sesión |
| Pantalla pendientes (admin) | `lib/screens/pending_approvals_screen.dart` | OK – lista `is_approved = false`, botón Aprobar → RPC |
| Enlace en Ajustes | `lib/screens/settings_screen.dart` | OK – “Cuentas pendientes de aprobación” para admins |
| handle_new_user | `20260220160000_handle_new_user_admin_coach_emails.sql` | OK – inserta `is_approved = is_admin_coach` (false para padres) |
| Edge notify admin | `supabase/functions/notify_admin_pending_approval/index.ts` | OK – email a `admin_coach_emails` |
| Edge bienvenida padre | `supabase/functions/notify_on_registration/index.ts` | OK – `welcome_on_approval` + texto “Tu cuenta ha sido aprobada” |

---

## ⚠️ Comprobar en tu proyecto

### 1. Mismo proyecto para DB y Edge Functions
El script SQL usa por defecto la URL **hquoczkfumtpolyomrlg**. Si tu base de datos y tu app usan otro proyecto (por ejemplo **bqqjqasqmuyjnvmiuqvl** o **jlkehixruxuqalocuczp**):

- Ejecuta el SQL en **ese** proyecto, y  
- En las funciones `trigger_notify_admin_pending_approval` y `trigger_welcome_on_approval` sustituye la URL y el `anon_key` por los de tu proyecto (Dashboard → Settings → API),  
**o**
- Despliega las Edge Functions en el **mismo** proyecto donde ejecutaste el SQL.

Si la URL del script no coincide con el proyecto donde están desplegadas las funciones, los triggers no llamarán a tus funciones.

### 2. RLS en `profiles`
El admin debe poder **SELECT** todos los perfiles (para ver pendientes). Debe existir una política tipo “Admins can view all profiles” usando `is_admin()`. Si tu esquema tiene solo “Users can view own profile”, añade una política para admins.

### 3. Tablas y funciones previas
- `public.notifications` (para la notificación in-app al admin)
- `public.admin_coach_emails` (emails de admins para notificación y lista)
- `public.is_admin()` (usada por `approve_parent` y RLS)
- Trigger `on auth.users` que llame a `handle_new_user` para crear el perfil con `is_approved`

### 4. Supabase Dashboard
- **Edge Functions**: desplegar `notify_admin_pending_approval` y `notify_on_registration` en el proyecto correcto.
- **Secrets**: `RESEND_API_KEY` para envío de correos.

### 5. App Flutter
- `.env` con `SUPABASE_URL` y `SUPABASE_ANON_KEY` del **mismo** proyecto donde está la base de datos y las funciones.

---

## Prueba rápida del flujo

1. Registrar un usuario con un email que **no** esté en `admin_coach_emails` (padre).
2. Iniciar sesión en la app → debe mostrarse “Esperando aprobación de la Academia”.
3. Como admin, en Ajustes → “Cuentas pendientes de aprobación” → debe aparecer el nuevo perfil → Aprobar.
4. El padre debe recibir el correo “Tu cuenta ha sido aprobada” y, al volver a entrar (o refrescar), acceder al dashboard.

Si algo de lo anterior falla, revisar: proyecto/URL en el script, RLS en `profiles`, y que las Edge Functions estén desplegadas y con `RESEND_API_KEY` en el mismo proyecto.
