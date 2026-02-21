/**
 * Edge Function: daily_report_generator
 * Genera el reporte semanal o mensual de créditos consumidos por familia.
 * Los créditos consumidos = sesiones en las que el jugador marcó asistencia (bookings.attended = true).
 *
 * Invocación: POST con body: { period: 'weekly' | 'monthly', date?: string (YYYY-MM-DD) }
 * O desde cron: sin body = reporte semanal de la semana pasada.
 */
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function getPeriodBounds(period: "weekly" | "monthly", refDate: Date): { start: string; end: string } {
  const start = new Date(refDate);
  const end = new Date(refDate);
  if (period === "weekly") {
    start.setDate(start.getDate() - 7);
    end.setDate(end.getDate() - 1);
  } else {
    start.setMonth(start.getMonth() - 1);
    start.setDate(1);
    end.setDate(0);
  }
  return {
    start: start.toISOString().slice(0, 10),
    end: end.toISOString().slice(0, 10),
  };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body = await req.json().catch(() => ({}));
    const period = (body.period ?? "weekly") as "weekly" | "monthly";
    const refDate = body.date ? new Date(body.date) : new Date();
    const { start, end } = getPeriodBounds(period, refDate);

    const { data: sessionsInRange } = await supabase
      .from("sessions")
      .select("id")
      .gte("date", start)
      .lte("date", end);
    const sessionIds = (sessionsInRange ?? []).map((s: { id: string }) => s.id);
    if (sessionIds.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          period,
          start,
          end,
          summary: { total_credits_consumed: 0, families: 0 },
          by_family: [],
        }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const { data: bookings } = await supabase
      .from("bookings")
      .select("id, session_id, player_id")
      .in("session_id", sessionIds)
      .eq("attended", true);
    if (!bookings?.length) {
      return new Response(
        JSON.stringify({
          success: true,
          period,
          start,
          end,
          summary: { total_credits_consumed: 0, families: 0 },
          by_family: [],
        }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const playerIds = [...new Set(bookings.map((b: { player_id: string }) => b.player_id))];
    const { data: players } = await supabase
      .from("players")
      .select("id, parent_id, name")
      .in("id", playerIds);
    const playerByParent = new Map<string, { name: string }[]>();
    const parentIds = new Set<string>();
    for (const p of players ?? []) {
      parentIds.add(p.parent_id);
      if (!playerByParent.has(p.parent_id)) playerByParent.set(p.parent_id, []);
      playerByParent.get(p.parent_id)!.push({ name: p.name });
    }

    const consumedByParent = new Map<string, number>();
    for (const b of bookings) {
      const player = (players ?? []).find((x: { id: string }) => x.id === b.player_id);
      if (player) {
        consumedByParent.set(
          player.parent_id,
          (consumedByParent.get(player.parent_id) ?? 0) + 1
        );
      }
    }

    const { data: profiles } = await supabase
      .from("profiles")
      .select("id, full_name, email")
      .in("id", [...parentIds]);
    const profileMap = new Map((profiles ?? []).map((p: { id: string }) => [p.id, p]));

    const by_family = [...consumedByParent.entries()].map(([parentId, credits]) => {
      const profile = profileMap.get(parentId);
      return {
        parent_id: parentId,
        full_name: profile?.full_name ?? null,
        email: profile?.email ?? null,
        credits_consumed: credits,
        players: playerByParent.get(parentId) ?? [],
      };
    });

    const total_credits_consumed = by_family.reduce((s, f) => s + f.credits_consumed, 0);

    const report = {
      success: true,
      period,
      start,
      end,
      summary: {
        total_credits_consumed,
        families: by_family.length,
      },
      by_family,
    };

    return new Response(JSON.stringify(report), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("daily_report_generator error:", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
});
