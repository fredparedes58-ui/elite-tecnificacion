/**
 * Edge Function: low_credits_alert
 * Se dispara cuando credit_balance llega a 1. Notifica a Pedro (admin) y al Padre.
 *
 * Invocación: Database Webhook en UPDATE de public.wallets
 * cuando NEW.credit_balance = 1, o POST con body: { parent_id: string }
 */
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LOW_CREDIT_THRESHOLD = 1;

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
      from: "Elite Performance <onboarding@resend.dev>",
      to: [to],
      subject,
      html,
    }),
  });
  if (!res.ok) throw new Error(`Resend error: ${await res.text()}`);
  return res.json();
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
      .select("device_token")
      .eq("user_id", userId);
    if (!tokens?.length) return;
    for (const { device_token } of tokens) {
      await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `key=${fcmServerKey}`,
        },
        body: JSON.stringify({
          to: device_token,
          notification: { title, body, sound: "default" },
          data: {},
        }),
      });
    }
  } catch (e) {
    console.error("Push error:", e);
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const fcmKey = Deno.env.get("FCM_SERVER_KEY") ?? null;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body = await req.json().catch(() => ({}));
    let parentId: string;
    let creditBalance: number;

    if (body.record?.parent_id != null && body.record?.credit_balance === LOW_CREDIT_THRESHOLD) {
      parentId = body.record.parent_id;
      creditBalance = body.record.credit_balance;
    } else if (body.parent_id != null) {
      const { data: wallet } = await supabase
        .from("wallets")
        .select("parent_id, credit_balance")
        .eq("parent_id", body.parent_id)
        .single();
      if (!wallet || wallet.credit_balance !== LOW_CREDIT_THRESHOLD) {
        return new Response(
          JSON.stringify({ success: true, message: "Balance no es 1, no se notifica" }),
          { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
        );
      }
      parentId = wallet.parent_id;
      creditBalance = wallet.credit_balance;
    } else {
      return new Response(
        JSON.stringify({ error: "Se requiere parent_id o payload record con credit_balance=1" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const { data: parentProfile } = await supabase
      .from("profiles")
      .select("id, email, full_name")
      .eq("id", parentId)
      .single();
    if (!parentProfile) {
      return new Response(
        JSON.stringify({ error: "Perfil del padre no encontrado" }),
        { status: 404, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const parentName = parentProfile.full_name ?? parentProfile.email ?? "Un padre";
    const title = "⚠️ Créditos en el mínimo";
    const message = `Solo te queda 1 crédito. Contacta con el administrador para recargar.`;

    const notificationRows: { user_id: string; type: string; title: string; message: string; metadata: object }[] = [
      {
        user_id: parentId,
        type: "low_credits_alert",
        title,
        message,
        metadata: { parent_id: parentId, credit_balance: creditBalance },
      },
    ];

    if (resendApiKey) {
      const html = `
        <div style="font-family: Arial; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #d97706;">${title}</h2>
          <p>Hola <strong>${parentName}</strong>,</p>
          <p>Tu saldo de créditos ha llegado a <strong>${creditBalance}</strong>. Para seguir reservando sesiones, contacta con el administrador.</p>
        </div>`;
      await sendEmailWithResend(parentProfile.email, title, html, resendApiKey);
    }
    await sendPushToUser(supabase, parentId, title, message, fcmKey);
    await supabase.from("notifications").insert(notificationRows);

    const { data: adminProfiles } = await supabase
      .from("profiles")
      .select("id, email, full_name")
      .eq("role", "admin");
    const admins = adminProfiles ?? [];
    const adminNotifications: typeof notificationRows = [];
    for (const admin of admins) {
      const adminTitle = "⚠️ Alerta: familia con 1 crédito";
      const adminMessage = `${parentName} (${parentProfile.email}) tiene solo 1 crédito.`;
      adminNotifications.push({
        user_id: admin.id,
        type: "low_credits_alert_admin",
        title: adminTitle,
        message: adminMessage,
        metadata: { parent_id: parentId, parent_email: parentProfile.email, credit_balance: creditBalance },
      });
      if (admin.email && resendApiKey) {
        const adminHtml = `
          <div style="font-family: Arial; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #d97706;">${adminTitle}</h2>
            <p><strong>${parentName}</strong> (${parentProfile.email}) tiene solo <strong>1 crédito</strong>. Considera contactarle para recargar.</p>
          </div>`;
        await sendEmailWithResend(admin.email, adminTitle, adminHtml, resendApiKey);
      }
      await sendPushToUser(supabase, admin.id, adminTitle, adminMessage, fcmKey);
    }
    if (adminNotifications.length > 0) {
      await supabase.from("notifications").insert(adminNotifications);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Alertas enviadas",
        parent_id: parentId,
        admins_notified: admins.length,
      }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("low_credits_alert error:", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
});
