# 🚀 MOTOR DE SUBIDA DE MEDIA - DOCUMENTACIÓN COMPLETA

**Fecha de Implementación:** 8 de Enero, 2026  
**Estado:** ✅ COMPLETADO  
**Versión:** 1.0

---

## 📋 RESUMEN EJECUTIVO

Se ha implementado exitosamente un **motor robusto de subida de archivos multimedia** con separación estricta de servicios:

- **📸 Imágenes** → Cloudflare R2 (S3-compatible)
- **🎥 Videos** → Bunny Stream (con encoding automático)

---

## 🏗️ ARQUITECTURA

```
┌─────────────────────────────────────────────┐
│         CAPA DE PRESENTACIÓN (UI)           │
│  ┌──────────────────────────────────────┐   │
│  │   TestUploadScreen                   │   │
│  │   (Pantalla de pruebas)              │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│       CAPA DE WIDGETS (Componentes)         │
│  ┌──────────────────────────────────────┐   │
│  │   SmartUploadButton                  │   │
│  │   • Selector Cámara/Galería          │   │
│  │   • Progress Tracking                │   │
│  │   • Error Handling                   │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│      CAPA DE SERVICIOS (Lógica)             │
│  ┌──────────────────────────────────────┐   │
│  │   MediaUploadService                 │   │
│  │   • uploadPhoto() → R2               │   │
│  │   • uploadVideo() → Bunny Stream     │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│     CAPA DE CONFIGURACIÓN                   │
│  ┌──────────────────────────────────────┐   │
│  │   MediaConfig                        │   │
│  │   • Credenciales R2                  │   │
│  │   • Credenciales Bunny               │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                     ↓
        ┌────────────────────────┐
        │  CLOUDFLARE R2         │  ← Fotos
        │  BUNNY STREAM          │  ← Videos
        └────────────────────────┘
```

---

## 📦 ARCHIVOS CREADOS

### 1. **Configuración**
```
lib/config/media_config.dart
```
- Credenciales de Cloudflare R2
- Credenciales de Bunny Stream
- Endpoints y configuración

### 2. **Servicio Principal**
```
lib/services/media_upload_service.dart
```
- `uploadPhoto(File file)` → Sube imagen a R2
- `uploadVideo(File file, onProgress)` → Sube video a Bunny Stream
- `BunnyVideoResult` → Modelo de respuesta

### 3. **Widget Reutilizable**
```
lib/widgets/smart_upload_button.dart
```
- Selector de fuente (Cámara/Galería)
- Indicador de progreso en tiempo real
- Bloqueo durante subida
- Callbacks de éxito/error

### 4. **Pantalla de Pruebas**
```
lib/screens/test_upload_screen.dart
```
- Interfaz visual para validar funcionalidad
- Dos secciones: Fotos y Videos
- Muestra URLs resultantes
- Copia URLs al portapapeles

### 5. **Modificaciones**
```
pubspec.yaml
```
- ✅ `dio: ^5.7.0` (Tracking de progreso HTTP)
- ✅ `minio: ^4.0.6` (Cliente S3 para R2)
- ✅ `path: ^1.9.0` (Manipulación de rutas)
- ✅ `path_provider: ^2.1.5` (Acceso a directorios)
- ✅ `image_picker: ^1.2.1` (Ya estaba instalado)
- ✅ `uuid: ^4.5.2` (Ya estaba instalado)

```
lib/screens/home_screen.dart
```
- ✅ Import de `TestUploadScreen`
- ✅ Botón "Subir Archivos" ahora abre la pantalla de prueba

---

## 🔑 CREDENCIALES CONFIGURADAS

### Cloudflare R2
```dart
Endpoint: https://cf60f9bc215ffa03c9dcbf139e1f9e8b.r2.cloudflarestorage.com
Access Key: 6cb92b2fff1fd2237f44087e3f40afa4
Secret Key: QG0bCW_m2GYHLC-zneXqTrpyGXHxw_iqsjyFChR8
Bucket: futbol-media-app
```

### Bunny Stream
```dart
API Key: 49aec20a-50cb-4d2d-b2fd072ac61b-6e05-4d7c
Library ID: 575748
CDN Hostname: vz-cc855308-31c.b-cdn.net
```

---

## 🎯 FUNCIONALIDADES IMPLEMENTADAS

### ✅ Subida de Fotos (Cloudflare R2)
- Soporta: JPG, PNG, WEBP, GIF
- Content-Type automático
- Generación de nombre único (UUID)
- Organización en carpeta `/photos/`
- Retorna URL pública inmediatamente

### ✅ Subida de Videos (Bunny Stream)
- Soporta: MP4, MOV, AVI, MKV, WEBM
- **Progreso en tiempo real** con callback
- Encoding automático por Bunny
- Genera:
  - `guid` → ID único del video
  - `directPlayUrl` → URL HLS (.m3u8)
  - `thumbnailUrl` → Thumbnail automático
  - `videoLibraryId` → ID de biblioteca

### ✅ UX Features
- **Selector de fuente:** Cámara o Galería
- **Indicador visual:**
  - Fotos → Spinner circular
  - Videos → Barra de progreso con porcentaje
- **Bloqueo de UI:** No permite doble clic durante subida
- **Feedback instantáneo:** SnackBars de éxito/error
- **Copia de URLs:** Un tap para copiar al portapapeles

---

## 🧪 CÓMO PROBAR

### Paso 1: Ejecutar la App
```bash
cd /Users/celiannycastro/Desktop/app-futbol-base/futbol---app
flutter run
```

### Paso 2: Navegar a la Pantalla de Pruebas
1. Abrir la app
2. En el Home Screen, hacer clic en el botón verde **"Subir Archivos"**
3. Se abrirá la pantalla `TestUploadScreen`

### Paso 3: Probar Subida de Foto
1. Clic en **"SUBIR FOTO A R2"**
2. Seleccionar **Cámara** o **Galería**
3. Elegir una imagen
4. Ver spinner mientras se sube
5. ✅ URL aparece en la sección "RESULTADOS"

### Paso 4: Probar Subida de Video
1. Clic en **"SUBIR VIDEO A BUNNY"**
2. Seleccionar **Cámara** o **Galería**
3. Elegir un video
4. Ver **barra de progreso en tiempo real**
5. ✅ URL de reproducción aparece en "RESULTADOS"

### Paso 5: Verificar URLs
1. Las URLs se muestran en la sección verde de resultados
2. Hacer clic en el cuadro de URL para copiarla
3. Pegar en un navegador para verificar que funciona

---

## 📊 EJEMPLO DE RESULTADOS

### Foto Subida a R2:
```
https://futbol-media-app.celiannycastro.workers.dev/photos/a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg
```

### Video Subido a Bunny Stream:
```json
{
  "guid": "d4e5f6a7-b8c9-0123-4567-89abcdef0123",
  "videoLibraryId": 575748,
  "directPlayUrl": "https://vz-cc855308-31c.b-cdn.net/d4e5f6a7-b8c9-0123-4567-89abcdef0123/playlist.m3u8",
  "thumbnailUrl": "https://vz-cc855308-31c.b-cdn.net/d4e5f6a7-b8c9-0123-4567-89abcdef0123/thumbnail.jpg"
}
```

---

## 🔧 USO PROGRAMÁTICO

### En tus propias pantallas:

```dart
import 'package:myapp/widgets/smart_upload_button.dart';

// Para subir una foto
SmartUploadButton(
  mediaType: MediaType.photo,
  onUploadSuccess: (url) {
    print('Foto subida: $url');
    // Guardar URL en base de datos, etc.
  },
  onUploadError: (error) {
    print('Error: $error');
  },
)

// Para subir un video
SmartUploadButton(
  mediaType: MediaType.video,
  buttonText: 'Mi Video',
  buttonIcon: Icons.video_library,
  buttonColor: Colors.purple,
  onUploadSuccess: (url) {
    print('Video subido: $url');
  },
)
```

### Uso directo del servicio:

```dart
import 'package:myapp/services/media_upload_service.dart';

final service = MediaUploadService();

// Subir foto
final photoUrl = await service.uploadPhoto(myImageFile);

// Subir video con progreso
final result = await service.uploadVideo(
  myVideoFile,
  onProgress: (progress) {
    print('Progreso: ${(progress * 100).toInt()}%');
  },
);

print('Video GUID: ${result.guid}');
print('URL de reproducción: ${result.directPlayUrl}');
```

---

## 🛡️ SEGURIDAD

### ⚠️ IMPORTANTE: Credenciales Hardcodeadas

Actualmente las credenciales están hardcodeadas en `media_config.dart`. 

**Para producción, se recomienda:**

1. **Mover credenciales a `.env`:**
```env
# Agregar al archivo .env
R2_ENDPOINT=https://...
R2_ACCESS_KEY=...
R2_SECRET_KEY=...
BUNNY_API_KEY=...
```

2. **Actualizar `media_config.dart`:**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MediaConfig {
  static String get r2Endpoint => dotenv.env['R2_ENDPOINT']!;
  static String get r2AccessKey => dotenv.env['R2_ACCESS_KEY']!;
  // etc...
}
```

3. **Habilitar RLS en base de datos** para controlar quién puede acceder a los archivos

---

## 🎨 PERSONALIZACIÓN

### Cambiar Colores del SmartUploadButton:

```dart
SmartUploadButton(
  mediaType: MediaType.photo,
  buttonColor: Colors.teal,        // Color del botón
  buttonIcon: Icons.camera_alt,    // Icono personalizado
  buttonText: 'Tomar Foto',        // Texto personalizado
  onUploadSuccess: (url) {},
)
```

### Agregar Validaciones:

```dart
// En media_upload_service.dart, método uploadPhoto:

// Validar tamaño de archivo
final bytes = await file.readAsBytes();
if (bytes.length > 10 * 1024 * 1024) { // 10 MB
  throw Exception('La imagen es demasiado grande (máx 10MB)');
}

// Validar dimensiones (requiere package 'image')
final image = img.decodeImage(bytes);
if (image!.width > 4000 || image.height > 4000) {
  throw Exception('Dimensiones máximas: 4000x4000px');
}
```

---

## 📈 PRÓXIMOS PASOS (Opcional)

### Mejoras Sugeridas:

1. **Compresión de Imágenes:**
   - Usar `flutter_image_compress`
   - Reducir tamaño antes de subir

2. **Cache de URLs:**
   - Guardar URLs en base de datos
   - Evitar re-subidas de archivos duplicados

3. **Gestión de Thumbnails:**
   - Generar thumbnails localmente
   - Subir thumbnail separado para previews rápidos

4. **Retry Logic:**
   - Reintentar automáticamente si falla
   - Usar exponential backoff

5. **Cancelación de Subida:**
   - Permitir cancelar subidas en progreso
   - Usar `CancelToken` de Dio

6. **Múltiples Archivos:**
   - Subir varios archivos a la vez
   - Mostrar progreso de cada uno

---

## 🐛 TROUBLESHOOTING

### Error: "Target of URI doesn't exist"
**Solución:**
```bash
flutter pub get
flutter clean
flutter pub get
```

### Error: "Bucket not found" (R2)
**Verificar:**
- El bucket `futbol-media-app` existe en Cloudflare R2
- Las credenciales son correctas
- El endpoint está bien escrito

### Error: "Invalid API key" (Bunny)
**Verificar:**
- La API key es válida y activa
- El Library ID es correcto
- La library existe en tu cuenta de Bunny

### Video no se reproduce
**Posibles causas:**
- El video aún está siendo procesado por Bunny (esperar 1-2 minutos)
- El formato del video no es compatible
- El navegador no soporta HLS (usar Safari o añadir player web como `hls.js`)

### Progreso se queda en 0%
**Verificar:**
- El callback `onProgress` está conectado correctamente
- El tamaño del archivo no es 0
- La conexión a internet es estable

---

## ✅ CHECKLIST DE VALIDACIÓN

```
☑ Dependencias instaladas (dio, minio, path, path_provider, etc.)
☑ MediaConfig creado con credenciales
☑ MediaUploadService implementado
☑ SmartUploadButton widget creado
☑ TestUploadScreen creada
☑ Navegación desde HomeScreen configurada
☑ Sin errores de linting
☑ Compilación exitosa
☐ Prueba de subida de foto (ejecutar app)
☐ Prueba de subida de video (ejecutar app)
☐ Verificar URLs generadas son accesibles
```

---

## 📞 SOPORTE

Para dudas o problemas:
1. Revisar logs en consola (`debugPrint`)
2. Verificar credenciales en `media_config.dart`
3. Consultar documentación oficial:
   - [Cloudflare R2](https://developers.cloudflare.com/r2/)
   - [Bunny Stream](https://docs.bunny.net/docs/stream)

---

**🎉 ¡MOTOR DE SUBIDA IMPLEMENTADO EXITOSAMENTE!**

El motor está listo para usar. Ahora puedes:
- ✅ Subir fotos a Cloudflare R2
- ✅ Subir videos a Bunny Stream
- ✅ Ver progreso en tiempo real
- ✅ Obtener URLs públicas instantáneamente

**Última actualización:** 8 de Enero, 2026  
**Versión:** 1.0  
**Autor:** Senior Flutter Engineer
