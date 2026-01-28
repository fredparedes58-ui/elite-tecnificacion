
## Plan: Completar Funcionalidades para Operatividad Total

### Fase 1: Tabla de Notificaciones (Critico)

**Crear migracion SQL para tabla `notifications`:**
```sql
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indices
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);

-- RLS Policies
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications"
  ON public.notifications FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
```

**Archivos afectados:**
- Remover `as any` casts en `src/hooks/useNotificationsCenter.ts`

---

### Fase 2: Cancelacion de Reservas para Padres

**Modificar `src/hooks/useReservations.ts`:**
- Agregar funcion `cancelReservation(id: string)` para padres
- Solo permitir cancelar reservas con status `pending` o `approved`
- Reembolsar creditos si estaba `approved`

**Modificar `src/pages/Reservations.tsx`:**
- Agregar boton "Cancelar" en cada tarjeta de reserva
- Mostrar modal de confirmacion antes de cancelar
- Deshabilitar cancelacion si la sesion es en menos de 24 horas

---

### Fase 3: Integrar Paquetes de Creditos en Wallet Manager

**Modificar `src/components/admin/CreditWalletManager.tsx`:**
```typescript
// Importar hook de paquetes
import { useCreditPackages } from '@/hooks/useCreditPackages';

// Reemplazar BONUS_OPTIONS hardcodeado
const { packages } = useCreditPackages();

// Usar packages.map() en lugar de BONUS_OPTIONS.map()
```

**Resultado:**
- Admin puede crear/editar paquetes desde CreditPackagesManager
- Los paquetes aparecen automaticamente en CreditWalletManager

---

### Fase 4: Pagina de Perfil de Usuario

**Crear `src/pages/Profile.tsx`:**
- Formulario para editar nombre completo
- Opcion para cambiar contrasena
- Mostrar email (readonly)
- Mostrar fecha de registro

**Modificar `src/App.tsx`:**
- Agregar ruta `/profile`

**Modificar `src/components/layout/Navbar.tsx`:**
- Agregar enlace a "Mi Perfil" en el menu de usuario

---

### Fase 5: Dashboard de Admin Mejorado

**Crear `src/components/admin/AdminDashboard.tsx`:**
- Cards con metricas:
  - Total usuarios activos
  - Reservas esta semana
  - Creditos vendidos este mes
  - Tasa de asistencia global
- Graficos rapidos de tendencias
- Lista de acciones pendientes (reservas por aprobar)

**Modificar `src/pages/Index.tsx`:**
- Mostrar AdminDashboard cuando `isAdmin === true`

---

### Fase 6: Exportar Reportes

**Modificar `src/components/admin/AttendanceReports.tsx`:**
- Agregar boton "Exportar a Excel"
- Usar libreria como `xlsx` para generar archivo
- Incluir datos de asistencia por mes/jugador/entrenador

**Modificar `src/components/admin/CreditTransactionHistory.tsx`:**
- Agregar boton "Exportar Historial"
- Generar CSV con transacciones

---

### Fase 7: Configuracion del Sistema (Opcional)

**Crear tabla `system_config`:**
```sql
CREATE TABLE public.system_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Valores iniciales
INSERT INTO system_config (key, value) VALUES
  ('schedule_hours', '{"start": 16, "end": 22}'),
  ('max_capacity', '6'),
  ('low_credit_threshold', '3'),
  ('active_days', '[1,2,3,4,5]');
```

**Crear `src/pages/AdminSettings.tsx`:**
- Formulario para editar configuracion
- Horarios de sesiones
- Capacidad maxima
- Umbral de creditos bajos

---

### Resumen de Archivos a Crear/Modificar

| Archivo | Accion | Prioridad |
|---------|--------|-----------|
| **Migracion SQL** | Crear tabla `notifications` | Alta |
| `src/hooks/useNotificationsCenter.ts` | Quitar type casts | Alta |
| `src/hooks/useReservations.ts` | Agregar `cancelReservation` | Alta |
| `src/pages/Reservations.tsx` | Boton cancelar + modal | Alta |
| `src/components/admin/CreditWalletManager.tsx` | Integrar `useCreditPackages` | Media |
| `src/pages/Profile.tsx` | Nueva pagina | Media |
| `src/App.tsx` | Ruta `/profile` | Media |
| `src/components/admin/AdminDashboard.tsx` | Nuevo componente | Media |
| `src/pages/Index.tsx` | Mostrar AdminDashboard | Media |
| `src/components/admin/AttendanceReports.tsx` | Exportar Excel | Baja |
| `src/pages/AdminSettings.tsx` | Configuracion | Baja |

---

### Orden de Implementacion Recomendado

1. **Tabla notifications** - Sin esto, los triggers fallan silenciosamente
2. **Cancelacion de reservas** - Funcionalidad basica esperada por padres
3. **Integrar paquetes de creditos** - Ya existe el codigo, solo falta conectar
4. **Pagina de perfil** - UX basica para usuarios
5. **Dashboard admin** - Mejora la experiencia del admin
6. **Exportar reportes** - Funcionalidad avanzada
7. **Configuracion del sistema** - Opcional, puede seguir hardcoded inicialmente
