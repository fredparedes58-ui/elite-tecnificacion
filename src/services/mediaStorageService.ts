/**
 * Servicio de almacenamiento soberano: R2 (fotos) y Bunny Stream (vídeo).
 * - Fotos: presigned URL R2 vía Edge Function, subida directa desde el cliente.
 * - Vídeo: TUS resumible a Bunny Stream; backend genera credenciales firmadas.
 */

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;

export interface BunnyUploadCredentials {
  uploadUrl: string;
  videoId: string;
  libraryId: string;
  authorizationSignature: string;
  authorizationExpire: number;
}

export interface PresignedResult {
  url: string;
  key: string;
}

export interface R2PresignParams {
  parent_id: string;
  player_id: string;
  filename: string;
  content_type: string;
}

/**
 * Obtiene una URL presigned de la Edge Function (valida sesión: parent o admin).
 */
export async function getR2PresignedUrl(
  params: R2PresignParams,
  accessToken: string
): Promise<PresignedResult> {
  const res = await fetch(`${SUPABASE_URL}/functions/v1/generate-r2-presigned-url`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify(params),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }));
    const errorMessage = (err as { error?: string }).error ?? "Failed to get upload URL";
    // Lanzar error con mensaje claro para el usuario
    throw new Error("Error al obtener permisos de subida. Verifica tu conexión e intenta de nuevo.");
  }

  return res.json() as Promise<PresignedResult>;
}

/**
 * Sube un archivo directamente a R2 usando la URL presigned.
 */
export async function uploadToR2(
  file: File,
  presignedUrl: string,
  contentType: string
): Promise<void> {
  const res = await fetch(presignedUrl, {
    method: "PUT",
    headers: { "Content-Type": contentType },
    body: file,
  });

  if (!res.ok) {
    // Mensaje claro para el usuario
    throw new Error("Error al subir la foto. El archivo puede ser muy grande o la conexión es inestable.");
  }
}

/**
 * Obtiene credenciales para subida TUS a Bunny Stream (vídeo de análisis).
 * Valida sesión: parent o admin.
 */
export async function getBunnyUploadCredentials(
  params: { parent_id: string; player_id: string; title?: string },
  accessToken: string
): Promise<BunnyUploadCredentials> {
  const res = await fetch(`${SUPABASE_URL}/functions/v1/create-bunny-upload`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify(params),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }));
    // Mensaje claro para el usuario
    throw new Error("Error al obtener permisos de subida de vídeo. Verifica tu conexión e intenta de nuevo.");
  }

  return res.json() as Promise<BunnyUploadCredentials>;
}

/**
 * Sube un archivo de vídeo con TUS (resumible) a Bunny Stream.
 * Requiere: npm install tus-js-client
 */
export async function uploadVideoTus(
  file: File,
  credentials: BunnyUploadCredentials,
  onProgress?: (bytesUploaded: number, bytesTotal: number) => void
): Promise<string> {
  const Tus = (await import("tus-js-client")).default;

  return new Promise((resolve, reject) => {
    const upload = new Tus.Upload(file, {
      endpoint: credentials.uploadUrl,
      retryDelays: [0, 3000, 5000, 10000, 20000],
      metadata: {
        filetype: file.type,
        title: file.name,
      },
      headers: {
        AuthorizationSignature: credentials.authorizationSignature,
        AuthorizationExpire: String(credentials.authorizationExpire),
        LibraryId: credentials.libraryId,
        VideoId: credentials.videoId,
      },
      onProgress(bytesUploaded, bytesTotal) {
        onProgress?.(bytesUploaded, bytesTotal ?? 0);
      },
      onSuccess() {
        resolve(credentials.videoId);
      },
      onError(err: Error) {
        // Mensaje claro para el usuario sobre errores de subida TUS
        reject(new Error("Error al subir el vídeo. Verifica tu conexión y el tamaño del archivo."));
      },
    });
    upload.start();
  });
}
