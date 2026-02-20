import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { Resend } from "npm:resend@2.0.0";

const resend = new Resend(Deno.env.get("RESEND_API_KEY"));

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

interface CreditReceiptRequest {
  parent_email: string;
  parent_name: string;
  player_name: string;
  credits_added: number;
  new_balance: number;
  payment_method?: string;
  cash_amount?: number;
  package_name?: string;
  description?: string;
}

const handler = async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const {
      parent_email,
      parent_name,
      player_name,
      credits_added,
      new_balance,
      payment_method,
      cash_amount,
      package_name,
      description,
    }: CreditReceiptRequest = await req.json();

    if (!parent_email || !player_name || credits_added === undefined) {
      throw new Error("Missing required fields: parent_email, player_name, credits_added");
    }

    const now = new Date();
    const dateFormatted = now.toLocaleDateString("es-ES", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });

    const receiptNumber = `E380-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, "0")}${String(now.getDate()).padStart(2, "0")}-${String(now.getHours()).padStart(2, "0")}${String(now.getMinutes()).padStart(2, "0")}`;

    const paymentMethodLabel = payment_method === "efectivo"
      ? "Efectivo"
      : payment_method === "transferencia"
      ? "Transferencia"
      : payment_method === "bizum"
      ? "Bizum"
      : payment_method || "No especificado";

    const cashAmountFormatted = cash_amount
      ? `${cash_amount.toFixed(2)} €`
      : "—";

    const emailHtml = `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0a0a1a; color: #e0e0e0;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; background-color: #111127;">
    <!-- Header -->
    <tr>
      <td style="padding: 30px 40px; text-align: center; background: linear-gradient(135deg, #06b6d4, #8b5cf6);">
        <h1 style="margin: 0; font-size: 28px; color: #ffffff; letter-spacing: 2px;">ELITE 380</h1>
        <p style="margin: 8px 0 0; font-size: 14px; color: rgba(255,255,255,0.85); letter-spacing: 1px;">RECIBO DE CRÉDITOS</p>
      </td>
    </tr>

    <!-- Receipt Number & Date -->
    <tr>
      <td style="padding: 25px 40px 10px;">
        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td style="font-size: 12px; color: #8888aa;">Recibo Nº</td>
            <td style="font-size: 12px; color: #8888aa; text-align: right;">Fecha</td>
          </tr>
          <tr>
            <td style="font-size: 14px; color: #06b6d4; font-weight: bold;">${receiptNumber}</td>
            <td style="font-size: 14px; color: #e0e0e0; text-align: right;">${dateFormatted}</td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- Divider -->
    <tr>
      <td style="padding: 10px 40px;">
        <hr style="border: none; border-top: 1px solid rgba(6,182,212,0.3);">
      </td>
    </tr>

    <!-- Client & Player Info -->
    <tr>
      <td style="padding: 10px 40px;">
        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td style="padding: 8px 0;">
              <span style="font-size: 12px; color: #8888aa;">Padre/Madre:</span><br>
              <span style="font-size: 16px; color: #ffffff; font-weight: bold;">${parent_name || parent_email}</span>
            </td>
          </tr>
          <tr>
            <td style="padding: 8px 0;">
              <span style="font-size: 12px; color: #8888aa;">Jugador:</span><br>
              <span style="font-size: 16px; color: #06b6d4; font-weight: bold;">⚽ ${player_name}</span>
            </td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- Credits Box -->
    <tr>
      <td style="padding: 15px 40px;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, rgba(6,182,212,0.15), rgba(139,92,246,0.15)); border: 1px solid rgba(6,182,212,0.3); border-radius: 12px;">
          <tr>
            <td style="padding: 20px; text-align: center;">
              <p style="margin: 0; font-size: 12px; color: #8888aa; text-transform: uppercase; letter-spacing: 1px;">Créditos Cargados</p>
              <p style="margin: 8px 0; font-size: 42px; color: #06b6d4; font-weight: bold;">+${credits_added}</p>
              ${package_name ? `<p style="margin: 0; font-size: 14px; color: #a0a0c0;">${package_name}</p>` : ""}
              ${description ? `<p style="margin: 4px 0 0; font-size: 12px; color: #8888aa;">${description}</p>` : ""}
            </td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- Payment Details -->
    <tr>
      <td style="padding: 10px 40px;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: rgba(255,255,255,0.03); border-radius: 8px;">
          <tr>
            <td style="padding: 12px 16px; border-bottom: 1px solid rgba(255,255,255,0.05);">
              <span style="font-size: 13px; color: #8888aa;">Método de pago</span>
            </td>
            <td style="padding: 12px 16px; text-align: right; border-bottom: 1px solid rgba(255,255,255,0.05);">
              <span style="font-size: 13px; color: #e0e0e0;">${paymentMethodLabel}</span>
            </td>
          </tr>
          ${cash_amount ? `
          <tr>
            <td style="padding: 12px 16px; border-bottom: 1px solid rgba(255,255,255,0.05);">
              <span style="font-size: 13px; color: #8888aa;">Monto recibido</span>
            </td>
            <td style="padding: 12px 16px; text-align: right; border-bottom: 1px solid rgba(255,255,255,0.05);">
              <span style="font-size: 13px; color: #10b981; font-weight: bold;">${cashAmountFormatted}</span>
            </td>
          </tr>
          ` : ""}
          <tr>
            <td style="padding: 12px 16px;">
              <span style="font-size: 13px; color: #8888aa;">Nuevo saldo</span>
            </td>
            <td style="padding: 12px 16px; text-align: right;">
              <span style="font-size: 18px; color: #06b6d4; font-weight: bold;">${new_balance} créditos</span>
            </td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- Footer -->
    <tr>
      <td style="padding: 30px 40px; text-align: center;">
        <hr style="border: none; border-top: 1px solid rgba(6,182,212,0.2); margin-bottom: 20px;">
        <p style="margin: 0; font-size: 12px; color: #666688;">
          Este recibo ha sido generado automáticamente por Elite 380.
        </p>
        <p style="margin: 8px 0 0; font-size: 11px; color: #555577;">
          © ${now.getFullYear()} Elite 380 — Entrenamiento de Fútbol
        </p>
      </td>
    </tr>
  </table>
</body>
</html>`;

    const emailResponse = await resend.emails.send({
      from: "Elite 380 <onboarding@resend.dev>",
      to: [parent_email],
      subject: `Recibo de Créditos — ${player_name} (+${credits_added})`,
      html: emailHtml,
    });

    console.log("Credit receipt email sent successfully:", emailResponse);

    return new Response(JSON.stringify(emailResponse), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: any) {
    console.error("Error in send-credit-receipt function:", error);
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
