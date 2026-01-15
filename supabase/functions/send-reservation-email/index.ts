import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface EmailRequest {
  reservation_id: string;
  type: "approved" | "rejected" | "updated" | "reminder";
}

const getEmailContent = (type: string, reservation: any, playerName: string, trainerName: string) => {
  const startTime = new Date(reservation.start_time).toLocaleString("es-ES", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });

  switch (type) {
    case "approved":
      return {
        subject: "✅ Tu reserva ha sido aprobada",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #10b981, #059669); padding: 30px; border-radius: 12px 12px 0 0;">
              <h1 style="color: white; margin: 0; font-size: 24px;">¡Reserva Aprobada! ✅</h1>
            </div>
            <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px;">
              <h2 style="color: #111827; margin-top: 0;">${reservation.title}</h2>
              <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 10px 0;"><strong>📅 Fecha:</strong> ${startTime}</p>
                ${playerName ? `<p style="margin: 10px 0;"><strong>⚽ Jugador:</strong> ${playerName}</p>` : ""}
                ${trainerName ? `<p style="margin: 10px 0;"><strong>👨‍🏫 Entrenador:</strong> ${trainerName}</p>` : ""}
                <p style="margin: 10px 0;"><strong>💳 Créditos:</strong> ${reservation.credit_cost || 1}</p>
              </div>
              <p style="color: #6b7280;">¡Nos vemos en la sesión!</p>
            </div>
          </div>
        `,
      };

    case "rejected":
      return {
        subject: "❌ Tu reserva ha sido rechazada",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #ef4444, #dc2626); padding: 30px; border-radius: 12px 12px 0 0;">
              <h1 style="color: white; margin: 0; font-size: 24px;">Reserva Rechazada ❌</h1>
            </div>
            <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px;">
              <h2 style="color: #111827; margin-top: 0;">${reservation.title}</h2>
              <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 10px 0;"><strong>📅 Fecha solicitada:</strong> ${startTime}</p>
                ${playerName ? `<p style="margin: 10px 0;"><strong>⚽ Jugador:</strong> ${playerName}</p>` : ""}
              </div>
              <p style="color: #6b7280;">Lamentamos que no haya sido posible confirmar esta reserva. Por favor, intenta con otra fecha u horario.</p>
            </div>
          </div>
        `,
      };

    case "updated":
      return {
        subject: "🔄 Tu reserva ha sido actualizada",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #3b82f6, #2563eb); padding: 30px; border-radius: 12px 12px 0 0;">
              <h1 style="color: white; margin: 0; font-size: 24px;">Reserva Actualizada 🔄</h1>
            </div>
            <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px;">
              <h2 style="color: #111827; margin-top: 0;">${reservation.title}</h2>
              <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 10px 0;"><strong>📅 Nueva fecha:</strong> ${startTime}</p>
                ${playerName ? `<p style="margin: 10px 0;"><strong>⚽ Jugador:</strong> ${playerName}</p>` : ""}
                ${trainerName ? `<p style="margin: 10px 0;"><strong>👨‍🏫 Entrenador:</strong> ${trainerName}</p>` : ""}
              </div>
              <p style="color: #6b7280;">Revisa los detalles de tu reserva actualizada.</p>
            </div>
          </div>
        `,
      };

    case "reminder":
      return {
        subject: "⏰ Recordatorio: Tu sesión es pronto",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #f59e0b, #d97706); padding: 30px; border-radius: 12px 12px 0 0;">
              <h1 style="color: white; margin: 0; font-size: 24px;">Recordatorio ⏰</h1>
            </div>
            <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px;">
              <h2 style="color: #111827; margin-top: 0;">${reservation.title}</h2>
              <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 10px 0;"><strong>📅 Fecha:</strong> ${startTime}</p>
                ${playerName ? `<p style="margin: 10px 0;"><strong>⚽ Jugador:</strong> ${playerName}</p>` : ""}
                ${trainerName ? `<p style="margin: 10px 0;"><strong>👨‍🏫 Entrenador:</strong> ${trainerName}</p>` : ""}
              </div>
              <p style="color: #6b7280;">¡No olvides tu sesión de entrenamiento!</p>
            </div>
          </div>
        `,
      };

    default:
      return {
        subject: "Actualización de reserva",
        html: `<p>Tu reserva "${reservation.title}" ha sido actualizada.</p>`,
      };
  }
};

const sendEmailWithResend = async (to: string, subject: string, html: string, apiKey: string) => {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "Elite Training <onboarding@resend.dev>",
      to: [to],
      subject: subject,
      html: html,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Resend API error: ${error}`);
  }

  return response.json();
};

const handler = async (req: Request): Promise<Response> => {
  console.log("send-reservation-email function called");

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      throw new Error("RESEND_API_KEY not configured");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { reservation_id, type }: EmailRequest = await req.json();
    console.log(`Processing ${type} email for reservation ${reservation_id}`);

    // Fetch reservation details
    const { data: reservation, error: resError } = await supabase
      .from("reservations")
      .select("*")
      .eq("id", reservation_id)
      .single();

    if (resError || !reservation) {
      console.error("Error fetching reservation:", resError);
      throw new Error("Reservation not found");
    }

    // Fetch user email
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("email, full_name")
      .eq("id", reservation.user_id)
      .single();

    if (profileError || !profile?.email) {
      console.error("Error fetching profile:", profileError);
      throw new Error("User email not found");
    }

    // Fetch player name if exists
    let playerName = "";
    if (reservation.player_id) {
      const { data: player } = await supabase
        .from("players")
        .select("name")
        .eq("id", reservation.player_id)
        .single();
      playerName = player?.name || "";
    }

    // Fetch trainer name if exists (using public view - no sensitive data needed)
    let trainerName = "";
    if (reservation.trainer_id) {
      const { data: trainer } = await supabase
        .from("trainers_public")
        .select("name")
        .eq("id", reservation.trainer_id)
        .single();
      trainerName = trainer?.name || "";
    }

    const { subject, html } = getEmailContent(type, reservation, playerName, trainerName);

    console.log(`Sending email to ${profile.email}`);
    const emailResponse = await sendEmailWithResend(profile.email, subject, html, resendApiKey);

    console.log("Email sent successfully:", emailResponse);

    return new Response(JSON.stringify({ success: true, emailResponse }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: any) {
    console.error("Error in send-reservation-email:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
};

serve(handler);
