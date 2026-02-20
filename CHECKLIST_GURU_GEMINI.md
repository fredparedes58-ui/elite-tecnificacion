# ✅ CHECKLIST: INSTALACIÓN GURU GEMINI

## 📋 Checklist de Instalación Completa

### ✅ PASO 1: Ejecutar SQL (Dashboard de Supabase)

- [ ] Abrir Dashboard de Supabase: https://app.supabase.com
- [ ] Seleccionar proyecto
- [ ] Ir a **SQL Editor** (menú lateral izquierdo)
- [ ] Click en **"New query"**
- [ ] Abrir archivo `SETUP_GURU_POSTS.sql`
- [ ] Copiar TODO el contenido del archivo
- [ ] Pegar en el editor SQL
- [ ] Click en **"Run"** (botón verde)
- [ ] Verificar mensajes de éxito:
  ```
  ✅ Tabla guru_posts creada correctamente
  ✅ Índices creados
  ✅ RLS habilitado
  ```

**Archivo necesario:** `SETUP_GURU_POSTS.sql`

---

### ✅ PASO 2: Configurar Secreto GEMINI_API_KEY

- [ ] Ir a Dashboard → **Settings** → **Edge Functions** → **Secrets**
- [ ] Click en **"Add new secret"**
- [ ] Agregar:
  - **Name:** `GEMINI_API_KEY`
  - **Value:** Tu API Key de Google Gemini
- [ ] Click en **"Save"**

**Obtener API Key:**
- Visitar: https://makersuite.google.com/app/apikey
- Crear nueva API Key si no tienes una
- Copiar la API Key

---

### ✅ PASO 3: Desplegar Edge Function

**Opción A: Dashboard (Recomendado)**

- [ ] Ir a Dashboard → **Edge Functions**
- [ ] Click en **"Create a new function"** o **"New function"**
- [ ] Nombre: `generate_match_report_gemini`
- [ ] Abrir archivo: `supabase/functions/generate_match_report_gemini/index.ts`
- [ ] Copiar TODO el contenido del archivo
- [ ] Pegar en el editor de código de la función
- [ ] Click en **"Deploy"** o **"Save & Deploy"**
- [ ] Esperar confirmación de despliegue exitoso

**Opción B: CLI (si tienes Supabase CLI instalado)**

```bash
# Desde la raíz del proyecto
supabase functions deploy generate_match_report_gemini
```

- [ ] Ejecutar comando
- [ ] Verificar mensaje de éxito

**Archivo necesario:** `supabase/functions/generate_match_report_gemini/index.ts`

---

### ✅ PASO 4: Verificar Instalación

**Verificar tabla en Supabase:**
- [ ] Ir a Dashboard → **Table Editor**
- [ ] Verificar que existe la tabla `guru_posts`
- [ ] Verificar columnas: `id`, `match_id`, `content`, `audience`, `status`, `created_at`, `updated_at`

**Verificar función:**
- [ ] Ir a Dashboard → **Edge Functions**
- [ ] Verificar que existe `generate_match_report_gemini`
- [ ] Verificar estado: "Active" o "Deployed"

**Verificar secreto:**
- [ ] Ir a Dashboard → **Settings** → **Edge Functions** → **Secrets**
- [ ] Verificar que existe `GEMINI_API_KEY`

---

### ✅ PASO 5: Probar en la App

- [ ] Ejecutar la app Flutter: `flutter run`
- [ ] Navegar a: **Partidos**
- [ ] Seleccionar un partido con estado **"FINISHED"** (Finalizado)
- [ ] Click en **"REGISTRAR ESTADÍSTICAS"**
- [ ] Verificar que aparece el botón **"GURU GURU"** (morado, debajo de "GUARDAR ESTADÍSTICAS")
- [ ] Click en **"GURU GURU"**
- [ ] Esperar 15-30 segundos (generación con Gemini)
- [ ] Verificar mensaje de éxito: "✅ Informes generados correctamente con Gemini AI"

**Verificar datos generados:**
- [ ] Ir a Dashboard → **Table Editor** → `guru_posts`
- [ ] Verificar que se crearon 2 registros:
  - Uno con `audience='coach'`
  - Uno con `audience='family'`
- [ ] Verificar que `status='draft'`
- [ ] Verificar que `match_id` corresponde al partido seleccionado
- [ ] Leer el contenido de ambos posts

---

## 🐛 Resolución de Problemas

### Error: "GEMINI_API_KEY no está configurada"
- ✅ Verificar que el secreto está configurado en Dashboard
- ✅ Verificar que el nombre es exactamente: `GEMINI_API_KEY` (sin espacios)

### Error: "Partido no encontrado"
- ✅ Verificar que el `match_id` existe en la tabla `matches`
- ✅ Verificar que el partido tiene datos (estadísticas o eventos)

### Error: "Error al generar informes"
- ✅ Verificar que la API Key de Gemini es válida
- ✅ Verificar conexión a internet
- ✅ Revisar logs de la Edge Function en Dashboard

### Error: "Error al guardar posts"
- ✅ Verificar que la tabla `guru_posts` existe
- ✅ Verificar que se ejecutó el SQL correctamente
- ✅ Revisar políticas RLS (la función usa service_role, debería funcionar)

---

## 📚 Documentación Adicional

- **Guía completa:** `GUIA_GEMINI_REPORTS.md`
- **Script SQL:** `SETUP_GURU_POSTS.sql`
- **Código función:** `supabase/functions/generate_match_report_gemini/index.ts`
- **Pantalla Flutter:** `lib/screens/match_report_screen.dart`

---

## ⏱️ Tiempo Estimado

- **PASO 1 (SQL):** 2 minutos
- **PASO 2 (Secreto):** 3 minutos (incluye obtener API Key si no la tienes)
- **PASO 3 (Desplegar):** 5 minutos
- **PASO 4 (Verificar):** 3 minutos
- **PASO 5 (Probar):** 5 minutos

**Total:** ~18 minutos

---

**ÚLTIMA ACTUALIZACIÓN:** 2026-01-08
