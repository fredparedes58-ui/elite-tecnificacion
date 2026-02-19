/**
 * Edge Function: Notificaciones unificadas para eventos de sesiones.
 * Dispara email (Resend) y boilerplate para Push (OneSignal / Firebase).
 *
 * Eventos:
 * - reservation_requested: un padre solicita sesión → notificar a admin
 * - reservation_accepted: Pedro acepta/mueve sesión → notificar al padre
 * - reservation_moved: sesión reprogramada → notificar al padre
 * - credits_low: balance < 1 → notificar al padre
 */
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type NotifyEvent =
  | "reservation_requested"
  | "reservation_accepted"
  | "reservation_moved"
  | "credits_low"
  | "training_completed";

interface NotifyPayload {
  event: NotifyEvent;
  reservation_id?: string;
  user_id?: string;
  player_name?: string;
  trainer_name?: string;
  start_time?: string;
  old_start_time?: string;
  balance?: number;
  trainer_comments?: string;
}

const sendEmailWithResend = async (
  to: string,
  subject: string,
  html: string,
  apiKey: string
) => {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "Elite Training <onboarding@resend.dev>",
      to: [to],
      subject,
      html,
    }),
  });
  if (!res.ok) throw new Error(`Resend error: ${await res.text()}`);
  return res.json();
};

/** OneSignal: envía push a un user_id (external_id). Configurar ONE_SIGNAL_APP_ID y ONE_SIGNAL_REST_API_KEY. */
const sendPushOneSignal = async (
  userId: string,
  heading: string,
  message: string
): Promise<void> => {
  const appId = Deno.env.get("ONE_SIGNAL_APP_ID");
  const apiKey = Deno.env.get("ONE_SIGNAL_REST_API_KEY");
  if (!appId || !apiKey) {
    console.log("OneSignal not configured, skipping push");
    return;
  }
  await fetch("https://api.onesignal.com/notifications", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic ${apiKey}`,
    },
    body: JSON.stringify({
      app_id: appId,
      include_external_user_ids: [userId],
      headings: { en: heading },
      contents: { en: message },
    }),
  });
};

/** Firebase FCM: envía a un token. Configurar FCM_SERVER_KEY y pasar device_token en payload si se usa. */
const sendPushFirebase = async (
  _deviceToken: string,
  title: string,
  body: string
): Promise<void> => {
  const fcmKey = Deno.env.get("FCM_SERVER_KEY");
  if (!fcmKey) {
    console.log("FCM not configured, skipping push");
    return;
  }
  // POST a https://fcm.googleapis.com/fcm/send con Authorization: key=FCM_SERVER_KEY
  // body: { to: deviceToken, notification: { title, body } }
  console.log("FCM push (boilerplate):", title, body);
};

const handler = async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) throw new Error("RESEND_API_KEY not configured");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const payload: NotifyPayload = await req.json();
    const { event } = payload;

    let targetEmail: string | null = null;
    let targetUserId: string | null = null;
    let subject = "";
    let html = "";
    let pushHeading = "";
    let pushBody = "";

    if (event === "reservation_requested" && payload.reservation_id) {
      const { data: res } = await supabase
        .from("reservations")
        .select("user_id, title, start_time")
        .eq("id", payload.reservation_id)
        .single();
      if (res) {
        const { data: profile } = await supabase
          .from("profiles")
          .select("email, full_name")
          .eq("id", res.user_id)
          .single();
        const parentName = profile?.full_name || "Un padre";
        subject = "📩 Nueva solicitud de sesión - Elite";
        html = `
          <div style="font-family: Arial; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #111;">Nueva solicitud de sesión</h2>
            <p><strong>${res.title}</strong></p>
            <p>Solicitante: ${parentName}</p>
            <p>Fecha solicitada: ${new Date(res.start_time).toLocaleString("es-ES")}</p>
            <p>Revisa el panel de reservas para aceptar o proponer otro horario.</p>
          </div>`;
        pushHeading = "Nueva solicitud de sesión";
        pushBody = `${parentName}: ${res.title}`;
        targetUserId = "admin"; // Para push: OneSignal/FCM pueden usar external_user_id = admin user_id
      }
      // Email a admin: usar user_roles (role = 'admin') + profiles.email
      const { data: adminRole } = await supabase
        .from("user_roles")
        .select("user_id")
        .eq("role", "admin")
        .limit(1)
        .maybeSingle();
      if (adminRole?.user_id) {
        const { data: adminProfile } = await supabase
          .from("profiles")
          .select("email")
          .eq("id", adminRole.user_id)
          .maybeSingle();
        targetEmail = adminProfile?.email ?? null;
        targetUserId = adminRole.user_id;
      }
      if (!targetEmail) {
        const { data: fallback } = await supabase
          .from("profiles")
          .select("email")
          .limit(1)
          .maybeSingle();
        targetEmail = fallback?.email ?? null;
      }
    }

    if (
      (event === "reservation_accepted" || event === "reservation_moved") &&
      payload.reservation_id
    ) {
      const { data: res } = await supabase
        .from("reservations")
        .select("user_id, title, start_time")
        .eq("id", payload.reservation_id)
        .single();
      if (res) {
        targetUserId = res.user_id;
        const { data: profile } = await supabase
          .from("profiles")
          .select("email, full_name")
          .eq("id", res.user_id)
          .single();
        targetEmail = profile?.email ?? null;
        const startTime = new Date(res.start_time).toLocaleString("es-ES");
        if (event === "reservation_accepted") {
          subject = "✅ Tu reserva ha sido aprobada";
          html = `
            <div style="font-family: Arial; max-width: 600px; margin: 0 auto; padding: 20px;">
              <h2 style="color: #059669;">Reserva aprobada</h2>
              <p><strong>${res.title}</strong></p>
              <p>Fecha: ${startTime}</p>
              <p>¡Nos vemos en la sesión!</p>
            </div>`;
          pushHeading = "Reserva aprobada";
          pushBody = `${res.title} - ${startTime}`;
        } else {
          const oldTime = payload.old_start_time
            ? new Date(payload.old_start_time).toLocaleString("es-ES")
            : "";
          subject = "📅 Tu sesión ha sido reprogramada";
          html = `
            <div style="font-family: Arial; max-width: 600px; margin: 0 auto; padding: 20px;">
              <h2 style="color: #d97706;">Sesión reprogramada</h2>
              <p><strong>${res.title}</strong></p>
              ${oldTime ? `<p style="text-decoration: line-through;">Antes: ${oldTime}</p>` : ""}
              <p><strong>Nueva fecha: ${startTime}</p>
            </div>`;
          pushHeading = "Sesión reprogramada";
          pushBody = `${res.title} - ${startTime}`;
        }
      }
    }

    if (event === "credits_low" && payload.user_id) {
      targetUserId = payload.user_id;
      const { data: profile } = await supabase
        .from("profiles")
        .select("email, full_name")
        .eq("id", payload.user_id)
        .single();
      targetEmail = profile?.email ?? null;
      const balance = payload.balance ?? 0;
      subject = balance < 1 ? "⚠️ Créditos agotados" : "⚡ Créditos bajos";
      html = `
        <div style="font-family: Arial; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: ${balance < 1 ? "#dc2626" : "#d97706"};">${subject}</h2>
          <p>Tu saldo de créditos es <strong>${balance}</strong>.</p>
          ${balance < 1 ? "<p>Contacta con el administrador para recargar.</p>" : "<p>Considera recargar pronto.</p>"}
        </div>`;
      pushHeading = subject;
      pushBody = `Créditos: ${balance}`;
    }

    if (event === "training_completed" && payload.reservation_id) {
      const { data: res } = await supabase
        .from("reservations")
        .select("user_id, title, start_time")
        .eq("id", payload.reservation_id)
        .single();
      if (res) {
        targetUserId = res.user_id;
        const { data: profile } = await supabase
          .from("profiles")
          .select("email, full_name")
          .eq("id", res.user_id)
          .single();
        targetEmail = profile?.email ?? null;
        const startTime = new Date(res.start_time).toLocaleString("es-ES");
        const comments = payload.trainer_comments?.trim() || "";
        subject = "✅ Entrenamiento finalizado";
        html = `
          <div style="font-family: Arial; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #059669;">Entrenamiento finalizado</h2>
            <p><strong>${res.title}</strong></p>
            <p>Fecha: ${startTime}</p>
            ${comments ? `<div style="margin-top: 16px; padding: 12px; background: #f0fdf4; border-radius: 8px; border-left: 4px solid #059669;"><p style="margin: 0; font-weight: 600;">Comentario del entrenador:</p><p style="margin: 8px 0 0 0;">${comments}</p></div>` : ""}
            <p style="margin-top: 16px; color: #6b7280;">Gracias por confiar en Elite 380.</p>
          </div>`;
        pushHeading = "Entrenamiento finalizado";
        pushBody = comments ? `${res.title}: ${comments.slice(0, 80)}${comments.length > 80 ? "…" : ""}` : res.title;
      }
    }

    if (targetEmail && subject && html) {
      await sendEmailWithResend(targetEmail, subject, html, resendApiKey);
    }
    if (targetUserId && pushHeading && pushBody) {
      await sendPushOneSignal(targetUserId, pushHeading, pushBody);
    }

    return new Response(
      JSON.stringify({ success: true, event }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("notify-session-events error:", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
};

serve(handler);
