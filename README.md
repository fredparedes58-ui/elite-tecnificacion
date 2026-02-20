# Elite 380 L - Academia de Fútbol de Élite

Aplicación móvil y web para gestión de entrenamientos, reservas y seguimiento de jugadores.

## 📋 Descripción

Elite 380 L es una aplicación desarrollada con Flutter que permite a padres y entrenadores gestionar sesiones de entrenamiento, reservas, seguimiento de jugadores y comunicación en tiempo real.

## 🛠️ Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- **Flutter** (v3.9 o superior) - [Descargar](https://flutter.dev/docs/get-started/install)
- **Dart** (v3.9 o superior) - Viene con Flutter
- **Git** - [Descargar](https://git-scm.com/)

### Para iOS:
- **macOS** (requerido para desarrollo iOS)
- **Xcode** (v14 o superior) - [Descargar desde App Store](https://apps.apple.com/app/xcode/id497799835)
- **CocoaPods** - Instalar con: `sudo gem install cocoapods`

### Para Android:
- **Android Studio** (Arctic Fox o superior) - [Descargar](https://developer.android.com/studio)
- **Java Development Kit (JDK)** 11 o superior
- **Android SDK** (instalado automáticamente con Android Studio)

## 📦 Instalación

1. **Clonar el repositorio** (si aún no lo has hecho):
   ```bash
   git clone https://github.com/fredparedes58-ui/elite-tecnificacion.git
   cd elite-tecnificacion
   ```

2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

3. **Configurar variables de entorno**:
   
   Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:
   
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu-anon-key
   ```
   
   > **Nota:** Obtén estas credenciales desde tu proyecto en [Supabase Dashboard](https://app.supabase.com)

## 🚀 Desarrollo

### Ejecutar en modo desarrollo

```bash
flutter run
```

### Ejecutar en dispositivo específico

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en dispositivo específico
flutter run -d <device-id>
```

### Build para producción

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📱 Build para Aplicaciones Nativas

### iOS

1. **Abrir en Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configurar Signing en Xcode**:
   - En Xcode, selecciona el proyecto "Runner" en el navegador
   - Ve a la pestaña "Signing & Capabilities"
   - Selecciona tu equipo de desarrollo
   - Xcode generará automáticamente un perfil de aprovisionamiento

3. **Ejecutar en simulador**:
   - En Xcode, selecciona un simulador (iPhone 14 Pro, etc.)
   - Presiona el botón "Play" o usa `Cmd + R`

### Android

1. **Abrir en Android Studio**:
   ```bash
   open android/
   ```

2. **Ejecutar en emulador**:
   - En Android Studio, crea un AVD (Android Virtual Device) si no tienes uno
   - Selecciona el emulador y presiona "Run" (▶️)

## 🔄 Flujo de trabajo recomendado

1. **Desarrollar**:
   ```bash
   flutter run
   ```
   - Realiza cambios en el código
   - Usa `r` para hot reload o `R` para hot restart

2. **Cuando estés listo para producción**:
   ```bash
   flutter build apk --release    # Android
   flutter build ios --release    # iOS
   ```

## 📝 Variables de Entorno Completas

Lista completa de variables de entorno necesarias:

```env
# Supabase
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key
```

## 🐛 Troubleshooting

### Problemas comunes

#### "Module not found" o errores de importación
```bash
# Limpiar y reinstalar
flutter clean
flutter pub get
```

#### Errores de build en iOS
- Verifica que CocoaPods esté instalado: `pod --version`
- En `ios/`, ejecuta: `pod install`
- Limpia el build en Xcode: Product > Clean Build Folder (`Cmd + Shift + K`)

#### Errores de build en Android
- Verifica que Android SDK esté instalado correctamente
- En Android Studio, ve a File > Sync Project with Gradle Files
- Limpia el proyecto: Build > Clean Project

#### La app no se conecta a Supabase
- Verifica que las variables de entorno en `.env` sean correctas
- Asegúrate de que `SUPABASE_URL` tenga el protocolo `https://`
- Revisa la consola para errores de CORS

## 📚 Estructura del Proyecto

```
elite-tecnificacion/
├── lib/
│   ├── screens/          # Pantallas principales
│   ├── widgets/           # Widgets reutilizables
│   ├── services/          # Servicios (Supabase, etc.)
│   ├── models/            # Modelos de datos
│   ├── theme/             # Tema y estilos
│   └── main.dart          # Punto de entrada
├── supabase/
│   ├── functions/         # Edge Functions
│   └── migrations/        # Migraciones SQL
├── android/               # Código nativo Android
├── ios/                   # Código nativo iOS
├── assets/                # Archivos estáticos
├── pubspec.yaml           # Dependencias
└── .env                   # Variables de entorno (no commitear)
```

## 🔐 Seguridad

- Las políticas RLS (Row Level Security) están configuradas en Supabase
- Los tokens de autenticación se manejan automáticamente por Supabase Auth
- Las Edge Functions requieren autenticación para operaciones sensibles

## 📞 Soporte

Para problemas o preguntas:
1. Revisa la sección de Troubleshooting
2. Consulta la documentación de [Flutter](https://flutter.dev/docs)
3. Consulta la documentación de [Supabase](https://supabase.com/docs)

## 📄 Licencia

[Especificar licencia si aplica]

---

**Última actualización:** Febrero 2026
