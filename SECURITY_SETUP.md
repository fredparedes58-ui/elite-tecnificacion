# 🔐 GUÍA DE SEGURIDAD - Configuración de Credenciales

## ⚠️ PROBLEMA DE SEGURIDAD RESUELTO

**Fecha**: 8 de Enero, 2026  
**Severidad**: 🔴 CRÍTICA  
**Estado**: ✅ SOLUCIONADO

---

## 📋 ¿Qué ocurrió?

Las credenciales de Supabase estaban **hardcodeadas** en el código y **expuestas públicamente** en:
- `lib/config/app_config.dart`
- Historial de git
- Cualquiera con acceso al repositorio podía verlas

**Esto es un riesgo de seguridad crítico** porque permite acceso no autorizado a tu base de datos.

---

## ✅ Solución Implementada

### 1. Variables de Entorno

Ahora las credenciales se almacenan en un archivo `.env` que:
- ✅ **NO se sube a git** (incluido en `.gitignore`)
- ✅ Solo existe localmente en cada máquina
- ✅ Cada desarrollador tiene su propia copia

### 2. Archivos Modificados

```
✅ .gitignore          → Ignora archivos .env
✅ .env.example        → Template sin credenciales
✅ .env                → Archivo real con credenciales (local)
✅ lib/config/app_config.dart → Lee desde variables de entorno
✅ lib/main.dart       → Carga .env al iniciar
✅ pubspec.yaml        → Añadido flutter_dotenv
```

---

## 🚨 ACCIÓN INMEDIATA REQUERIDA

### ⚡ PASO 1: ROTAR CREDENCIALES (URGENTE)

Las credenciales expuestas deben ser rotadas **inmediatamente**:

1. **Ve a Supabase Dashboard**
   ```
   https://supabase.com/dashboard/project/bqqjqasqmuyjnvmiuqvl
   ```

2. **Rotar la API Key**
   - Settings → API
   - Click en "Reset" en la sección "anon key"
   - **IMPORTANTE**: Guarda la nueva key

3. **Actualiza tu archivo `.env`**
   ```bash
   SUPABASE_ANON_KEY=tu-nueva-key-aqui
   ```

### ⚡ PASO 2: Limpiar Historial de Git (Opcional pero Recomendado)

Las credenciales antiguas **siguen en el historial de git**. Para eliminarlas:

```bash
# ADVERTENCIA: Esto reescribe el historial de git
# Solo hazlo si entiendes las consecuencias

# Opción 1: Limpiar con git-filter-repo (recomendado)
git filter-repo --path lib/config/app_config.dart --invert-paths

# Opción 2: BFG Repo-Cleaner
bfg --delete-files app_config.dart

# Después de cualquier opción:
git push origin --force --all
```

**⚠️ ADVERTENCIA**: Esto reescribirá el historial. Coordina con tu equipo antes de hacerlo.

---

## 📦 Instalación para Nuevos Desarrolladores

### Paso 1: Clonar el Repositorio
```bash
git clone [tu-repo]
cd futbol---app
```

### Paso 2: Crear Archivo `.env`
```bash
cp .env.example .env
```

### Paso 3: Obtener Credenciales de Supabase

1. Ve a: https://supabase.com/dashboard
2. Selecciona tu proyecto: `bqqjqasqmuyjnvmiuqvl`
3. Settings → API
4. Copia:
   - **Project URL** → `SUPABASE_URL`
   - **anon/public key** → `SUPABASE_ANON_KEY`

### Paso 4: Editar `.env`
```bash
# Abre con tu editor favorito
nano .env

# O
code .env
```

Reemplaza los valores:
```env
SUPABASE_URL=https://bqqjqasqmuyjnvmiuqvl.supabase.co
SUPABASE_ANON_KEY=tu-nueva-key-rotada-aqui
N8N_WEBHOOK_URL=https://pedro08.app.n8n.cloud/webhook/cronica
```

### Paso 5: Instalar Dependencias
```bash
flutter pub get
```

### Paso 6: Ejecutar
```bash
flutter run
```

---

## 🔒 Mejores Prácticas de Seguridad

### ✅ DO (Hacer)

1. **Rotar credenciales inmediatamente** cuando se exponen
2. **Usar variables de entorno** para datos sensibles
3. **Incluir `.env` en `.gitignore`** siempre
4. **Proporcionar `.env.example`** como template
5. **Usar Row Level Security (RLS)** en Supabase
6. **Limitar permisos** de las API keys

### ❌ DON'T (No Hacer)

1. ❌ Nunca commitear archivos `.env` a git
2. ❌ Nunca hardcodear credenciales en el código
3. ❌ Nunca compartir credenciales por email/chat
4. ❌ Nunca usar credenciales de producción en desarrollo
5. ❌ Nunca dejar credenciales en logs o screenshots

---

## 🛡️ Verificación de Seguridad

### Checklist Post-Implementación

```bash
# ✅ Verificar que .env está en .gitignore
cat .gitignore | grep .env

# ✅ Verificar que .env NO está en git
git status --ignored | grep .env

# ✅ Verificar que app_config.dart no tiene credenciales
grep -i "eyJ" lib/config/app_config.dart

# ✅ Verificar que la app lee correctamente las variables
flutter run --verbose
```

### Resultado Esperado

```
✅ .env aparece en .gitignore
✅ .env NO aparece en git status (como untracked)
✅ app_config.dart NO contiene tokens JWT
✅ App inicia sin errores de configuración
```

---

## 🔐 Configuración Adicional en Supabase

### 1. Habilitar Row Level Security (RLS)

```sql
-- En Supabase SQL Editor:
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
```

### 2. Políticas de Acceso

```sql
-- Solo usuarios autenticados pueden ver perfiles
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Solo coaches pueden modificar equipos
CREATE POLICY "Coaches can manage teams"
ON teams FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = teams.id
    AND user_id = auth.uid()
    AND role = 'coach'
  )
);
```

### 3. Limitar Tasa de Peticiones

En Supabase Dashboard:
- Settings → API
- Enable "Rate Limiting"
- Max requests: 100/minute (ajustar según necesidad)

---

## 📊 Monitoreo de Seguridad

### Logs de Acceso

Revisa regularmente en Supabase:
- Dashboard → Logs → API Logs
- Busca patrones sospechosos:
  - Múltiples fallos de autenticación
  - Accesos desde IPs desconocidas
  - Queries extrañas

### Alertas Recomendadas

Configura notificaciones para:
- ⚠️ Intentos de acceso no autorizado
- ⚠️ Cambios en tablas críticas
- ⚠️ Uso excesivo de la API
- ⚠️ Errores de autenticación

---

## 🆘 Incidentes de Seguridad

### Si Detectas un Acceso No Autorizado:

1. **🚨 Acción Inmediata**
   - Rotar TODAS las API keys
   - Cambiar contraseñas de administrador
   - Revisar logs de acceso

2. **🔍 Investigación**
   - Identificar qué datos fueron accedidos
   - Revisar cambios en la base de datos
   - Documentar el incidente

3. **🛡️ Prevención**
   - Implementar RLS más estricto
   - Añadir autenticación de dos factores
   - Auditar permisos de usuarios

4. **📢 Notificación**
   - Informar al equipo
   - Si hay datos de usuarios afectados, considerar notificación

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Supabase Security](https://supabase.com/docs/guides/auth/security)
- [Flutter Environment Variables](https://pub.dev/packages/flutter_dotenv)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

### Herramientas de Auditoría

- [git-secrets](https://github.com/awslabs/git-secrets) - Previene commits con secretos
- [truffleHog](https://github.com/trufflesecurity/trufflehog) - Encuentra secretos en git
- [gitleaks](https://github.com/gitleaks/gitleaks) - Escáner de secretos

---

## ✅ Checklist Final

```
☐ Credenciales rotadas en Supabase
☐ Archivo .env creado localmente
☐ .env añadido a .gitignore
☐ app_config.dart actualizado para leer .env
☐ main.dart carga dotenv al iniciar
☐ Dependencia flutter_dotenv añadida
☐ App ejecuta sin errores
☐ RLS habilitado en Supabase
☐ Políticas de seguridad configuradas
☐ Rate limiting activado
☐ Equipo informado del cambio
☐ Documentación actualizada
```

---

## 🎯 Resumen

**Antes**:
```dart
// ❌ INSEGURO
static const String supabaseUrl = 'https://...';
static const String supabaseAnonKey = 'eyJ...';
```

**Después**:
```dart
// ✅ SEGURO
static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? ...;
static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? ...;
```

**Credenciales ahora en**:
- `.env` (local, NO commiteado)
- Variables de entorno en producción
- Secrets manager en CI/CD

---

**📞 ¿Preguntas?**

Si tienes dudas sobre la implementación o necesitas ayuda con la rotación de credenciales, consulta:
- Documentación de Supabase: https://supabase.com/docs
- Flutter Security Best Practices: https://flutter.dev/security

---

**Última actualización**: 8 de Enero, 2026  
**Versión del documento**: 1.0  
**Responsable**: Equipo de Desarrollo
