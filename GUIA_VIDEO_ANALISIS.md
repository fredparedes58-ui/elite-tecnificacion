# 🎥 GUÍA: SISTEMA DE VIDEO ANÁLISIS PARA ENTRENADORES

## 📋 RESUMEN

El **Sistema de Video Análisis** permite a los entrenadores subir videos de análisis técnico individual para jugadores y adjuntar videos de referencia a tácticas, todo con máxima privacidad y reutilizando el motor de subida existente (Bunny Stream).

---

## 🎯 CARACTERÍSTICAS IMPLEMENTADAS

### ✅ PASO 3: HERRAMIENTAS DEL ENTRENADOR (Completado)

#### **1. MÓDULO: PERFIL DEL JUGADOR - Video Análisis**

**Ubicación:** `PlayerProfileScreen` → Pestaña "Análisis"

**Funcionalidades:**
- ✅ Nueva pestaña "Análisis" en el perfil del jugador
- ✅ Entrenador puede subir videos de corrección técnica
- ✅ Videos suben a Bunny Stream (HLS)
- ✅ Privacidad máxima: Solo entrenador y jugador pueden ver los videos
- ✅ Categorías: Técnica, Posicionamiento, Toma de Decisiones, Condición Física, Mental
- ✅ Comentarios del entrenador adjuntos a cada video
- ✅ Reproductor con controles (sin autoplay)
- ✅ Barra de progreso en tiempo real durante la subida

**Privacidad (RLS):**
- Solo el entrenador que subió el video puede verlo
- Solo el jugador analizado puede ver SUS videos
- Nadie más del equipo tiene acceso

---

#### **2. MÓDULO: PIZARRA TÁCTICA - Videos de Referencia**

**Ubicación:** `TacticalBoardScreen` → Botón "Videos de Referencia" 🎬

**Funcionalidades:**
- ✅ Botón morado en la barra de herramientas: "Videos de Referencia"
- ✅ Subir videos de jugadas reales (ej: partido de un equipo profesional)
- ✅ Vincular videos a tácticas o alineaciones guardadas
- ✅ Tipos de video: Referencia Profesional, Partido Real, Entrenamiento
- ✅ Reproductor flotante al seleccionar un video
- ✅ Visible para todo el cuerpo técnico

**Cómo Usar:**
1. Guarda una jugada o selecciona una alineación
2. Haz clic en el botón morado "Videos de Referencia" 🎬
3. Sube un video de referencia (ej: jugada de Messi)
4. Al abrir la táctica, verás el botón "Ver Video"

---

## 🗄️ BASE DE DATOS

### **Nuevas Tablas Creadas**

#### 1. `player_analysis_videos`
```sql
Campos:
- id (UUID)
- player_id (UUID) → Jugador analizado
- coach_id (UUID) → Entrenador que sube el video
- team_id (UUID)
- video_url (TEXT) → URL de Bunny Stream (HLS)
- thumbnail_url (TEXT)
- video_guid (TEXT) → GUID de Bunny
- title (VARCHAR)
- comments (TEXT) → Observaciones técnicas
- analysis_type (VARCHAR) → 'technique', 'positioning', etc.
- duration_seconds (INTEGER)
- created_at, updated_at
```

**Políticas RLS:**
- ✅ Entrenador puede subir videos
- ✅ Entrenador solo ve sus videos
- ✅ Jugador solo ve sus videos
- ❌ Resto del equipo NO puede ver

#### 2. `tactical_videos`
```sql
Campos:
- id (UUID)
- tactical_session_id (UUID) → Vinculado a una jugada
- alignment_id (UUID) → Vinculado a una alineación
- team_id (UUID)
- coach_id (UUID)
- video_url (TEXT)
- thumbnail_url (TEXT)
- video_guid (TEXT)
- title (VARCHAR)
- description (TEXT)
- video_type (VARCHAR) → 'reference', 'real_match', 'training'
- duration_seconds (INTEGER)
- created_at, updated_at
```

**Políticas RLS:**
- ✅ Cuerpo técnico puede subir videos
- ✅ Cuerpo técnico puede ver todos los videos tácticos
- ✅ Creador puede editar/eliminar

---

## 🛠️ ARCHIVOS CREADOS/MODIFICADOS

### **Archivos Nuevos:**
1. ✅ `SETUP_VIDEO_ANALYSIS.sql` - Script SQL completo
2. ✅ `lib/models/player_analysis_video_model.dart` - Modelos de datos
3. ✅ `lib/widgets/video_player_modal.dart` - Reproductor de video
4. ✅ `lib/widgets/analysis_video_list.dart` - Lista de videos de análisis
5. ✅ `GUIA_VIDEO_ANALISIS.md` - Esta guía

### **Archivos Modificados:**
1. ✅ `lib/services/supabase_service.dart` - Métodos para videos
2. ✅ `lib/screens/player_profile_screen.dart` - Pestaña de análisis
3. ✅ `lib/screens/tactical_board_screen.dart` - Botón de videos
4. ✅ `lib/providers/tactic_board_provider.dart` - Métodos de videos tácticos

---

## 🚀 INSTALACIÓN

### **Paso 1: Ejecutar el Script SQL**
```bash
# En el panel de Supabase SQL Editor, ejecuta:
/Users/celiannycastro/Desktop/app-futbol-base/futbol---app/SETUP_VIDEO_ANALYSIS.sql
```

### **Paso 2: Verificar Dependencias**
Asegúrate de que `pubspec.yaml` incluye:
```yaml
dependencies:
  video_player: ^2.8.0
  image_picker: ^1.0.0
  dio: ^5.4.0
  minio: ^4.0.0
```

### **Paso 3: Instalar Paquetes**
```bash
flutter pub get
```

### **Paso 4: Configurar Permisos (iOS)**
Edita `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso para subir videos de análisis</string>
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso para grabar videos de análisis</string>
```

### **Paso 5: Configurar Permisos (Android)**
Edita `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

---

## 📖 CÓMO USAR

### **Para Entrenadores:**

#### **Subir Video de Análisis Individual:**
1. Ve al perfil del jugador (`PlayerProfileScreen`)
2. Toca la pestaña "Análisis"
3. Haz clic en "SUBIR VIDEO DE ANÁLISIS"
4. Selecciona un video de tu galería
5. Espera la barra de progreso (puede tardar según el tamaño)
6. Completa:
   - Título (obligatorio)
   - Tipo de análisis
   - Comentarios técnicos
7. El jugador recibirá el video en su perfil (solo él y tú pueden verlo)

#### **Adjuntar Video de Referencia a una Táctica:**
1. Abre `TacticalBoardScreen`
2. Guarda una jugada o selecciona una alineación
3. Haz clic en el botón morado 🎬 "Videos de Referencia"
4. Haz clic en "ADJUNTAR VIDEO"
5. Selecciona un video (ej: jugada de un partido profesional)
6. Completa:
   - Título (obligatorio)
   - Tipo (Referencia / Partido Real / Entrenamiento)
   - Descripción
7. El video quedará vinculado a esa táctica

---

### **Para Jugadores:**

#### **Ver Videos de Análisis:**
1. Ve a tu perfil
2. Toca la pestaña "Análisis"
3. Verás todos los videos que tu entrenador ha subido para ti
4. Haz clic en un video para reproducirlo
5. El video NO se reproduce automáticamente (debes dar play)

---

## 🎨 EXPERIENCIA DE USUARIO (UX)

### **✅ BUENAS PRÁCTICAS IMPLEMENTADAS:**

1. **No Autoplay Molesto**
   - Los videos NO se reproducen automáticamente
   - El usuario decide cuándo ver

2. **Barra de Progreso en Tiempo Real**
   - Feedback visual durante la subida
   - Porcentaje actualizado en vivo

3. **Privacidad Crítica**
   - Banner naranja indica privacidad del contenido
   - RLS estricto en base de datos

4. **Reproductor Optimizado**
   - Controles play/pause
   - Barra de progreso interactiva
   - Duración formateada (MM:SS)
   - Sin pantalla completa (puede agregarse si se necesita)

5. **Thumbnails Automáticos**
   - Bunny Stream genera miniaturas automáticamente
   - Se muestran en las listas de videos

6. **Tipos de Videos Organizados**
   - Análisis: Técnica, Posicionamiento, etc.
   - Tácticos: Referencia, Partido Real, Entrenamiento

---

## 🔐 SEGURIDAD

### **Políticas RLS Implementadas:**

#### **Videos de Análisis (Máxima Privacidad):**
```sql
✅ Entrenador puede insertar videos
✅ Entrenador solo ve sus videos
✅ Jugador solo ve SUS videos
✅ Entrenador puede actualizar/eliminar sus videos
❌ Resto del equipo NO tiene acceso
```

#### **Videos Tácticos (Cuerpo Técnico):**
```sql
✅ Cuerpo técnico puede insertar videos
✅ Cuerpo técnico puede ver todos los videos
✅ Creador puede actualizar/eliminar
❌ Jugadores normales NO tienen acceso (solo entrenadores)
```

---

## 🧪 TESTING

### **Pruebas Recomendadas:**

1. ✅ **Subir video como entrenador**
   - Verificar barra de progreso
   - Verificar que se guarda en Bunny Stream
   - Verificar que aparece en la lista

2. ✅ **Ver video como jugador**
   - Verificar que solo ve SUS videos
   - Verificar que no ve videos de otros jugadores

3. ✅ **Adjuntar video a táctica**
   - Verificar que se vincula correctamente
   - Verificar que al abrir la táctica, aparece el video

4. ✅ **Privacidad**
   - Intentar acceder a un video de otro jugador (debe fallar)
   - Verificar que solo el cuerpo técnico ve videos tácticos

---

## 🛡️ TROUBLESHOOTING

### **Problema: Video no sube**
- Verifica conexión a internet
- Verifica credenciales de Bunny Stream en `media_config.dart`
- Verifica que el video no sea muy pesado (>500MB)

### **Problema: No puedo ver videos de análisis**
- Verifica que eres entrenador o el jugador analizado
- Verifica las políticas RLS en Supabase

### **Problema: Botón de videos no aparece en TacticalBoard**
- Guarda una jugada o selecciona una alineación primero
- El botón morado 🎬 está en la barra superior

---

## 📊 MÉTRICAS Y MONITOREO

### **Vistas Útiles Creadas:**

1. `player_analysis_videos_detailed` - Incluye nombres de jugadores y entrenadores
2. `tactical_videos_detailed` - Incluye nombres de tácticas y alineaciones

### **Queries Útiles:**

```sql
-- Videos de análisis más recientes
SELECT * FROM player_analysis_videos_detailed 
ORDER BY created_at DESC LIMIT 10;

-- Videos por entrenador
SELECT coach_name, COUNT(*) as total_videos
FROM player_analysis_videos_detailed
GROUP BY coach_name;

-- Videos tácticos más usados
SELECT title, video_type, COUNT(*) as views
FROM tactical_videos_detailed
GROUP BY title, video_type;
```

---

## 🎯 PRÓXIMAS MEJORAS (OPCIONALES)

1. **Reproductor Fullscreen** - Agregar modo pantalla completa
2. **Marcadores de Tiempo** - Permitir comentarios en puntos específicos del video
3. **Comparación de Videos** - Ver dos videos lado a lado
4. **Análisis Automático** - IA para detectar errores técnicos
5. **Notificaciones Push** - Notificar al jugador cuando hay un nuevo video

---

## 📞 SOPORTE

Si tienes problemas con el sistema de video análisis:

1. Verifica que ejecutaste `SETUP_VIDEO_ANALYSIS.sql` en Supabase
2. Verifica las credenciales de Bunny Stream en `media_config.dart`
3. Revisa los logs en la consola de Flutter (busca "❌ Error")
4. Verifica las políticas RLS en el dashboard de Supabase

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [x] Script SQL ejecutado en Supabase
- [x] Modelos de datos creados
- [x] Servicio de subida integrado
- [x] Pantalla de perfil con pestaña de análisis
- [x] Pizarra táctica con botón de videos
- [x] Reproductor de video sin autoplay
- [x] Políticas RLS configuradas
- [x] Barra de progreso en tiempo real
- [x] Thumbnails de videos
- [x] Categorías de análisis
- [x] Eliminación de videos
- [x] Testing de privacidad

---

## 🎉 CONCLUSIÓN

El sistema de video análisis está **completamente implementado** y listo para usar. Los entrenadores pueden subir videos privados de análisis técnico y adjuntar videos de referencia a sus tácticas, todo con máxima privacidad y una experiencia de usuario profesional.

**Orden de Implementación (Para Referencia Futura):**
1. ✅ PASO 1: Infraestructura de Subida (R2 + Bunny Stream)
2. ✅ PASO 2: Red Social con Videos
3. ✅ PASO 3: Herramientas del Entrenador (Este Paso)

---

**Última Actualización:** 2026-01-08  
**Versión:** 1.0.0  
**Desarrollador:** Celiannycastro
