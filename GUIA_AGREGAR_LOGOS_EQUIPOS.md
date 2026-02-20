# 🎯 GUÍA: Agregar Logos de Equipos

## 📋 Estructura de Archivos

Los logos de los equipos deben guardarse en:
```
assets/images/teams/
```

## 🏆 Equipos y Nombres de Archivos

Debes agregar los logos con estos nombres exactos:

| Equipo | Nombre del Archivo |
|--------|-------------------|
| Picassent C.F. 'A' | `picassent.png` |
| F.B.U.E. Atlètic Amistat 'A' | `atletic_amistat.png` |
| Col. Salgui E.D.E. 'A' | `salgui.png` |
| C.D. Don Bosco 'A' | `don_bosco.png` |
| F.B.C.D. Catarroja 'B' | `catarroja.png` |
| C.F. Fundació VCF 'A' | `fundacio_vcf.png` |
| C.F. Sporting Xirivella 'C' | `sporting_xirivella.png` |
| Torrent C.F. 'C' | `torrent.png` |
| Unió Benetússer-Favara C.F. 'A' | `benetusser_favara.png` |
| U.D. Alzira 'A' | `alzira.png` |
| C.F.B. Ciutat de València 'A' | `ciutat_valencia.png` |
| C.D. San Marcelino 'A' | `san_marcelino.png` |

## 📝 Pasos para Agregar los Logos

### 1. Crear la carpeta (si no existe)
```bash
mkdir -p assets/images/teams
```

### 2. Agregar los archivos PNG
Coloca cada logo en formato PNG con el nombre correspondiente en la tabla anterior.

### 3. Verificar en pubspec.yaml
El archivo `pubspec.yaml` ya está configurado para incluir:
```yaml
assets:
  - assets/images/teams/
```

### 4. Ejecutar flutter pub get
```bash
flutter pub get
```

## 🖼️ Especificaciones Recomendadas

- **Formato**: PNG (con transparencia si es posible)
- **Tamaño**: 256x256 píxeles o superior (idealmente 512x512)
- **Fondo**: Transparente preferiblemente
- **Calidad**: Alta resolución para que se vean bien en pantallas Retina

## ✅ Verificación

Una vez agregados los logos, puedes usarlos en el código así:

```dart
import 'package:myapp/data/team_rosters.dart';

// Obtener logo de un equipo
final logoPath = TeamLogoHelper.getLogoPath('Picassent C.F. \'A\'');
// Retorna: 'assets/images/teams/picassent.png'

// Usar en un widget Image
Image.asset(logoPath ?? TeamLogoHelper.getDefaultLogo())
```

## 🔧 Notas Técnicas

- Los logos se cargan automáticamente desde `TeamRoster.logoPath`
- Si un logo no existe, puedes usar `TeamLogoHelper.getDefaultLogo()`
- Los logos están mapeados en `TeamLogoHelper.teamLogos`

## 📦 Estructura Final

```
assets/
  └── images/
      └── teams/
          ├── picassent.png
          ├── atletic_amistat.png
          ├── salgui.png
          ├── don_bosco.png
          ├── catarroja.png
          ├── fundacio_vcf.png
          ├── sporting_xirivella.png
          ├── torrent.png
          ├── benetusser_favara.png
          ├── alzira.png
          ├── ciutat_valencia.png
          └── san_marcelino.png
```

---

✅ **Una vez que agregues los archivos PNG, los logos aparecerán automáticamente en la app.**
