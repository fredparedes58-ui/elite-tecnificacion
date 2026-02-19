/**
 * Genera presigned URLs S3 para subida directa a Cloudflare R2.
 * Path: parents/{parent_id}/players/{player_id}/{uuid}_{filename}
 * Valida que el usuario autenticado sea el parent o admin antes de generar el link.
 */
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { S3Client, PutObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3.0.0";
import { getSignedUrl } from "https://esm.sh/@aws-sdk/s3-request-presigner@3.0.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const ALLOWED_IMAGE_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
];

interface PresignRequest {
  parent_id: string;
  player_id: string;
  filename: string;
  content_type: string;
}

function sanitizeFilename(name: string): string {
  return name.replace(/[^a-zA-Z0-9._-]/g, "_").slice(0, 200);
}

const handler = async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization" }),
        { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", "")
    );
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const role = (user.app_metadata as Record<string, string>)?.role;
    const isAdmin = role === "admin";

    const body: PresignRequest = await req.json();
    const { parent_id, player_id, filename, content_type } = body;

    if (!parent_id || !player_id || !filename || !content_type) {
      return new Response(
        JSON.stringify({ error: "parent_id, player_id, filename, content_type required" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (!ALLOWED_IMAGE_TYPES.includes(content_type)) {
      return new Response(
        JSON.stringify({ error: "content_type not allowed for photos" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (!isAdmin && user.id !== parent_id) {
      return new Response(
        JSON.stringify({ error: "Only the parent or admin can upload for this player" }),
        { status: 403, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const accountId = Deno.env.get("R2_ACCOUNT_ID");
    const accessKeyId = Deno.env.get("R2_ACCESS_KEY_ID");
    const secretAccessKey = Deno.env.get("R2_SECRET_ACCESS_KEY");
    const bucket = Deno.env.get("R2_BUCKET");

    if (!accountId || !accessKeyId || !secretAccessKey || !bucket) {
      return new Response(
        JSON.stringify({ error: "R2 not configured" }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const uuid = crypto.randomUUID();
    const safeName = sanitizeFilename(filename);
    const key = `parents/${parent_id}/players/${player_id}/${uuid}_${safeName}`;

    const s3 = new S3Client({
      region: "auto",
      endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
      credentials: { accessKeyId, secretAccessKey },
    });

    const putCommand = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      ContentType: content_type,
    });

    const url = await getSignedUrl(s3, putCommand, { expiresIn: 3600 });

    return new Response(
      JSON.stringify({ url, key }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("generate-r2-presigned-url error:", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
};

serve(handler);
