# Elite 380 L - Academia de Fútbol de Élite

Aplicación móvil y web para gestión de entrenamientos, reservas y seguimiento de jugadores.

## 📋 Descripción

Elite 380 L es una aplicación híbrida desarrollada con React, TypeScript, Vite y Capacitor que permite a padres y entrenadores gestionar sesiones de entrenamiento, reservas, seguimiento de jugadores y comunicación en tiempo real.

## 🛠️ Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- **Node.js** (v18 o superior) - [Descargar](https://nodejs.org/)
- **npm** (v9 o superior) - Viene con Node.js
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
   git clone <url-del-repositorio>
   cd "Elite 380 L"
   ```

2. **Instalar dependencias**:
   ```bash
   npm install
   ```

3. **Configurar variables de entorno**:
   
   Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:
   
   ```env
   VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
   VITE_SUPABASE_PROJECT_ID=tu-project-id
   VITE_SUPABASE_PUBLISHABLE_KEY=tu-publishable-key
   ```
   
   > **Nota:** Obtén estas credenciales desde tu proyecto en [Supabase Dashboard](https://app.supabase.com)

## 🚀 Desarrollo

### Ejecutar en modo desarrollo (Web)

```bash
npm run dev
```

La aplicación estará disponible en `http://localhost:5173` (o el puerto que Vite asigne).

### Build para producción (Web)

```bash
npm run build
```

Los archivos compilados se generarán en la carpeta `dist/`.

### Preview del build de producción

```bash
npm run preview
```

## 📱 Build para Aplicaciones Nativas

### Configuración inicial de Capacitor

Si es la primera vez que trabajas con este proyecto, necesitas sincronizar las plataformas:

```bash
# Sincronizar Capacitor con las plataformas
npx cap sync
```

### iOS

1. **Agregar plataforma iOS** (si no está agregada):
   ```bash
   npx cap add ios
   npx cap sync
   ```

2. **Abrir en Xcode**:
   ```bash
   npx cap open ios
   ```

3. **Configurar Signing en Xcode**:
   - En Xcode, selecciona el proyecto "App" en el navegador
   - Ve a la pestaña "Signing & Capabilities"
   - Selecciona tu equipo de desarrollo
   - Xcode generará automáticamente un perfil de aprovisionamiento

4. **Ejecutar en simulador**:
   - En Xcode, selecciona un simulador (iPhone 14 Pro, etc.)
   - Presiona el botón "Play" o usa `Cmd + R`

5. **Ejecutar en dispositivo físico**:
   - Conecta tu iPhone/iPad vía USB
   - Selecciona tu dispositivo en Xcode
   - Presiona "Play"
   - En tu dispositivo, ve a Configuración > General > Gestión de Dispositivos y confía en el certificado

### Android

1. **Agregar plataforma Android** (si no está agregada):
   ```bash
   npx cap add android
   npx cap sync
   ```

2. **Abrir en Android Studio**:
   ```bash
   npx cap open android
   ```

3. **Configurar Signing** (para producción):
   - En Android Studio, ve a `android/app/build.gradle`
   - Configura `signingConfigs` con tus credenciales de keystore
   - Ejemplo:
     ```gradle
     signingConfigs {
         release {
             storeFile file('path/to/keystore.jks')
             storePassword 'tu-password'
             keyAlias 'tu-alias'
             keyPassword 'tu-password'
         }
     }
     ```

4. **Ejecutar en emulador**:
   - En Android Studio, crea un AVD (Android Virtual Device) si no tienes uno
   - Selecciona el emulador y presiona "Run" (▶️)

5. **Ejecutar en dispositivo físico**:
   - Habilita "Opciones de desarrollador" y "Depuración USB" en tu dispositivo Android
   - Conecta vía USB
   - Selecciona tu dispositivo en Android Studio y presiona "Run"

## 🔄 Flujo de trabajo recomendado

1. **Desarrollar en web**:
   ```bash
   npm run dev
   ```
   - Realiza cambios en el código
   - Prueba en el navegador

2. **Cuando estés listo para probar en móvil**:
   ```bash
   # Build para producción
   npm run build
   
   # Sincronizar con Capacitor
   npx cap sync
   
   # Abrir en Xcode o Android Studio
   npx cap open ios    # o
   npx cap open android
   ```

3. **Después de cambios en código nativo**:
   - Si modificas archivos en `ios/` o `android/`, ejecuta `npx cap sync` nuevamente

## 📝 Variables de Entorno Completas

Lista completa de variables de entorno necesarias:

```env
# Supabase
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_PROJECT_ID=tu-project-id
VITE_SUPABASE_PUBLISHABLE_KEY=tu-publishable-key

# Push Notifications (Firebase Cloud Messaging)
# Configurar en Supabase Edge Functions como secretos:
# FCM_SERVER_KEY=tu-fcm-server-key

# Resend (para emails)
# Configurar en Supabase Edge Functions como secretos:
# RESEND_API_KEY=tu-resend-api-key
```

## 🐛 Troubleshooting

### Problemas comunes

#### "Module not found" o errores de importación
```bash
# Eliminar node_modules y reinstalar
rm -rf node_modules package-lock.json
npm install
```

#### Capacitor no sincroniza cambios
```bash
# Forzar sincronización completa
npx cap sync --force
```

#### Errores de build en iOS
- Verifica que CocoaPods esté instalado: `pod --version`
- En `ios/`, ejecuta: `pod install`
- Limpia el build en Xcode: Product > Clean Build Folder (`Cmd + Shift + K`)

#### Errores de build en Android
- Verifica que Android SDK esté instalado correctamente
- En Android Studio, ve a File > Sync Project with Gradle Files
- Limpia el proyecto: Build > Clean Project

#### Push Notifications no funcionan
- Verifica que `FCM_SERVER_KEY` esté configurado en Supabase Edge Functions
- En iOS, asegúrate de tener un certificado APNs configurado en Xcode
- En Android, verifica que `google-services.json` esté en `android/app/`

#### La app no se conecta a Supabase
- Verifica que las variables de entorno en `.env` sean correctas
- Asegúrate de que `VITE_SUPABASE_URL` tenga el protocolo `https://`
- Revisa la consola del navegador/dispositivo para errores de CORS

## 📚 Estructura del Proyecto

```
Elite 380 L/
├── src/
│   ├── components/      # Componentes React reutilizables
│   ├── contexts/        # Contextos de React (Auth, etc.)
│   ├── hooks/           # Custom hooks
│   ├── integrations/    # Integraciones (Supabase, etc.)
│   ├── pages/           # Páginas principales
│   ├── services/        # Servicios (API, storage, etc.)
│   └── main.tsx         # Punto de entrada
├── supabase/
│   ├── functions/       # Edge Functions
│   └── migrations/      # Migraciones SQL
├── android/             # Código nativo Android
├── ios/                 # Código nativo iOS
├── public/              # Archivos estáticos
├── capacitor.config.ts # Configuración de Capacitor
├── package.json         # Dependencias
└── vite.config.ts       # Configuración de Vite
```

## 🔐 Seguridad

- Las políticas RLS (Row Level Security) están configuradas en Supabase
- Los tokens de autenticación se manejan automáticamente por Supabase Auth
- Las Edge Functions requieren autenticación para operaciones sensibles

## 📞 Soporte

Para problemas o preguntas:
1. Revisa la sección de Troubleshooting
2. Consulta la documentación de [Capacitor](https://capacitorjs.com/docs)
3. Consulta la documentación de [Supabase](https://supabase.com/docs)

## 📄 Licencia

[Especificar licencia si aplica]

---

**Última actualización:** Febrero 2026
