# 🎥 GUÍA COMPLETA: ProMatch Analysis Suite

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Instalación](#instalación)
3. [Configuración de Base de Datos](#configuración-de-base-de-datos)
4. [Configuración de Permisos](#configuración-de-permisos)
5. [Uso de la Pantalla](#uso-de-la-pantalla)
6. [Funcionalidades](#funcionalidades)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Descripción General

**ProMatch Analysis Suite** es una herramienta profesional de análisis táctico que combina:

- 🎥 **Video Streaming**: Reproducción fluida desde Bunny Stream
- 🎙️ **Voice Tagging**: Reconocimiento de voz con auto-detección de jugadores y eventos
- ✏️ **Telestration**: Dibujo táctico sobre el video con herramientas profesionales
- 📊 **Timeline Interactivo**: Navegación rápida entre eventos marcados
- ☁️ **Almacenamiento en la Nube**: Dibujos en R2, datos en Supabase

---

## 📦 Instalación

### PASO 1: Instalar Dependencias

Las dependencias ya están añadidas en `pubspec.yaml`. Ejecuta:

```bash
flutter pub get
```

### PASO 2: Configurar Permisos iOS (Info.plist)

Edita `ios/Runner/Info.plist` y añade:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Necesitamos acceso al micrófono para grabar notas de análisis con voz</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Usamos reconocimiento de voz para identificar jugadores y eventos automáticamente</string>
```

### PASO 3: Configurar Permisos Android (AndroidManifest.xml)

Edita `android/app/src/main/AndroidManifest.xml` y añade dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 🗄️ Configuración de Base de Datos

### PASO 1: Ejecutar Script SQL

En Supabase, ve a **SQL Editor** y ejecuta:

```sql
-- Copiar y pegar el contenido de:
SETUP_PROMATCH_ANALYSIS.sql
```

Este script crea:
- ✅ Tabla `analysis_events` (eventos de análisis)
- ✅ Tabla `event_types` (tipos de eventos predefinidos)
- ✅ Vista `analysis_events_detailed` (datos enriquecidos)
- ✅ Función `get_match_analysis_timeline()` (timeline optimizado)
- ✅ Policies de seguridad (RLS)

### PASO 2: Verificar Creación

Ejecuta en SQL Editor:

```sql
-- Debe retornar 12 filas
SELECT COUNT(*) FROM event_types;

-- Debe retornar la estructura de la tabla
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'analysis_events';
```

---

## 🔐 Configuración de Permisos

### Permisos del Sistema

Al abrir la pantalla por primera vez, la app pedirá:

1. **🎤 Permiso de Micrófono**: Para grabar notas de voz
2. **🗣️ Reconocimiento de Voz**: Para transcribir automáticamente

Si el usuario rechaza los permisos, **Voice Tagging** no funcionará, pero el resto de funcionalidades sí.

### Permisos de Supabase (RLS)

Ya están configurados automáticamente:
- ✅ Entrenadores pueden ver eventos de su equipo
- ✅ Entrenadores pueden crear/editar/eliminar sus propios eventos
- ✅ Los jugadores NO pueden modificar eventos (solo verlos)

---

## 🚀 Uso de la Pantalla

### Abrir la Pantalla

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProMatchAnalysisScreen(
      videoUrl: 'https://vz-xxxx.b-cdn.net/VIDEO_GUID/playlist.m3u8',
      videoGuid: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
      matchId: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
      teamId: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    ),
  ),
);
```

**Parámetros:**

| Parámetro | Tipo | Obligatorio | Descripción |
|-----------|------|-------------|-------------|
| `videoUrl` | String | ✅ Sí | URL del video en Bunny Stream (.m3u8) |
| `videoGuid` | String | ⚠️ Opcional | GUID del video (para referencia) |
| `matchId` | String | ⚠️ Opcional | ID del partido (para guardar eventos) |
| `teamId` | String | ⚠️ Opcional | ID del equipo (para detección de jugadores) |

---

## ⚙️ Funcionalidades

### 1️⃣ Reproducción de Video

- ▶️ Play/Pause automático
- ⏩ Controles de velocidad (0.5x, 1x, 1.5x, 2x)
- 🔊 Control de volumen
- 📱 Pantalla completa
- 🕐 Timestamp visible en tiempo real

### 2️⃣ Voice Tagging (Grabación de Voz)

**Cómo usar:**

1. Mientras el video reproduce, **mantén pulsado** el botón del micrófono (🎤)
2. Habla claramente: *"Pérdida de Nico"* o *"Gol de Mauro"*
3. Suelta el botón
4. La app detectará automáticamente:
   - 🏃 Jugador mencionado (por nombre, apodo o número)
   - ⚽ Tipo de evento (gol, pase, pérdida, etc.)
   - 🏷️ Tags sugeridos (ataque, defensa, contraataque)

**Ejemplo de transcripciones reconocidas:**

| Tu dices | Detecta |
|----------|---------|
| "Pérdida de Nico" | Evento: `perdida`, Jugador: Nico |
| "Gol número 10" | Evento: `gol`, Jugador: #10 |
| "Jesús hace una asistencia" | Evento: `pase`, Jugador: Jesús |
| "Error en defensa" | Evento: `perdida`, Tag: defensa |
| "Contraataque peligroso" | Tag: contraataque |

### 3️⃣ Telestration (Dibujo Táctico)

**Cómo usar:**

1. Toca el botón de **lápiz** (✏️) en la barra superior
2. El video se **pausa automáticamente**
3. Aparece la barra de herramientas:
   - 🖌️ **Pincel**: Trazo libre
   - ➡️ **Flecha**: Para señalar movimientos
   - 🧹 **Borrador**: Elimina trazos
4. Selecciona un **color** (rojo, amarillo, verde, azul, blanco)
5. Dibuja sobre el video
6. Toca **Guardar** para:
   - 📸 Capturar la imagen del dibujo
   - ☁️ Subirla automáticamente a R2
   - 💾 Guardar el evento en Supabase

**Resultado:** El dibujo queda vinculado al timestamp exacto del video.

### 4️⃣ Timeline de Eventos

**Panel inferior** muestra todos los eventos marcados:

- 🕐 Timestamp (mm:ss)
- 📝 Título del evento
- 🏃 Jugador implicado (si aplica)
- 🎨 Iconos: 🎤 (voz) / 🖼️ (dibujo)

**Navegación:**
- Toca cualquier evento → El video **salta automáticamente** a ese momento

---

## 🎨 Diseño Visual

### Estilo Heredado

La pantalla respeta las reglas de diseño del proyecto:

- **Fondo**: Negro puro (#000000)
- **Acentos**: Cyan neón (#00BCD4)
- **Fuentes**:
  - Títulos: `Oswald` (bold, letterspacing: 2)
  - Texto: `RobotoCondensed`
  - Timestamps: `RobotoMono`
- **Glassmorphism**: Gradientes con opacidad
- **Borders**: Cyan con opacidad 0.3

---

## 🔧 Arquitectura Técnica

### Servicios Utilizados

```
ProMatchAnalysisScreen
│
├── BunnyVideoPlayer (Widget)
│   └── Chewie + VideoPlayer
│
├── TelestrationLayer (Widget)
│   └── DrawingBoard
│
├── VoiceTaggingService
│   └── speech_to_text + permission_handler
│
├── MediaUploadService
│   └── Minio (R2) + Dio
│
└── SupabaseService
    └── supabase_flutter
```

### Flujo de Datos

```
Usuario → Voice Input → VoiceTaggingService
                           ↓
                    Transcript + Detección
                           ↓
                    SupabaseService.createAnalysisEvent()
                           ↓
                    Supabase DB (analysis_events)
                           ↓
                    Recargar Timeline
```

```
Usuario → Dibuja → TelestrationController.captureAsImage()
                           ↓
                    File temporal (PNG)
                           ↓
                    MediaUploadService.uploadPhoto()
                           ↓
                    Cloudflare R2
                           ↓
                    URL pública
                           ↓
                    SupabaseService.createAnalysisEvent(drawingUrl)
                           ↓
                    Supabase DB
```

---

## 🐛 Troubleshooting

### ❌ Error: "Permiso de micrófono denegado"

**Solución:**
1. Ve a Configuración del dispositivo
2. Busca la app
3. Habilita "Micrófono" manualmente
4. Reinicia la app

### ❌ Error: "No se pudo inicializar STT"

**Posibles causas:**
- No hay conectividad a internet (iOS necesita conexión la primera vez)
- El idioma español no está disponible en el dispositivo

**Solución:**
```dart
// En VoiceTaggingService, cambia:
localeId: 'es_ES'
// Por:
localeId: 'es_MX' // o 'en_US' para inglés
```

### ❌ Error: "No se pudo capturar el dibujo"

**Solución:**
- Asegúrate de que el widget `TelestrationLayer` esté envuelto en `RepaintBoundary`
- Verifica que `flutter_drawing_board` esté correctamente instalado

### ❌ La detección de jugadores no funciona

**Verifica:**
1. ¿Se llamó a `setTeamPlayers()`?
2. ¿Los nombres de jugadores tienen apodos/nicknames configurados?
3. ¿Estás pronunciando correctamente?

**Debug:**
```dart
// Añade esto en _handleVoiceResult:
debugPrint('Jugadores en cache: ${_teamPlayers.length}');
debugPrint('Transcript: ${result.transcript}');
```

### ❌ El video no carga

**Verifica:**
1. URL del video es válida (debe terminar en `.m3u8`)
2. El video está correctamente subido en Bunny Stream
3. El CDN hostname está configurado en `MediaConfig`

---

## 🎓 Ejemplos de Uso

### Caso 1: Análisis Rápido Post-Partido

```dart
// En la pantalla de detalles del partido:
ElevatedButton(
  child: Text('ANÁLISIS PROMATCH'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProMatchAnalysisScreen(
          videoUrl: match.videoUrl,
          videoGuid: match.videoGuid,
          matchId: match.id,
          teamId: currentTeamId,
        ),
      ),
    );
  },
)
```

### Caso 2: Análisis de Video Subido

```dart
// Después de subir un video:
final result = await mediaService.uploadVideo(videoFile);

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProMatchAnalysisScreen(
      videoUrl: result.directPlayUrl,
      videoGuid: result.guid,
      // Sin matchId si es un video de entrenamiento
    ),
  ),
);
```

---

## 📊 Base de Datos: Estructura de Eventos

### Tabla `analysis_events`

```sql
{
  "id": "uuid",
  "match_id": "uuid",
  "team_id": "uuid",
  "player_id": "uuid | null",
  "coach_id": "uuid",
  "video_timestamp": 125,  // segundos
  "video_guid": "xxx-xxx-xxx",
  "event_type": "gol",
  "event_title": "Gol de Mauro",
  "voice_transcript": "Gol número 10",
  "voice_confidence": 0.95,
  "drawing_url": "https://r2.../xxx.png",
  "tags": ["ataque", "contraataque"],
  "created_at": "2026-01-08T12:00:00Z"
}
```

---

## 🚀 Próximos Pasos

Funcionalidades que podrías añadir:

1. **Exportar Informe**: Genera PDF con todos los eventos + capturas
2. **Compartir Eventos**: Envía eventos específicos al equipo vía chat
3. **Filtros**: Filtra eventos por tipo, jugador o timestamp
4. **Editar Eventos**: Permite modificar el título/notas posteriormente
5. **Comparación**: Compara dos videos lado a lado
6. **IA Predictiva**: Sugerir eventos basado en patrones

---

## 📞 Soporte

Si tienes dudas:
1. Revisa los logs en Debug Console
2. Verifica que las tablas SQL estén creadas
3. Comprueba los permisos del dispositivo
4. Revisa la configuración de `MediaConfig` y `AppConfig`

---

**¡La Suite ProMatch está lista para llevarte al siguiente nivel de análisis táctico! ⚽🔥**
