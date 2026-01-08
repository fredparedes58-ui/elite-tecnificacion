# ⚡ INICIO RÁPIDO: FÚTBOL SOCIAL

## 🚀 3 PASOS PARA PONER EN MARCHA EL MÓDULO

---

## PASO 1: CONFIGURAR BASE DE DATOS (5 minutos)

### 1.1 Abrir Supabase Dashboard

1. Ve a [https://supabase.com](https://supabase.com)
2. Abre tu proyecto
3. Navega a: **SQL Editor** (en el menú lateral)

### 1.2 Ejecutar Script

1. Crea una nueva query
2. Copia todo el contenido de `SETUP_SOCIAL_FEED.sql`
3. Pégalo en el editor
4. Click en **RUN** (o presiona F5)

### 1.3 Verificar

Deberías ver el mensaje:
```
Social Feed Setup completado exitosamente!
```

---

## PASO 2: INSTALAR DEPENDENCIAS (2 minutos)

Abre la terminal en la carpeta del proyecto y ejecuta:

```bash
flutter pub get
```

Espera a que descargue:
- ✅ video_player
- ✅ chewie
- ✅ cached_network_image
- ✅ timeago

---

## PASO 3: CONFIGURAR TEAM ID (IMPORTANTE)

### Opción A: Usar ID de Prueba (Para testing rápido)

Si solo quieres probar la funcionalidad, deja el ID de demo:

```dart
// Ya configurado en home_screen.dart
teamId: 'demo-team-id'
```

**NOTA:** Esto funcionará pero necesitarás crear un equipo con ese ID en Supabase.

### Opción B: Obtener ID Real del Usuario (Producción)

**Recomendado para producción:**

1. Crea un Provider de autenticación (si no existe):

```dart
// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  String? get currentUserId => _supabase.auth.currentUser?.id;
  
  Future<String?> getCurrentTeamId() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    final response = await _supabase
        .from('team_members')
        .select('team_id')
        .eq('user_id', userId)
        .maybeSingle();
    
    return response?['team_id'] as String?;
  }
}
```

2. Actualiza `home_screen.dart`:

```dart
// En lugar de:
teamId: 'demo-team-id'

// Usa:
FutureBuilder<String?>(
  future: Provider.of<AuthProvider>(context, listen: false).getCurrentTeamId(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return SocialFeedScreen(teamId: snapshot.data!);
  },
)
```

---

## 🎯 TESTING RÁPIDO

### Opción 1: Crear Equipo de Demo en Supabase

```sql
-- Ejecuta esto en SQL Editor de Supabase

-- 1. Crear equipo de prueba
INSERT INTO teams (id, name, category) 
VALUES ('demo-team-id', 'Equipo Demo', 'Sub-17');

-- 2. Agregar tu usuario al equipo
-- Reemplaza 'TU_USER_ID' con tu UUID de auth.users
INSERT INTO team_members (user_id, team_id, role, user_full_name)
VALUES ('TU_USER_ID', 'demo-team-id', 'coach', 'Entrenador Demo');

-- 3. Crear un post de ejemplo
INSERT INTO social_posts (
  team_id, 
  user_id, 
  content_text, 
  media_url, 
  media_type
)
VALUES (
  'demo-team-id',
  'TU_USER_ID',
  '¡Primer post de prueba! 🎉⚽',
  'https://images.unsplash.com/photo-1579952363873-27f3bade9f55',
  'image'
);
```

### Opción 2: Usar la App para Crear Post

1. Ejecuta la app: `flutter run`
2. Navega a "Fútbol Social" desde el Home
3. Toca el FAB "COMPARTIR"
4. Selecciona una foto
5. Escribe una descripción
6. Toca "PUBLICAR AHORA"

---

## ✅ CHECKLIST DE VERIFICACIÓN

Marca cada item cuando funcione:

- [ ] ✅ Script SQL ejecutado sin errores
- [ ] ✅ Dependencias instaladas (`flutter pub get`)
- [ ] ✅ App compila sin errores
- [ ] ✅ Puedes navegar a "Fútbol Social"
- [ ] ✅ Ves el estado vacío ("Aún no hay publicaciones")
- [ ] ✅ Puedes abrir "Crear Post"
- [ ] ✅ Puedes seleccionar una foto
- [ ] ✅ La vista previa se muestra correctamente
- [ ] ✅ Puedes publicar el post
- [ ] ✅ El post aparece en el feed
- [ ] ✅ Puedes dar like al post
- [ ] ✅ El contador de likes se actualiza

---

## 🐛 SOLUCIÓN DE PROBLEMAS COMUNES

### Error: "relation 'social_posts' does not exist"

**Causa:** El script SQL no se ejecutó correctamente.

**Solución:**
1. Verifica que estás en el proyecto correcto de Supabase
2. Ejecuta el script `SETUP_SOCIAL_FEED.sql` completo
3. Revisa la consola de errores en Supabase

---

### Error: "No rows found for maybeSingle()"

**Causa:** El usuario no está asignado a ningún equipo.

**Solución:**
```sql
-- Agrega tu usuario a un equipo
INSERT INTO team_members (user_id, team_id, role, user_full_name)
VALUES ('TU_USER_ID', 'TU_TEAM_ID', 'coach', 'Tu Nombre');
```

---

### Error: "Failed to load image"

**Causa:** URL de imagen inválida o problemas de red.

**Solución:**
1. Verifica que la URL es accesible
2. Usa URLs de prueba como:
   - `https://images.unsplash.com/photo-1579952363873-27f3bade9f55`
   - `https://picsum.photos/800/600`

---

### El feed está vacío

**Causa:** No hay posts para ese equipo.

**Solución:**
1. Crea un post desde la app
2. O inserta uno manualmente con el SQL de arriba

---

### Los likes no funcionan

**Causa:** Problemas con RLS o usuario no autenticado.

**Solución:**
1. Verifica que estás logueado: `Supabase.instance.client.auth.currentUser`
2. Revisa las políticas RLS en Supabase Dashboard
3. Verifica que el usuario es miembro del equipo

---

## 📱 PRÓXIMOS PASOS

Después de verificar que todo funciona:

1. **Implementar Subida Real de Media:**
   - Integrar con R2/Bunny/Supabase Storage
   - Ver: `MEDIA_UPLOAD_ENGINE.md`

2. **Agregar Video Player:**
   - Implementar reproductor con `chewie`
   - Generar thumbnails automáticos

3. **Sistema de Comentarios:**
   - Crear tabla `social_post_comments`
   - Pantalla de detalle del post

4. **Notificaciones:**
   - Cuando alguien da like
   - Cuando hay un nuevo post

---

## 🎉 ¡LISTO!

Si completaste todos los pasos, tu módulo de Fútbol Social está funcionando.

Para más detalles, consulta: **`GUIA_FUTBOL_SOCIAL.md`**

---

**⚽ ¡A compartir momentos del equipo! 📸**
