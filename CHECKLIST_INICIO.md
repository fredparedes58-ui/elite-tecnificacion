# ✅ Checklist de Inicio - Sistema de Convocatoria

## 🎯 Usa este checklist para poner en marcha el sistema

---

## 📋 FASE 1: Base de Datos (5 minutos)

### ☐ Paso 1.1: Abrir Supabase
```
1. Ve a: https://supabase.com
2. Inicia sesión
3. Selecciona tu proyecto: [NOMBRE_DE_TU_PROYECTO]
```

### ☐ Paso 1.2: Ejecutar Script SQL
```
1. En el menú lateral → SQL Editor
2. Click en "New Query"
3. Abre: SETUP_MATCH_STATUS.sql
4. Copia TODO el contenido
5. Pega en el editor
6. Click en RUN (▶️)
```

### ☐ Paso 1.3: Verificar Instalación
```sql
-- Copia y ejecuta esta consulta:
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'team_members'
AND column_name IN ('match_status', 'status_note');
```

**✅ Esperado**: Debes ver 2 filas:
- `match_status` | `text`
- `status_note` | `text`

### ☐ Paso 1.4: (Opcional) Inicializar Datos
```sql
-- Si quieres empezar con 11 titulares automáticos:
-- Descomenta el bloque DO $$ en el archivo SQL
-- Líneas 52-79 del archivo SETUP_MATCH_STATUS.sql
```

---

## 📋 FASE 2: Código Flutter (YA COMPLETADO ✅)

### ✅ Archivos Nuevos Creados
- `lib/screens/squad_management_screen.dart`
- `SETUP_MATCH_STATUS.sql`
- `GUIA_GESTION_CONVOCATORIA.md`
- `INSTALACION_RAPIDA.md`
- `RESUMEN_IMPLEMENTACION.md`
- `CHECKLIST_INICIO.md` ← (Este archivo)

### ✅ Archivos Modificados
- `lib/models/player_model.dart`
- `lib/models/player_stats.dart`
- `lib/services/supabase_service.dart`
- `lib/providers/tactic_board_provider.dart`
- `lib/screens/tactical_board_screen.dart`
- `lib/widgets/player_piece.dart`
- `lib/screens/home_screen.dart`

---

## 📋 FASE 3: Ejecutar la App (2 minutos)

### ☐ Paso 3.1: Instalar Dependencias
```bash
flutter pub get
```

**✅ Esperado**: `Resolving dependencies... Got dependencies!`

### ☐ Paso 3.2: Verificar Configuración
```bash
# Verifica que existe:
cat lib/config/app_config.dart
```

**✅ Esperado**: Archivo con `supabaseUrl` y `supabaseAnonKey`

### ☐ Paso 3.3: Limpiar y Reconstruir
```bash
flutter clean
flutter pub get
```

### ☐ Paso 3.4: Ejecutar
```bash
flutter run
```

**✅ Esperado**: App se abre sin errores

---

## 📋 FASE 4: Prueba Funcional (3 minutos)

### TEST 1: Verificar Navegación

#### ☐ 1.1: Abrir Gestión de Plantilla
```
1. App abre en "Command Center"
2. Busca botón "Plantilla" (azul con icono 👥)
3. Toca el botón
```

**✅ Esperado**: 
- Se abre pantalla "GESTIÓN DE PLANTILLA"
- Ves lista de jugadores
- Hay contador superior con 3 secciones

#### ☐ 1.2: Verificar Jugadores Cargados
```
Si ves: "No hay jugadores en el equipo"
→ VE A: FASE 5 - Solución de Problemas
```

**✅ Esperado**: Lista con al menos 1 jugador

---

### TEST 2: Cambiar Estados de Jugadores

#### ☐ 2.1: Marcar Titulares
```
1. Toca el botón "Titular" (⭐ verde) en 11 jugadores diferentes
2. Observa el contador superior
```

**✅ Esperado**:
- Botones cambian a verde intenso
- Contador muestra: "11/11" en TITULARES
- Cambio es instantáneo

#### ☐ 2.2: Marcar Suplentes
```
1. Toca el botón "Suplente" (👥 naranja) en 5 jugadores
```

**✅ Esperado**:
- Botones cambian a naranja
- Contador muestra: "5" en SUPLENTES

#### ☐ 2.3: Desconvocar con Nota
```
1. Toca el botón "Descartado" (🚫 rojo) en 1 jugador
2. Aparece diálogo
3. Escribe: "Prueba de desconvocatoria"
4. Toca "Guardar"
```

**✅ Esperado**:
- Diálogo se cierra
- Jugador aparece con opacidad reducida
- Se ve la nota debajo del jugador
- Contador muestra: "1" en DESCONVOCADOS

---

### TEST 3: Pizarra Táctica Automática

#### ☐ 3.1: Abrir Pizarra
```
1. Regresa al Command Center (botón ← atrás)
2. Toca el botón "Tácticas" (morado 🎯)
```

**✅ Esperado**:
- Se abre "Pizarra Táctica"
- **¡MAGIA!** Los 11 titulares YA están en el campo
- Están distribuidos en formación 4-4-2
- Abajo hay una barra "BANQUILLO"

#### ☐ 3.2: Verificar Banquillo
```
1. Scroll horizontal en la barra inferior
2. Cuenta los jugadores
```

**✅ Esperado**:
- Se ven los 5 suplentes que marcaste
- NO aparece el jugador desconvocado

#### ☐ 3.3: Mover Jugador en Campo
```
1. Arrastra cualquier jugador titular a otra posición
2. Suéltalo
```

**✅ Esperado**:
- Jugador se mueve suavemente
- Se queda en la nueva posición

---

### TEST 4: Sistema de Sustituciones

#### ☐ 4.1: Seleccionar Titular
```
1. Toca (NO arrastres) un jugador del CAMPO
```

**✅ Esperado**:
- Jugador se ilumina con brillo DORADO ⭐
- Aparece icono ✓ en la esquina del avatar
- Jugador aumenta de tamaño (110%)
- Banquillo muestra: "⚡ MODO SUSTITUCIÓN"

#### ☐ 4.2: Realizar Sustitución
```
1. Sin deseleccionar, toca un jugador del BANQUILLO
```

**✅ Esperado**:
- **¡INTERCAMBIO INSTANTÁNEO!** 💥
- El suplente sale del banquillo y aparece en el campo
- El titular va al banquillo
- Modo sustitución se desactiva automáticamente

#### ☐ 4.3: Verificar Persistencia
```
1. Regresa al Command Center (← atrás)
2. Vuelve a entrar en "Plantilla"
3. Busca los jugadores que intercambiaste
```

**✅ Esperado**:
- El que era suplente ahora tiene badge "TITULAR" 🟢
- El que era titular ahora tiene badge "SUPLENTE" 🟠
- ¡Los cambios se guardaron en la base de datos! 🎉

#### ☐ 4.4: Cancelar Sustitución
```
1. Regresa a "Tácticas"
2. Toca un jugador del campo (se selecciona)
3. Toca el botón [X] en el indicador "MODO SUSTITUCIÓN"
```

**✅ Esperado**:
- Jugador se deselecciona
- Brillo dorado desaparece
- Modo sustitución se desactiva

---

## 📋 FASE 5: Solución de Problemas

### ⚠️ Problema: "No hay jugadores en el equipo"

#### ☐ 5.1: Verificar Datos en Supabase
```sql
-- En Supabase SQL Editor:
SELECT 
  tm.id,
  tm.team_id,
  tm.user_id,
  tm.match_status,
  p.full_name
FROM team_members tm
LEFT JOIN profiles p ON p.id = tm.user_id
LIMIT 10;
```

**Si la consulta devuelve 0 filas:**
```sql
-- Opción 1: Verifica que exista un equipo
SELECT * FROM teams LIMIT 5;

-- Opción 2: Verifica que existan perfiles
SELECT * FROM profiles LIMIT 5;
```

#### ☐ 5.2: Crear Datos de Prueba (si es necesario)
```sql
-- Este es un ejemplo, ajusta según tu estructura:
-- 1. Crear un equipo de prueba
INSERT INTO teams (name) VALUES ('Equipo de Prueba');

-- 2. Obtener el ID del equipo
SELECT id FROM teams WHERE name = 'Equipo de Prueba';

-- 3. Añadir jugadores al equipo (reemplaza los UUIDs)
INSERT INTO team_members (team_id, user_id, match_status)
VALUES 
  ('[TEAM_ID]', '[USER_ID_1]', 'starter'),
  ('[TEAM_ID]', '[USER_ID_2]', 'starter'),
  -- ... añade más según necesites
```

---

### ⚠️ Problema: "Error de conexión con Supabase"

#### ☐ 5.3: Verificar Credenciales
```dart
// Abre: lib/config/app_config.dart
// Verifica que tenga:
class AppConfig {
  static const String supabaseUrl = 'https://TU-PROYECTO.supabase.co';
  static const String supabaseAnonKey = 'eyJ...'; // Token largo
}
```

#### ☐ 5.4: Verificar RLS (Row Level Security)
```sql
-- En Supabase SQL Editor:
-- Ver políticas actuales
SELECT * FROM pg_policies WHERE tablename = 'team_members';

-- Si necesitas desactivar RLS temporalmente (SOLO PARA DESARROLLO):
ALTER TABLE team_members DISABLE ROW LEVEL SECURITY;

-- O crear una política permisiva:
CREATE POLICY "Allow all for authenticated users"
ON team_members
FOR ALL
USING (auth.role() = 'authenticated');
```

---

### ⚠️ Problema: "Los cambios no se sincronizan"

#### ☐ 5.5: Forzar Recarga Manual
```
1. En Gestión de Plantilla: Pull down to refresh
2. En Pizarra Táctica: Toca botón ↻ Recargar
```

#### ☐ 5.6: Verificar Update en BD
```sql
-- Después de hacer un cambio en la app, ejecuta:
SELECT 
  user_id,
  match_status,
  status_note,
  updated_at
FROM team_members
ORDER BY updated_at DESC
LIMIT 5;
```

**✅ Esperado**: Ver timestamp reciente en `updated_at`

---

## 📋 FASE 6: Lectura de Documentación

### ☐ 6.1: Guía Rápida (15 min)
```
📖 Abre: INSTALACION_RAPIDA.md
Secciones recomendadas:
- ✅ Prueba Rápida (2 minutos)
- ✅ Problemas Comunes
- ✅ Estructura de Datos
```

### ☐ 6.2: Guía Completa (30-45 min)
```
📖 Abre: GUIA_GESTION_CONVOCATORIA.md
Secciones recomendadas:
- ✅ Uso de la Gestión de Plantilla
- ✅ Sistema de Sustituciones
- ✅ Flujo de Trabajo Completo
- ✅ Personalización (Formaciones)
```

### ☐ 6.3: Detalles Técnicos
```
📖 Abre: RESUMEN_IMPLEMENTACION.md
Para entender:
- ✅ Qué archivos se crearon/modificaron
- ✅ Cómo funciona la arquitectura
- ✅ Estadísticas de implementación
```

---

## 🎯 RESULTADO FINAL

### Si todos los checkboxes están marcados ✅:

**¡FELICIDADES!** 🎉

Tienes funcionando:
- ✅ Base de datos configurada
- ✅ Gestión de plantilla operativa
- ✅ Pizarra táctica inteligente
- ✅ Sistema de sustituciones profesional
- ✅ Sincronización entre pantallas

---

## 📊 Scorecard Final

### Marca lo que funciona:

```
☐ Puedo abrir Gestión de Plantilla
☐ Puedo cambiar estados de jugadores
☐ Los contadores se actualizan
☐ Puedo añadir notas de desconvocatoria
☐ Los titulares aparecen automáticamente en la pizarra
☐ Los suplentes están en el banquillo
☐ Puedo hacer sustituciones con tap
☐ Los cambios se guardan en la base de datos
☐ Puedo recargar y ver los cambios persistidos
☐ El diseño Elite se mantiene consistente

TOTAL: ___/10
```

**Si tienes 10/10**: ¡Sistema perfecto! 🏆  
**Si tienes 7-9/10**: Casi allá, revisa FASE 5  
**Si tienes <7/10**: Ve a Solución de Problemas o contacta soporte

---

## 🚀 Próximos Pasos Recomendados

1. **Personaliza las formaciones**
   - Edita `tactic_board_provider.dart`
   - Ajusta posiciones en `defaultPositions`

2. **Añade más jugadores**
   - Usa tu sistema de registro existente
   - O añade manualmente en Supabase

3. **Prueba en un partido real**
   - Prepara convocatoria completa
   - Diseña tu táctica
   - Simula sustituciones

4. **Comparte feedback**
   - ¿Qué funcionalidad te gustaría añadir?
   - ¿Algún bug encontrado?
   - ¿Mejoras de UX sugeridas?

---

## 📞 ¿Necesitas Ayuda?

### Stack Overflow
```
Tag: flutter, supabase, tactical-board
Incluye: Logs de error, versión de Flutter
```

### Comunidad Flutter
```
Discord: Flutter Dev
Subreddit: r/FlutterDev
```

### Documentación Oficial
```
Flutter: https://flutter.dev/docs
Supabase: https://supabase.com/docs
Provider: https://pub.dev/packages/provider
```

---

**🎉 ¡Disfruta tu Sistema de Convocatoria Profesional!**

---

**Versión**: 1.0  
**Fecha**: Enero 2026  
**Tiempo estimado total**: 10-15 minutos  
**Dificultad**: 🟢 Fácil
