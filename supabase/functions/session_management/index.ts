/**
 * Edge Function: session_management
 * Cuando el admin (Pedro) asigne, modifique o cancele una sesión,
 * envía notificación push y en app a los padres con reserva y al coach asignado.
 *
 * Invocación: desde el cliente tras crear/actualizar sesión, o Database Webhook
 * Body: { action: 'assigned' | 'updated' | 'cancelled', session_id: string }
 */
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function sendPushToUser(
  supabase: any,
  userId: string,
  title: string,
  body: string,
  fcmServerKey: string | null
): Promise<void> {
  if (!fcmServerKey) return;
  try {
    const { data: tokens } = await supabase
      .from("device_tokens")
      .select("device_token, platform")
      .eq("user_id", userId);
    if (!tokens?.length) return;
    for (const { device_token } of tokens) {
      const res = await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `key=${fcmServerKey}`,
        },
        body: JSON.stringify({
          to: device_token,
          notification: { title, body, sound: "default" },
          data: { click_action: "FLUTTER_NOTIFICATION_CLICK" },
        }),
      });
      if (!res.ok && (res.status === 400 || res.status === 401)) {
        await supabase.from("device_tokens").delete().eq("device_token", device_token);
      }
    }
  } catch (e) {
    console.error("Push error for", userId, e);
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const fcmKey = Deno.env.get("FCM_SERVER_KEY") ?? null;

    const body = await req.json().catch(() => ({}));
    const action = body.action as string;
    const sessionId = body.session_id as string;

    if (!sessionId || !["assigned", "updated", "cancelled"].includes(action)) {
      return new Response(
        JSON.stringify({ error: "Se requiere action (assigned|updated|cancelled) y session_id" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const { data: session, error: sessionError } = await supabase
      .from("sessions")
      .select("id, coach_id, date, start_time, status")
      .eq("id", sessionId)
      .single();

    if (sessionError || !session) {
      return new Response(
        JSON.stringify({ error: "Sesión no encontrada" }),
        { status: 404, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const coachId = session.coach_id;
    const dateStr = session.date;
    const timeStr = session.start_time;
    const sessionLabel = `${dateStr} ${timeStr}`;

    const { data: coachProfile } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", coachId)
      .single();
    const coachName = coachProfile?.full_name ?? "El coach";

    const { data: bookings } = await supabase
      .from("bookings")
      .select("player_id")
      .eq("session_id", sessionId);
    const playerIds = (bookings ?? []).map((b: { player_id: string }) => b.player_id);
    const parentIds = new Set<string>();

    if (playerIds.length > 0) {
      const { data: players } = await supabase
        .from("players")
        .select("id, parent_id")
        .in("id", playerIds);
      (players ?? []).forEach((p: { parent_id: string }) => parentIds.add(p.parent_id));
    }

    const titles: Record<string, string> = {
      assigned: "📅 Sesión asignada",
      updated: "📅 Sesión modificada",
      cancelled: "❌ Sesión cancelada",
    };
    const messages: Record<string, string> = {
      assigned: `Tu sesión del ${sessionLabel} con ${coachName} ha sido asignada.`,
      updated: `La sesión del ${sessionLabel} ha sido modificada. Revisa los detalles.`,
      cancelled: `La sesión del ${sessionLabel} ha sido cancelada.`,
    };
    const notifTitle = titles[action];
    const notifMessage = messages[action];

    const notificationRows: { user_id: string; type: string; title: string; message: string; metadata: object }[] = [];

    // Notificar al coach
    notificationRows.push({
      user_id: coachId,
      type: `session_${action}`,
      title: notifTitle,
      message: notifMessage,
      metadata: { session_id: sessionId, action },
    });
    await sendPushToUser(supabase, coachId, notifTitle, notifMessage, fcmKey);

    // Notificar a cada padre con reserva en la sesión
    for (const parentId of parentIds) {
      notificationRows.push({
        user_id: parentId,
        type: `session_${action}`,
        title: notifTitle,
        message: notifMessage,
        metadata: { session_id: sessionId, action },
      });
      await sendPushToUser(supabase, parentId, notifTitle, notifMessage, fcmKey);
    }

    const { error: insertError } = await supabase.from("notifications").insert(notificationRows);
    if (insertError) console.error("Error insertando notificaciones:", insertError);

    return new Response(
      JSON.stringify({
        success: true,
        action,
        session_id: sessionId,
        notified_coach: coachId,
        notified_parents: Array.from(parentIds),
      }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("session_management error:", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
});
