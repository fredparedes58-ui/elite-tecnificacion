/**
 * Edge Function: notify_admin_pending_approval
 * Cuando un padre se registra (is_approved = false), envía email a los admins
 * (emails en admin_coach_emails) avisando que hay una cuenta pendiente de aprobación.
 */
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

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

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ error: "RESEND_API_KEY no configurada" }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const body = await req.json().catch(() => ({}));
    const record = body.record;
    if (!record?.id || !record?.email) {
      return new Response(
        JSON.stringify({ error: "Se requiere body.record con id y email" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const fullName = record.full_name ?? record.email?.split("@")[0] ?? "Un padre";
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: adminEmails, error } = await supabase
      .from("admin_coach_emails")
      .select("email");

    if (error || !adminEmails?.length) {
      console.warn("No admin emails found in admin_coach_emails, skipping email");
      return new Response(
        JSON.stringify({ success: true, message: "No hay admins para notificar" }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const subject = "Nueva cuenta pendiente de aprobación – Elite Performance";
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #dc2626, #b91c1c); padding: 24px; border-radius: 12px 12px 0 0;">
          <h1 style="color: white; margin: 0; font-size: 20px;">Nueva cuenta pendiente de aprobación</h1>
        </div>
        <div style="background: #f9fafb; padding: 24px; border-radius: 0 0 12px 12px;">
          <p style="color: #111827;">Un nuevo padre se ha registrado y está esperando que apruebes su cuenta.</p>
          <p style="color: #4b5563;"><strong>Nombre:</strong> ${fullName}</p>
          <p style="color: #4b5563;"><strong>Email:</strong> ${record.email}</p>
          <p style="color: #6b7280; font-size: 14px;">Entra en la app como administrador y aprueba la cuenta en Ajustes → Cuentas pendientes de aprobación.</p>
        </div>
      </div>`;

    for (const row of adminEmails) {
      const to = row.email;
      if (to) await sendEmailWithResend(to, subject, html, resendApiKey);
    }

    return new Response(
      JSON.stringify({ success: true, message: "Admins notificados", profile_id: record.id }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("notify_admin_pending_approval error:", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
});
