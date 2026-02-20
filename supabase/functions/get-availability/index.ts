import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface AvailabilitySlot {
  date: string;
  hour: number;
  count: number;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { start_date, end_date } = await req.json();

    if (!start_date || !end_date) {
      return new Response(
        JSON.stringify({ error: "start_date and end_date are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Query reservations between dates with status pending or approved
    const { data: reservations, error } = await supabase
      .from("reservations")
      .select("start_time")
      .in("status", ["pending", "approved"])
      .gte("start_time", start_date)
      .lte("start_time", end_date);

    if (error) throw error;

    // Aggregate by date and hour
    const availability: Record<string, Record<number, number>> = {};

    for (const res of reservations || []) {
      const date = new Date(res.start_time);
      const dateKey = date.toISOString().split("T")[0];
      const hour = date.getHours();

      if (!availability[dateKey]) {
        availability[dateKey] = {};
      }
      if (!availability[dateKey][hour]) {
        availability[dateKey][hour] = 0;
      }
      availability[dateKey][hour]++;
    }

    // Convert to flat array
    const slots: AvailabilitySlot[] = [];
    for (const [date, hours] of Object.entries(availability)) {
      for (const [hour, count] of Object.entries(hours)) {
        slots.push({ date, hour: parseInt(hour), count });
      }
    }

    return new Response(
      JSON.stringify({ slots }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: unknown) {
    console.error("Error:", error);
    const message = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
