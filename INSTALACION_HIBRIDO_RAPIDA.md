# ⚡ INSTALACIÓN RÁPIDA - SISTEMA HÍBRIDO

## 🎯 3 Pasos, 5 Minutos

---

## Paso 1: Base de Datos (2 minutos)

### Opción A: Supabase Dashboard (Recomendado)

1. Abre [Supabase Dashboard](https://app.supabase.com)
2. Selecciona tu proyecto
3. Ve a **SQL Editor** (icono de base de datos)
4. Crea una nueva query
5. Copia y pega el contenido de `SETUP_HYBRID_SYSTEM.sql`
6. Click en **Run** (o `Ctrl+Enter`)

**Esperado:**
```
✅ Sistema Híbrido configurado correctamente
```

### Opción B: CLI

```bash
# Desde la raíz del proyecto
psql -U postgres -d tu_base_de_datos -f SETUP_HYBRID_SYSTEM.sql
```

### Verificar

```sql
-- Ejecuta esto en SQL Editor
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'analysis_events'
  AND column_name IN ('match_timestamp', 'video_timestamp');
```

**Esperado:**
```
column_name      | data_type | is_nullable
-----------------+-----------+-------------
match_timestamp  | integer   | NO
video_timestamp  | integer   | YES
```

---

## Paso 2: Flutter (1 minuto)

### Verificar Dependencias

Abre `pubspec.yaml` y asegúrate de tener:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Ya deberías tenerlas (de ProMatch)
  supabase_flutter: ^2.0.0
  google_fonts: ^6.1.0
  speech_to_text: ^6.5.1
  permission_handler: ^11.0.1
  
  # Para video (Bunny)
  video_player: ^2.8.1
  chewie: ^1.7.4
```

Si falta algo:

```bash
flutter pub get
```

### Verificar Archivos Creados

```bash
# Deberías tener estos 4 archivos nuevos:
ls lib/screens/live_match_screen.dart
ls lib/screens/video_sync_screen.dart

# Y estos actualizados:
ls lib/screens/promatch_analysis_screen.dart
ls lib/screens/matches_screen.dart
```

---

## Paso 3: Probar (2 minutos)

### 1. Crear Partido de Prueba

```sql
-- En Supabase SQL Editor
INSERT INTO matches (
  id,
  team_id,
  team_home,
  team_away,
  status,
  match_date
) VALUES (
  'test-hybrid-001',
  'tu-team-id',  -- Reemplaza con tu team_id real
  'Mi Equipo',
  'Rival FC',
  'LIVE',
  NOW()
);
```

### 2. Abrir la App

```bash
flutter run
```

### 3. Navegar

1. **Home** → **Partidos**
2. Busca "Mi Equipo vs Rival FC"
3. Verás un botón verde: **"MODO LIVE"**
4. Púlsalo

### 4. Registrar Eventos

1. Pulsa **"INICIAR"** en el cronómetro
2. Espera 5 segundos
3. Tap en **"GOL"**
4. Espera 5 segundos
5. Mantén el **micrófono** y di: *"Tiro de Juan"*
6. Suelta el micrófono

### 5. Verificar

```sql
-- En Supabase SQL Editor
SELECT 
  event_type,
  match_timestamp,
  video_timestamp,
  voice_transcript
FROM analysis_events
WHERE match_id = 'test-hybrid-001'
ORDER BY match_timestamp;
```

**Esperado:**
```
event_type | match_timestamp | video_timestamp | voice_transcript
-----------+-----------------+-----------------+------------------
gol        | 5               | NULL            | NULL
tiro       | 10              | NULL            | Tiro de Juan
```

---

## ✅ Checklist de Instalación

- [ ] SQL ejecutado sin errores
- [ ] Columnas verificadas (`match_timestamp`, `video_timestamp`)
- [ ] Funciones creadas (`sync_live_events_with_video`, etc.)
- [ ] Dependencias de Flutter instaladas
- [ ] Archivos nuevos presentes
- [ ] App compila sin errores
- [ ] Partido de prueba creado
- [ ] Botón "MODO LIVE" visible
- [ ] Cronómetro funciona
- [ ] Eventos se guardan en Supabase

---

## 🐛 Solución de Problemas Rápida

### Error: "Column 'match_timestamp' does not exist"

**Causa:** No ejecutaste el SQL

**Solución:**
```sql
-- Ejecuta esto manualmente
ALTER TABLE analysis_events
ADD COLUMN IF NOT EXISTS match_timestamp INTEGER NOT NULL DEFAULT 0;
```

### Error: "No se puede insertar NULL en video_timestamp"

**Causa:** La columna no es nullable

**Solución:**
```sql
ALTER TABLE analysis_events
ALTER COLUMN video_timestamp DROP NOT NULL;
```

### Error: "Function sync_live_events_with_video does not exist"

**Causa:** Las funciones no se crearon

**Solución:** Ejecuta `SETUP_HYBRID_SYSTEM.sql` completo de nuevo

### No aparece el botón "MODO LIVE"

**Causa:** El partido no está en estado "LIVE" o "PENDING"

**Solución:**
```sql
UPDATE matches
SET status = 'LIVE'
WHERE id = 'test-hybrid-001';
```

### La voz no funciona

**Causa:** Permisos de micrófono no concedidos

**Solución:**
1. iOS: Ve a Ajustes → Tu App → Micrófono → Activar
2. Android: La app debería pedir permisos automáticamente

---

## 🚀 Siguiente Paso

Una vez que todo funcione, lee:

1. **GUIA_SISTEMA_HIBRIDO.md** - Uso completo
2. **INICIO_RAPIDO_HIBRIDO.md** - Pruebas detalladas

---

## 📞 ¿Problemas?

Si algo no funciona:

1. Revisa los logs:
   ```bash
   flutter logs | grep -E "(Live|Sync|Event)"
   ```

2. Verifica Supabase:
   - Dashboard → Logs
   - Busca errores en `analysis_events`

3. Comprueba permisos RLS:
   ```sql
   SELECT * FROM pg_policies
   WHERE tablename = 'analysis_events';
   ```

---

**¡Instalación completada! 🎉**

Si todos los checks están ✅, estás listo para usar el Sistema Híbrido en producción.

**Tiempo total:** ~5 minutos  
**Dificultad:** ⭐⭐☆☆☆ (Fácil)  
**Resultado:** Sistema profesional listo para el campo ⚽
