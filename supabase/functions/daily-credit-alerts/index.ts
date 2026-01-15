import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LOW_CREDIT_THRESHOLD = 5;

const getEmailContent = (playerName: string, credits: number, alertType: 'low' | 'exhausted') => {
  if (alertType === "exhausted") {
    return {
      subject: "⚠️ Créditos Agotados - Elite Training",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #ef4444, #dc2626); padding: 30px; border-radius: 12px 12px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 24px;">⚠️ Créditos Agotados</h1>
          </div>
          <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px;">
            <h2 style="color: #111827; margin-top: 0;">Recordatorio Automático</h2>
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
            <p style="color: #9ca3af; font-size: 12px; margin-top: 20px;">
              Este es un recordatorio automático del sistema Elite Training.
            </p>
          </div>
        </div>
      `,
    };
  }

  return {
    subject: "⚡ Recordatorio: Créditos Bajos - Elite Training",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #f59e0b, #d97706); padding: 30px; border-radius: 12px 12px 0 0;">
          <h1 style="color: white; margin: 0; font-size: 24px;">⚡ Créditos Bajos</h1>
        </div>
        <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 12px 12px;">
          <h2 style="color: #111827; margin-top: 0;">Recordatorio Automático</h2>
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
          <p style="color: #9ca3af; font-size: 12px; margin-top: 20px;">
            Este es un recordatorio automático del sistema Elite Training.
          </p>
        </div>
      </div>
    `,
  };
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
  console.log("daily-credit-alerts function called at", new Date().toISOString());

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

    // Get all players with their parent info and credits
    const { data: players, error: playersError } = await supabase
      .from('players')
      .select('id, name, parent_id');

    if (playersError) {
      console.error("Error fetching players:", playersError);
      throw playersError;
    }

    if (!players || players.length === 0) {
      console.log("No players found");
      return new Response(JSON.stringify({ success: true, message: "No players to check" }), {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    // Get unique parent IDs
    const parentIds = [...new Set(players.map(p => p.parent_id))];

    // Get credits and profiles for all parents
    const [creditsRes, profilesRes] = await Promise.all([
      supabase.from('user_credits').select('user_id, balance').in('user_id', parentIds),
      supabase.from('profiles').select('id, email, full_name').in('id', parentIds)
    ]);

    if (creditsRes.error) throw creditsRes.error;
    if (profilesRes.error) throw profilesRes.error;

    const creditsMap = new Map(creditsRes.data?.map(c => [c.user_id, c.balance]) || []);
    const profilesMap = new Map(profilesRes.data?.map(p => [p.id, p]) || []);

    // Find players with low or zero credits
    const playersWithLowCredits = players
      .map(player => ({
        ...player,
        credits: creditsMap.get(player.parent_id) || 0,
        parent: profilesMap.get(player.parent_id)
      }))
      .filter(player => player.credits <= LOW_CREDIT_THRESHOLD && player.parent?.email);

    console.log(`Found ${playersWithLowCredits.length} players with low/zero credits`);

    if (playersWithLowCredits.length === 0) {
      return new Response(JSON.stringify({ 
        success: true, 
        message: "No players with low credits",
        checked: players.length 
      }), {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    // Group by parent to avoid sending multiple emails
    const parentAlerts = new Map<string, { email: string; players: { name: string; credits: number }[] }>();
    
    for (const player of playersWithLowCredits) {
      const parentId = player.parent_id;
      if (!parentAlerts.has(parentId)) {
        parentAlerts.set(parentId, {
          email: player.parent!.email,
          players: []
        });
      }
      parentAlerts.get(parentId)!.players.push({
        name: player.name,
        credits: player.credits
      });
    }

    let sentCount = 0;
    let errorCount = 0;

    // Send emails and create in-app notifications for each parent
    for (const [parentId, data] of parentAlerts) {
      try {
        for (const playerInfo of data.players) {
          const alertType = playerInfo.credits === 0 ? 'exhausted' : 'low';
          const { subject, html } = getEmailContent(playerInfo.name, playerInfo.credits, alertType);
          
          // Send email
          await sendEmailWithResend(data.email, subject, html, resendApiKey);
          
          // Create in-app notification
          await supabase.from('notifications').insert({
            user_id: parentId,
            type: alertType === 'exhausted' ? 'credit_exhausted' : 'credit_low',
            title: alertType === 'exhausted' ? '⚠️ Créditos Agotados' : '⚡ Créditos Bajos',
            message: alertType === 'exhausted' 
              ? `Los créditos de ${playerInfo.name} se han agotado. Contacta con el administrador.`
              : `Los créditos de ${playerInfo.name} están bajos (${playerInfo.credits} restantes).`,
            metadata: { player_name: playerInfo.name, credits: playerInfo.credits }
          });
          
          sentCount++;
          console.log(`Sent ${alertType} alert for ${playerInfo.name} to ${data.email}`);
        }
      } catch (err) {
        console.error(`Error sending alert to ${data.email}:`, err);
        errorCount++;
      }
    }

    console.log(`Daily credit alerts completed: ${sentCount} sent, ${errorCount} failed`);

    return new Response(JSON.stringify({ 
      success: true, 
      sent: sentCount,
      failed: errorCount,
      totalPlayers: players.length,
      lowCreditPlayers: playersWithLowCredits.length
    }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });

  } catch (error: any) {
    console.error("Error in daily-credit-alerts:", error);
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
