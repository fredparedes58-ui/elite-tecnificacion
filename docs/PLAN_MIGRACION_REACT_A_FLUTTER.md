# Plan de migración React Web → Flutter (una sola codebase)

> **Decisión de proyecto:** Todo el desarrollo se realiza **solo en Flutter**. No se hará desarrollo ni mantenimiento en React. La carpeta `src/` es legacy/referencia; el código activo está en `lib/`.

**Objetivo:** Migrar toda la funcionalidad de la app React Web (`src/`) a Flutter (`lib/`) para tener una sola codebase Flutter (Android, iOS y Flutter Web), sin perder funcionalidad y evitando riesgos conocidos del paradigma React → Flutter.

**Reglas de oro:** Lead Dev approach con (1) Layout wrapper web/móvil, (2) Repository + caché tipo React Query, (3) GoRouter obligatorio, (4) Logic Extraction antes de UI.

---

## 1. Inventario y mapeo

### 1.1 Rutas React (App.tsx) vs estado Flutter actual

| Ruta React | Pantalla/Flujo React | Equivalente Flutter actual | Notas |
|------------|----------------------|----------------------------|--------|
| `/` | Index (landing / admin dashboard / redirect) | `AuthGate` → `DashboardScreen` o `AuthScreen` | Flutter no tiene Index con landing + admin; usa Dashboard con BottomNav fijo |
| `/auth` | Auth (login/registro) | `AuthScreen` | Existe |
| `/scouting` | Scouting (grid jugadores, filtros) | Parcial: `SquadScreen`, `PlayerCardScreen`, etc. | No hay ruta única ni paridad de Scouting |
| `/dashboard` | Dashboard (panel padre) | `DashboardScreen` → `HomeScreen` (Command Center) | Flutter: BottomNav siempre; React: Navbar + contenido |
| `/players` | Players (mis jugadores) | `SquadScreen`, `SquadManagementScreen`, `AddTeamMemberScreen` | Disperso, sin ruta `/players` |
| `/reservations` | Reservations (reservas padre) | `FieldScheduleScreen`, `BookingRequestScreen` | Parcial |
| `/chat` | Chat (padre) | `TeamChatScreen`, `SelectChatRecipientScreen` | Existe en BottomNav |
| `/my-credits` | MyCredits | `CreditReportScreen` + widgets créditos | Parcial |
| `/profile` | Profile | `ProfileScreen` | Existe |
| `/notifications` | Notifications | `NotificationsScreen` | En BottomNav |
| `/settings` | Settings | `SettingsScreen` | Existe |
| `/admin` | Index para admin (panel admin) | No equivalente; Flutter no distingue / vs /admin | Falta |
| `/admin/users` | AdminUsers | No existe pantalla dedicada | Falta |
| `/admin/reservations` | AdminReservations | No equivalente directo | Falta |
| `/admin/chat` | AdminChat | Mismo chat con rol admin | Falta ruta y vista admin |
| `/admin/notifications` | AdminNotifications | No | Falta |
| `/admin/settings` | AdminSettings | No | Falta |
| `/admin/player-approval` | AdminPlayerApproval | `PendingApprovalsScreen`, `WaitingApprovalScreen` | Parcial |
| `/admin/players` | AdminPlayers | `SquadManagementScreen` / directorio | Falta ruta y vista admin |
| `/admin/compare-players` | ComparePlayers | No | Falta |
| BlockedScreen | Usuario no aprobado | `WaitingApprovalScreen` | Existe concepto |
| `*` (NotFound) | NotFound | No manejado en Flutter | Falta |

### 1.2 Hooks React → lógica a extraer (Logic Extraction)

Cada hook debe convertirse en **repositorio + ChangeNotifier/Provider** antes de implementar UI.

| Hook React | Tablas/Recursos Supabase | Realtime | Caché (staleTime/gcTime) | Destino Flutter |
|------------|--------------------------|----------|---------------------------|-----------------|
| `useAuth` (AuthContext) | auth, profiles, user_roles | onAuthStateChange | — | `AuthProvider` + `AuthRepository` (perfil, roles, isApproved) |
| `useReservations` | reservations | postgres_changes (reservations) | 30s / 5min | `ReservationsRepository` + `ReservationsProvider` |
| `useCredits` | user_credits | postgres_changes (user_credits) | — | `CreditsRepository` + `CreditsProvider` |
| `useConversations` | conversations, messages, conversation_state | postgres_changes | — | `ConversationsRepository` + `ChatProvider` |
| `useUnreadCounts` | conversation_state | postgres_changes | — | Incluir en `ConversationsRepository` o `ChatProvider` |
| `useNotifications` | notifications + realtime | postgres_changes (notifications) | — | `NotificationsRepository` + `NotificationsProvider` (realtime + sonido opcional) |
| `useUsers` | profiles, user_roles, user_credits | — | — | `UsersRepository` + `AdminUsersProvider` |
| `useMyPlayers` | parent_child_relationships, players, etc. | — | — | `MyPlayersRepository` + `MyPlayersProvider` |
| `usePlayers` | players, profiles, etc. | — | React Query | `PlayersRepository` (scouting) + caché |
| `usePendingPlayers` | players (pending) | — | — | `PendingPlayersRepository` o parte de `PlayersRepository` |
| `useAdminKPIs` | varias (reservations, users, etc.) | — | — | `AdminKpiRepository` + provider |
| `useCreditPackages` | credit_packages | — | — | `CreditPackagesRepository` |
| `useCreditTransactions` | credit_transactions | — | — | `CreditTransactionsRepository` |
| `useTrainers` | trainers / profiles | — | — | `TrainersRepository` |
| `usePlayerSessionHistory` | session_history | — | — | `SessionHistoryRepository` |
| `usePlayerStatsHistory` | stats | — | — | `PlayerStatsRepository` |
| `useSessionHistory` | — | — | — | Revisar y mapear a repo existente |
| `useNotificationsCenter` | notifications | — | — | Mismo que useNotifications |
| `useCapacityColors` | system_config / slots | — | — | `SystemConfigRepository` o parte de reservas |
| `useSystemConfig` | system_config | — | — | `SystemConfigRepository` |
| `useUpload` | storage | — | — | Ya existe `MediaUploadService` / `FileManagementService`; exponer si falta |
| `use-mobile` | — | — | — | `MediaQuery` / `LayoutBuilder` en layout wrapper |
| `use-toast` | — | — | — | SnackBar / overlay en Flutter |
| `usePlayersWeeklyImprovement` | — | — | — | Parte de `PlayersRepository` o stats |

---

## 2. Reglas obligatorias (resumen)

1. **Layout wrapper (web vs móvil)**  
   - Detección: `kIsWeb` o `MediaQuery.of(context).size.width` (p.ej. breakpoint 600–800).  
   - Web/pantalla ancha: navegación **Sidebar** (drawer lateral o NavigationRail).  
   - Móvil/pantalla estrecha: **BottomNav** (o navegación móvil actual).  
   - Todas las pantallas migradas se envuelven en este wrapper (no depender solo del BottomNav actual del `DashboardScreen`).

2. **Repository + caché (tipo React Query)**  
   - En `lib/services/` (o `lib/repositories/`): repos por dominio (users, players, reservations, credits, conversations, notifications, etc.).  
   - Caché en memoria por clave (recurso + id o query).  
   - TTL o invalidación explícita para no usar datos obsoletos.  
   - Las pantallas consumen solo repos/providers, no llaman a Supabase directamente para listas/detalle.

3. **GoRouter obligatorio**  
   - Rutas que reflejen la web: `/`, `/auth`, `/dashboard`, `/players`, `/reservations`, `/chat`, `/my-credits`, `/profile`, `/notifications`, `/settings`, `/admin`, `/admin/users`, `/admin/reservations`, `/admin/chat`, `/admin/notifications`, `/admin/settings`, `/admin/player-approval`, `/admin/players`, `/admin/compare-players`, `/scouting`.  
   - Flutter Web: mismas URLs y botones atrás/adelante del navegador.  
   - Navegación con `context.go` / rutas nombradas; no depender solo de `Navigator.push`.

4. **Logic Extraction antes de UI**  
   - Por cada página/componente React: listar todos los `useEffect`, suscripciones Supabase (realtime), fetches en mount, invalidaciones.  
   - Convertir en métodos y estado de un **ChangeNotifier** (o Provider) en `lib/providers/` o `lib/services/`.  
   - Hooks → datos/caché = Repository; efectos y suscripciones = ChangeNotifier (init, dispose, listen to Supabase).  
   - Solo después implementar la pantalla en Flutter que escuche al Provider/ChangeNotifier.

---

## 3. Flujo por pantalla (A → B → C → D)

Para **cada** pantalla o flujo migrado:

- **A) Logic Extraction:** Extraer de los `.tsx`/`.ts` de React toda la lógica (hooks, useEffect, Supabase) a repositorios + ChangeNotifier/Provider.  
- **B) Repositorios y caché:** Asegurar que `lib/services/` (o `lib/repositories/`) tengan el patrón de caché tipo React Query donde aplique.  
- **C) Rutas:** Registrar la pantalla en GoRouter con la URL correcta (paridad con React).  
- **D) UI:** Implementar la pantalla usando el **Screen Layout Wrapper** (Sidebar en web, BottomNav en móvil) y que consuma solo los repos y providers de (A)–(B).  
- **E)** No borrar `src/` hasta que la versión Flutter esté probada y aceptada.

---

## 4. Plan por fases

### Fase 0 — Infraestructura (sin migrar pantallas React aún)

Objetivo: tener listo GoRouter, Layout Wrapper y patrón Repository+caché para el resto de fases.

| Tarea | Descripción |
|-------|-------------|
| **0.1 GoRouter** | Añadir `go_router`, definir árbol de rutas (shell con layout wrapper y rutas hijas). Rutas públicas: `/`, `/auth`, `/reset-password`. Rutas protegidas: `/dashboard`, `/players`, `/reservations`, `/chat`, `/my-credits`, `/profile`, `/notifications`, `/settings`. Admin: `/admin`, `/admin/users`, `/admin/reservations`, `/admin/chat`, `/admin/notifications`, `/admin/settings`, `/admin/player-approval`, `/admin/players`, `/admin/compare-players`. `/scouting`. Ruta catch-all `*` → NotFound. Integrar con `AuthGate` (redirect por rol y aprobación). |
| **0.2 Screen Layout Wrapper** | Widget que use `MediaQuery`/`LayoutBuilder` (y opcionalmente `kIsWeb`). Si web o ancho > breakpoint: Shell con **Sidebar** (NavigationRail o Drawer persistente) que muestre enlaces según rol (admin vs padre). Si móvil: Shell con **BottomNav** (actualizar ítems para que coincidan con rutas GoRouter). Todas las pantallas de app (post-login) se muestran dentro de este shell. |
| **0.3 Repository base + caché** | Crear en `lib/services/` o `lib/repositories/` una clase base o mixin de “caché por clave con TTL” (ej. `CacheKey`, `getCached`, `setCached`, `invalidate`). Documentar uso para repos nuevos. Opcional: `lib/repositories/credits_repository.dart` como primer ejemplo con `user_credits` y realtime. |

**Entregables Fase 0:** GoRouter funcionando en web con URLs correctas, Layout Wrapper mostrando Sidebar en web y BottomNav en móvil, y patrón de repositorio con caché documentado y al menos un repo de ejemplo.

**Implementado (Fase 0 completada):**
- `lib/config/app_router.dart`: GoRouter con rutas /, /auth, /reset-password, /waiting-approval, /dashboard, /players, … /admin/*, /scouting y catch-all a NotFound.
- `lib/auth/app_auth_state.dart`: Estado de sesión/rol para el shell.
- `lib/auth/auth_gate_redirect.dart`: Gate que detecta rol y redirige a /auth, /waiting-approval, /admin o /dashboard.
- `lib/widgets/screen_layout_wrapper.dart`: Sidebar (web/≥800px) o BottomNav (móvil), ítems según admin/padre.
- `lib/services/memory_cache.dart`: Caché en memoria con TTL e invalidación (clave, prefix).
- `lib/repositories/credits_repository.dart`: Balance user_credits con caché 30s y realtime; ejemplo de uso del patrón.

---

### Fase 1 — Auth, Index, BlockedScreen, NotFound

| Pantalla | A) Logic Extraction | B) Repos + caché | C) GoRouter | D) UI con layout wrapper |
|----------|---------------------|-------------------|-------------|---------------------------|
| **Auth** | AuthContext: `onAuthStateChange`, `fetchProfile`, `refreshProfile`, signIn/signUp/signOut, push notifications init. Mapear a `AuthProvider` (ChangeNotifier) + llamadas a Supabase (profiles, user_roles). | `AuthRepository`: getProfile(userId), setProfile, no caché largo para perfil actual (o TTL corto). | Ruta `/auth`. Redirect post-login según rol a `/` o `/admin` o `/dashboard`. | Pantalla de login/registro existente; sin layout wrapper (pantalla full). |
| **Index (/)** | Index.tsx: uso de useAuth (loading, isApproved, isAdmin), usePendingPlayers (badge). Lógica: si !user → landing; si user && !isApproved && !isAdmin → BlockedScreen; si isAdmin → AdminDashboardContent (useViewMode, usePendingPlayers); si approved → landing con “Ir a Mi Panel”. | `PendingPlayersRepository` (o parte de PlayersRepository) con caché/ invalidación para badge. ViewMode → estado local o `ViewModeProvider`. | Ruta `/`. AuthGate/GoRouter: si no auth → `/auth`; si parent no aprobado → pantalla bloqueo; si admin → contenido admin en `/`; si approved → landing con link a `/dashboard`. | Landing (logo, features, CTA). Admin: panel con cards (KPIs, créditos, usuarios, scouting, reservas, chat, aprobación, compare). Todo dentro de Layout Wrapper cuando hay usuario (admin o padre). |
| **BlockedScreen** | Solo UI + mensaje “pendiente de aprobación”. Sin hooks críticos. | — | Ruta dedicada opcional (ej. `/blocked`) o mismo `/` con redirect desde AuthGate. | Una pantalla simple; puede estar dentro del wrapper o fullscreen. |
| **NotFound** | Solo UI 404. | — | Ruta `*` en GoRouter. | Página 404; sin wrapper o con wrapper mínimo. |

**Implementado (Fase 1 completada):**
- **Auth:** `lib/repositories/auth_repository.dart` con `getAuthUserInfo(userId)` (perfil + rol). `AuthGateRedirect` usa `AuthRepository` para detectar rol.
- **Index (/):** Sin usuario se muestra `LandingScreen` (logo ELITE 380, 3 features, CTA "Comenzar Ahora" → `/auth`). Admin redirige a `/admin` y ve `AdminDashboardScreen`.
- **Landing:** `lib/screens/landing_screen.dart` (paridad con React Index landing).
- **Admin dashboard:** `lib/screens/admin_dashboard_screen.dart` con grid de cards (Usuarios, Scouting, Jugadores, Reservas, Chat, Aprobación con badge, Créditos, Comparar); consume `PendingPlayersRepository` para el badge.
- **PendingPlayersRepository:** `lib/repositories/pending_players_repository.dart` (jugadores `approval_status = 'pending'`), caché 60s y realtime; proporcionado en `main.dart`.
- **BlockedScreen:** Ya cubierto por `WaitingApprovalScreen` en `/waiting-approval`.
- **NotFound:** Ya cubierto por `NotFoundScreen` en ruta `*`.

---

### Fase 2 — Dashboard (padre), Profile, Settings, Notifications

| Pantalla | A) Logic Extraction | B) Repos + caché | C) GoRouter | D) UI con layout wrapper |
|----------|---------------------|-------------------|-------------|---------------------------|
| **Dashboard (padre)** | Dashboard.tsx: Layout, posiblemente datos de resumen (reservas próximas, jugadores). Revisar si hay useReservations u otros hooks. | Si hay datos: `ReservationsRepository` (mis próximas), `MyPlayersRepository` (resumen). Caché corto (ej. 1 min). | Ruta `/dashboard`. | Contenido tipo “Mi Panel”: resumen reservas, jugadores, acceso rápido. Envuelto en Layout Wrapper (Sidebar/BottomNav). |
| **Profile** | Profile.tsx: useAuth, actualización de perfil (nombre, avatar). | `AuthRepository` o `ProfileRepository`: updateProfile. Caché: invalidar perfil actual tras update. | Ruta `/profile`. | Pantalla de perfil existente; dentro del Layout Wrapper. |
| **Settings** | Settings.tsx: useAuth, cambio contraseña, cerrar sesión, posiblemente preferencias. | AuthRepository signOut; cambio contraseña vía Supabase auth. | Ruta `/settings`. | Pantalla de ajustes; dentro del Layout Wrapper. |
| **Notifications** | useNotifications (realtime), useNotificationsCenter. Listado, marcar leído, sonido. | `NotificationsRepository`: fetch, markRead, suscripción realtime. Opcional: TTL corto para lista. | Ruta `/notifications`. | Lista de notificaciones; dentro del Layout Wrapper. |

**Implementado (Fase 2 completada):**
- **Dashboard (padre):** Sigue siendo `HomeScreen` en `/dashboard` con `ScreenLayoutWrapper` (sin nuevos repos en esta fase).
- **Profile:** `lib/repositories/profile_repository.dart` (getProfile, updateProfile). `ProfileScreen` reescrita: formulario nombre/teléfono, guardado vía repo y actualización de `AppAuthState.userName`. Ruta `/profile` muestra la pantalla real.
- **Settings:** Cierre de sesión con `Provider<AppAuthState>.clear()` y `context.go('/')`. Navegación a perfil con `context.go('/profile')`. Ruta `/settings` muestra la pantalla real. Corregidos textos de diálogo (sesión).
- **Notifications:** `lib/repositories/notifications_repository.dart` (fetch desde `notices` por team_id y target_roles, caché 60s, realtime). `NotificationsScreen` refactorizada para consumir el repo (Provider), subscribeRealtime en initState y detalle con `NoticeDetailScreen`. Ruta `/notifications` muestra la pantalla real.
- `main.dart`: Provider de `NotificationsRepository` añadido.

---

### Fase 3 — Players, Reservations, MyCredits, Chat

| Pantalla | A) Logic Extraction | B) Repos + caché | C) GoRouter | D) UI con layout wrapper |
|----------|---------------------|-------------------|-------------|---------------------------|
| **Players** | useMyPlayers (padre), posiblemente usePlayers. Listado “mis jugadores”, alta/edición. | `MyPlayersRepository` (parent_child + players). Caché lista (ej. 2 min), invalidar tras crear/editar. | Ruta `/players`. | Lista de jugadores del padre; formularios alta/edición; dentro del Layout Wrapper. |
| **Reservations** | useReservations: fetch, create, cancel, realtime. AvailabilityPicker, calendario. | `ReservationsRepository`: getMyReservations, create, cancel; realtime por user_id. Caché 30s–1 min. | Ruta `/reservations`. | Calendario/reservas padre; dentro del Layout Wrapper. |
| **MyCredits** | useCredits (balance, historial). CreditBalanceCard, CreditHistoryList. | `CreditsRepository`: balance, historial; realtime user_credits. Ya existe widget créditos en Flutter; conectar a repo. | Ruta `/my-credits`. | Balance + historial de créditos; dentro del Layout Wrapper. |
| **Chat** | useConversations, useUnreadCounts; mensajes, adjuntos, realtime. | `ConversationsRepository`: lista conversaciones, mensajes por conversación, unread counts; realtime. | Ruta `/chat`. Lista conversaciones; ruta `/chat/:id` para hilo. | Lista de chats y pantalla de conversación; dentro del Layout Wrapper. Badge unread en Sidebar/BottomNav. |

**Implementado (Fase 3 completada):**
- **Players:** `lib/repositories/my_players_repository.dart` (fetch por parent_id, create/update/delete, caché 2 min, realtime). `MyPlayersScreen`: lista, FAB añadir jugador, menú eliminar; rutas `/players` con wrapper.
- **Reservations:** `lib/repositories/reservations_repository.dart` (tabla reservations: getMyReservations, create, cancel, caché 45s, realtime). `ReservationsListScreen`: lista de reservas, cancelar pendientes, FAB a FieldScheduleScreen para solicitar; ruta `/reservations`.
- **MyCredits:** `CreditsRepository` ampliado con `getTransactionHistory()` y `CreditTransactionItem`. `MyCreditsScreen`: saldo (repo) + historial de transacciones; ruta `/my-credits`. Providers de CreditsRepository, MyPlayersRepository, ReservationsRepository, ConversationsRepository en `main.dart`.
- **Chat:** `lib/repositories/conversations_repository.dart` (conversaciones, unread, participant name, last message; realtime). `ChatListScreen`: lista conversaciones, badge unread, tap a TeamChatScreen; ruta `/chat` con wrapper. ConversacionesRepository proporcionado en main.

---

### Fase 4 — Admin (Users, Reservations, Chat, Notifications, Settings, PlayerApproval, Players, ComparePlayers)

| Pantalla | A) Logic Extraction | B) Repos + caché | C) GoRouter | D) UI con layout wrapper |
|----------|---------------------|-------------------|-------------|---------------------------|
| **Admin Users** | useUsers: fetchUsers, approveUser, rechazar, pestaña créditos (UserManagement, CreditWalletManager, etc.). | `UsersRepository`: list profiles + roles + credits; approve; créditos por usuario. Caché 1–2 min, invalidar tras approve. | Ruta `/admin/users`. Query `?tab=credits` opcional. | Lista usuarios, aprobación, gestión créditos; Sidebar admin. |
| **Admin Reservations** | useReservations (admin: todas o filtros), ReservationManagement, WeeklyScheduleView, ReservationCalendarView. | `ReservationsRepository`: getAll o filtros para admin; aprobar/rechazar. Realtime para tabla reservations. | Ruta `/admin/reservations`. | Calendario/vista semanal y gestión; Sidebar admin. |
| **Admin Chat** | Mismo useConversations (isAdmin), ChatConsole. | Mismo `ConversationsRepository` con vista admin. | Ruta `/admin/chat`. | Consola de chats; Sidebar admin. |
| **Admin Notifications** | useNotifications (admin: enviar o listar todas). | `NotificationsRepository`: list all, create (si aplica). | Ruta `/admin/notifications`. | Lista/gestión notificaciones admin; Sidebar admin. |
| **Admin Settings** | AdminSettings.tsx: useSystemConfig, configuración global. | `SystemConfigRepository`: get/update. | Ruta `/admin/settings`. | Pantalla configuración sistema; Sidebar admin. |
| **Admin Player Approval** | usePendingPlayers, PendingPlayersPanel, aprobar/rechazar jugadores. | `PendingPlayersRepository` o `PlayersRepository`: list pending, approve, reject. Invalidar tras acción. | Ruta `/admin/player-approval`. | Lista pendientes + acciones; Sidebar admin. |
| **Admin Players** | usePlayers / PlayerDirectory, filtros, edición. | `PlayersRepository` (admin): list all, filters. Caché + invalidación. | Ruta `/admin/players`. | Directorio jugadores; Sidebar admin. |
| **Compare Players** | usePlayers o datos de dos jugadores; vista comparativa estilo FIFA. | `PlayersRepository`: getById (x2) o lista para elegir. Caché por id. | Ruta `/admin/compare-players`. | Pantalla comparativa dos jugadores; Sidebar admin. |

**Implementado (Fase 4 completada):**
- **Admin Users:** `lib/repositories/users_repository.dart` (lista perfiles + roles + créditos, updateApproval). `CreditsRepository.setBalanceForUser` para asignar créditos. `AdminUsersScreen`: tabla/lista, aprobar/revocar, diálogo créditos; pestañas Usuarios/Créditos con `?tab=credits`.
- **Admin Reservations:** `ReservationsRepository.fetchAll()` y `updateStatus()`. `AdminReservationsScreen`: lista de reservas, aprobar/rechazar pendientes.
- **Admin Chat:** Misma `ChatListScreen` en `/admin/chat` (ConversationsRepository).
- **Admin Notifications:** `lib/repositories/in_app_notifications_repository.dart` (tabla `notifications`, markAsRead, markAllAsRead, delete, clearAll, realtime). `AdminNotificationsScreen`: tabs Todas, Usuarios, Reservas, Mensajes, Sistema.
- **Admin Settings:** `lib/repositories/system_config_repository.dart` (session_hours, max_capacity, active_days, credit_alert_threshold, cancellation_window). `AdminSettingsScreen`: formularios por sección.
- **Admin Player Approval:** `PendingPlayersRepository` con approve/reject y campos extra. `AdminPlayerApprovalScreen`: lista pendientes, búsqueda, aprobar/rechazar con motivo opcional.
- **Admin Players:** `lib/repositories/players_repository.dart` (listado con padre). `AdminPlayersScreen`: directorio con búsqueda y filtros categoría/posición.
- **Compare Players:** `ComparePlayersScreen`: dos selectores y dos cards (estilo FIFA); usa `PlayersRepository`.
- Rutas `/admin/*` en `app_router.dart` con pantallas reales. Providers en `main.dart`: UsersRepository, InAppNotificationsRepository, SystemConfigRepository, PlayersRepository.

---

### Fase 5 — Scouting

| Pantalla | A) Logic Extraction | B) Repos + caché | C) GoRouter | D) UI con layout wrapper |
|----------|---------------------|-------------------|-------------|---------------------------|
| **Scouting** | usePlayers (todos), ScoutingFilters, PlayerGrid, PlayerDetailModal. Stats, radar, evolución. | `PlayersRepository` (scouting): list all con filtros; getById para detalle. Caché lista 1–2 min. | Ruta `/scouting`. Opcional `/scouting/:id` para detalle. | Grid de jugadores con filtros y modal detalle; mismo Layout Wrapper (admin/padre según rol). |

---

## 5. Orden de implementación recomendado (por dependencias)

1. **Fase 0** (GoRouter, Layout Wrapper, Repository base).  
2. **Fase 1** (Auth, Index, Blocked, NotFound) para tener rutas y flujo de entrada.  
3. **Fase 2** (Dashboard, Profile, Settings, Notifications) para estabilizar shell y datos básicos.  
4. **Fase 3** (Players, Reservations, MyCredits, Chat) para paridad con flujos padre.  
5. **Fase 4** (todas las pantallas admin) para paridad admin.  
6. **Fase 5** (Scouting) para cerrar paridad funcional.

---

## 6. Checklist por pantalla (recordatorio)

- [ ] **A** Lógica extraída de React a repos + ChangeNotifier; listado de useEffects y realtime documentado.  
- [ ] **B** Repos con caché (clave + TTL/invalidación) donde aplique.  
- [ ] **C** Ruta en GoRouter con URL correcta; redirects y permisos por rol.  
- [ ] **D** UI implementada dentro del Screen Layout Wrapper; consume solo repos/providers.  
- [ ] **E** No eliminar código en `src/` hasta aceptación de la versión Flutter.

---

## 7. Referencias rápidas

- **Rutas React:** `src/App.tsx`.  
- **Layout React:** `src/components/layout/Layout.tsx`, `Navbar.tsx`, `BottomNav.tsx`.  
- **Auth React:** `src/contexts/AuthContext.tsx`.  
- **Flutter entrada:** `lib/main.dart`, `lib/auth/auth_gate.dart`, `lib/screens/dashboard_screen.dart`.  
- **Reglas UI bloqueadas:** `.cursorrules` y `DESIGN_BLUEPRINT_MASTER.md` (no modificar diseño sin “MODO REDISEÑO”).

Documento vivo: actualizar este plan al completar cada fase o al cambiar rutas/repos.
