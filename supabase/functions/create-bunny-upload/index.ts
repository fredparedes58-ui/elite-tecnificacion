/**
 * Crea un video en Bunny Stream y devuelve credenciales para subida TUS resumible.
 * El cliente usa tus-js-client con uploadUrl + headers (AuthorizationSignature, AuthorizationExpire, LibraryId, VideoId).
 */
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const TUS_UPLOAD_URL = "https://video.bunnycdn.com/tusupload";

interface CreateBunnyRequest {
  parent_id: string;
  player_id: string;
  title?: string;
}

const handler = async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    const role = (user.app_metadata as Record<string, string>)?.role;
    const isAdmin = role === "admin";

    const body: CreateBunnyRequest = await req.json();
    const { parent_id, player_id, title } = body;

    if (!parent_id || !player_id) {
      return new Response(
        JSON.stringify({ error: "parent_id and player_id required" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (!isAdmin && user.id !== parent_id) {
      return new Response(
        JSON.stringify({ error: "Only the parent or admin can create uploads for this player" }),
        { status: 403, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const libraryId = Deno.env.get("BUNNY_STREAM_LIBRARY_ID");
    const apiKey = Deno.env.get("BUNNY_STREAM_API_KEY");

    if (!libraryId || !apiKey) {
      return new Response(JSON.stringify({ error: "Bunny Stream not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    const videoTitle = title || `Analysis ${player_id} ${Date.now()}`;

    const createRes = await fetch(
      `https://video.bunnycdn.com/library/${libraryId}/videos`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          AccessKey: apiKey,
        },
        body: JSON.stringify({ title: videoTitle }),
      }
    );

    if (!createRes.ok) {
      const errText = await createRes.text();
      console.error("Bunny create video error:", errText);
      return new Response(
        JSON.stringify({ error: "Failed to create video", details: errText }),
        { status: 502, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const video = (await createRes.json()) as { guid?: string };
    const videoId = video.guid;
    if (!videoId) {
      return new Response(JSON.stringify({ error: "No videoId in response" }), {
        status: 502,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    const expirationTime = Math.floor(Date.now() / 1000) + 3600;
    const signatureString = `${libraryId}${apiKey}${expirationTime}${videoId}`;
    const encoder = new TextEncoder();
    const data = encoder.encode(signatureString);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = new Uint8Array(hashBuffer);
    const authorizationSignature = Array.from(hashArray)
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    return new Response(
      JSON.stringify({
        uploadUrl: TUS_UPLOAD_URL,
        videoId,
        libraryId,
        authorizationSignature,
        authorizationExpire: expirationTime,
      }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("create-bunny-upload error:", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
};

serve(handler);
