# 🤖 GUÍA: GENERADOR DE INFORMES CON GEMINI

## 📋 ÍNDICE
1. [Instalación](#instalación)
2. [Configuración](#configuración)
3. [Uso de la Función](#uso-de-la-función)
4. [Estructura de Datos](#estructura-de-datos)
5. [Arquitectura Técnica](#arquitectura-técnica)

---

## 🚀 INSTALACIÓN

### PASO 1: Crear la tabla guru_posts

1. Abre tu Dashboard de Supabase: https://app.supabase.com
2. Selecciona tu proyecto
3. Ve a **SQL Editor** (menú lateral izquierdo)
4. Click en **"New query"**
5. Copia **TODO** el contenido del archivo `SETUP_GURU_POSTS.sql`
6. Pega en el editor
7. Click en **"Run"** (botón verde)
8. Verifica que veas los mensajes de éxito:
   ```
   ✅ Tabla guru_posts creada correctamente
   ✅ Índices creados
   ✅ RLS habilitado
   ```

### PASO 2: Configurar el secreto GEMINI_API_KEY

**Opción A: Dashboard de Supabase (Recomendado)**
1. Ve a tu Dashboard: https://supabase.com/dashboard
2. Selecciona tu proyecto
3. Ve a **Settings** → **Edge Functions** → **Secrets**
4. Haz clic en **Add new secret**
5. Agrega:
   - **Name:** `GEMINI_API_KEY`
   - **Value:** Tu API Key de Google Gemini
6. Guarda

**Opción B: CLI de Supabase (si tienes Node.js instalado)**
```bash
npx supabase secrets set GEMINI_API_KEY=tu_api_key_aqui
```

### PASO 3: Desplegar la Edge Function

Si usas Supabase CLI:
```bash
# Desde la raíz del proyecto
supabase functions deploy generate_match_report_gemini
```

Si no tienes Supabase CLI, puedes desplegar manualmente:
1. Ve al Dashboard → **Edge Functions**
2. Crea una nueva función llamada `generate_match_report_gemini`
3. Copia el contenido de `supabase/functions/generate_match_report_gemini/index.ts`

---

## ⚙️ CONFIGURACIÓN

### Variables de Entorno Requeridas

- `GEMINI_API_KEY`: Tu API Key de Google Gemini
  - Obtener en: https://makersuite.google.com/app/apikey
  - Configurar como secreto en Supabase Edge Functions

### Permisos de la Función

La función usa `SUPABASE_SERVICE_ROLE_KEY` para:
- Consultar datos de `matches`, `analysis_events`, `match_stats`
- Insertar datos en `guru_posts`

---

## 📱 USO DE LA FUNCIÓN

### Desde Flutter (Dart)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> generateMatchReport(String matchId) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      'generate_match_report_gemini',
      body: {
        'match_id': matchId,
      },
    );

    if (response.status == 200) {
      final data = response.data as Map<String, dynamic>;
      print('✅ Informes generados correctamente');
      print('Coach Post ID: ${data['coach_post_id']}');
      print('Family Post ID: ${data['family_post_id']}');
    } else {
      print('❌ Error: ${response.data}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### Desde JavaScript/TypeScript

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function generateMatchReport(matchId: string) {
  const { data, error } = await supabase.functions.invoke(
    'generate_match_report_gemini',
    {
      body: { match_id: matchId },
    }
  );

  if (error) {
    console.error('Error:', error);
    return;
  }

  console.log('✅ Informes generados:', data);
}
```

### Desde cURL (Testing)

```bash
curl -X POST \
  'https://TU_PROYECTO.supabase.co/functions/v1/generate_match_report_gemini' \
  -H 'Authorization: Bearer TU_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"match_id": "uuid-del-partido"}'
```

---

## 📊 ESTRUCTURA DE DATOS

### Input (POST Body)

```json
{
  "match_id": "uuid-del-partido"
}
```

### Output (Success)

```json
{
  "success": true,
  "message": "Informes generados correctamente",
  "coach_post_id": "uuid-del-post-coach",
  "family_post_id": "uuid-del-post-family"
}
```

### Output (Error)

```json
{
  "error": "Mensaje de error descriptivo"
}
```

### Tabla: guru_posts

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | ID único del post |
| `match_id` | UUID | Referencia al partido |
| `content` | TEXT | Contenido del informe generado |
| `audience` | TEXT | `'coach'` o `'family'` |
| `status` | TEXT | `'draft'` o `'published'` (default: `'draft'`) |
| `created_at` | TIMESTAMPTZ | Fecha de creación |
| `updated_at` | TIMESTAMPTZ | Última actualización |

---

## 🏗️ ARQUITECTURA TÉCNICA

### Flujo de la Función

```
1. Recibe match_id vía POST
   ↓
2. Consulta datos del partido:
   - matches (datos del partido)
   - analysis_events (eventos cronológicos)
   - match_stats (estadísticas de jugadores)
   ↓
3. Construye prompt para Gemini con todos los datos
   ↓
4. Llama a Gemini API (gemini-1.5-flash)
   ↓
5. Parsea respuesta JSON con dos informes:
   - coach_report (técnico/táctico)
   - family_report (emocionante/celebratorio)
   ↓
6. Guarda en guru_posts (2 registros):
   - Post 1: audience='coach', status='draft'
   - Post 2: audience='family', status='draft'
   ↓
7. Retorna éxito con IDs de los posts
```

### Modelo de Gemini

- **Modelo:** `gemini-1.5-flash`
- **Configuración:**
  - Temperature: 0.7
  - Max Output Tokens: 2048
  - Response Format: JSON

### Seguridad

- ✅ CORS habilitado para requests desde la app
- ✅ RLS habilitado en `guru_posts`
- ✅ Service Role Key usado solo en Edge Function (no expuesto al cliente)
- ✅ API Key de Gemini guardada como secreto (no en código)

---

## 🐛 RESOLUCIÓN DE PROBLEMAS

### Error: "GEMINI_API_KEY no está configurada"
- **Solución:** Verifica que el secreto esté configurado en Supabase Dashboard → Edge Functions → Secrets

### Error: "Partido no encontrado"
- **Solución:** Verifica que el `match_id` sea válido y exista en la tabla `matches`

### Error: "Error al parsear respuesta de Gemini"
- **Solución:** Gemini a veces devuelve texto adicional. La función intenta limpiarlo automáticamente. Si persiste, verifica los logs de la función.

### Error: "Error al guardar posts"
- **Solución:** Verifica que la tabla `guru_posts` esté creada y que las políticas RLS permitan la inserción desde service_role.

---

## 📝 NOTAS ADICIONALES

- Los informes se guardan con `status='draft'` por defecto. Puedes actualizar el estado a `'published'` cuando estés listo.
- La función puede tardar varios segundos (15-30s) debido a la llamada a Gemini API.
- Los informes se generan cada vez que se llama la función (no hay caché). Considera implementar validación para evitar duplicados si es necesario.

---

**ÚLTIMA ACTUALIZACIÓN:** 2026-01-08  
**VERSIÓN:** 1.0.0
