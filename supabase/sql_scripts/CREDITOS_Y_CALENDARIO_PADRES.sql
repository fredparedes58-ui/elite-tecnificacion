-- =============================================================================
-- SCRIPTS: Créditos para padres + Calendario escolar + Resumen/verificación
-- Ejecutar en Supabase SQL Editor en el orden que necesites.
--
-- Si ves "relation public.user_credits does not exist":
--   La tabla user_credits no existe. Ejecuta ANTES la migración
--   supabase/migrations/20260221110000_user_credits_and_realtime.sql
--   en el SQL Editor (todo el contenido del archivo).
-- =============================================================================

-- =============================================================================
-- PUNTO 2: DAR CRÉDITOS A PADRES
-- =============================================================================
-- Solo se ejecuta si la tabla user_credits existe. Da balance 10 a padres
-- que tengan relación en parent_child_relationships y aún no tengan fila.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_credits') THEN
    RAISE NOTICE 'PUNTO 2 omitido: la tabla user_credits no existe. Ejecuta antes la migración 20260221110000_user_credits_and_realtime.sql';
    RETURN;
  END IF;

  INSERT INTO public.user_credits (user_id, balance)
  SELECT pcr.parent_id, 10
  FROM public.parent_child_relationships pcr
  LEFT JOIN public.user_credits uc ON uc.user_id = pcr.parent_id
  WHERE uc.user_id IS NULL
  ON CONFLICT (user_id) DO NOTHING;

  RAISE NOTICE 'PUNTO 2 listo: créditos asignados a padres que no tenían fila.';
END $$;

-- Si no tienes parent_child_relationships, usa los perfiles que existan y
-- crea una fila por cada uno (descomenta y ajusta si hace falta):
/*
INSERT INTO public.user_credits (user_id, balance)
SELECT id, 10
FROM public.profiles p
WHERE NOT EXISTS (SELECT 1 FROM public.user_credits uc WHERE uc.user_id = p.id)
ON CONFLICT (user_id) DO NOTHING;
*/

-- Opción B: Dar créditos a UN padre concreto (sustituye USER_ID_DEL_PADRE).
-- =============================================================================
/*
INSERT INTO public.user_credits (user_id, balance)
VALUES ('USER_ID_DEL_PADRE', 10)
ON CONFLICT (user_id) DO UPDATE SET balance = user_credits.balance + 10;
*/

-- Opción C: Sumar 10 créditos a todos los padres que ya tengan fila.
-- =============================================================================
/*
UPDATE public.user_credits uc
SET balance = balance + 10, updated_at = NOW()
WHERE user_id IN (SELECT parent_id FROM public.parent_child_relationships);
*/


-- =============================================================================
-- PUNTO 3: EVENTOS EN EL CALENDARIO ESCOLAR
-- =============================================================================
-- Inserta eventos de ejemplo (eventos, cierres, entrenamientos especiales).
-- Tipos: 'event' | 'closure' | 'special_training'
-- =============================================================================

INSERT INTO public.school_calendar_events (title, description, event_type, start_at, end_at)
VALUES
  -- Cierres
  ('Cierre por festivo local', 'No hay actividad. Disfruten el día.', 'closure',
   date_trunc('week', CURRENT_DATE + INTERVAL '1 week') + INTERVAL '1 day',
   date_trunc('week', CURRENT_DATE + INTERVAL '1 week') + INTERVAL '1 day'),
  ('Fin de temporada', 'Último día de actividad antes de vacaciones.', 'closure',
   date_trunc('month', CURRENT_DATE) + INTERVAL '2 months' - INTERVAL '1 day',
   date_trunc('month', CURRENT_DATE) + INTERVAL '2 months' - INTERVAL '1 day'),
  -- Entrenamientos especiales
  ('Entrenamiento técnico abierto', 'Sesión extra de técnica para todas las categorías.', 'special_training',
   date_trunc('week', CURRENT_DATE + INTERVAL '2 weeks') + INTERVAL '3 days' + TIME '18:00',
   date_trunc('week', CURRENT_DATE + INTERVAL '2 weeks') + INTERVAL '3 days' + TIME '20:00'),
  ('Clinic de porteros', 'Entrenamiento específico para porteros.', 'special_training',
   date_trunc('week', CURRENT_DATE + INTERVAL '3 weeks') + INTERVAL '6 days' + TIME '10:00',
   date_trunc('week', CURRENT_DATE + INTERVAL '3 weeks') + INTERVAL '6 days' + TIME '12:00'),
  -- Eventos generales
  ('Reunión de padres', 'Información sobre la temporada y horarios.', 'event',
   date_trunc('week', CURRENT_DATE + INTERVAL '1 week') + INTERVAL '5 days' + TIME '19:00',
   date_trunc('week', CURRENT_DATE + INTERVAL '1 week') + INTERVAL '5 days' + TIME '20:30'),
  ('Torneo interno', 'Jornada de partidos entre equipos de la escuela.', 'event',
   date_trunc('week', CURRENT_DATE + INTERVAL '4 weeks') + INTERVAL '0 days' + TIME '09:00',
   date_trunc('week', CURRENT_DATE + INTERVAL '4 weeks') + INTERVAL '0 days' + TIME '14:00');

-- Si ejecutas este INSERT más de una vez se crearán eventos duplicados.
-- Para borrar eventos de prueba: DELETE FROM public.school_calendar_events WHERE title LIKE '%';


-- =============================================================================
-- PUNTO 4: RESUMEN Y VERIFICACIÓN
-- =============================================================================
-- Script de solo lectura: comprueba que todo esté listo para padres.
-- Ejecuta y revisa los resultados.
-- =============================================================================

DO $$
DECLARE
  n_credits   INT := 0;
  n_calendar  INT := 0;
  n_parents   INT := 0;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_credits') THEN
    SELECT COUNT(*) INTO n_credits FROM public.user_credits;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'school_calendar_events') THEN
    SELECT COUNT(*) INTO n_calendar FROM public.school_calendar_events WHERE start_at >= NOW();
  END IF;
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'parent_child_relationships') THEN
    SELECT COUNT(DISTINCT parent_id) INTO n_parents FROM public.parent_child_relationships;
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'RESUMEN - Transparencia créditos y calendario';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Padres (parent_child_relationships): %', n_parents;
  RAISE NOTICE 'Filas en user_credits: %', n_credits;
  RAISE NOTICE 'Eventos futuros en calendario escolar: %', n_calendar;
  RAISE NOTICE '========================================';
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_credits') THEN
    RAISE NOTICE 'AVISO: user_credits no existe. Ejecuta la migración 20260221110000_user_credits_and_realtime.sql';
  ELSIF n_credits = 0 AND n_parents > 0 THEN
    RAISE NOTICE 'AVISO: Hay padres pero ninguno tiene créditos. Ejecuta el PUNTO 2.';
  END IF;
  IF n_calendar = 0 THEN
    RAISE NOTICE 'AVISO: No hay eventos futuros en el calendario. Ejecuta el PUNTO 3.';
  END IF;
END $$;

-- Consultas útiles de verificación (solo lectura):
-- Padres y su saldo actual:
-- SELECT p.id, p.full_name, COALESCE(uc.balance, 0) AS creditos
-- FROM public.profiles p
-- LEFT JOIN public.user_credits uc ON uc.user_id = p.id
-- WHERE p.id IN (SELECT parent_id FROM public.parent_child_relationships);

-- Próximos eventos del calendario:
-- SELECT title, event_type, start_at
-- FROM public.school_calendar_events
-- WHERE start_at >= NOW()
-- ORDER BY start_at
-- LIMIT 10;
