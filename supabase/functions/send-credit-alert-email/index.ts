import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CreditAlertRequest {
  user_id: string;
  player_name: string;
  credits_remaining: number;
  alert_type: "low" | "exhausted";
}

const getEmailContent = (playerName: string, credits: number, alertType: string) => {
  if (alertType === "exhausted") {
    return {
      subject: "⚠️ Créditos Agotados - Elite Training",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #ef4444, #dc2626); padding: 30px; border-radius: 12px 12px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 24px;">⚠️ Créditos Agotados</h1>
          </div>
          <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px;">
            <h2 style="color: #111827; margin-top: 0;">Hola,</h2>
            <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ef4444;">
              <p style="margin: 10px 0; font-size: 16px;">
                Los créditos de <strong>${playerName}</strong> se han agotado.
              </p>
              <p style="margin: 10px 0; color: #ef4444; font-weight: bold; font-size: 20px;">
                Créditos actuales: 0
              </p>
            </div>
            <p style="color: #6b7280;">
              Para continuar reservando sesiones de entrenamiento, por favor contacta con el administrador para recargar créditos.
            </p>
            <div style="margin-top: 20px; padding: 15px; background: #fef2f2; border-radius: 8px;">
              <p style="margin: 0; color: #dc2626; font-size: 14px;">
                ⚠️ Sin créditos no podrás acceder al calendario de reservas.
              </p>
            </div>
          </div>
        </div>
      `,
    };
  }

  return {
    subject: "⚡ Créditos Bajos - Elite Training",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #f59e0b, #d97706); padding: 30px; border-radius: 12px 12px 0 0;">
          <h1 style="color: white; margin: 0; font-size: 24px;">⚡ Créditos Bajos</h1>
        </div>
        <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px;">
          <h2 style="color: #111827; margin-top: 0;">Hola,</h2>
          <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f59e0b;">
            <p style="margin: 10px 0; font-size: 16px;">
              Los créditos de <strong>${playerName}</strong> están por agotarse.
            </p>
            <p style="margin: 10px 0; color: #f59e0b; font-weight: bold; font-size: 20px;">
              Créditos restantes: ${credits}
            </p>
          </div>
          <p style="color: #6b7280;">
            Te recomendamos recargar pronto para no quedarte sin acceso al calendario de reservas.
          </p>
          <div style="margin-top: 20px; padding: 15px; background: #fffbeb; border-radius: 8px;">
            <p style="margin: 0; color: #b45309; font-size: 14px;">
              💡 Contacta con el administrador para adquirir un nuevo bono de sesiones.
            </p>
          </div>
        </div>
      </div>
    `,
  };
};

const handler = async (req: Request): Promise<Response> => {
  console.log("send-credit-alert-email function called");

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

    const { user_id, player_name, credits_remaining, alert_type }: CreditAlertRequest = await req.json();
    console.log(`Processing ${alert_type} credit alert for user ${user_id}, player ${player_name}`);

    // Fetch user email
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("email, full_name")
      .eq("id", user_id)
      .single();

    if (profileError || !profile?.email) {
      console.error("Error fetching profile:", profileError);
      throw new Error("User email not found");
    }

    const { subject, html } = getEmailContent(player_name, credits_remaining, alert_type);

    console.log(`Sending credit alert email to ${profile.email}`);
    
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Elite Training <onboarding@resend.dev>",
        to: [profile.email],
        subject: subject,
        html: html,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Resend API error: ${error}`);
    }

    const emailResponse = await response.json();
    console.log("Credit alert email sent successfully:", emailResponse);

    return new Response(JSON.stringify({ success: true, emailResponse }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: any) {
    console.error("Error in send-credit-alert-email:", error);
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
