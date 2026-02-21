# ⚡ INICIO RÁPIDO: ProMatch Analysis

## 🎯 3 Pasos para Empezar

### PASO 1: Configurar Base de Datos

```sql
-- En Supabase SQL Editor, ejecuta:
\i SETUP_PROMATCH_ANALYSIS.sql
```

Verifica que se creó correctamente:

```sql
SELECT COUNT(*) FROM event_types;
-- Debe retornar: 12
```

---

### PASO 2: Configurar Permisos del Dispositivo

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Para grabar notas de análisis con voz</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Para identificar jugadores automáticamente</string>
```

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

---

### PASO 3: Usar en tu App

#### Opción A: Desde el Home Screen

Añade un botón en `home_screen.dart`:

```dart
QuickActionButton(
  icon: Icons.analytics,
  title: 'Análisis ProMatch',
  subtitle: 'Video + Voz + Dibujo',
  color: Colors.purple,
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProMatchAnalysisScreen(
          videoUrl: 'https://vz-xxx.b-cdn.net/VIDEO_GUID/playlist.m3u8',
          videoGuid: 'tu-video-guid',
          matchId: 'tu-match-id',
          teamId: 'tu-team-id',
        ),
      ),
    );
  },
),
```

#### Opción B: Desde Pantalla de Partido

En `match_details_screen.dart` o similar:

```dart
ElevatedButton.icon(
  icon: Icon(Icons.video_library),
  label: Text('ANÁLISIS COMPLETO'),
  onPressed: () async {
    // Si ya tienes el video subido:
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProMatchAnalysisScreen(
          videoUrl: match.videoUrl,
          videoGuid: match.videoGuid,
          matchId: match.id,
          teamId: match.teamId,
        ),
      ),
    );
  },
)
```

#### Opción C: Después de Subir un Video

```dart
// Después de subir un video nuevo:
final videoFile = await FilePicker.getFile();
final mediaService = MediaUploadService();

// Subir a Bunny Stream
final result = await mediaService.uploadVideo(videoFile);

// Abrir análisis inmediatamente
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProMatchAnalysisScreen(
      videoUrl: result.directPlayUrl,
      videoGuid: result.guid,
      matchId: currentMatchId, // Opcional
      teamId: currentTeamId,   // Opcional
    ),
  ),
);
```

---

## 🎮 Cómo Usar

### 1️⃣ Voice Tagging (Grabación de Voz)

1. Mientras el video reproduce, **mantén pulsado** el botón 🎤
2. Di: *"Pérdida de Nico"* o *"Gol de Mauro"*
3. Suelta el botón
4. **Verás un Toast** con lo detectado

**La app detectará automáticamente:**
- 👤 Nombre del jugador
- ⚽ Tipo de evento (gol, pase, pérdida, etc.)
- 🏷️ Tags relacionados

### 2️⃣ Telestration (Dibujo)

1. Toca el botón ✏️ en la barra superior
2. El video se pausa
3. Dibuja con el dedo
4. Cambia colores y herramientas
5. Toca **Guardar**
6. La imagen se sube a R2 automáticamente

### 3️⃣ Timeline de Eventos

- Los eventos aparecen abajo en orden cronológico
- **Toca un evento** → El video salta a ese momento
- Iconos: 🎤 (voz) / 🖼️ (dibujo)

---

## 🐛 Problemas Comunes

### ❌ "Permiso de micrófono denegado"

**Solución:**
- iOS/Android: Ve a Configuración → Tu App → Habilita Micrófono

### ❌ "No se detectan jugadores"

**Verifica:**
1. ¿Pasaste `teamId` al widget?
2. ¿Los jugadores tienen nombres en la BD?
3. ¿Pronuncias claramente?

**Debug:**
```dart
// Añade esto en la pantalla:
debugPrint('Jugadores cargados: ${_teamPlayers.length}');
```

### ❌ "Error al cargar video"

**Verifica:**
- URL termina en `.m3u8`
- El video existe en Bunny Stream
- Tienes conexión a internet

### ❌ "No se guarda el dibujo"

**Verifica:**
- Pasaste `matchId` al widget
- Las credenciales R2 están en `.env`
- El bucket R2 existe

---

## 🎨 Personalización

### Cambiar Colores de Dibujo

En `telestration_layer.dart`:

```dart
// Añadir más colores:
_ColorButton(
  color: Colors.purple,
  isSelected: controller.currentColor == Colors.purple,
  onTap: () => controller.setColor(Colors.purple),
),
```

### Cambiar Tipos de Eventos

Edita en SQL:

```sql
INSERT INTO event_types (id, name, category, icon, color, keywords) VALUES
  ('tackle', 'Tackle Limpio', 'defensive', 'sports', '#00BCD4', 
   ARRAY['tackle', 'entrada', 'barrida']);
```

Luego se detectará automáticamente con esas keywords.

---

## 📊 Ver Eventos Guardados

### En Supabase

```sql
-- Ver todos los eventos de un partido:
SELECT * FROM analysis_events_detailed 
WHERE match_id = 'tu-match-id'
ORDER BY video_timestamp;
```

### En tu App

```dart
final supabase = SupabaseService();
final events = await supabase.getMatchAnalysisEvents(
  matchId: 'tu-match-id',
);

// Procesar eventos:
for (var event in events) {
  print('${event['video_timestamp']}s - ${event['event_title']}');
  if (event['player_name'] != null) {
    print('  Jugador: ${event['player_name']}');
  }
}
```

---

## 🚀 Próximos Pasos

Después de la implementación básica:

1. **Exportar PDF**: Genera informes con todos los eventos
2. **Filtros**: Filtra por tipo de evento o jugador
3. **Comparar Videos**: Análisis lado a lado
4. **Compartir**: Envía eventos al chat del equipo
5. **Estadísticas**: Genera métricas automáticas

---

## 📖 Documentación Completa

Para detalles técnicos, arquitectura y troubleshooting avanzado:

👉 **Lee:** `GUIA_PROMATCH_ANALYSIS.md`

---

## ✅ Checklist de Verificación

Antes de probar en producción:

- [ ] SQL ejecutado correctamente
- [ ] Permisos iOS/Android configurados
- [ ] `flutter pub get` ejecutado
- [ ] Credenciales R2 en `.env`
- [ ] Video de prueba en Bunny Stream
- [ ] Al menos 1 jugador en la BD
- [ ] Probado en dispositivo físico (no emulador para voz)

---

**¡Listo! Ya tienes análisis táctico de nivel profesional 🔥⚽**

Cualquier duda, revisa los logs con:
```bash
flutter run --verbose
```
