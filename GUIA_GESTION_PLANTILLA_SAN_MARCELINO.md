# 🎯 Guía: Gestión de Plantilla C.D. San Marcelino 'A'

## 📋 Configuración Inicial

### 1. Configurar tu equipo como San Marcelino

Tu equipo se detecta automáticamente desde la tabla `team_members` en Supabase. Asegúrate de que:

- Tu usuario esté vinculado al equipo C.D. San Marcelino 'A' en la tabla `team_members`
- El `team_id` corresponda al equipo de San Marcelino

### 2. Importar la Plantilla

1. Abre la pantalla **"Gestión de Plantilla"**
2. Toca el botón de importación (icono de descarga) en la barra superior
3. Selecciona **"C.D. San Marcelino 'A'"**
4. Toca **"Importar"**

Los 13 jugadores se importarán como suplentes por defecto.

## ⚙️ Gestionar Estados de Jugadores

### Estados Disponibles

1. **TITULAR** (Verde 🟢): Jugador que juega desde el inicio
2. **SUPLENTE** (Naranja 🟠): Jugador en el banquillo
3. **DESCONVOCADO** (Rojo 🔴): Jugador no disponible

### Cómo Cambiar Estados

1. En la pantalla de **"Gestión de Plantilla"**, verás todos los jugadores
2. Cada jugador tiene 3 botones:
   - **Titular**: Marca al jugador como titular
   - **Suplente**: Marca al jugador como suplente
   - **Descartado**: Marca al jugador como desconvocado
3. Si seleccionas **"Desconvocado"**, se pedirá un motivo (ej: lesión, sanción, descanso)
4. Los contadores se actualizan automáticamente en la parte superior

### Límites

- **Máximo 11 titulares** permitidos
- Los suplentes no tienen límite
- Los desconvocados no aparecen en otras áreas de la app

## 🔄 Sincronización Automática

### Áreas que se Actualizan Automáticamente

Cuando cambias el estado de un jugador en **"Gestión de Plantilla"**, estos cambios se reflejan automáticamente en:

#### 1. **Pantalla de Tácticas**
- Los **titulares** aparecen en el campo automáticamente
- Los **suplentes** aparecen en el banquillo
- Los **desconvocados** NO aparecen

#### 2. **Alineaciones Personalizadas**
- Al crear o cargar alineaciones, se respetan los estados
- Solo los jugadores disponibles (titulares/suplentes) pueden ser colocados

#### 3. **Asistencia**
- Todos los jugadores del equipo aparecen en la lista de asistencia
- El estado (titular/suplente/desconvocado) se muestra junto al nombre

#### 4. **Partidos**
- Los datos de la plantilla se usan para gestionar convocatorias

## 📊 Plantilla Actual de San Marcelino

### Jugadores Disponibles (13)

1. JAIDER ANDRES ALCIBAR GOMEZ
2. JORGE ARCOBA BIOT
3. ALEJANDRO BALLESTEROS HUERTA
4. MARTIN CABEZA CAÑAS
5. IKER DOLZ SANCHEZ
6. RAUL LAZURAN
7. UNAI LILLO AVILA
8. HUGO MARTÍNEZ RIAZA
9. SAMUEL ALEJANDRO PAREDES CASTRO
10. JULEN PARRAGA MORENO
11. DYLAN STEVEN RAMOS GONZALEZ
12. EMMANUEL RINCON SANCHEZ
13. MARCOS RODRIGUEZ GIMENEZ

### Técnico

- JOSE EMILIO FARINOS CERVERA (Técnico)

## 🎯 Flujo de Trabajo Recomendado

### Antes de un Partido

1. **Abre "Gestión de Plantilla"**
2. **Marca los 11 titulares** que jugarán desde el inicio
3. **Marca los suplentes** que estarán disponibles
4. **Marca como desconvocados** a los jugadores no disponibles (con motivo)
5. **Ve a "Tácticas"** - Los titulares ya estarán en el campo
6. **Ajusta posiciones** si es necesario
7. **Guarda la alineación** para referencia

### Durante la Temporada

- Actualiza los estados según disponibilidad de jugadores
- Los cambios se sincronizan automáticamente en todas las áreas
- Usa los motivos de desconvocación para mantener registro (lesiones, sanciones, etc.)

## 🔧 Detalles Técnicos

### Estructura de Datos

Los estados se guardan en la tabla `team_members`:
- `match_status`: 'starter', 'sub', o 'unselected'
- `status_note`: Motivo de desconvocación (opcional)

### Consultas en la App

- **Titulares**: `WHERE match_status = 'starter'`
- **Suplentes**: `WHERE match_status = 'sub'`
- **Disponibles**: `WHERE match_status IN ('starter', 'sub')`
- **Desconvocados**: `WHERE match_status = 'unselected'`

## ✅ Verificación

Después de cambiar estados, verifica que:

1. ✅ Los contadores en "Gestión de Plantilla" son correctos
2. ✅ Los titulares aparecen en "Tácticas"
3. ✅ Los suplentes están en el banquillo
4. ✅ Los desconvocados no aparecen en ninguna lista activa

---

**Nota**: Los cambios se guardan automáticamente en Supabase. Si cambias de dispositivo, los datos se sincronizan.
