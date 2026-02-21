# ⚡ INICIO RÁPIDO - SISTEMA HÍBRIDO

## 🎯 En 5 Minutos

### Paso 1: Ejecutar SQL (Solo Primera Vez)

```bash
# Desde Supabase Dashboard → SQL Editor
# Copia y ejecuta: SETUP_HYBRID_SYSTEM.sql
```

**¿Qué hace?**
- Añade `match_timestamp` a `analysis_events`
- Hace `video_timestamp` nullable
- Crea funciones de sincronización
- Añade campos a `matches` (video_offset, is_synced)

### Paso 2: Probar Modo Live

1. Abre la app
2. Ve a **"Partidos"**
3. Busca un partido con estado "LIVE" o "PENDING"
4. Pulsa **"MODO LIVE"** (botón verde)
5. Pulsa **"INICIAR"** en el cronómetro
6. Registra 3 eventos:
   - Tap en **"GOL"**
   - Tap en **"TIRO"**
   - Mantén el **micrófono** y di: *"Pérdida de Juan"*

**Resultado esperado:**
- Cronómetro corriendo
- Eventos guardados con `video_timestamp = null`
- Contadores actualizados en tiempo real

### Paso 3: Subir Video (Simulación)

Para probar la sincronización, necesitas un video en Bunny:

```dart
// Opción A: Usar un video de prueba existente
final testVideoUrl = 'https://vz-xxxxx.b-cdn.net/tu-video-guid/playlist.m3u8';

// Opción B: Subir uno nuevo desde la app
// (Usa MediaUploadService)
```

### Paso 4: Sincronizar

1. Ve a **ProMatch Analysis** del mismo partido
2. Verás un diálogo: **"Sincronizar Eventos"**
3. Pulsa **"Sincronizar"**
4. Reproduce el video hasta el pitido inicial
5. Pausa y pulsa **"MARCAR PITIDO INICIAL"**
6. Confirma con **"SINCRONIZAR AHORA"**

**Resultado esperado:**
```
✅ Se sincronizaron 3 eventos correctamente
```

### Paso 5: Verificar

En ProMatch Analysis:
- Los 3 eventos ahora tienen timestamps de video
- Puedes hacer click en ellos para saltar en el video
- Los marcadores aparecen en la línea de tiempo

---

## 🧪 Prueba Completa (10 minutos)

### Escenario: Partido Real Simulado

#### 1. Preparación (1 min)

```sql
-- Crear un partido de prueba
INSERT INTO matches (
  id,
  team_id,
  team_home,
  team_away,
  status,
  match_date
) VALUES (
  'test-match-hybrid-001',
  'tu-team-id',
  'Mi Equipo',
  'Rival FC',
  'LIVE',
  NOW()
);
```

#### 2. Modo Live (3 min)

1. Abre **"Partidos"** → Busca "Mi Equipo vs Rival FC"
2. Pulsa **"MODO LIVE"**
3. Inicia el cronómetro
4. Espera 10 segundos → Tap en **"GOL"**
5. Espera 15 segundos → Di por voz: *"Tiro de Carlos"*
6. Espera 20 segundos → Tap en **"PÉRDIDA"**
7. Pausa el cronómetro
8. Cierra la pantalla

#### 3. Verificar Base de Datos (1 min)

```sql
SELECT 
  event_type,
  match_timestamp,
  video_timestamp,
  voice_transcript
FROM analysis_events
WHERE match_id = 'test-match-hybrid-001'
ORDER BY match_timestamp;
```

**Esperado:**
```
event_type | match_timestamp | video_timestamp | voice_transcript
-----------+-----------------+-----------------+------------------
gol        | 10              | NULL            | NULL
tiro       | 25              | NULL            | Tiro de Carlos
perdida    | 45              | NULL            | NULL
```

#### 4. Subir Video de Prueba (2 min)

```dart
// Desde Flutter DevTools o un script
final mediaService = MediaUploadService();
final videoFile = File('path/to/test-video.mp4');
final videoGuid = await mediaService.uploadVideo(videoFile);

// Actualizar el partido
await Supabase.instance.client
  .from('matches')
  .update({
    'video_url': 'https://vz-xxxxx.b-cdn.net/$videoGuid/playlist.m3u8',
    'video_guid': videoGuid,
  })
  .eq('id', 'test-match-hybrid-001');
```

#### 5. Sincronizar (2 min)

1. Abre **ProMatch Analysis** del partido
2. Verás el diálogo de sincronización (3 eventos)
3. Pulsa **"Sincronizar"**
4. Marca el pitido inicial en el segundo **30** del video
5. Confirma

#### 6. Verificar Sincronización (1 min)

```sql
SELECT 
  event_type,
  match_timestamp,
  video_timestamp,
  (video_timestamp - match_timestamp) AS offset
FROM analysis_events
WHERE match_id = 'test-match-hybrid-001'
ORDER BY match_timestamp;
```

**Esperado:**
```
event_type | match_timestamp | video_timestamp | offset
-----------+-----------------+-----------------+--------
gol        | 10              | 40              | 30
tiro       | 25              | 55              | 30
perdida    | 45              | 75              | 30
```

**Verificar partido:**
```sql
SELECT video_offset, is_synced
FROM matches
WHERE id = 'test-match-hybrid-001';
```

**Esperado:**
```
video_offset | is_synced
-------------+-----------
30           | true
```

---

## 🎬 Video Tutorial (Próximamente)

Mientras tanto, sigue estos pasos:

1. **Grabación del Partido:**
   - Usa tu móvil en un trípode
   - Graba desde el inicio (pitido inicial visible)
   - Formato recomendado: 1080p, 30fps

2. **Registro Live:**
   - Mantén el móvil en el bolsillo
   - Usa comandos de voz principalmente
   - No te preocupes por la precisión exacta

3. **Sincronización:**
   - Busca el pitido inicial con calma
   - Usa las flechas del reproductor (frame a frame)
   - Confirma cuando estés seguro

---

## 🔍 Comandos de Verificación

### Ver Eventos Sin Sincronizar

```sql
SELECT COUNT(*) AS unsynced_events
FROM analysis_events
WHERE match_id = 'tu-match-id'
  AND video_timestamp IS NULL;
```

### Ver Estadísticas de un Partido

```sql
SELECT * FROM get_live_events_stats('tu-match-id');
```

### Verificar si Hay Eventos Sin Sincronizar

```sql
SELECT has_unsynced_live_events('tu-match-id');
```

### Sincronizar Manualmente (Si falla la UI)

```sql
SELECT * FROM sync_live_events_with_video(
  'tu-match-id',
  45  -- Offset en segundos (pitido inicial en el video)
);
```

---

## 🐛 Debugging Rápido

### Logs de Flutter

```bash
flutter logs | grep -E "(Live|Sync|Event)"
```

Busca:
- ✅ `LiveMatchScreen inicializado`
- ✅ `Evento registrado: gol en 00:23`
- ✅ `Sincronización completada: 3 eventos`

### Logs de Supabase

Dashboard → Logs → Filter: `analysis_events`

Busca:
- ✅ `INSERT INTO analysis_events` (con video_timestamp NULL)
- ✅ `UPDATE analysis_events SET video_timestamp` (después de sync)

### Verificar Permisos RLS

```sql
-- Como usuario autenticado
SET LOCAL role TO authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "tu-user-id"}';

-- Intentar insertar evento
INSERT INTO analysis_events (
  match_id,
  team_id,
  coach_id,
  match_timestamp,
  event_type
) VALUES (
  'test-match-hybrid-001',
  'tu-team-id',
  'tu-user-id',
  100,
  'gol'
);
```

Si falla, revisa las policies de `analysis_events`.

---

## 📊 Métricas de Éxito

Después de implementar, deberías poder:

- ✅ Registrar 10+ eventos en 1 minuto (Modo Live)
- ✅ Sincronizar 50 eventos en < 30 segundos
- ✅ Saltar a cualquier evento en el video en < 2 segundos
- ✅ Usar comandos de voz con 80%+ precisión

---

## 🚀 Siguiente Nivel

Una vez que funcione:

1. **Personaliza los Botones:**
   - Edita `_buildQuickActionsGrid()` en `LiveMatchScreen`
   - Añade eventos específicos de tu metodología

2. **Mejora el Reconocimiento de Voz:**
   - Añade keywords en `VoiceTaggingService`
   - Entrena con nombres de tus jugadores

3. **Automatiza la Subida:**
   - Integra con Google Drive / Dropbox
   - Sube videos automáticamente después del partido

4. **Exporta Datos:**
   - Genera PDFs con estadísticas
   - Comparte clips individuales

---

## 🎯 Checklist de Implementación

- [ ] SQL ejecutado (`SETUP_HYBRID_SYSTEM.sql`)
- [ ] Partido de prueba creado
- [ ] Modo Live funciona (3+ eventos registrados)
- [ ] Video subido a Bunny
- [ ] Sincronización completada
- [ ] Eventos visibles en ProMatch Analysis
- [ ] Timeline funcional (click → salta al video)
- [ ] Comandos de voz funcionan
- [ ] Contadores en tiempo real actualizados

---

**¡Listo para el campo! ⚽🚀**

Si todos los checks están ✅, tu sistema está **production-ready**.
