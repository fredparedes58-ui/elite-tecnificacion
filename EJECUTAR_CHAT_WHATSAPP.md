# 📱 EJECUTAR SCRIPT SQL - CHAT WHATSAPP

## 🚀 Instrucciones para Ejecutar el Script SQL

El script `SETUP_CHAT_WHATSAPP_FEATURES.sql` está listo para ejecutarse. Este script agrega:

- ✅ Mensajes privados (uno a uno)
- ✅ Audio, documentos, ubicación
- ✅ Representantes de jugadores
- ✅ Políticas de seguridad (RLS)

---

## 📋 Pasos para Ejecutar

### 1. Abre Supabase Dashboard
Ve a: https://supabase.com/dashboard

### 2. Selecciona tu Proyecto
Busca el proyecto de la app de fútbol

### 3. Ve al SQL Editor
- Haz clic en **"SQL Editor"** en el menú lateral
- O ve directamente a: `https://supabase.com/dashboard/project/[TU_PROYECTO]/sql/new`

### 4. Copia y Pega el Script
1. Abre el archivo `SETUP_CHAT_WHATSAPP_FEATURES.sql`
2. **Copia TODO el contenido** (Ctrl+A, Ctrl+C)
3. **Pega** en el editor SQL de Supabase (Ctrl+V)

### 5. Ejecuta el Script
- Haz clic en el botón **"Run"** o presiona `Ctrl+Enter`
- Espera a que termine (debería mostrar "Success" verde)

---

## ✅ Verificación

Después de ejecutar, verifica que todo funcionó:

```sql
-- Verificar que los campos se agregaron correctamente
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'chat_messages' 
AND column_name IN ('recipient_id', 'is_private', 'latitude', 'longitude', 'player_represented_id');

-- Verificar que la vista se creó
SELECT * FROM chat_messages_detailed LIMIT 1;

-- Verificar que la función existe
SELECT proname FROM pg_proc WHERE proname = 'get_or_create_private_chat';
```

---

## ⚠️ Notas Importantes

- Este script es **idempotente**: Puedes ejecutarlo varias veces sin problemas
- Usa `IF NOT EXISTS` y `IF EXISTS` para evitar errores
- Las políticas RLS se actualizan/reemplazan automáticamente
- No afectará datos existentes, solo agrega campos nuevos

---

## 🎯 Después de Ejecutar

Una vez ejecutado el script:

1. ✅ La app podrá usar chats privados
2. ✅ Se podrán enviar audios, documentos y ubicaciones
3. ✅ Los representantes de jugadores estarán integrados
4. ✅ Todo funcionará con las nuevas funcionalidades

---

## 🐛 Si Hay Errores

Si aparece algún error:

1. **Error de permisos**: Asegúrate de ser el owner del proyecto
2. **Error de constraint**: El script maneja esto automáticamente con `DROP CONSTRAINT IF EXISTS`
3. **Error de vista**: El script recrea la vista con `CREATE OR REPLACE`

---

**El script está listo. Solo necesitas copiarlo y ejecutarlo en Supabase Dashboard.** ✨
