# Prompt para QA paso a paso – App Fútbol

**Objetivo:** Ejecutar una pasada QA sistemática para saber qué funciona y qué no en la app, probando cada área y documentando resultados.

---

## Instrucción para el agente (copiar y pegar)

```
Ejecuta una pasada QA paso a paso de la app Flutter "Futbol AI" según este plan:

1. **Contexto**
   - App: Flutter con Supabase, tema oscuro.
   - Roles: Coach/Admin (gestión completa) y Padre (vista limitada: asistencia hijos, chat solo lectura en Avisos, etc.).
   - Punto de entrada: AuthGate → Dashboard (Home, Metodología, Notificaciones, Chat, Galería).

2. **Por cada área de la app** (ver lista abajo), haz:
   - Abrir la pantalla o flujo desde el Home o la barra inferior.
   - Ejecutar las acciones críticas (ej: crear, editar, guardar, navegar atrás).
   - Anotar: ¿Pantalla carga? ¿Botones responden? ¿Hay errores en consola/logs? ¿Datos se guardan o muestran?
   - Marcar resultado: ✅ OK | ⚠️ Parcial | ❌ Falla | ⏭️ No probado (motivo).

3. **Probar ambos roles cuando aplique**
   - Con usuario Coach: todas las áreas.
   - Con usuario Padre: Asistencia (ParentAttendanceScreen), Chat (solo lectura en Avisos), Tablón, y cualquier otra pantalla accesible para padres.

4. **Entregable**
   - Un informe en markdown con:
     - Tabla por área: Pantalla/Flujo | Acciones probadas | Resultado | Notas.
     - Lista de bugs o comportamientos raros con pasos para reproducir.
     - Resumen: qué funciona, qué no, qué falta probar (ej: sin datos en Supabase).
```

---

## Áreas a probar (checklist)

### Desde Home – Grid de acceso rápido

| # | Área | Pantalla destino | Acciones a probar |
|---|------|------------------|-------------------|
| 1 | Plantilla | SquadManagementScreen | Listar jugadores, buscar, ver perfil, añadir/editar (si hay UI) |
| 2 | Tácticas | TacticalBoardScreen | Abrir tablero, colocar jugadores, guardar/cargar alineación |
| 3 | Entrenamientos | TrainingCategoriesScreen | Ver categorías, abrir sesiones, ver detalle |
| 4 | Ejercicios | DrillsScreen | Listar ejercicios, abrir detalle, filtrar |
| 5 | Partidos | MatchesScreen | Ver partidos, crear/editar, ver reporte, live |
| 6 | Chat Equipo | TeamChatScreen | Enviar mensaje (canal equipo), ver Avisos, (Coach) crear aviso |
| 7 | Fútbol Social | SocialFeedScreen | Ver feed, crear post, like/comentario |
| 8 | Galería | GalleryScreen | Ver galería, subir/ver fotos |
| 9 | Metodología | MethodologyScreen | Navegar contenido |
| 10 | Campos | FieldScheduleScreen | Ver reservas, solicitar/ver horarios |
| 11 | Goleadores | TopScorersScreen | Ver tabla de goleadores por equipo/categoría |
| 12 | Asistencia | AttendanceScreen (coach) / ParentAttendanceScreen (padre) | Coach: pasar lista. Padre: ver sesiones, marcar asistencia del hijo |
| 13 | Tablón | NoticeBoardScreen | Ver avisos, crear (coach), filtrar, abrir detalle |

### Barra inferior (Dashboard)

| # | Tab | Acciones a probar |
|---|-----|-------------------|
| 14 | Inicio | Que cargue Home y grid |
| 15 | Metodología | Contenido visible |
| 16 | Notificaciones | Lista y abrir notificación |
| 17 | Chat | Mismo que "Chat Equipo" |
| 18 | Galería | Mismo que "Galería" del grid |

### Acciones rápidas (FAB "ACCIONES")

| # | Acción | Resultado esperado |
|---|--------|--------------------|
| 19 | Añadir Jugador | Snackbar o navegación a alta |
| 20 | Nueva Sesión | SessionPlannerScreen |
| 21 | Subir Archivo | Snackbar o TestUploadScreen |
| 22 | Compartir Momento | SocialFeedScreen |
| 23 | Editar / Eliminar elemento | Snackbar o flujo correspondiente |

### Otras pantallas (desde flujos secundarios)

| # | Pantalla | Cómo llegar | Acciones clave |
|---|----------|-------------|----------------|
| 24 | SessionPlannerScreen | Acciones → Nueva Sesión o Editar Sesión | Crear/editar sesión, guardar |
| 25 | TestUploadScreen | Acciones → Subir Archivo (botón verde) | Subir archivo/imagen |
| 26 | PlayerProfileScreen | Plantilla → jugador | Ver datos, notas, historial |
| 27 | MatchReportScreen | Partidos → partido → reporte | Ver/editar reporte |
| 28 | LiveMatchScreen | Partidos → en vivo | Seguir partido en vivo |
| 29 | NoticeBoardScreen (detalle) | Tablón → aviso | Ver contenido completo |
| 30 | CreatePostScreen | Fútbol Social → crear | Crear post con texto/imagen |
| 31 | SelectChatRecipientScreen | Chat (si aplica) | Elegir grupo o contacto |
| 32 | Settings / Profile | AppBar (icono ajustes) si existe | Ajustes, cerrar sesión |

---

## Cómo usar este prompt

1. **En Cursor:** Pega el bloque "Instrucción para el agente" en el chat y adjunta este archivo (`QA_PROMPT.md`) si hace falta.
2. **Manual:** Usa la tabla "Áreas a probar" como checklist; ve pantalla por pantalla y anota ✅/⚠️/❌ en un informe.
3. **Con dos usuarios:** Crea o usa un usuario Coach y un usuario Padre en Supabase y repite las pruebas que apliquen a cada rol.

---

## Notas para el QA

- La app usa **Supabase**. Si no hay datos (equipos, jugadores, partidos, sesiones), muchas pantallas pueden estar vacías o fallar; anótalo como "Sin datos" en lugar de "Falla" si el fallo es por datos.
- **AuthGate** actualmente redirige directo al Dashboard con `userRole: 'coach'`. Para probar como Padre hace falta cambiar temporalmente el rol o implementar login real y entrar con usuario padre.
- Documenta versión de Flutter, dispositivo/emulador y si usaste `.env` con Supabase configurado.
