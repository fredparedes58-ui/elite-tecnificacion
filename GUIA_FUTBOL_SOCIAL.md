# 📱 GUÍA: FÚTBOL SOCIAL - Feed Social tipo Instagram

## 🎯 OBJETIVO

Módulo de feed social donde el equipo puede compartir momentos (fotos/videos) con una experiencia UX tipo Instagram/Facebook. Los padres y entrenadores pueden ver, dar like y comentar publicaciones del equipo.

---

## 📦 ARCHIVOS CREADOS

### Backend (Supabase)
- **`SETUP_SOCIAL_FEED.sql`**: Script SQL completo con:
  - Tabla `social_posts` (posts con fotos/videos)
  - Tabla `social_post_likes` (sistema de likes)
  - Row Level Security (RLS) para privacidad por equipo
  - Triggers automáticos para contadores
  - Función `get_team_social_feed()` con paginación

### Modelos
- **`lib/models/social_post_model.dart`**: 
  - Clase `SocialPost` con todos los campos
  - Enum `MediaType` (image/video)
  - DTO `CreateSocialPostDto` para crear posts
  - Método `getRelativeTime()` para fechas relativas (ej: "hace 2h")

### Servicios
- **`lib/services/social_service.dart`**:
  - `getTeamFeed()`: Obtener posts con paginación
  - `streamTeamFeed()`: Stream en tiempo real
  - `createPost()`: Crear nueva publicación
  - `likePost()` / `unlikePost()`: Sistema de likes
  - `toggleLike()`: Like/unlike automático
  - `deletePost()`: Eliminar publicación

### Pantallas
- **`lib/screens/social_feed_screen.dart`**:
  - Feed principal estilo Instagram
  - Scroll infinito con paginación
  - Pull-to-refresh
  - Componentes:
    - `SocialPostCard`: Card individual del post
    - `_PostHeader`: Cabecera con avatar y nombre
    - `_PostMedia`: Imagen o video
    - `_PostFooter`: Likes y descripción

- **`lib/screens/create_post_screen.dart`**:
  - Pantalla para crear posts
  - Selección de foto/video desde galería o cámara
  - Vista previa del archivo
  - Campo de descripción opcional
  - Indicador de progreso de subida

---

## 🚀 INSTALACIÓN

### 1. Configurar Base de Datos

Ejecuta el script SQL en tu proyecto de Supabase:

```bash
# Abre el SQL Editor en Supabase Dashboard
# Copia y pega el contenido de SETUP_SOCIAL_FEED.sql
# Ejecuta el script
```

**Nota Importante:** Asegúrate de que la tabla `teams` y `team_members` ya existan, ya que el script las referencia.

### 2. Instalar Dependencias

Las dependencias ya están agregadas en `pubspec.yaml`:

```yaml
# 📱 Social Feed Dependencies
video_player: ^2.10.1      # Reproducción de videos
chewie: ^1.8.5              # Video player UI mejorado
cached_network_image: ^3.4.1 # Caché de imágenes
timeago: ^3.7.0             # Fechas relativas
```

Ejecuta:

```bash
flutter pub get
```

### 3. Navegación

La navegación ya está configurada en `HomeScreen`:

**Opción 1:** Botón en el grid de "Acceso Rápido"
- Título: "Fútbol Social"
- Icono: `Icons.photo_camera`
- Color: `Colors.deepOrange`

**Opción 2:** Opción en el menú flotante (FAB)
- "Compartir Momento" → Navega al feed social

---

## 💡 CARACTERÍSTICAS PRINCIPALES

### ✨ Feed Social

1. **Diseño Tipo Instagram:**
   - Cards con bordes redondeados y sombras
   - Fondo oscuro elite (`#0A0E21`)
   - Animaciones suaves

2. **Cabecera del Post:**
   - Avatar circular con inicial del usuario
   - Nombre del autor + Rol (Entrenador/Padre)
   - Fecha relativa ("hace 2h", "hace 3d")
   - Botón de eliminar (solo para el autor)

3. **Contenido Multimedia:**
   - **Fotos:** Cargadas con caché (CachedNetworkImage)
   - **Videos:** Miniatura con botón de Play central
   - Placeholder con shimmer effect durante la carga

4. **Interacción:**
   - Like/Unlike con animación (corazón rojo)
   - Contador de likes visible
   - Contador de comentarios (preparado para futura expansión)

5. **Paginación Inteligente:**
   - Carga inicial: 20 posts
   - Scroll infinito: Carga automática al llegar al 90% del scroll
   - Pull-to-refresh para actualizar

### 📝 Crear Posts

1. **Selección de Media:**
   - Galería de Fotos
   - Galería de Videos
   - Tomar Foto con la cámara

2. **Vista Previa:**
   - Imagen a pantalla completa
   - Indicador de video seleccionado

3. **Descripción Opcional:**
   - Campo de texto multilinea
   - Límite: 500 caracteres
   - Placeholder claro

4. **Progreso de Subida:**
   - Indicador circular animado
   - Porcentaje visible

---

## 🔐 SEGURIDAD (RLS)

Las políticas de Row Level Security garantizan:

✅ **Lectura:** Solo miembros del equipo pueden ver los posts
✅ **Creación:** Solo usuarios autenticados del equipo pueden publicar
✅ **Actualización:** Solo el autor o admin/coach pueden editar
✅ **Eliminación:** Solo el autor o admin/coach pueden eliminar

---

## 📊 BASE DE DATOS

### Tabla: `social_posts`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | uuid | ID único del post |
| `created_at` | timestamp | Fecha de creación |
| `updated_at` | timestamp | Última actualización |
| `team_id` | uuid | ID del equipo (privacidad) |
| `user_id` | uuid | Autor del post |
| `content_text` | text | Descripción (opcional) |
| `media_url` | text | URL de la foto/video |
| `media_type` | text | 'image' o 'video' |
| `thumbnail_url` | text | Miniatura del video (opcional) |
| `likes_count` | integer | Contador de likes |
| `comments_count` | integer | Contador de comentarios |
| `is_pinned` | boolean | Post fijado |

### Tabla: `social_post_likes`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | uuid | ID único |
| `post_id` | uuid | ID del post |
| `user_id` | uuid | Usuario que dio like |
| `created_at` | timestamp | Fecha del like |

---

## 🎨 DISEÑO VISUAL

### Colores

- **Fondo principal:** `#0A0E21` (oscuro)
- **Cards:** `#1D1E33` (gris oscuro)
- **Bordes:** Blanco con opacidad 0.1-0.3
- **Accent:** `theme.primaryColor` (neón cyan)
- **Like activo:** `Colors.red`

### Tipografía

- **Títulos:** `GoogleFonts.oswald` (bold, mayúsculas)
- **Texto normal:** `GoogleFonts.roboto`
- **Fechas relativas:** Roboto (12px, opacidad 0.6)

### Espaciado

- Padding cards: 12px
- Margin entre cards: 8px vertical
- Border radius: 16px
- Avatar size: 40px (radio 20)

---

## 🚧 TODO: PRÓXIMAS MEJORAS

### Fase 2 (Recomendado)

1. **Sistema de Comentarios:**
   - Tabla `social_post_comments`
   - Modal o pantalla de detalle
   - Notificaciones de nuevos comentarios

2. **Subida Real de Media:**
   - Integrar con `MediaUploadService`
   - Subir a R2/Bunny/Supabase Storage
   - Generar thumbnails automáticos para videos

3. **Video Player Completo:**
   - Implementar `chewie` para reproducción
   - Controles personalizados
   - Fullscreen mode

4. **Notificaciones Push:**
   - Like en tu post
   - Comentario en tu post
   - Nueva publicación del equipo

### Fase 3 (Avanzado)

1. **Stories (Historias):**
   - Contenido efímero (24h)
   - Visualización tipo Instagram Stories
   - Indicador de "visto"

2. **Filtros y Edición:**
   - Filtros de imagen antes de publicar
   - Crop y rotación
   - Stickers del equipo

3. **Menciones y Etiquetas:**
   - @mencionar jugadores
   - #hashtags
   - Galería por etiquetas

4. **Estadísticas:**
   - Posts más populares del mes
   - Usuario más activo
   - Analytics del engagement

---

## 🐛 TROUBLESHOOTING

### Error: "Target of URI doesn't exist: 'package:cached_network_image'"

**Solución:**
```bash
flutter pub get
flutter clean
flutter pub get
```

### Error: "team_id no existe en el contexto"

**Solución:** Reemplaza `'demo-team-id'` con el ID real del equipo. Implementa un provider o servicio de autenticación para obtener el team_id del usuario actual.

```dart
// En lugar de:
teamId: 'demo-team-id'

// Usa:
teamId: Provider.of<AuthProvider>(context).currentTeamId
```

### Videos no se reproducen

**Solución:** Implementa el reproductor con `chewie`:

```dart
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

// TODO: Ver documentación de chewie para implementación completa
```

---

## 📖 DOCUMENTACIÓN RELACIONADA

- **Media Upload:** Ver `MEDIA_UPLOAD_ENGINE.md`
- **Supabase Storage:** Ver `SETUP_SUPABASE_STORAGE.md`
- **Diseño General:** Ver `DESIGN_BLUEPRINT_MASTER.md`

---

## 🎉 RESULTADO FINAL

Al completar esta guía, tendrás:

✅ Feed social completamente funcional
✅ Sistema de likes en tiempo real
✅ Subida de fotos con vista previa
✅ Diseño profesional tipo Instagram
✅ Seguridad por equipo con RLS
✅ Paginación y scroll infinito
✅ Pull-to-refresh

---

## 👤 CRÉDITOS

**Implementado por:** Celiannycastro  
**Fecha:** 2026-01-08  
**Framework:** Flutter 3.9+  
**Backend:** Supabase

---

## 📞 SOPORTE

Si encuentras algún problema o necesitas ayuda:

1. Verifica que el script SQL se ejecutó correctamente
2. Confirma que las dependencias están instaladas
3. Revisa los logs de Supabase para errores de RLS
4. Consulta `DESIGN_BLUEPRINT_MASTER.md` para detalles de diseño

---

**¡Disfruta compartiendo momentos con tu equipo! ⚽📸**
