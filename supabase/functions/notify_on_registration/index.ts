/**
 * Edge Function: notify_on_registration
 * Al crear un perfil de padre, envía correo de confirmación.
 *
 * Invocación: Database Webhook en INSERT de public.profiles WHERE role = 'parent'
 * o llamada HTTP POST con body: { profile_id: string }
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

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Soporta: welcome_on_approval (trigger al aprobar), record con role=parent, o profile_id
    let profileId: string;
    let email: string;
    let fullName: string;

    const body = await req.json().catch(() => ({}));

    if (body.welcome_on_approval && body.record?.id) {
      const r = body.record;
      profileId = r.id;
      email = r.email;
      fullName = r.full_name ?? r.email?.split("@")[0] ?? "Usuario";
    } else if (body.record?.id && body.record?.role === "parent") {
      const r = body.record;
      profileId = r.id;
      email = r.email;
      fullName = r.full_name ?? r.email?.split("@")[0] ?? "Usuario";
    } else if (body.profile_id) {
      const { data: profile, error } = await supabase
        .from("profiles")
        .select("id, email, full_name")
        .eq("id", body.profile_id)
        .single();
      if (error || !profile) {
        return new Response(
          JSON.stringify({ error: "Perfil no encontrado" }),
          { status: 404, headers: { "Content-Type": "application/json", ...corsHeaders } }
        );
      }
      profileId = profile.id;
      email = profile.email;
      fullName = profile.full_name ?? profile.email?.split("@")[0] ?? "Usuario";
    } else {
      return new Response(
        JSON.stringify({ error: "Se requiere profile_id, welcome_on_approval+record, o record con role=parent" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const subject = "✅ Tu cuenta ha sido aprobada – Elite Performance";
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #059669, #047857); padding: 30px; border-radius: 12px 12px 0 0;">
          <h1 style="color: white; margin: 0; font-size: 24px;">¡Tu cuenta ha sido aprobada!</h1>
        </div>
        <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px;">
          <p style="color: #111827; font-size: 16px;">Hola <strong>${fullName}</strong>,</p>
          <p style="color: #4b5563;">
            La academia ha aprobado tu solicitud. Ya puedes iniciar sesión en la app y empezar a interactuar con la academia: reservar sesiones, ver el balance de créditos y recibir notificaciones.
          </p>
          <ul style="color: #6b7280;">
            <li>Reserva sesiones con nuestros coaches</li>
            <li>Consulta el balance de créditos de tu familia</li>
            <li>Recibe notificaciones de asignaciones y cambios</li>
          </ul>
          <p style="color: #4b5563; font-weight: 500;">¡Bienvenido a Elite Performance!</p>
          <p style="color: #9ca3af; font-size: 12px; margin-top: 24px;">
            Este es un correo automático. Si no has solicitado el registro, contacta con el administrador.
          </p>
        </div>
      </div>`;

    await sendEmailWithResend(email, subject, html, resendApiKey);

    return new Response(
      JSON.stringify({ success: true, message: "Correo de confirmación enviado", profile_id: profileId }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("notify_on_registration error:", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
});
