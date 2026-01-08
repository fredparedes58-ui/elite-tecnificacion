# Configuración de Supabase Storage para Fotos de Jugadores

## 📦 Bucket Requerido

Necesitas crear un bucket en Supabase Storage para almacenar las fotos de los jugadores.

### Pasos en Supabase Dashboard:

1. **Ir a Storage**
   - Abre tu proyecto en [supabase.com](https://supabase.com)
   - Ve a la sección **Storage** en el menú lateral

2. **Crear Nuevo Bucket**
   - Haz clic en **"New bucket"**
   - Nombre: `player-photos`
   - Público: ✅ **Sí** (para que las URLs sean accesibles)
   - File size limit: 5 MB (recomendado)
   - Allowed MIME types: `image/jpeg, image/png, image/webp`

3. **Configurar Políticas de Seguridad (RLS)**

   Ejecuta estas políticas SQL en el editor SQL de Supabase:

   ```sql
   -- Permitir lectura pública de fotos
   CREATE POLICY "Public Access"
   ON storage.objects FOR SELECT
   USING ( bucket_id = 'player-photos' );

   -- Permitir subida solo a usuarios autenticados
   CREATE POLICY "Authenticated users can upload"
   ON storage.objects FOR INSERT
   WITH CHECK (
     bucket_id = 'player-photos' 
     AND auth.role() = 'authenticated'
   );

   -- Permitir actualización solo a usuarios autenticados
   CREATE POLICY "Authenticated users can update"
   ON storage.objects FOR UPDATE
   USING ( bucket_id = 'player-photos' AND auth.role() = 'authenticated' );

   -- Permitir eliminación solo a usuarios autenticados
   CREATE POLICY "Authenticated users can delete"
   ON storage.objects FOR DELETE
   USING ( bucket_id = 'player-photos' AND auth.role() = 'authenticated' );
   ```

4. **Verificar Tabla `profiles`**

   Asegúrate de que la tabla `profiles` tiene el campo `avatar_url`:

   ```sql
   -- Agregar columna si no existe
   ALTER TABLE profiles 
   ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT 'assets/players/default.png';
   ```

## ✅ Buckets Completos del Proyecto

Tu configuración final debe tener estos buckets:

```
📦 Supabase Storage
├── 📁 player-photos (fotos de perfil de jugadores)
├── 📁 app-files (archivos generales de la app)
└── 📁 documents (PDFs, tácticas, etc.)
```

## 🔒 Notas de Seguridad

- **Público:** Las fotos de jugadores son públicas (necesario para mostrarlas en la app)
- **Autenticación:** Solo usuarios autenticados pueden subir/modificar/eliminar fotos
- **Límite de tamaño:** 5 MB por imagen (configurable)

## 🧪 Probar la Funcionalidad

1. Ejecuta la app: `flutter run -d chrome`
2. Navega a la ficha de un jugador
3. Haz clic en la foto de perfil
4. Selecciona una imagen desde:
   - 📷 Cámara (solo móvil)
   - 🖼️ Galería
   - 📁 Explorador de archivos (PC/Nube)
5. Verifica que la foto se suba y actualice en la base de datos

## 🐛 Troubleshooting

### Error: "Bucket not found"
- Verifica que el bucket `player-photos` existe en Storage
- Asegúrate de que el nombre es exactamente `player-photos` (sin espacios)

### Error: "Policy violation"
- Verifica que las políticas RLS están configuradas correctamente
- Asegúrate de que el usuario está autenticado

### La imagen no se muestra
- Verifica que el bucket es **público**
- Revisa que la URL en `avatar_url` es correcta
- Comprueba la consola del navegador para errores CORS
