

## Plan: Recibo Digital, Registro de Pagos en Efectivo y Colores por Entrenador

Este plan cubre tres funcionalidades:
1. **Recibo digital por email** cuando el admin carga creditos manualmente
2. **Registro de pagos en efectivo** con monto anotado para control contable
3. **Colores por entrenador** en la vista semanal de reservas

---

### 1. Recibo Digital por Email

Cuando el administrador carga creditos a un jugador (via paquete o carga manual), se enviara automaticamente un email al padre con un recibo detallado que incluye: nombre del jugador, cantidad de creditos cargados, metodo de pago, monto en efectivo (si aplica) y nuevo saldo.

**Cambios necesarios:**

- **Nueva Edge Function `send-credit-receipt`**: Recibe `user_id`, `player_name`, `credits_added`, `new_balance`, `payment_method`, `cash_amount` y genera un email con formato de recibo profesional usando Resend (la API key ya esta configurada).

- **Actualizar `CreditWalletManager.tsx`**: Despues de cargar creditos exitosamente (tanto por paquete como manual), invocar la edge function para enviar el recibo al padre.

---

### 2. Registro de Pagos en Efectivo

Para que el admin tenga control contable de los pagos recibidos en efectivo al cargar creditos.

**Cambios necesarios:**

- **Nueva tabla `cash_payments`**: Registra cada pago en efectivo con campos:
  - `id` (UUID)
  - `user_id` (quien paga - el padre)
  - `transaction_id` (referencia a `credit_transactions`)
  - `cash_amount` (DECIMAL - monto en euros recibido)
  - `payment_method` (TEXT - "efectivo", "transferencia", "bizum", etc.)
  - `notes` (TEXT - notas adicionales del admin)
  - `received_by` (UUID - admin que recibio el pago)
  - `created_at`
  - RLS: Solo admins pueden ver/insertar/actualizar

- **Actualizar `CreditWalletManager.tsx`**: Anadir campos opcionales en la pestana "Anadir" para registrar:
  - Monto en efectivo recibido (EUR)
  - Metodo de pago (Efectivo / Transferencia / Bizum)
  - Notas adicionales
  
  Estos campos se guardan en `cash_payments` junto con la transaccion de creditos.

- **Reporte contable**: Anadir una seccion en `PlayerCreditsView` o en el historial de transacciones que muestre los pagos en efectivo asociados, para que el admin pueda llevar control.

---

### 3. Colores por Entrenador en Vista Semanal

Cada entrenador tendra un color unico asignado, y las sesiones en la grilla semanal se mostraran con ese color de fondo para identificar rapidamente a que entrenador pertenece cada sesion.

**Cambios necesarios:**

- **Agregar columna `color` a tabla `trainers`**: Campo TEXT para almacenar el color hex asignado (ej: `#06b6d4`, `#a855f7`, `#f59e0b`). Se inicializara con colores predeterminados para los 3 entrenadores existentes (Pedro, Saul, Sebastian).

- **Actualizar `DraggableReservation`** en `WeeklyScheduleView.tsx`: 
  - En lugar de usar solo colores basados en el status, aplicar el color del entrenador como borde izquierdo o fondo sutil.
  - Mostrar una pequena linea/indicador con el color del entrenador.
  - Si no hay entrenador asignado, usar el color por defecto del status.

- **Leyenda de entrenadores**: Agregar una pequena leyenda visual debajo de la navegacion de semana mostrando los colores asignados a cada entrenador.

- **Actualizar `TrainerManagement.tsx`**: Permitir al admin cambiar el color asignado a cada entrenador desde la gestion de entrenadores.

---

### Detalles Tecnicos

**Migracion SQL:**
```text
-- Tabla cash_payments
CREATE TABLE public.cash_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  transaction_id UUID REFERENCES public.credit_transactions(id),
  cash_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'efectivo',
  notes TEXT,
  received_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.cash_payments ENABLE ROW LEVEL SECURITY;

-- Solo admins pueden gestionar pagos
CREATE POLICY "Admins manage cash payments"
  ON public.cash_payments FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Color en trainers  
ALTER TABLE public.trainers 
  ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#06b6d4';

-- Inicializar colores para entrenadores existentes
UPDATE public.trainers SET color = '#06b6d4' WHERE name = 'Pedro';
UPDATE public.trainers SET color = '#a855f7' WHERE name LIKE 'Saul%';
UPDATE public.trainers SET color = '#f59e0b' WHERE name = 'Sebastian';
```

**Edge Function `send-credit-receipt`:**
- Usa Resend API (key ya configurada)
- Genera un email con diseno profesional tipo recibo
- Incluye: fecha, jugador, creditos cargados, metodo de pago, monto, saldo actualizado
- Se agrega a `supabase/config.toml` con `verify_jwt = false`

**Archivos a modificar:**
- `supabase/functions/send-credit-receipt/index.ts` (nuevo)
- `supabase/config.toml` (agregar nueva funcion)
- `src/components/admin/CreditWalletManager.tsx` (campos de pago + envio de recibo)
- `src/components/admin/WeeklyScheduleView.tsx` (colores por entrenador en celdas + leyenda)
- `src/components/admin/TrainerManagement.tsx` (selector de color por entrenador)
- `src/hooks/useTrainers.ts` (incluir campo color en la interfaz Trainer)

**Archivos nuevos:**
- `supabase/functions/send-credit-receipt/index.ts`
- Migracion SQL para `cash_payments` y columna `color` en `trainers`

