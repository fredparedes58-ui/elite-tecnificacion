# 🎯 Sistema de Alineaciones Personalizadas

## ¿Qué puedes hacer ahora?

✅ **Guardar** la configuración actual del campo como alineación  
✅ **Crear** alineaciones desde cero asignando jugadores a posiciones  
✅ **Editar** alineaciones personalizadas existentes  
✅ **Seleccionar** una alineación y ver jugadores en posiciones exactas  
✅ **Cambiar** de formación (4-4-2, 4-3-3, 3-5-2)  

---

## 📋 PASO 1: Configurar Base de Datos

Antes de usar alineaciones, debes ejecutar el script SQL en Supabase:

1. **Abre Supabase Dashboard** → SQL Editor
2. **Copia el contenido de**: `SETUP_ALIGNMENTS.sql`
3. **Pégalo y ejecuta** (Run ▶️)
4. **Verifica** con:
   ```sql
   SELECT * FROM alignments;
   ```

---

## 🎮 PASO 2: Usar el Sistema

### Opción A: Guardar Configuración Actual

**Escenario:** Ya tienes jugadores colocados perfectamente en el campo

1. **Ve a Pizarra Táctica** (botón morado Tácticas)
2. **Coloca los 11 jugadores** en el campo como quieras
3. **Click en el botón ➕** (Nueva Alineación) en la barra superior
4. **Selecciona**: "Guardar configuración actual"
5. **Ingresa**:
   - Nombre: Ej: "Alineación vs Madrid"
   - Formación: Ej: "4-4-2"
6. **Click "GUARDAR"**

**Resultado:** ✅ La posición exacta de cada jugador se guarda

---

### Opción B: Crear desde Cero

**Escenario:** Quieres planificar una alineación específica

1. **Ve a Pizarra Táctica** (botón morado)
2. **Click en el botón ➕** (Nueva Alineación)
3. **Selecciona**: "Crear desde cero"
4. **Pantalla de Editor se abre:**
   - Campo visual con posiciones marcadas
   - Cada posición tiene un círculo con icono +

5. **Asignar jugadores:**
   - Click en una posición vacía (⊕)
   - Se abre diálogo con lista de jugadores
   - Selecciona el jugador
   - Se asigna a esa posición

6. **Repite** hasta asignar los 11 jugadores
7. **Contador** muestra: "Jugadores asignados: X/11"
8. **Cuando estén los 11**, click "GUARDAR ALINEACIÓN"

**Resultado:** ✅ Alineación personalizada guardada

---

## 📖 PASO 3: Usar Alineaciones Guardadas

### Cargar Alineación

1. **Ve a Pizarra Táctica**
2. **Click en el dropdown** de alineaciones (al lado del botón ➕)
3. **Selecciona una alineación** de la lista
4. **¡MAGIA!** Los jugadores aparecen en sus posiciones asignadas

**Si la alineación tiene jugadores asignados:**
- ✅ Cada jugador aparece en SU posición específica
- ✅ Respeta la formación seleccionada
- ✅ Los demás jugadores quedan en el banquillo

**Si la alineación NO tiene jugadores asignados:**
- ⚠️ Carga titulares (match_status=starter) en formación por defecto

---

### Editar Alineación Personalizada

1. **Selecciona una alineación personalizada** (aparece ✏️ dorado en el nombre)
2. **Click en el botón ✏️** (Editar) que aparece al lado del dropdown
3. **Se abre el Editor** con la alineación actual
4. **Modifica**:
   - Cambiar nombre
   - Cambiar formación
   - Reasignar jugadores a posiciones
5. **Guardar**

**Resultado:** ✅ Alineación actualizada

---

## 🎨 Interfaz Visual

### En la Pizarra Táctica:

```
┌─────────────────────────────────────────────┐
│ [◀] [➕] [Alineaciones ▼] [✏️] [📊] [...] │
│       ↑         ↑          ↑               │
│   Crear    Seleccionar  Editar             │
└─────────────────────────────────────────────┘
```

### En el Editor de Alineaciones:

```
┌─────────────────────────────────────────┐
│  Nombre: [Mi Alineación ___________]   │
│  Formación: [4-4-2] [4-3-3] [3-5-2]    │
│                                         │
│  Jugadores asignados: 8/11 ⚠️          │
│                                         │
│  ┌───────────────────────────────┐     │
│  │     Campo Visual              │     │
│  │                               │     │
│  │  ⊕ = Click para asignar       │     │
│  │  👤 = Jugador asignado        │     │
│  │                               │     │
│  └───────────────────────────────┘     │
│                                         │
│  [GUARDAR ALINEACIÓN]                   │
└─────────────────────────────────────────┘
```

---

## 🔄 Flujo Completo de Ejemplo

### Caso Real: Crear "Alineación vs Atlético"

**Situación:** Tienes un partido importante y quieres una alineación específica

1. **Ir a Pizarra Táctica**
2. **Click ➕** → "Crear desde cero"
3. **Nombre:** "vs Atlético - 4-3-3"
4. **Formación:** Seleccionar "4-3-3"
5. **Asignar jugadores:**
   
   **Portero** (abajo centro):
   - Click en posición ⊕
   - Seleccionar: Ter Stegen

   **Defensas** (línea):
   - Posición 1: Dest
   - Posición 2: Piqué
   - Posición 3: Lenglet  
   - Posición 4: Alba

   **Medios** (triángulo):
   - Posición 1: De Jong
   - Posición 2: Busquets (centro)
   - Posición 3: Pedri

   **Delanteros** (tres):
   - Posición 1: Dembélé (izq)
   - Posición 2: Messi (centro)
   - Posición 3: Griezmann (der)

6. **Contador:** "11/11" ✅ verde
7. **Click "GUARDAR ALINEACIÓN"**

**Resultado:** 
- ✅ Alineación guardada en Supabase
- ✅ Aparece en el dropdown
- ✅ Al seleccionarla, cada jugador va a SU posición

---

## 🎯 Beneficios

### Antes:
- ❌ Seleccionar alineación → Solo cambiaba formación
- ❌ Tenías que mover manualmente todos los jugadores
- ❌ No recordaba quién iba en cada posición
- ❌ No podías guardar alineaciones tácticas

### Ahora:
- ✅ Seleccionar alineación → **Jugadores en posiciones exactas**
- ✅ **Guardas configuraciones completas**
- ✅ **Recuerda jugadores + posiciones + formación**
- ✅ **Creas múltiples alineaciones tácticas**

---

## 📊 Casos de Uso

### 1. Alineación vs Equipos Fuertes
```
Nombre: "vs Real Madrid - Defensivo"
Formación: 5-4-1
Jugadores: Más defensas, 1 delantero rápido
```

### 2. Alineación vs Equipos Débiles
```
Nombre: "vs Equipos Menores - Ofensivo"
Formación: 4-3-3
Jugadores: 3 delanteros, medios creativos
```

### 3. Alineación para Partidos Caseros
```
Nombre: "En Casa - Equilibrado"
Formación: 4-4-2
Jugadores: Balance perfecto
```

---

## 🔧 Opciones Avanzadas

### Editar Alineación Existente

1. **Seleccionar la alineación** en el dropdown
2. **Click en el botón ✏️** dorado
3. **Editor se abre** con jugadores actuales
4. **Modificar** lo que necesites:
   - Cambiar jugador en posición X
   - Cambiar formación completa
   - Renombrar alineación
5. **Guardar**

### Duplicar Alineación

1. **Carga la alineación** que quieres duplicar
2. **Click ➕** → "Guardar configuración actual"
3. **Nuevo nombre**: "Alineación X - Variante"
4. **Guardar**

**Resultado:** Dos alineaciones similares con pequeñas diferencias

---

## 🗄️ Estructura de Datos en Supabase

### Tabla: `alignments`

```sql
CREATE TABLE alignments (
  id TEXT PRIMARY KEY,
  team_id UUID REFERENCES teams(id),
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  formation TEXT DEFAULT '4-4-2',
  player_positions JSONB,
  is_custom BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Ejemplo de `player_positions` (JSONB):

```json
{
  "player-id-1": {
    "x": 180,
    "y": 600,
    "role": "Portero"
  },
  "player-id-2": {
    "x": 80,
    "y": 480,
    "role": "Defensa"
  },
  ...
}
```

---

## 🐛 Troubleshooting

### La alineación no guarda

**Verifica:**
1. ✅ Ejecutaste `SETUP_ALIGNMENTS.sql` en Supabase
2. ✅ La tabla `alignments` existe
3. ✅ Asignaste los 11 jugadores (contador 11/11)
4. ✅ Ingresaste un nombre

### Los jugadores no aparecen en sus posiciones

**Verifica:**
1. ✅ La alineación tiene `player_positions` (no está vacío)
2. ✅ Los IDs de jugadores coinciden con la base de datos
3. ✅ Recargaste la app después de guardar

### El dropdown no muestra mis alineaciones

**Verifica:**
1. ✅ Las políticas RLS en Supabase permiten SELECT
2. ✅ Estás autenticado en la app
3. ✅ La tabla `alignments` tiene registros

**Query de verificación:**
```sql
SELECT * FROM alignments WHERE user_id = 'tu-user-id';
```

---

## ✨ Tips Profesionales

### 1. Organiza por Rival
```
- "vs Barcelona - Ofensivo"
- "vs Real Madrid - Defensivo"
- "vs Equipos Menores - Rotación"
```

### 2. Organiza por Competición
```
- "Liga - Titular"
- "Copa - Rotación"
- "Amistosos - Juveniles"
```

### 3. Experimenta con Formaciones
```
- Crea la misma alineación en 4-4-2 y 4-3-3
- Compara cuál funciona mejor
- Guarda ambas versiones
```

---

## 🚀 Próximos Pasos

### Después de crear alineaciones:

1. **Úsalas en partidos reales**
2. **Analiza resultados**
3. **Ajusta** si algo no funcionó
4. **Crea variantes** (Alineación A, B, C)
5. **Comparte** con tu cuerpo técnico

---

## 📦 Resumen de Funcionalidades

| Funcionalidad | Estado | Ubicación |
|---------------|--------|-----------|
| **Crear alineación desde cero** | ✅ | Pizarra → ➕ → Crear desde cero |
| **Guardar configuración actual** | ✅ | Pizarra → ➕ → Guardar actual |
| **Seleccionar alineación** | ✅ | Dropdown en barra superior |
| **Editar alineación custom** | ✅ | Botón ✏️ al lado del dropdown |
| **Ver jugadores en posiciones** | ✅ | Automático al seleccionar |
| **Cambiar formación** | ✅ | Editor de alineación |
| **Asignar jugadores a posiciones** | ✅ | Click en posición del campo |
| **Validación de 11 jugadores** | ✅ | Contador automático |
| **Persistencia en Supabase** | ✅ | Automático al guardar |

---

## 🎉 ¡Disfruta tu Sistema Profesional!

Ahora tienes un sistema de alineaciones digno de apps profesionales como:
- 📱 OneFootball
- 📱 SofaScore
- 📱 FIFA Mobile

**¡A crear alineaciones ganadoras!** ⚽🏆

---

**Versión:** 3.0.0  
**Fecha:** Enero 2026  
**Autor:** Sistema de Gestión Táctica
