-- Motor de Análisis de Progreso: histórico 6 métricas, mejora mensual, vistas para admin.
-- Las instantáneas en player_stats_history pueden tener stats en formato 5 (speed, technique...)
-- o 6 (velocidad, tiro, pase, regate, defensa, fisico). Soporte para ambos.

-- Función: obtiene el "Average Rating" desde el JSONB de stats (5 o 6 métricas).
CREATE OR REPLACE FUNCTION public.player_avg_rating(stats jsonb)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  total numeric := 0;
  cnt int := 0;
  v numeric;
  k text;
BEGIN
  IF stats IS NULL OR stats = '{}' THEN
    RETURN 0;
  END IF;
  -- Formato 6 (carta): velocidad, tiro, pase, regate, defensa, fisico
  FOR k IN SELECT unnest(ARRAY['velocidad','tiro','pase','regate','defensa','fisico']) LOOP
    v := (stats->>k)::numeric;
    IF v IS NOT NULL AND v >= 0 AND v <= 100 THEN
      total := total + v;
      cnt := cnt + 1;
    END IF;
  END LOOP;
  IF cnt >= 1 THEN
    RETURN round((total / cnt)::numeric, 2);
  END IF;
  -- Formato 5 (legacy): speed, technique, physical, mental, tactical
  total := 0;
  cnt := 0;
  FOR k IN SELECT unnest(ARRAY['speed','technique','physical','mental','tactical']) LOOP
    v := (stats->>k)::numeric;
    IF v IS NOT NULL AND v >= 0 AND v <= 100 THEN
      total := total + v;
      cnt := cnt + 1;
    END IF;
  END LOOP;
  IF cnt >= 1 THEN
    RETURN round((total / cnt)::numeric, 2);
  END IF;
  RETURN 0;
END;
$$;

-- Vista: por jugador y mes (primer día del mes), el último snapshot del mes y su avg rating.
CREATE OR REPLACE VIEW public.player_monthly_avg_rating AS
SELECT DISTINCT ON (player_id, date_trunc('month', recorded_at)::date)
  player_id,
  (date_trunc('month', recorded_at)::date) AS month_start,
  recorded_at,
  public.player_avg_rating(stats) AS avg_rating
FROM public.player_stats_history
ORDER BY player_id, date_trunc('month', recorded_at)::date, recorded_at DESC;

-- Vista: mejora mensual % (comparando mes actual con mes anterior por jugador).
CREATE OR REPLACE VIEW public.player_monthly_improvement AS
SELECT
  curr.player_id,
  curr.month_start,
  curr.avg_rating,
  prev.avg_rating AS prev_month_avg_rating,
  CASE
    WHEN prev.avg_rating IS NULL OR prev.avg_rating = 0 THEN NULL
    ELSE round(((curr.avg_rating - prev.avg_rating) / prev.avg_rating * 100)::numeric, 2)
  END AS pct_improvement
FROM public.player_monthly_avg_rating curr
LEFT JOIN public.player_monthly_avg_rating prev
  ON curr.player_id = prev.player_id
  AND prev.month_start = (curr.month_start - interval '1 month')::date;

-- Vista: jugadores que subieron +5 puntos de media esta semana (para Pedro).
DROP VIEW IF EXISTS public.players_weekly_improvement;
CREATE VIEW public.players_weekly_improvement AS
WITH latest_snapshot AS (
  SELECT DISTINCT ON (player_id)
    player_id,
    public.player_avg_rating(stats) AS current_avg,
    recorded_at
  FROM public.player_stats_history
  WHERE recorded_at >= (now() - interval '7 days')
  ORDER BY player_id, recorded_at DESC
),
snapshot_week_ago AS (
  SELECT DISTINCT ON (player_id)
    player_id,
    public.player_avg_rating(stats) AS past_avg
  FROM public.player_stats_history
  WHERE recorded_at < (now() - interval '7 days')
    AND recorded_at >= (now() - interval '14 days')
  ORDER BY player_id, recorded_at DESC
)
SELECT
  l.player_id,
  l.current_avg,
  s.past_avg,
  (l.current_avg - COALESCE(s.past_avg, l.current_avg))::numeric(5,2) AS points_gain
FROM latest_snapshot l
LEFT JOIN snapshot_week_ago s ON l.player_id = s.player_id
WHERE (l.current_avg - COALESCE(s.past_avg, l.current_avg)) >= 5;

COMMENT ON VIEW public.player_monthly_improvement IS 'Mejora % mensual por jugador (avg rating mes actual vs anterior)';
COMMENT ON VIEW public.players_weekly_improvement IS 'Jugadores que subieron >= 5 puntos de media esta semana (para dashboard admin)';

-- RPC para el dashboard: devuelve jugadores con mejora >= 5 esta semana (evita depender de la vista en tipos).
CREATE OR REPLACE FUNCTION public.get_players_weekly_improvement()
RETURNS TABLE (
  player_id uuid,
  current_avg numeric,
  past_avg numeric,
  points_gain numeric
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM public.players_weekly_improvement;
$$;
