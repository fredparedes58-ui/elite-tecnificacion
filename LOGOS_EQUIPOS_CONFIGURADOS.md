# ✅ Logos de Equipos Configurados

## 📋 Equipos con Logos Configurados

Los siguientes equipos tienen sus logos correctamente configurados en la aplicación:

### 1. Torrent C.F. 'C'
- **Nombre del archivo**: `torrent.png`
- **Ruta**: `assets/images/teams/torrent.png`
- **Descripción del logo**: Escudo naranja con corona negra, texto "TORRENT CF" y castillos estilizados

### 2. Unió Benetússer-Favara C.F. 'A'
- **Nombre del archivo**: `benetusser_favara.png`
- **Ruta**: `assets/images/teams/benetusser_favara.png`
- **Descripción del logo**: Cresta heráldica con corona dorada, escudo con rayas senyera, balón vintage y texto "BENETÚSSER - FAVARA" y "UNIÓ C.F."

### 3. U.D. Alzira 'A'
- **Nombre del archivo**: `alzira.png`
- **Ruta**: `assets/images/teams/alzira.png`
- **Descripción del logo**: Escudo dividido diagonalmente con balón de fútbol, llave dorada, rayas senyera y texto "U.D. ALZIRA"

### 4. C.F.B. Ciutat de València 'A'
- **Nombre del archivo**: `ciutat_valencia.png`
- **Ruta**: `assets/images/teams/ciutat_valencia.png`
- **Descripción del logo**: Escudo blanco con letras "FCB" en rojo, azul y amarillo, diamante con balón y texto "CIUTAT DE VALÈNCIA"

### 5. C.D. San Marcelino 'A'
- **Nombre del archivo**: `san_marcelino.png`
- **Ruta**: `assets/images/teams/san_marcelino.png`
- **Descripción del logo**: Cresta con corona, anillo gris, símbolos de teatro y arte, y texto "SAN MARCELINO"

## 📁 Ubicación de los Archivos

Todos los logos deben estar en:
```
assets/images/teams/
```

## ✅ Estado Actual

### Configuración en Código
- ✅ Todos los equipos tienen sus rutas de logos configuradas
- ✅ El mapeo está en `TeamLogoHelper.teamLogos`
- ✅ Cada `TeamRoster` incluye su `logoPath`
- ✅ El diálogo de importación muestra los logos
- ✅ Sistema de fallback configurado (icono de fútbol si falta el logo)

### Archivos Físicos
- ⏳ Pendiente: Agregar los archivos PNG a la carpeta `assets/images/teams/`

## 🎯 Cómo Agregar los Logos

1. **Crear la carpeta** (ya existe):
   ```bash
   mkdir -p assets/images/teams
   ```

2. **Agregar los archivos PNG** con estos nombres exactos:
   - `torrent.png`
   - `benetusser_favara.png`
   - `alzira.png`
   - `ciutat_valencia.png`
   - `san_marcelino.png`

3. **Ejecutar**:
   ```bash
   flutter pub get
   ```

4. **Verificar** que los logos aparecen en el diálogo de importación

## 📝 Especificaciones Recomendadas

- **Formato**: PNG con transparencia
- **Tamaño**: 256x256 píxeles o superior (512x512 ideal)
- **Calidad**: Alta resolución para pantallas Retina
- **Fondo**: Transparente preferiblemente

## 🔧 Uso en la App

Los logos se muestran automáticamente en:
- ✅ Diálogo de importación de plantillas
- ✅ Lista de equipos disponibles
- ✅ Cualquier widget que use `TeamRoster.logoPath`

## 📱 Próximos Pasos

1. Agregar los archivos PNG a `assets/images/teams/`
2. Probar la importación para verificar que los logos aparecen
3. Verificar que el fallback funciona si falta algún logo

---

**Estado**: ✅ Código configurado | ⏳ Archivos pendientes de agregar
