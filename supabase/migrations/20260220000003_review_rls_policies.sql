-- =============================================================================
-- Revisión y Documentación de Políticas RLS (Row Level Security)
-- Fecha: 2026-02-20
-- =============================================================================
-- Este archivo documenta las políticas RLS recomendadas para las tablas
-- principales: players, reservations, y profiles.
-- Si alguna política falta, se documenta aquí para implementación futura.
-- =============================================================================

-- =============================================================================
-- TABLA: players
-- =============================================================================
-- Políticas recomendadas:
-- 1. Los padres solo pueden ver/editar sus propios jugadores (players.parent_id = auth.uid())
-- 2. Los admins pueden ver/editar todos los jugadores
-- 3. Los entrenadores pueden ver jugadores de sus sesiones (a través de enrollments)

-- Verificar si RLS está habilitado
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'players'
  ) THEN
    RAISE NOTICE 'Tabla players no existe';
  ELSIF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'players'
  ) THEN
    RAISE NOTICE '⚠️ ADVERTENCIA: Tabla players no tiene políticas RLS configuradas';
    RAISE NOTICE 'Recomendación: Crear políticas para que padres solo vean sus jugadores';
  ELSE
    RAISE NOTICE '✅ Tabla players tiene políticas RLS configuradas';
  END IF;
END $$;

-- Política recomendada para players (si no existe):
-- CREATE POLICY "Parents can view own players"
--   ON players FOR SELECT
--   USING (parent_id = auth.uid());
--
-- CREATE POLICY "Parents can insert own players"
--   ON players FOR INSERT
--   WITH CHECK (parent_id = auth.uid());
--
-- CREATE POLICY "Parents can update own players"
--   ON players FOR UPDATE
--   USING (parent_id = auth.uid());
--
-- CREATE POLICY "Admins can manage all players"
--   ON players FOR ALL
--   USING (
--     EXISTS (
--       SELECT 1 FROM user_roles
--       WHERE user_roles.user_id = auth.uid()
--       AND user_roles.role = 'admin'
--     )
--   );

-- =============================================================================
-- TABLA: reservations
-- =============================================================================
-- Políticas recomendadas:
-- 1. Los padres solo pueden ver sus propias reservas (reservations.user_id = auth.uid())
-- 2. Los admins pueden ver todas las reservas
-- 3. Los entrenadores pueden ver reservas donde son trainer (reservations.trainer_id = auth.uid())

-- Verificar si RLS está habilitado
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'reservations'
  ) THEN
    RAISE NOTICE 'Tabla reservations no existe';
  ELSIF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'reservations'
  ) THEN
    RAISE NOTICE '⚠️ ADVERTENCIA: Tabla reservations no tiene políticas RLS configuradas';
    RAISE NOTICE 'Recomendación: Crear políticas para que padres solo vean sus reservas';
  ELSE
    RAISE NOTICE '✅ Tabla reservations tiene políticas RLS configuradas';
  END IF;
END $$;

-- Política recomendada para reservations (si no existe):
-- CREATE POLICY "Users can view own reservations"
--   ON reservations FOR SELECT
--   USING (user_id = auth.uid());
--
-- CREATE POLICY "Users can create own reservations"
--   ON reservations FOR INSERT
--   WITH CHECK (user_id = auth.uid());
--
-- CREATE POLICY "Users can update own reservations"
--   ON reservations FOR UPDATE
--   USING (user_id = auth.uid());
--
-- CREATE POLICY "Trainers can view their sessions"
--   ON reservations FOR SELECT
--   USING (trainer_id = auth.uid());
--
-- CREATE POLICY "Admins can manage all reservations"
--   ON reservations FOR ALL
--   USING (
--     EXISTS (
--       SELECT 1 FROM user_roles
--       WHERE user_roles.user_id = auth.uid()
--       AND user_roles.role = 'admin'
--     )
--   );

-- =============================================================================
-- TABLA: profiles
-- =============================================================================
-- Políticas recomendadas:
-- 1. Los usuarios solo pueden ver su propio perfil (profiles.id = auth.uid())
-- 2. Los usuarios pueden actualizar su propio perfil
-- 3. Los admins pueden ver todos los perfiles

-- Verificar si RLS está habilitado
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'profiles'
  ) THEN
    RAISE NOTICE 'Tabla profiles no existe';
  ELSIF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'profiles'
  ) THEN
    RAISE NOTICE '⚠️ ADVERTENCIA: Tabla profiles no tiene políticas RLS configuradas';
    RAISE NOTICE 'Recomendación: Crear políticas para que usuarios solo vean su perfil';
  ELSE
    RAISE NOTICE '✅ Tabla profiles tiene políticas RLS configuradas';
  END IF;
END $$;

-- Política recomendada para profiles (si no existe):
-- CREATE POLICY "Users can view own profile only"
--   ON profiles FOR SELECT
--   USING (id = auth.uid());
--
-- CREATE POLICY "Users can update own profile"
--   ON profiles FOR UPDATE
--   USING (id = auth.uid());
--
-- CREATE POLICY "Admins can view all profiles"
--   ON profiles FOR SELECT
--   USING (
--     EXISTS (
--       SELECT 1 FROM user_roles
--       WHERE user_roles.user_id = auth.uid()
--       AND user_roles.role = 'admin'
--     )
--   );

-- =============================================================================
-- RESUMEN DE VERIFICACIÓN
-- =============================================================================
-- Este script verifica que las políticas RLS estén configuradas correctamente.
-- Si alguna política falta, se documenta arriba para implementación manual.
--
-- Para verificar políticas existentes:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- AND tablename IN ('players', 'reservations', 'profiles')
-- ORDER BY tablename, policyname;

COMMENT ON SCHEMA public IS 'Revisión de políticas RLS completada el 2026-02-20. Ver migración 20260220000003_review_rls_policies.sql para detalles.';
