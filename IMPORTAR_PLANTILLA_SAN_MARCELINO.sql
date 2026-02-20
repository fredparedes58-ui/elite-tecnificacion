-- ============================================================
-- SCRIPT SQL: IMPORTAR PLANTILLA C.D. SAN MARCELINO 'A'
-- ============================================================
-- Este script crea usuarios y perfiles para los jugadores
-- de C.D. San Marcelino 'A' que luego pueden ser importados
-- desde la app
-- ============================================================
-- EJECUTA ESTE SCRIPT EN SUPABASE SQL EDITOR
-- ============================================================

-- NOTA: Este script requiere permisos de administrador
-- Los usuarios se crearán con emails temporales
-- Puedes modificar los emails después

-- Función helper para crear usuario y perfil
CREATE OR REPLACE FUNCTION create_player_profile(
  player_name TEXT,
  player_email TEXT DEFAULT NULL,
  player_position TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  new_user_id UUID;
  default_email TEXT;
BEGIN
  -- Generar email si no se proporciona
  IF player_email IS NULL THEN
    default_email := lower(replace(player_name, ' ', '.')) || '@sanmarcelino.local';
  ELSE
    default_email := player_email;
  END IF;

  -- Crear usuario en auth.users (requiere extensión uuid-ossp)
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data,
    is_super_admin,
    role
  )
  VALUES (
    gen_random_uuid(),
    default_email,
    crypt('temp_password_' || gen_random_uuid()::text, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    jsonb_build_object('full_name', player_name),
    false,
    'authenticated'
  )
  RETURNING id INTO new_user_id;

  -- Crear perfil
  INSERT INTO public.profiles (
    id,
    full_name,
    position,
    avatar_url
  )
  VALUES (
    new_user_id,
    player_name,
    player_position,
    'assets/players/default.png'
  );

  RETURN new_user_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Si el usuario ya existe, buscar su ID
    SELECT id INTO new_user_id
    FROM auth.users
    WHERE email = default_email
    LIMIT 1;
    
    IF new_user_id IS NULL THEN
      RAISE;
    END IF;
    
    RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Lista de jugadores de C.D. San Marcelino 'A'
DO $$
DECLARE
  v_user_id UUID;
  v_team_id UUID;
BEGIN
  -- Obtener el primer equipo (o usar un ID específico)
  SELECT id INTO v_team_id FROM teams LIMIT 1;
  
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'No se encontró ningún equipo. Crea un equipo primero.';
  END IF;

  -- Crear jugadores
  -- 1. JAIDER ANDRES ALCIBAR GOMEZ
  v_user_id := create_player_profile('JAIDER ANDRES ALCIBAR GOMEZ');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 2. JORGE ARCOBA BIOT
  v_user_id := create_player_profile('JORGE ARCOBA BIOT');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 3. ALEJANDRO BALLESTEROS HUERTA
  v_user_id := create_player_profile('ALEJANDRO BALLESTEROS HUERTA');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 4. MARTIN CABEZA CAÑAS
  v_user_id := create_player_profile('MARTIN CABEZA CAÑAS');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 5. IKER DOLZ SANCHEZ
  v_user_id := create_player_profile('IKER DOLZ SANCHEZ');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 6. RAUL LAZURAN
  v_user_id := create_player_profile('RAUL LAZURAN');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 7. UNAI LILLO AVILA
  v_user_id := create_player_profile('UNAI LILLO AVILA');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 8. HUGO MARTÍNEZ RIAZA
  v_user_id := create_player_profile('HUGO MARTÍNEZ RIAZA');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 9. SAMUEL ALEJANDRO PAREDES CASTRO
  v_user_id := create_player_profile('SAMUEL ALEJANDRO PAREDES CASTRO');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 10. JULEN PARRAGA MORENO
  v_user_id := create_player_profile('JULEN PARRAGA MORENO');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 11. DYLAN STEVEN RAMOS GONZALEZ
  v_user_id := create_player_profile('DYLAN STEVEN RAMOS GONZALEZ');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 12. EMMANUEL RINCON SANCHEZ
  v_user_id := create_player_profile('EMMANUEL RINCON SANCHEZ');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  -- 13. MARCOS RODRIGUEZ GIMENEZ
  v_user_id := create_player_profile('MARCOS RODRIGUEZ GIMENEZ');
  INSERT INTO team_members (team_id, user_id, role, match_status)
  VALUES (v_team_id, v_user_id, 'player', 'sub')
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Plantilla importada exitosamente: 13 jugadores agregados al equipo %', v_team_id;
END $$;

-- Limpiar función temporal (opcional)
-- DROP FUNCTION IF EXISTS create_player_profile(TEXT, TEXT, TEXT);

-- ============================================================
-- NOTAS:
-- ============================================================
-- 1. Los jugadores se crean como 'sub' (suplentes) por defecto
-- 2. Puedes cambiar su estado desde la app usando los botones
--    de Titular/Suplente/Desconvocado
-- 3. Los emails son temporales (formato: nombre.apellido@sanmarcelino.local)
-- 4. Todos los jugadores tienen la contraseña temporal generada
-- ============================================================
