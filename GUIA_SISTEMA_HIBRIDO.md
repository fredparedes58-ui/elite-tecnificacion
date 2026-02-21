# 🔄 GUÍA DEL SISTEMA HÍBRIDO (LIVE + VIDEO SYNC)

## 📋 Índice

1. [¿Qué es el Sistema Híbrido?](#qué-es-el-sistema-híbrido)
2. [Flujo de Trabajo](#flujo-de-trabajo)
3. [Modo Live (En el Campo)](#modo-live-en-el-campo)
4. [Sincronización con Video](#sincronización-con-video)
5. [Análisis Post-Partido](#análisis-post-partido)
6. [Casos de Uso](#casos-de-uso)

---

## 🎯 ¿Qué es el Sistema Híbrido?

El **Sistema Híbrido** permite a los entrenadores usar ProMatch de dos formas:

### 🏟️ Modo Live (Sin Video)
- Registra eventos **durante el partido** usando solo un cronómetro
- No necesitas grabar video ni tener internet
- Usa comandos de voz o botones rápidos
- Perfecto para el banquillo

### 🎬 Modo Video (Post-Partido)
- Sube el video del partido cuando llegues a casa
- Sincroniza automáticamente los eventos Live con el video
- Analiza jugadas con precisión frame a frame
- Añade telestration (dibujos tácticos)

---

## 🔄 Flujo de Trabajo

```
┌─────────────────┐
│  PARTIDO LIVE   │
│  (En el campo)  │
└────────┬────────┘
         │
         │ Registras eventos con cronómetro
         │ (Gol en minuto 23:45)
         ▼
┌─────────────────┐
│ EVENTOS GUARDADOS│
│  video_timestamp │
│      = NULL      │
└────────┬────────┘
         │
         │ Llegas a casa
         │ Subes el video
         ▼
┌─────────────────┐
│ SINCRONIZACIÓN  │
│ Marcas el pitido│
│ inicial (ej: 45s)│
└────────┬────────┘
         │
         │ Sistema calcula offset
         │ video_timestamp = match_timestamp + 45
         ▼
┌─────────────────┐
│ ANÁLISIS VIDEO  │
│ Eventos ahora   │
│ tienen timestamp│
│ exacto del video│
└─────────────────┘
```

---

## 🏟️ Modo Live (En el Campo)

### 1. Iniciar Modo Live

**Desde la pantalla de Partidos:**

1. Ve a **"Partidos"** en el menú principal
2. Busca el partido próximo o en vivo
3. Pulsa el botón **"MODO LIVE"** (verde)

### 2. Usar el Cronómetro

```
┌──────────────────────────┐
│      23:45               │  ← Tiempo del partido
│   [PAUSAR] [REINICIAR]   │
└──────────────────────────┘
```

- **Iniciar:** Pulsa al pitido inicial del árbitro
- **Pausar:** Para descansos o interrupciones
- **Reiniciar:** Solo si te equivocas (borra eventos)

### 3. Registrar Eventos

#### Opción A: Botones Rápidos

Grid de 8 botones principales:

| GOL | TIRO | PASE | PÉRDIDA |
|-----|------|------|---------|
| **ROBO** | **FALTA** | **CÓRNER** | **TARJETA** |

**Uso:** Tap simple → Se guarda con el tiempo actual del cronómetro

#### Opción B: Comando de Voz

1. **Mantén presionado** el botón grande de micrófono
2. Di algo como:
   - *"Gol de Juan"*
   - *"Pérdida de balón de Carlos"*
   - *"Tiro a puerta del número 10"*
3. **Suelta** el botón
4. El sistema detecta automáticamente:
   - Tipo de evento (gol, tiro, pérdida...)
   - Jugador mencionado
   - Tiempo exacto

### 4. Ver Estadísticas en Tiempo Real

En la parte inferior verás contadores:

```
┌──────────────────────────────┐
│ ESTADÍSTICAS DEL PARTIDO     │
│ Goles: 2  Tiros: 8           │
│ Pérdidas: 5  Robos: 3        │
└──────────────────────────────┘
```

### 5. Finalizar

- Simplemente cierra la pantalla
- Los eventos quedan guardados en Supabase
- Puedes volver a entrar en cualquier momento

---

## 🎬 Sincronización con Video

### Cuándo Sincronizar

La app te avisará automáticamente cuando:
1. Entres a **ProMatch Analysis** de un partido
2. Ese partido tenga eventos Live sin sincronizar
3. Exista un video subido

Verás este diálogo:

```
┌─────────────────────────────────┐
│ 🔄 Sincronizar Eventos          │
│                                 │
│ Este partido tiene 12 eventos   │
│ registrados en modo Live.       │
│                                 │
│ ¿Deseas sincronizarlos con el   │
│ video?                          │
│                                 │
│  [Ahora No]  [Sincronizar]      │
└─────────────────────────────────┘
```

### Proceso de Sincronización

#### Paso 1: Buscar el Pitido Inicial

1. Se abre el video del partido
2. **Reproduce** el video
3. Busca el momento exacto donde el árbitro **pita el inicio**
4. **Pausa** justo en ese frame

#### Paso 2: Marcar el Momento

```
┌──────────────────────────────┐
│   [VIDEO PLAYER]             │
│                              │
│   ▶ 00:45                    │
│                              │
│  [MARCAR PITIDO INICIAL]     │
└──────────────────────────────┘
```

Pulsa el botón verde **"MARCAR PITIDO INICIAL"**

#### Paso 3: Confirmar

```
┌──────────────────────────────┐
│ Pitido Inicial: 00:45        │
│ Eventos a Sincronizar: 12    │
│                              │
│ [REINTENTAR] [SINCRONIZAR]   │
└──────────────────────────────┘
```

- **Reintentar:** Si te equivocaste, vuelve al paso 1
- **Sincronizar:** Confirma y el sistema hace la magia

#### Paso 4: Resultado

```
✅ Se sincronizaron 12 eventos correctamente
```

El sistema calcula automáticamente:
```
video_timestamp = match_timestamp + video_offset

Ejemplo:
- Gol registrado en Live: 23:45 (1425 segundos)
- Pitido inicial en video: 00:45 (45 segundos)
- Timestamp final en video: 24:30 (1470 segundos)
```

---

## 📊 Análisis Post-Partido

Una vez sincronizado, en **ProMatch Analysis**:

### Timeline de Eventos

```
┌──────────────────────────────────┐
│ 03:12  ⚽ Gol - Juan Pérez       │ ← Click para saltar
│ 08:45  🎯 Tiro - Carlos García   │
│ 15:30  ⚠️ Pérdida - Pedro López  │
│ 23:45  ⚽ Gol - Juan Pérez       │
└──────────────────────────────────┘
```

**Funcionalidad:**
- Click en cualquier evento → El video salta a ese momento exacto
- Puedes añadir dibujos tácticos
- Exportar clips individuales
- Generar reportes

### Indicadores Visuales

Los eventos sincronizados tienen:
- ✅ Badge verde: "Sincronizado"
- 🎬 Timestamp del video visible
- ⏱️ Timestamp del partido (tiempo real)

---

## 🎯 Casos de Uso

### Caso 1: Partido Amateur (Sin Cámara Fija)

**Problema:** No tienes cámara en el campo

**Solución:**
1. Usa **Modo Live** durante el partido
2. Pídele a un padre que grabe con el móvil
3. Al llegar a casa, sube el video
4. Sincroniza y analiza

### Caso 2: Entrenador Solo

**Problema:** Estás solo en el banquillo

**Solución:**
1. Usa **comandos de voz** en Modo Live
2. No necesitas mirar la pantalla
3. Di "Gol de Juan" y sigue viendo el partido
4. Sincroniza después con calma

### Caso 3: Partido Profesional

**Problema:** Tienes video pero quieres datos en vivo

**Solución:**
1. Usa **Modo Live** para estadísticas instantáneas
2. Comparte contadores con el cuerpo técnico
3. Después del partido, sincroniza con el video oficial
4. Análisis completo con ambas fuentes

### Caso 4: Sin Video (Solo Estadísticas)

**Problema:** No vas a tener video nunca

**Solución:**
1. Usa **Modo Live** normalmente
2. Los eventos se guardan con tiempo del partido
3. Puedes generar reportes estadísticos
4. No necesitas sincronizar

---

## 🔧 Configuración de Base de Datos

### Ejecutar el SQL de Actualización

Si eres el administrador del sistema, ejecuta:

```bash
psql -U postgres -d tu_base_de_datos -f SETUP_HYBRID_SYSTEM.sql
```

O desde Supabase Dashboard:
1. Ve a **SQL Editor**
2. Copia el contenido de `SETUP_HYBRID_SYSTEM.sql`
3. Ejecuta

### Verificar Instalación

```sql
-- Verificar que las columnas existen
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'analysis_events'
  AND column_name IN ('match_timestamp', 'video_timestamp');

-- Verificar funciones
SELECT routine_name
FROM information_schema.routines
WHERE routine_name LIKE '%sync%';
```

Deberías ver:
- ✅ `match_timestamp` (integer, NOT NULL)
- ✅ `video_timestamp` (integer, NULL)
- ✅ `sync_live_events_with_video()` (function)
- ✅ `has_unsynced_live_events()` (function)

---

## 📱 Pantallas del Sistema

### 1. LiveMatchScreen
**Archivo:** `lib/screens/live_match_screen.dart`

**Características:**
- Cronómetro gigante (Stopwatch)
- Grid de 8 botones rápidos
- Botón de voz (mantener presionado)
- Contadores en tiempo real
- Diseño alto contraste (para sol)

### 2. VideoSyncScreen
**Archivo:** `lib/screens/video_sync_screen.dart`

**Características:**
- Reproductor de video Bunny
- Instrucciones claras paso a paso
- Botón de marcado de pitido
- Panel de confirmación
- Feedback de sincronización

### 3. ProMatchAnalysisScreen (Actualizada)
**Archivo:** `lib/screens/promatch_analysis_screen.dart`

**Nuevas características:**
- Detecta eventos sin sincronizar
- Muestra diálogo de sincronización
- Navega a VideoSyncScreen
- Recarga eventos después de sync

---

## 🚀 Próximos Pasos

Una vez que domines el Sistema Híbrido, puedes:

1. **Motor de Estadísticas:** Gráficos automáticos de rendimiento
2. **Exportación de Clips:** Compartir jugadas individuales
3. **Comparación de Partidos:** Evolución del equipo
4. **Análisis de Calor:** Mapas de posiciones

---

## 🆘 Solución de Problemas

### "No aparece el botón Modo Live"

**Causa:** El partido está marcado como "FINISHED"

**Solución:** Cambia el estado del partido a "LIVE" o "PENDING" en Supabase

### "Los eventos no se sincronizan"

**Causa:** El video no tiene GUID o el matchId no coincide

**Solución:**
1. Verifica que el video se subió correctamente
2. Comprueba que `video_guid` no es null
3. Revisa los logs de Supabase

### "El cronómetro se reinicia solo"

**Causa:** La app se cerró o perdió estado

**Solución:** Los eventos ya guardados permanecen, solo continúa desde donde ibas

### "La voz no detecta jugadores"

**Causa:** Los jugadores no están cargados en el servicio

**Solución:**
1. Verifica que `teamId` es correcto
2. Comprueba que los jugadores tienen nombres en `profiles`
3. Revisa permisos de `team_members`

---

## 📞 Soporte

Si tienes problemas:

1. Revisa los logs de Flutter: `flutter logs`
2. Verifica Supabase Dashboard → Logs
3. Comprueba que ejecutaste `SETUP_HYBRID_SYSTEM.sql`
4. Revisa que los permisos RLS están correctos

---

**¡Disfruta del Sistema Híbrido! 🚀⚽**

Tu app ahora es **verdaderamente profesional**: funciona en el campo sin internet y se sincroniza perfectamente en casa.
