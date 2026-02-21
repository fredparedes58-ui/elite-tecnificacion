# Análisis completo: Backend, Frontend y UI/UX — Elite 380 L

**Fecha:** Febrero 2025  
**Alcance:** Todo lo desarrollado e implementado en la app (backend Supabase, Flutter, React Web, UI/UX).

---

## 1. BACKEND (Supabase + Edge Functions)

### 1.1 Base de datos (PostgreSQL)

#### Tablas principales

| Tabla | Propósito |
|-------|-----------|
| **profiles** | Usuarios: id (auth.users), email, full_name, avatar_url, phone, **is_approved**, image_rights_terms_accepted_at |
| **user_roles** | Roles por usuario: admin, parent, player (enum app_role) |
| **user_credits** | Saldo de créditos por usuario (padre). Realtime habilitado |
| **players** | Hijos de padres: name, category (U8–U18), level, photo_url, stats (JSONB), birth_date, position |
| **reservations** | Reservas de sesiones: user_id, player_id, start/end_time, status (pending/approved/rejected), credit_cost |
| **conversations** | Chat: participant_id, subject |
| **messages** | Mensajes de chat: conversation_id, sender_id, content, is_read |
| **notifications** | Notificaciones in-app por usuario |
| **credit_packages** | Paquetes de créditos a la venta |
| **credit_transactions** | Historial de transacciones de créditos |
| **cash_payments** | Pagos en efectivo |
| **trainers** | Entrenadores |
| **system_config** | Configuración global del sistema |
| **session_changes_history** | Historial de cambios de estado de sesiones |
| **teams** | Equipos (category, club_id, etc.) |
| **team_members** | Miembros de equipo (user_id, team_id, role, match_status) |
| **enrollments** | Inscripciones (Elite Performance) |
| **stats** | Estadísticas (tabla elite_stats) |
| **player_stats_history** | Historial de estadísticas por jugador |
| **conversation_state** | Estado de conversaciones (chat) |
| **admin_coach_emails** | Emails de admins/coaches para notificaciones y aprobación |
| **device_tokens** | Tokens para push notifications |
| **school_calendar_events** | Calendario escolar: eventos, cierres, entrenamientos especiales |

#### Enums

- **app_role:** admin, parent, player  
- **player_category:** U8, U10, U12, U14, U16, U18  
- **player_level:** beginner, intermediate, advanced, elite  
- **reservation_status:** pending, approved, rejected  

#### Seguridad (RLS)

- **Row Level Security (RLS)** habilitado en todas las tablas relevantes.
- **Funciones helper:** `is_admin()`, `is_approved()` (y variante `is_admin(uuid)`) para políticas.
- Políticas por tabla: usuarios ven solo sus datos; admins ven/gestionan según rol; calendario escolar solo lectura para autenticados, escritura solo admins.

#### Realtime

- **user_credits** en publicación `supabase_realtime` para widget de saldo en tiempo real.

#### Triggers y lógica en DB

- **Admin-gated onboarding:** al registrarse un padre (`is_approved = false`) → notificación in-app a admins + llamada a Edge Function `notify_admin_pending_approval`. Al aprobar → envío de bienvenida al padre.
- Triggers de notificaciones (pendientes de aprobación, bienvenida, etc.).
- Migraciones de revisión de políticas RLS (`review_rls_policies`).

---

### 1.2 Edge Functions (Deno)

| Función | Propósito |
|---------|-----------|
| **notify_admin_pending_approval** | Email a admins (Resend) cuando un padre se registra y está pendiente de aprobación |
| **notify_on_registration** | Notificación/email en registro (complementa onboarding) |
| **send-notification-email** | Envío de emails de notificación |
| **send-credit-alert-email** | Alerta por créditos bajos |
| **send-credit-receipt** | Recibo tras compra de créditos |
| **low_credits_alert** | Lógica de alerta de créditos bajos |
| **daily-credit-alerts** | Alertas diarias de créditos |
| **send-reservation-email** | Email relacionado con reservas |
| **get-availability** | Obtener disponibilidad (reservas/sesiones) |
| **create-bunny-upload** | Crear sesión de subida a Bunny (vídeo) |
| **generate-r2-presigned-url** | URLs pre-firmadas para subida a Cloudflare R2 (fotos) |
| **generate_match_report_gemini** | Genera informes de partido (coach + familia) vía Google Gemini API |
| **daily_report_generator** | Generación de reportes diarios |
| **notify-session-events** | Notificaciones por eventos de sesión |
| **session_management** | Gestión de sesiones |
| **generate-demo-data** | Generación de datos de prueba |

Integraciones externas usadas en backend: **Resend** (email), **Google Gemini** (informes), **Cloudflare R2** (almacenamiento imágenes), **Bunny** (streaming vídeo).

---

### 1.3 Configuración y secretos

- **Supabase:** URL y anon key en app vía `.env` (AppConfig).
- Variables de Edge Functions: `RESEND_API_KEY`, `GEMINI_API_KEY`, etc., en Supabase Dashboard.

---

## 2. FRONTEND

### 2.1 Flutter (app móvil y Flutter web)

#### Auth y acceso

- **AuthGate:** Detecta sesión y rol desde Supabase (profiles, user_roles). Redirige a: no logueado → AuthScreen; no aprobado → WaitingApprovalScreen; padre → DashboardScreen; coach/admin → HomeScreen.
- **AuthScreen:** Login/registro con Supabase Auth.
- **ResetPasswordScreen:** Recuperación de contraseña (deep link).
- **WaitingApprovalScreen:** Pantalla para padres pendientes de aprobación.
- **PendingApprovalsScreen:** Lista de cuentas pendientes (admin).

#### Navegación principal (coach/admin)

- **HomeScreen:** Hub principal con tarjetas a: plantilla, tablero táctico, planificador de sesiones, categorías de entrenamiento, partidos, drills, chat del equipo, galería, ajustes, metodología, campos, goleadores, upload test, feed social, asistencia, asistencia padres, tablón de anuncios, añadir miembro, calendario escolar, créditos. Incluye **CreditsRealtimeWidget** (saldo en tiempo real).
- **DashboardScreen:** Dashboard para padres (mis jugadores, resumen).

#### Equipo y plantilla

- **SquadScreen**, **SquadManagementScreen**, **AddTeamMemberScreen**, **DelegateScreen.**  
- **AlignmentEditorScreen**, **TacticalBoardScreen** (tablero táctico con **TacticBoardProvider**).  
- **PlayerCardScreen**, **PlayerProfileScreen**, **TopScorersScreen.**

#### Sesiones y entrenamiento

- **SessionPlannerScreen**, **SessionDetailsScreen**, **TrainingCategoriesScreen**, **DrillsScreen**, **DrillDetailsScreen**, **DrillSelectionScreen.**  
- **MethodologyScreen**, **CommandCenterScreen.**

#### Partidos y análisis

- **MatchesScreen**, **LiveMatchScreen** (cronómetro, eventos, sin vídeo en vivo).  
- **MatchReportScreen**, **ProMatchAnalysisScreen** (análisis con vídeo/Gemini).  
- **AttendanceScreen**, **ParentAttendanceScreen.**

#### Comunicación y contenido

- **TeamChatScreen**, **SelectChatRecipientScreen.**  
- **NoticeBoardScreen**, **NoticeDetailScreen**, **CreateNoticeScreen.**  
- **SocialFeedScreen**, **CreatePostScreen**, **CommunityHubScreen.**  
- **GalleryScreen**, **VictoryShareScreen.**

#### Campos y reservas

- **FieldScheduleScreen**, **BookingRequestScreen.**

#### Créditos y calendario

- **CreditReportScreen**, **SchoolCalendarScreen.**

#### Admin y configuración

- **AdminCoachEmailsScreen** (gestión de emails admin/coach).  
- **SettingsScreen**, **ProfileScreen**, **NotificationsScreen.**  
- **TestUploadScreen** (pruebas de subida media).

#### Servicios (lib/services/)

| Servicio | Responsabilidad |
|----------|-----------------|
| **SupabaseService** | Cliente Supabase; equipos, team_members, jugadores, chat, noticias, posts, alineaciones, partidos, stats, etc. |
| **DataService** | Datos de ligas, partidos, plantillas (FFCV, datos estáticos/mock). |
| **SessionService** | Sesiones de entrenamiento. |
| **FieldService** | Campos y reservas. |
| **SocialService** | Feed social, posts. |
| **StatsService** | Estadísticas y goleadores. |
| **MediaUploadService** | Subida a R2/Bunny (fotos/vídeo). |
| **FileManagementService** | Gestión de archivos y tipos. |
| **VoiceTaggingService** | Etiquetado por voz en análisis. |

#### Modelos (lib/models/)

Incluyen, entre otros: alignment, booking, booking_request, chat_channel, chat_message, drill, field, formation, league, match_stats, notice_board_post, notice_read_receipt, player, player_analysis_video, player_stats, social_post, tactical_session, team, training_session, etc.

#### Configuración

- **AppConfig:** SUPABASE_URL, SUPABASE_ANON_KEY, N8N_WEBHOOK_URL desde `.env`.  
- **MediaConfig:** R2 (endpoint, keys, bucket, public URL), Bunny (API key, library, CDN, stream endpoint) desde `.env`.

#### Estado

- **Provider:** TacticBoardProvider (ChangeNotifier) para tablero táctico.  
- Resto principalmente StatefulWidget + llamadas directas a servicios.

---

### 2.2 React Web (Vite + TypeScript)

#### Rutas (react-router-dom)

- **Públicas / usuario:** `/`, `/auth`, `/scouting`, `/dashboard`, `/players`, `/reservations`, `/chat`, `/my-credits`, `/profile`, `/notifications`, `/settings`.  
- **Admin:** `/admin`, `/admin/users`, `/admin/reservations`, `/admin/chat`, `/admin/notifications`, `/admin/settings`, `/admin/player-approval`, `/admin/players`, `/admin/compare-players`.  
- **Otros:** `/blocked`, `*` (NotFound).

#### Páginas (src/pages/)

- Index, Auth, Dashboard, Players, Reservations, Chat, MyCredits, Profile, Notifications, Settings, Scouting, ComparePlayers, BlockedScreen, NotFound.  
- Admin: AdminUsers, AdminReservations, AdminChat, AdminNotifications, AdminSettings, AdminPlayerApproval, AdminPlayers.

#### Componentes por dominio

- **Layout:** Layout, Navbar, BottomNav, BackButton, NavLink.  
- **UI (shadcn-style):** button, card, dialog, form, input, tabs, dropdown, sheet, calendar, table, etc. (muchos en `src/components/ui/`).  
- **Dashboard:** MyPlayerCard, PlayerForm, ReservationForm, PhotoUpload.  
- **Admin:** UserManagement, ReservationManagement, ReservationCalendarView, WeeklyScheduleView, ChatConsole, PendingPlayersPanel, PlayerDirectory, AdminKPIDashboard, CreditPackagesManager, CreditWalletManager, CreditTransactionHistory, CreditsReportDashboard, TrainerManagement, AttendanceReports, AdminSettings, ViewModeToggle, etc.  
- **Players:** PlayerCard, ElitePlayerCard, EditPlayerModal, DeletePlayerModal, PlayerProgressChart, PlayerSessionHistoryList, PlayerEvolutionPanel, RadarChart, SimpleRadarChart.  
- **Credits:** CreditBalanceCard, CreditHistoryList.  
- **Reservations:** AvailabilityPicker, NewReservationWithCalendar, CancelReservationModal, ReservationNegotiationCard.  
- **Chat:** ParentChat, MessageAttachments, AttachmentPreviewBar.  
- **Notifications:** NotificationBell, NotificationItem.  
- **Scouting:** PlayerGrid, ScoutingFilters, PlayerDetailModal.  
- **Onboarding:** PlayerOnboardingWizard.  
- **Calendar:** CapacityCalendar.

#### Estado y datos (React)

- **Contextos:** AuthContext, ViewModeContext.  
- **Hooks:** useCredits, useReservations, usePlayers, useNotifications, useConversations, useMessages, useCreditPackages, useCreditTransactions, useTrainers, useUsers, useUnreadCounts, useAdminKPIs, usePlayerStatsHistory, usePlayerSessionHistory, useReservations, useCapacityColors, useSystemConfig, use-mobile, use-toast, etc.  
- **Integraciones:** `src/integrations/supabase/client.ts` (cliente Supabase tipado).  
- **Servicios:** mediaStorageService (R2/Bunny presigned, TUS), pushNotificationService.

#### Build

- **Vite** con `@vitejs/plugin-react-swc`, alias `@/` → `src/`, puerto 8080.  
- **package.json** en raíz solo declara Capacitor; las dependencias de React/Vite están en uso en código pero pueden faltar en ese package.json (restaurar react, react-dom, react-router-dom, @tanstack/react-query, etc. para `npm run dev`).

---

## 3. UI/UX

### 3.1 Flutter (Material 3)

#### Tema (lib/theme/theme.dart)

- **Modo oscuro por defecto** (ThemeMode.dark en main.dart).  
- **Paleta:**  
  - Oscuro: fondo #0A0A0A, surface #1A1A1A, texto primario blanco, secundario gris; acentos amarillo neón (#FFD700), verde (#00FF00), azul (#00FFFF).  
  - Claro: fondo #F5F5F5, surface blanco, acento azul #0052D4.  
- **Material 3:** useMaterial3: true.  
- **Componentes:** AppBar sin elevación en oscuro; botones elevados con bordes redondeados (30); cards con borde accent y borderRadius 16; BottomNav sin etiquetas; inputs con relleno y bordes redondeados.  
- **ThemeProvider** para alternar tema claro/oscuro.

#### Componentes reutilizables (UX)

- **EmptyStateWidget:** Estados vacíos con icono, título, subtítulo y botón de acción; animación de entrada.  
- **LoadingWidget:** Spinner y mensaje opcional.  
- **ErrorStateWidget:** Mensaje de error y botón “Reintentar”.  
- **SnackBarHelper:** SnackBars por tipo (éxito, error, advertencia, info) con iconos y colores semánticos.  
- **AppBarBack,** **PlayerAvatar,** **ElitePlayerCard,** **UpcomingMatchCard,** **LiveStandingsCard,** **SquadStatusCard,** **CreditsRealtimeWidget,** etc.

#### Patrones

- Navegación por pantallas completas (Navigator.push) desde HomeScreen; sin GoRouter todavía (las URLs en Flutter web no están unificadas con la web React).  
- Listas y grids en muchas pantallas; uso de tarjetas y listas para partidos, plantilla, noticias, feed social.

---

### 3.2 React Web (Cyber-Electric / Neon)

#### Design system (src/index.css)

- **Fuentes:** Orbitron, Rajdhani (Google Fonts).  
- **Tema oscuro:** fondo ~6%, card ~8%; primario cyan neón (185 100% 50%), secundario purple (285 100% 50%), accent pink (320 100% 60%); bordes y ring en tonos cyan.  
- **Variables CSS:** --background, --foreground, --card, --primary, --secondary, --accent, --muted, --border, --radius (0.75rem), sombras neón (shadow-neon-cyan, shadow-neon-purple).  
- **Sidebar:** fondo ~5%, primary cyan, accent purple, bordes definidos.  
- **Gradientes:** gradient-cyber, gradient-neon, gradient-card.

#### Componentes UI

- Base tipo **shadcn/ui** (Button, Card, Dialog, Form, Input, Tabs, Select, Sheet, Calendar, Table, Avatar, etc.).  
- **NeonButton,** **EliteCard,** **StatusBadge** como componentes de marca.  
- **Layout:** Navbar, BottomNav, Layout con sidebar para admin; uso de useIsMobile para adaptar.

#### Patrones UX

- Rutas con URLs legibles (/admin/users, etc.).  
- TanStack Query para caché y estado de servidor.  
- Formularios con validación; modales para crear/editar (jugadores, reservas, etc.).  
- Tablas y calendarios en admin (reservas, disponibilidad, reportes).  
- Toasts (sonner) y alertas para feedback.

---

## 4. Resumen por capa

| Capa | Implementado |
|------|--------------|
| **Backend DB** | ~20+ tablas, RLS, enums, triggers, Realtime en user_credits, políticas admin/parent/player. |
| **Backend Edge** | 16 Edge Functions: auth/onboarding, emails (Resend), créditos, reservas, media (R2/Bunny), Gemini reportes, notificaciones, sesiones, demo. |
| **Flutter** | ~45+ pantallas, 8+ servicios, ~25 modelos, tema Material 3 claro/oscuro, widgets de UX (empty/loading/error), integración Supabase + R2 + Bunny. |
| **React Web** | ~20 rutas, ~130+ componentes (UI + dominio), hooks y contextos, Supabase + R2/Bunny, design system neon/cyber, admin completo. |
| **UI/UX Flutter** | Tema neón/futurista oscuro por defecto, componentes reutilizables y SnackBarHelper documentados en MEJORAS_UX_IMPLEMENTADAS.md. |
| **UI/UX React** | Design system “Elite 380” cyber-electric con Tailwind, variables CSS, fuentes Orbitron/Rajdhani, sidebar admin. |

---

## 5. Garantías de la migración (React → Flutter)

Al ejecutar la **Opción A** (unificar todo en Flutter) siguiendo el prompt de migración con Logic Extraction, Repository Pattern, GoRouter y Layout Wrapper, se aplican las siguientes garantías.

### 5.1 Qué no se pierde

| Área | Garantía |
|------|----------|
| **Backend** | La migración es solo de frontend. Base de datos, RLS, triggers, Realtime y las 16 Edge Functions **no se tocan**. Todo lo descrito en la sección 1 sigue igual. |
| **App Flutter actual** | La app Flutter existente es la base del proyecto unificado. Pantallas, servicios, modelos y tema actuales **se mantienen** y se amplían, no se reemplazan. |
| **Funcionalidad React** | Cada pantalla y flujo que hoy solo existe en React se **reimplementa** en Flutter (inventario + plan + Logic Extraction). No se pierde si se sigue el plan. |
| **Lógica “oculta”** | El paso de **Logic Extraction** asegura que useEffect, suscripciones Supabase y hooks se conviertan en métodos de ChangeNotifier/Provider antes de escribir la UI. |
| **Caché / estado servidor** | El **Repository Pattern** en `lib/services/` con caché tipo React Query evita perder el comportamiento de TanStack Query. |
| **URLs y navegación web** | **GoRouter** con rutas equivalentes a React (/admin/users, etc.) mantiene deep linking y botones atrás/adelante del navegador. |
| **UX web vs móvil** | El **Layout Wrapper** (Sidebar en web/anchura grande, BottomNav en móvil) evita perder la distinción de experiencia. |
| **Código React** | No se borra `src/` hasta que la versión Flutter de cada parte esté probada y aceptada; se puede comparar en cualquier momento. |

### 5.2 Checklist: paridad React ↔ Flutter

Usar esta lista para comprobar que **cada ítem del inventario React tiene pantalla o flujo equivalente en Flutter** antes de dar por cerrada la migración. Marcar con `[ ]` / `[x]` según se vaya completando.

#### Rutas y páginas

- [ ] `/` (Index) → pantalla de entrada / home según rol
- [ ] `/auth` → AuthScreen (login/registro)
- [ ] `/dashboard` → DashboardScreen (padre)
- [ ] `/players` → pantalla(s) de jugadores (mis hijos / listado)
- [ ] `/reservations` → reservas (FieldScheduleScreen / BookingRequestScreen o equivalente)
- [ ] `/chat` → TeamChatScreen / SelectChatRecipientScreen o equivalente para chat padre
- [ ] `/my-credits` → CreditReportScreen o pantalla “Mis créditos”
- [ ] `/profile` → ProfileScreen
- [ ] `/notifications` → NotificationsScreen
- [ ] `/settings` → SettingsScreen
- [ ] `/scouting` → flujo de scouting (jugadores / comparativas)
- [ ] `/admin` → acceso admin (HomeScreen coach o redirección)
- [ ] `/admin/users` → AdminCoachEmailsScreen / gestión de usuarios
- [ ] `/admin/reservations` → gestión de reservas (calendario / aprobaciones)
- [ ] `/admin/chat` → chat admin (TeamChatScreen o equivalente)
- [ ] `/admin/notifications` → notificaciones admin
- [ ] `/admin/settings` → ajustes admin
- [ ] `/admin/player-approval` → PendingApprovalsScreen
- [ ] `/admin/players` → gestión de jugadores (plantilla / directorio)
- [ ] `/admin/compare-players` → comparativa de jugadores
- [ ] `/blocked` → pantalla “bloqueado” (ej. WaitingApprovalScreen o equivalente)
- [ ] Ruta catch-all (NotFound) → pantalla 404 en Flutter

#### Funcionalidad por dominio

- [ ] Auth: login, registro, recuperación de contraseña, espera de aprobación
- [ ] Créditos: saldo en tiempo real, historial, paquetes, compra (si aplica)
- [ ] Reservas: ver, crear, cancelar, aprobar/rechazar (admin), calendario y disponibilidad
- [ ] Jugadores: listado, alta/edición/eliminación, progreso, radar, sesiones, onboarding
- [ ] Chat: conversaciones, mensajes, adjuntos, estado de lectura
- [ ] Notificaciones: listado, marcar leídas, campana
- [ ] Admin: KPIs, reportes de asistencia, gestión de entrenadores, configuración del sistema
- [ ] Scouting: grid de jugadores, filtros, detalle/modal
- [ ] Calendario: eventos escolares, capacidad (CapacityCalendar equivalente si aplica)

#### Servicios y datos

- [ ] Cliente Supabase: mismo proyecto y tablas; Flutter usa `lib/services/` y modelos existentes
- [ ] Media (R2/Bunny): subida de fotos y vídeo desde Flutter (MediaUploadService / MediaConfig)
- [ ] Realtime: user_credits (y otros si se usan) con suscripción en Flutter

#### UI/UX

- [ ] Tema: oscuro por defecto, acentos neón (alineados con design system “Elite 380”)
- [ ] Layout: Sidebar en web / pantalla ancha, BottomNav en móvil (Layout Wrapper)
- [ ] Estados vacío / carga / error: EmptyStateWidget, LoadingWidget, ErrorStateWidget
- [ ] Feedback: SnackBars o equivalente (SnackBarHelper) para éxito, error, advertencia, info

### 5.3 Cómo usar esta sección

1. **Durante la migración:** ir marcando la checklist según se implemente cada ítem en Flutter.
2. **Antes de eliminar React:** comprobar que todos los ítems estén marcados y que las pruebas (manuales o E2E) pasen en Flutter.
3. **Después de la migración:** mantener este documento como referencia de lo que debe seguir existiendo en la app unificada.

---

*Documento generado a partir del análisis del repositorio Elite 380 L.*
