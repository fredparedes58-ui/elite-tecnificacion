# Inventario detallado — Elite 380 L

Solo sobre la app **Elite 380 L** (React + Vite + Supabase + Capacitor).  
Academia de fútbol: reservas de sesiones, créditos, jugadores, scouting, chat y panel admin.

---

# PARTE 1 — TODO LO QUE TENEMOS EN ELITE 380 L

## 1. Tecnologías

### Frontend
- **React 18** + **TypeScript**
- **Vite** (build)
- **React Router DOM** (rutas)
- **TanStack React Query** (cache y datos)
- **Tailwind CSS** + **tailwindcss-animate**
- **Radix UI** (tabs, dialog, select, etc.) + **shadcn-style** (components/ui)
- **Recharts** (gráficos en reportes)
- **date-fns** (fechas)
- **lucide-react** (iconos)
- **framer-motion** (animaciones)
- **React Hook Form** + **Zod** (formularios y validación)
- **xlsx** (export Excel en reportes)
- **tus-js-client** (subida de vídeo resumible a Bunny)
- **Capacitor** (iOS y Android)

### Backend y servicios
- **Supabase**: Auth, PostgreSQL, Realtime, Storage, Edge Functions
- **Resend** (emails desde Edge Function `notify-session-events`)
- **R2** (fotos): presigned URL vía Edge Function `generate-r2-presigned-url`
- **Bunny Stream** (vídeo): TUS upload con credenciales desde backend
- Variables: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, etc.

---

## 2. Rutas (App.tsx)

| Ruta | Página | Quién |
|------|--------|--------|
| `/` | Index | Todos (landing o panel admin según rol) |
| `/auth` | Auth | Login/registro |
| `/scouting` | Scouting | Usuarios aprobados + admin |
| `/dashboard` | Dashboard | Padres (no admin) |
| `/players` | Players | Padres |
| `/reservations` | Reservations | Padres |
| `/chat` | Chat | Padres |
| `/my-credits` | MyCredits | Padres |
| `/profile` | Profile | Usuario logueado |
| `/notifications` | Notifications | Usuario logueado |
| `/settings` | Settings | Usuario logueado |
| `/admin` | Index (panel admin) | Admin |
| `/admin/users` | AdminUsers | Admin |
| `/admin/reservations` | AdminReservations | Admin |
| `/admin/chat` | AdminChat | Admin |
| `/admin/notifications` | AdminNotifications | Admin |
| `/admin/settings` | AdminSettings | Admin |
| `/admin/player-approval` | AdminPlayerApproval | Admin |
| `/admin/players` | AdminPlayers | Admin |
| `/admin/compare-players` | ComparePlayers | Admin |
| `*` | NotFound | Cualquiera |

---

## 3. Autenticación y roles

| Qué tenemos | Dónde |
|-------------|--------|
| Login y registro | AuthContext: signIn, signUp con Supabase Auth |
| Cerrar sesión | signOut en AuthContext |
| Perfil desde BD | profiles (id, email, full_name, avatar_url, phone, is_approved) |
| Rol admin | user_roles.role === 'admin' |
| Usuario aprobado | profile.is_approved |
| Bloqueo si no aprobado | BlockedScreen cuando user && !isApproved && !isAdmin |
| Redirect admin a panel | Index: si isAdmin → AdminDashboardContent |

---

## 4. Pantallas y funcionalidades

### 4.1 Index (Landing / Panel Admin)
- **Invitados o no aprobados:** Landing "ELITE 380", CTA "Comenzar Ahora" → /auth o "Ir a Mi Panel" → /dashboard.
- **Admin:** Panel con ViewModeToggle (vista admin vs simulación padre), botones KPIs y Reportes Créditos, PerformanceSummaryCard, Comparativa (ComparePlayers), grid de tarjetas: Usuarios, Scouting, Jugadores, Reservas, Chats, Aprobación (con badge pendientes), Créditos.

### 4.2 Auth
- Login y registro (Supabase Auth); flujo completo.

### 4.3 Dashboard (padres)
- Créditos (useCredits), mis jugadores (useMyPlayers), mis reservas (useReservations).
- MyPlayerCard por jugador, alta/edición/borrado de jugadores (EditPlayerModal, DeletePlayerModal), PlayerOnboardingWizard.
- ReservationForm para solicitar sesión, listado de reservas con estado y negociación (ReservationNegotiationCard), CancelReservationModal.
- Subida de foto de jugador (uploadPlayerPhoto → R2 vía useUpload / mediaStorageService).

### 4.4 Reservations (padres)
- Listado de reservas propias, créditos, NewReservationWithCalendar, ReservationNegotiationCard, CancelReservationModal.
- Crear reserva con calendario, jugador, entrenador, créditos; cancelar reserva.

### 4.5 Admin Reservations
- **Tabs:** Semanal (WeeklyScheduleView), Cal. (ReservationCalendarView), Lista (ReservationManagement), Créd. (PlayerCreditsView), Entren. (TrainerManagement), Reportes (AttendanceReports).
- **Datos:** useAllReservations (con Realtime), useTrainers, usePlayers.
- **Vista semanal:** Bloques por franja, reservas arrastrables; doble clic abre detalle; reservas sin entrenador muestran "Sin entrenador" y se puede asignar en el modal.
- **Lista:** Tabla con Padre, Jugador, Título (editable in situ), Fecha/Hora, Mensaje, Estado, Acciones (Check aprobar, Proponer, Rechazar). Origen: tabla reservations + joins profiles y players. Al hacer Check: updateReservationStatus(id, 'approved', true) y envío de email.
- **Reportes:** Por mes, gráficos por estado (completadas, pendientes, no_show, etc.), export Excel. **No** incluye ya la sección "Asistencia por Jugador" (quitada).
- **Créditos:** PlayerCreditsView (cartera por jugador/padre).
- **Entrenadores:** TrainerManagement.

### 4.6 Admin Jugadores
- Página AdminPlayers con Layout y PlayerDirectory (directorio de jugadores aprobados, gestión).

### 4.7 Scouting
- Filtros por categoría, nivel, búsqueda (ScoutingFilters).
- PlayerGrid, PlayerDetailModal (detalle jugador, stats, radar; actualización de stats y player_stats_history).
- usePlayers con approval_status approved; categorías/niveles desde tipos Supabase.

### 4.8 Comparativa (ComparePlayers)
- Comparar dos jugadores estilo FIFA (ElitePlayerCard, radar, etc.).

### 4.9 Créditos y cartera
- useCredits, useCreditTransactions, useCreditPackages.
- Admin: CreditWalletManager, CreditTransactionHistory, PlayerCreditsView; cash_payments, credit_transactions.

### 4.10 Chat
- Chat para padres (Chat.tsx), conversaciones; AdminChat (ChatConsole).
- conversation_state (unread_count, last_read_at), conversations.

### 4.11 Notificaciones
- useNotificationsCenter, tabla notifications; NotificationBell, NotificationItem.
- Admin: AdminNotifications.

### 4.12 Aprobación de jugadores
- AdminPlayerApproval, usePendingPlayers (players con approval_status pendiente + profiles).
- Aprobar/rechazar jugadores.

### 4.13 Perfil y ajustes
- Profile: edición de perfil (profiles).
- Settings: preferencias (lectura/escritura en profiles).
- Admin: AdminSettings.

### 4.14 Sesiones completadas y notificaciones
- CompleteSessionModal: marcar sesión completada, comentario técnico, actualización reservations y player_stats_history; llamada a Edge Function notify-session-events (training_completed).
- notify-session-events: reservation_requested, reservation_accepted, reservation_moved, credits_low, training_completed; envía email vía Resend.

### 4.15 Media (fotos y vídeo)
- mediaStorageService: getR2PresignedUrl (Edge Function generate-r2-presigned-url), uploadToR2; Bunny TUS (credenciales firmadas).
- useUpload: uso en subida de foto de jugador y vídeo (TUS a Bunny).

### 4.16 Scouting y evolución
- usePlayerStatsHistory, usePlayersWeeklyImprovement (RPC get_players_weekly_improvement).
- player_stats_history; migración scouting_evolution.
- AverageRatingLineChart, PlayerEvolutionPanel, PlayerSessionHistoryList, ElitePlayerCard, PerformanceSummaryCard.

### 4.17 Otros
- Layout, Navbar, BottomNav, BackButton.
- Componentes UI: EliteCard, NeonButton, StatusBadge, etc.
- ViewModeContext (vista admin vs padre).
- Páginas: Players, MyCredits, Notifications, Settings, NotFound, BlockedScreen.

---

## 5. Tablas Supabase (según tipos y uso en código)

- profiles, user_roles  
- players (parent_id, approval_status, category, level, stats, etc.), player_stats_history  
- reservations (user_id, player_id, trainer_id, status, start_time, end_time, title, etc.)  
- trainers, trainers_public  
- notifications  
- conversations, conversation_state  
- user_credits, credit_transactions, credit_packages, cash_payments  
- system_config  
- session_changes_history  

---

# PARTE 2 — LO QUE NO TENEMOS EN ELITE 380 L

- **Push notifications** en dispositivo: la Edge Function tiene boilerplate para OneSignal/Firebase pero no está integrado en la app (solo email Resend).
- **Recuperación de contraseña** en la UI (Supabase Auth lo soporta; flujo en pantalla no revisado).
- **Verificación de email** explícita en flujo (depende de configuración Supabase).
- **App instalable / PWA** documentada (Capacitor está; no hay doc de build iOS/Android en el repo).
- **Tests E2E** (solo tests unitarios/vitest básicos).
- **Sección "Asistencia por Jugador"** en reportes de asistencia (se quitó a petición; el cálculo playerStats sigue en Excel si se usa).
- **Múltiples idiomas** (i18n) en la app.
- **Modo offline** o cola de operaciones sin conexión.

---

# PARTE 3 — LO QUE DEBERÍAMOS TENER (RECOMENDACIONES)

- **Push:** Conectar cliente (OneSignal/Firebase) con la Edge Function para notificaciones en tiempo real en móvil.
- **Recuperación de contraseña:** Pantalla o enlace "¿Olvidaste tu contraseña?" que use Supabase Auth.
- **Documentación de build:** README con pasos para `npm run build`, Capacitor sync y abrir en Xcode/Android Studio para Elite 380 L.
- **Revisión RLS:** Asegurar políticas por rol (padres solo sus jugadores y reservas, admin todo).
- **Manejo de errores:** Toasts o mensajes claros cuando falle presigned R2, TUS Bunny o notify-session-events.
- **Tests:** Aumentar cobertura en hooks críticos (useReservations, useCredits, useMyPlayers) y flujos principales.

---

# Resumen en una tabla (Elite 380 L)

| Área | Tenemos | No tenemos | Deberíamos tener |
|------|---------|------------|------------------|
| Auth | Login, registro, logout, perfil, is_approved, admin por user_roles | Recuperación contraseña en UI | Link "Olvidé contraseña" |
| Home | Landing + Panel admin con tarjetas (Usuarios, Scouting, Jugadores, Reservas, Chat, Aprobación, Créditos) | - | - |
| Reservas admin | Semanal, Calendario, Lista (título editable, Check aprobar), Créditos, Entrenadores, Reportes (sin asistencia por jugador) | - | - |
| Reservas padre | Crear, listar, negociar, cancelar; Realtime | - | - |
| Jugadores | Directorio admin, scouting, comparativa, aprobación, stats e evolución | - | - |
| Créditos | Cartera, transacciones, paquetes, cash; descuento al aprobar reserva | - | - |
| Chat | Conversaciones, estado no leído, consola admin | - | - |
| Notificaciones | Tabla, centro, campana | Push en dispositivo | Integrar push con notify-session-events |
| Media | R2 presigned (fotos), Bunny TUS (vídeo) | - | Errores claros en UI |
| Notificaciones email | Resend vía notify-session-events | - | - |

Este documento refleja **solo** el estado de la app **Elite 380 L** (React + Vite + Supabase + Capacitor).
