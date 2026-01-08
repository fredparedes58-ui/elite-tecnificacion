# 🎯 Guía: Sistema de Gestión de Convocatoria y Táctica Dinámica

## 📋 Índice
1. [Introducción](#introducción)
2. [Configuración Inicial](#configuración-inicial)
3. [Uso de la Gestión de Plantilla](#uso-de-la-gestión-de-plantilla)
4. [Uso de la Pizarra Táctica](#uso-de-la-pizarra-táctica)
5. [Sistema de Sustituciones](#sistema-de-sustituciones)
6. [Flujo de Trabajo Completo](#flujo-de-trabajo-completo)
7. [Solución de Problemas](#solución-de-problemas)

---

## 🎬 Introducción

Este sistema conecta la **Base de Datos** (quién juega) con la **Pizarra Táctica** (dónde juegan), creando un flujo de trabajo inteligente para gestionar tu equipo.

### ✨ Características Principales

- ✅ **Gestión de Estados**: Marca jugadores como Titular, Suplente o Desconvocado
- ✅ **Notas de Desconvocatoria**: Registra motivos (lesión, sanción, descanso)
- ✅ **Carga Automática**: Los titulares aparecen automáticamente en el campo
- ✅ **Banquillo Interactivo**: Suplentes listos para entrar
- ✅ **Sustituciones Inteligentes**: Intercambia jugadores con un simple toque
- ✅ **Sincronización en Tiempo Real**: Cambios instantáneos entre pantallas

---

## ⚙️ Configuración Inicial

### Paso 1: Configurar la Base de Datos

1. **Accede a tu Dashboard de Supabase**
   - Ve a tu proyecto en [supabase.com](https://supabase.com)
   - Navega a **SQL Editor**

2. **Ejecuta el Script SQL**
   - Abre el archivo `SETUP_MATCH_STATUS.sql`
   - Copia todo el contenido
   - Pégalo en el SQL Editor de Supabase
   - Haz clic en **Run** (▶️)

3. **Verifica la Instalación**
   - Ejecuta esta consulta para confirmar:
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns
   WHERE table_name = 'team_members'
   AND column_name IN ('match_status', 'status_note');
   ```
   - Deberías ver ambas columnas listadas

### Paso 2: Verificar Dependencias

Asegúrate de que tu `pubspec.yaml` incluye:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  google_fonts: ^6.1.0
  provider: ^6.1.0
  uuid: ^4.0.0
```

Ejecuta:
```bash
flutter pub get
```

---

## 📱 Uso de la Gestión de Plantilla

### Acceder a la Pantalla

1. Desde el **Command Center** (pantalla principal)
2. Toca el botón **"Plantilla"** (icono azul de personas)
3. Se abrirá la pantalla de **Gestión de Plantilla**

### Interfaz de Gestión

#### 🎯 Contador Superior
```
┌─────────────────────────────────────────────┐
│  ⚽ TITULARES    │  👥 SUPLENTES  │  ❌ DESCARTADOS  │
│     8/11        │       5        │       2         │
└─────────────────────────────────────────────┘
```

- **TITULARES**: Muestra cuántos de los 11 titulares están seleccionados
- **SUPLENTES**: Cantidad de jugadores en el banquillo
- **DESCONVOCADOS**: Jugadores no disponibles para el partido

#### 📋 Lista de Jugadores

Cada tarjeta de jugador muestra:
- 📸 **Avatar** del jugador
- 🏷️ **Nombre** y posición
- 🎯 **Estado actual** (Titular/Suplente/Desconvocado)
- 3️⃣ **Botones de cambio rápido**

### Cambiar el Estado de un Jugador

#### ✅ Marcar como TITULAR
1. Toca el botón **"Titular"** (⭐ verde)
2. El jugador se marca inmediatamente como titular
3. El contador superior se actualiza

#### 🟧 Marcar como SUPLENTE
1. Toca el botón **"Suplente"** (👥 naranja)
2. El jugador pasa al banquillo
3. Se actualiza en la base de datos

#### ❌ Marcar como DESCONVOCADO
1. Toca el botón **"Descartado"** (🚫 rojo)
2. Aparece un diálogo para introducir el motivo:
   - Ejemplo: "Lesión tobillo"
   - Ejemplo: "Sanción - Tarjeta roja"
   - Ejemplo: "Descanso preventivo"
3. Toca **"Guardar"**
4. El jugador aparece opaco con su nota visible

### Indicadores Visuales

```
🟢 TITULAR      → Borde verde brillante
🟠 SUPLENTE     → Borde naranja
🔴 DESCONVOCADO → Borde rojo + opacidad 50%
```

---

## 🎮 Uso de la Pizarra Táctica

### Acceder a la Pizarra

1. Desde el **Command Center**
2. Toca el botón **"Tácticas"** (icono morado)
3. Se abrirá la **Pizarra Táctica**

### Carga Automática de Jugadores

**¡MAGIA!** 🪄 Al abrir la pizarra:

1. ✅ Los **11 titulares** ya están en el campo (formación 4-4-2 por defecto)
2. ✅ Los **suplentes** están en el banquillo inferior
3. ✅ Los **desconvocados** no aparecen (no estorban)

### Estructura de la Pantalla

```
┌──────────────────────────────────────┐
│  🎯 Pizarra Táctica      [↻] [💾]  │
├──────────────────────────────────────┤
│                                      │
│         ⚽ CAMPO DE JUEGO            │
│                                      │
│    [Jugadores distribuidos aquí]    │
│                                      │
├──────────────────────────────────────┤
│  🪑 BANQUILLO                        │
│  [👤] [👤] [👤] [👤] [👤]           │
└──────────────────────────────────────┘
```

### Mover Jugadores en el Campo

1. **Arrastra** cualquier jugador titular
2. **Suéltalo** en su nueva posición
3. La formación se actualiza automáticamente

### Recargar Jugadores

Si hiciste cambios en la Gestión de Plantilla:
1. Toca el botón **↻ Recargar**
2. Los jugadores se actualizan según sus estados actuales

---

## 🔄 Sistema de Sustituciones

### Método: Toque Simple (Recomendado)

#### Paso 1: Seleccionar Primer Jugador
- Toca un jugador **del campo** o **del banquillo**
- El jugador se resalta con un **brillo dorado** ⭐
- Aparece el indicador: `⚡ MODO SUSTITUCIÓN`

#### Paso 2: Seleccionar Segundo Jugador
- Toca otro jugador (debe ser del grupo opuesto)
  - Si tocaste un titular → toca un suplente
  - Si tocaste un suplente → toca un titular
- **¡BOOM!** 💥 Se intercambian automáticamente

#### Paso 3: Resultado
```
ANTES:
Campo: [Messi] [Ronaldo] [Neymar]
Banquillo: [Suárez] [Mbappé]

→ Tocas MESSI (campo)
→ Tocas MBAPPÉ (banquillo)

DESPUÉS:
Campo: [Mbappé] [Ronaldo] [Neymar]
Banquillo: [Suárez] [Messi]
```

### Indicadores Visuales durante Sustitución

```
🟡 JUGADOR SELECCIONADO:
   - Borde dorado grueso
   - Brillo amarillo
   - Escala aumentada (110%)
   - Icono ✓ en la esquina

📍 BANQUILLO ACTIVO:
   - Barra superior: "⚡ MODO SUSTITUCIÓN"
   - Botón [X] para cancelar
```

### Cancelar una Sustitución

- Toca el botón **[X]** en el banquillo
- O toca el mismo jugador que ya estaba seleccionado

### Restricciones

❌ **NO se puede intercambiar**:
- Dos titulares entre sí (deben ser posicionados manualmente)
- Dos suplentes entre sí (no tiene sentido)

✅ **SÍ se puede intercambiar**:
- Un titular con cualquier suplente
- Un suplente con cualquier titular

---

## 🔄 Flujo de Trabajo Completo

### Caso de Uso: Preparar Convocatoria para un Partido

#### 1️⃣ **Planificar el Equipo**
```
📱 Command Center → Plantilla
```
- Marca 11 jugadores como **Titular**
- Marca 7 jugadores como **Suplente**
- Marca 2 jugadores como **Desconvocado** (con motivos)

**Ejemplo**:
- Titular: Portero, 4 defensas, 4 medios, 2 delanteros
- Suplente: 1 portero, 2 defensas, 2 medios, 2 delanteros
- Desconvocado: "Pérez - Lesión rodilla", "García - Sanción"

#### 2️⃣ **Diseñar la Táctica**
```
📱 Command Center → Tácticas
```
- Los 11 titulares ya están en el campo 🎉
- Ajusta las posiciones según tu formación
- Usa el modo dibujo para marcar jugadas

#### 3️⃣ **Durante el Partido (Sustitución)**
```
🎮 Pizarra Táctica → Modo Sustitución
```
- Toca al titular que quieres sacar
- Toca al suplente que quieres meter
- ¡Cambio realizado! ⚽

#### 4️⃣ **Guardar la Formación**
```
💾 Botón Guardar → "4-4-2 vs Real Madrid"
```
- Guarda la formación para reutilizarla
- Carga formaciones previas cuando las necesites

---

## 🐛 Solución de Problemas

### ❌ Problema: "No hay jugadores en el equipo"

**Causa**: La tabla `team_members` está vacía o no estás autenticado.

**Solución**:
1. Verifica que tienes jugadores en tu equipo:
   ```sql
   SELECT * FROM team_members WHERE team_id = 'tu-team-id';
   ```
2. Si no hay datos, añade jugadores manualmente o importa datos de ejemplo

### ❌ Problema: "Los cambios no se guardan"

**Causa**: Error de conexión con Supabase o permisos RLS.

**Solución**:
1. Verifica tu conexión a internet
2. Revisa las políticas RLS en Supabase:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'team_members';
   ```
3. Asegúrate de que el usuario autenticado tiene permisos de UPDATE

### ❌ Problema: "Los titulares no aparecen en la pizarra"

**Causa**: Los jugadores no tienen `match_status = 'starter'`.

**Solución**:
1. Ve a **Gestión de Plantilla**
2. Marca jugadores como **Titular**
3. Regresa a la **Pizarra Táctica**
4. Toca el botón **↻ Recargar**

### ❌ Problema: "No puedo hacer sustituciones"

**Causa**: Estás intentando intercambiar dos jugadores del mismo grupo.

**Solución**:
- Solo puedes intercambiar un **titular** con un **suplente**
- Si quieres mover dos titulares entre sí, usa el drag & drop manual

### ❌ Problema: "El contador muestra valores incorrectos"

**Causa**: Datos desincronizados en la base de datos.

**Solución**:
1. Toca el botón **↻ Recargar** en la pantalla
2. O ejecuta esta consulta en Supabase:
   ```sql
   UPDATE team_members 
   SET match_status = 'sub' 
   WHERE match_status IS NULL;
   ```

---

## 🎨 Personalización

### Cambiar la Formación por Defecto

Edita el archivo: `lib/providers/tactic_board_provider.dart`

Busca la función `_autoLoadStartersAndSubs()` y modifica las posiciones:

```dart
final defaultPositions = [
  const Offset(180, 600),  // Portero
  const Offset(80, 480),   // Defensa 1
  // ... modifica según tu formación preferida
];
```

### Formaciones Populares

#### 4-3-3 Ofensivo
```dart
// Portero
const Offset(180, 600),
// Defensas
const Offset(80, 480), const Offset(140, 500), 
const Offset(220, 500), const Offset(280, 480),
// Medios
const Offset(100, 340), const Offset(180, 360), const Offset(260, 340),
// Delanteros
const Offset(80, 180), const Offset(180, 160), const Offset(280, 180),
```

#### 5-3-2 Defensivo
```dart
// Portero
const Offset(180, 600),
// Defensas
const Offset(60, 480), const Offset(120, 500), const Offset(180, 500),
const Offset(240, 500), const Offset(300, 480),
// Medios
const Offset(100, 340), const Offset(180, 360), const Offset(260, 340),
// Delanteros
const Offset(140, 200), const Offset(220, 200),
```

---

## 📊 Mejores Prácticas

### ✅ DO (Haz esto)

1. **Actualiza la convocatoria antes del partido**
   - Revisa lesiones y sanciones
   - Marca desconvocados con motivos claros

2. **Usa nombres descriptivos para formaciones guardadas**
   - ❌ "Formación 1"
   - ✅ "4-4-2 vs Equipos Defensivos"

3. **Mantén el banquillo equilibrado**
   - Al menos 1 portero suplente
   - Suplentes para todas las posiciones

4. **Guarda cambios importantes**
   - Toca **💾 Guardar Formación** después de ajustes mayores

### ❌ DON'T (Evita esto)

1. **No dejes jugadores sin estado**
   - Todos deben ser: Titular, Suplente o Desconvocado

2. **No marques más de 11 titulares**
   - El sistema lo permite, pero la pizarra se saturará

3. **No olvides recargar después de cambios de convocatoria**
   - Los cambios no son automáticos entre pantallas

---

## 🚀 Próximas Funcionalidades

- [ ] **Historial de Convocatorias**: Ver convocatorias pasadas
- [ ] **Análisis de Rotación**: Estadísticas de minutos jugados
- [ ] **Notificaciones**: Alertas de jugadores lesionados
- [ ] **Exportar PDF**: Convocatoria lista para imprimir
- [ ] **Cambios en vivo**: Sincronización en tiempo real con el staff

---

## 📞 Soporte

¿Problemas? ¿Sugerencias?

- 📧 Email: soporte@futbolapp.com
- 💬 Discord: [FutbolApp Community](#)
- 📚 Docs: [docs.futbolapp.com](#)

---

**Última actualización**: Enero 2026  
**Versión**: 2.0.0  
**Desarrollador**: Celiannycastro
