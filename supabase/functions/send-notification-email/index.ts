import { serve } from "https://deno.land/std@0.190.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface NotificationEmailRequest {
  to_email: string;
  to_name: string;
  title: string;
  message: string;
  type: string;
  metadata?: Record<string, unknown>;
}

const getEmailTemplate = (title: string, message: string, type: string) => {
  // Color schemes per notification type
  const colorMap: Record<string, { gradient: string; accent: string }> = {
    reservation_approved: { gradient: "linear-gradient(135deg, #10b981, #059669)", accent: "#059669" },
    reservation_rejected: { gradient: "linear-gradient(135deg, #ef4444, #dc2626)", accent: "#dc2626" },
    reservation_proposal: { gradient: "linear-gradient(135deg, #8b5cf6, #7c3aed)", accent: "#7c3aed" },
    new_message: { gradient: "linear-gradient(135deg, #06b6d4, #0891b2)", accent: "#0891b2" },
    player_updated: { gradient: "linear-gradient(135deg, #f59e0b, #d97706)", accent: "#d97706" },
    scouting_updated: { gradient: "linear-gradient(135deg, #10b981, #047857)", accent: "#047857" },
    session_updated: { gradient: "linear-gradient(135deg, #3b82f6, #2563eb)", accent: "#2563eb" },
    session_player_removed: { gradient: "linear-gradient(135deg, #6b7280, #4b5563)", accent: "#4b5563" },
    credit_low: { gradient: "linear-gradient(135deg, #f59e0b, #d97706)", accent: "#d97706" },
    credit_exhausted: { gradient: "linear-gradient(135deg, #ef4444, #dc2626)", accent: "#dc2626" },
    new_user: { gradient: "linear-gradient(135deg, #8b5cf6, #7c3aed)", accent: "#7c3aed" },
    new_reservation_request: { gradient: "linear-gradient(135deg, #06b6d4, #0891b2)", accent: "#0891b2" },
  };

  const colors = colorMap[type] || { gradient: "linear-gradient(135deg, #3b82f6, #2563eb)", accent: "#2563eb" };

  return {
    subject: `Elite 380 - ${title.replace(/[\p{Emoji}]/gu, "").trim()}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: ${colors.gradient}; padding: 30px; border-radius: 12px 12px 0 0;">
          <h1 style="color: white; margin: 0; font-size: 22px;">${title}</h1>
        </div>
        <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px; border: 1px solid #e5e7eb; border-top: none;">
          <div style="background: white; padding: 20px; border-radius: 8px; border-left: 4px solid ${colors.accent}; margin-bottom: 20px;">
            <p style="margin: 0; font-size: 15px; color: #374151; line-height: 1.6;">${message}</p>
          </div>
          <p style="color: #9ca3af; font-size: 12px; margin: 0; text-align: center;">
            Este es un mensaje automático de Elite 380 Training.
          </p>
        </div>
      </div>
    `,
  };
};

const handler = async (req: Request): Promise<Response> => {
  console.log("send-notification-email function called");

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      throw new Error("RESEND_API_KEY not configured");
    }

    const { to_email, to_name, title, message, type }: NotificationEmailRequest = await req.json();
    console.log(`Processing notification email: type=${type}, to=${to_email}`);

    if (!to_email || !title || !message) {
      throw new Error("Missing required fields: to_email, title, message");
    }

    const { subject, html } = getEmailTemplate(title, message, type);

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Elite Training <onboarding@resend.dev>",
        to: [to_email],
        subject,
        html,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error(`Resend API error: ${error}`);
      throw new Error(`Resend API error: ${error}`);
    }

    const emailResponse = await response.json();
    console.log("Notification email sent successfully:", emailResponse);

    return new Response(JSON.stringify({ success: true, emailResponse }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("Error in send-notification-email:", errorMessage);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
};

serve(handler);
