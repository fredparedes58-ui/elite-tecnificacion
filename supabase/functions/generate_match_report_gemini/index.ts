// ============================================================
// SUPABASE EDGE FUNCTION: generate_match_report_gemini
// ============================================================
// Genera informes de partidos usando Google Gemini API
// ============================================================

// @ts-ignore: Deno runtime imports
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
// @ts-ignore: Deno runtime imports
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// @ts-ignore: Deno está disponible en el runtime de Supabase Edge Functions
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

interface MatchData {
  match: any;
  events: any[];
  stats: any[];
}

interface GeminiResponse {
  coach_report: string;
  family_report: string;
}

serve(async (req) => {
  // Configurar CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    // Verificar API Key de Gemini
    if (!GEMINI_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY no está configurada' }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        }
      );
    }

    // Obtener match_id del body
    const { match_id } = await req.json();

    if (!match_id) {
      return new Response(
        JSON.stringify({ error: 'match_id es requerido' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        }
      );
    }

    // Inicializar cliente de Supabase
    // @ts-ignore: Deno está disponible en el runtime de Supabase Edge Functions
    const supabaseClient = createClient(
      // @ts-ignore: Deno está disponible en el runtime de Supabase Edge Functions
      Deno.env.get('SUPABASE_URL') ?? '',
      // @ts-ignore: Deno está disponible en el runtime de Supabase Edge Functions
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // 1. Obtener datos del partido
    const matchData = await getMatchData(supabaseClient, match_id);

    if (!matchData.match) {
      return new Response(
        JSON.stringify({ error: 'Partido no encontrado' }),
        {
          status: 404,
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        }
      );
    }

    // 2. Generar informes con Gemini
    const reports = await generateReportsWithGemini(matchData);

    // 3. Guardar en guru_posts
    const coachPost = await supabaseClient
      .from('guru_posts')
      .insert({
        match_id: match_id,
        content: reports.coach_report,
        audience: 'coach',
        status: 'draft',
      })
      .select()
      .single();

    const familyPost = await supabaseClient
      .from('guru_posts')
      .insert({
        match_id: match_id,
        content: reports.family_report,
        audience: 'family',
        status: 'draft',
      })
      .select()
      .single();

    if (coachPost.error || familyPost.error) {
      throw new Error(
        `Error al guardar posts: ${coachPost.error?.message || familyPost.error?.message}`
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Informes generados correctamente',
        coach_post_id: coachPost.data.id,
        family_post_id: familyPost.data.id,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      }
    );
  } catch (error) {
    console.error('Error en generate_match_report_gemini:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      }
    );
  }
});

/**
 * Obtiene todos los datos del partido
 */
async function getMatchData(supabaseClient: any, matchId: string): Promise<MatchData> {
  // Obtener datos del partido
  const { data: match, error: matchError } = await supabaseClient
    .from('matches')
    .select('*')
    .eq('id', matchId)
    .single();

  if (matchError) throw matchError;

  // Obtener eventos de análisis
  const { data: events, error: eventsError } = await supabaseClient
    .from('analysis_events')
    .select('*')
    .eq('match_id', matchId)
    .order('match_timestamp', { ascending: true });

  if (eventsError) throw eventsError;

  // Obtener estadísticas del partido
  const { data: stats, error: statsError } = await supabaseClient
    .from('match_stats')
    .select('*')
    .eq('match_id', matchId);

  if (statsError) throw statsError;

  return {
    match,
    events: events || [],
    stats: stats || [],
  };
}

/**
 * Genera los informes usando Gemini API
 */
async function generateReportsWithGemini(matchData: MatchData): Promise<GeminiResponse> {
  // Preparar el prompt con los datos del partido
  const matchJson = JSON.stringify(matchData, null, 2);

  const prompt = `Actúa como un Analista de Fútbol de élite. Analiza los siguientes datos estadísticos del partido:

${matchJson}

Genera un objeto JSON con exactamente dos claves:

1. "coach_report": Un análisis técnico, crítico y táctico. Identifica debilidades defensivas o eficiencias ofensivas basadas en los números. Usa jerga profesional. Sé específico y detallado.

2. "family_report": Un resumen emocionante, estilo narrador deportivo o periódico. Destaca el esfuerzo, los goles y el buen ambiente. Tono positivo y celebratorio.

IMPORTANTE: Devuelve ÚNICAMENTE un objeto JSON válido, sin texto adicional antes o después. El formato debe ser:

{
  "coach_report": "...",
  "family_report": "..."
}`;

  // Llamar a Gemini API
  const response = await fetch(`${GEMINI_API_URL}?key=${GEMINI_API_KEY}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            {
              text: prompt,
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
        responseMimeType: 'application/json',
      },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error en Gemini API: ${response.status} - ${errorText}`);
  }

  const data = await response.json();

  // Extraer el texto de la respuesta
  const responseText = data.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!responseText) {
    throw new Error('No se recibió respuesta de Gemini API');
  }

  // Parsear el JSON de la respuesta
  let reports: GeminiResponse;
  try {
    // Limpiar el texto (eliminar markdown code blocks si existen)
    const cleanText = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    reports = JSON.parse(cleanText);
  } catch (parseError) {
    console.error('Error parsing Gemini response:', responseText);
    throw new Error(`Error al parsear respuesta de Gemini: ${parseError.message}`);
  }

  // Validar que tenga ambas claves
  if (!reports.coach_report || !reports.family_report) {
    throw new Error('La respuesta de Gemini no contiene ambos informes requeridos');
  }

  return reports;
}
