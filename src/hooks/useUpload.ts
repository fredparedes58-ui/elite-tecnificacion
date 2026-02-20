/**
 * Hook useUpload: subida de fotos a R2 (presigned) desde el cliente.
 * useTusUpload: subida de vídeo a Bunny Stream con TUS (resumible).
 */
import { useState, useCallback } from "react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import {
  getR2PresignedUrl,
  uploadToR2,
  getBunnyUploadCredentials,
  uploadVideoTus,
  type BunnyUploadCredentials,
} from "@/services/mediaStorageService";

export interface UseUploadOptions {
  parentId: string;
  playerId: string;
  onSuccess?: (key: string) => void;
  onError?: (error: Error) => void;
}

export interface UseUploadResult {
  upload: (file: File) => Promise<string | null>;
  uploading: boolean;
  error: Error | null;
  progress: number | null;
}

const ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];

export function useUpload(options: UseUploadOptions): UseUploadResult {
  const { parentId, playerId, onSuccess, onError } = options;
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [progress, setProgress] = useState<number | null>(null);

  const upload = useCallback(
    async (file: File): Promise<string | null> => {
      if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
        const err = new Error("Tipo de archivo no permitido. Usa JPEG, PNG, WebP o GIF.");
        setError(err);
        onError?.(err);
        return null;
      }

      setUploading(true);
      setError(null);
      setProgress(0);

      try {
        const {
          data: { session },
        } = await supabase.auth.getSession();
        if (!session?.access_token) {
          throw new Error("No hay sesión activa");
        }

        const { url, key } = await getR2PresignedUrl(
          {
            parent_id: parentId,
            player_id: playerId,
            filename: file.name,
            content_type: file.type,
          },
          session.access_token
        );

        setProgress(50);
        await uploadToR2(file, url, file.type);
        setProgress(100);

        onSuccess?.(key);
        return key;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        // Mostrar mensaje de error al usuario usando toast
        toast.error(e.message || "Error al subir la foto. Verifica tu conexión e intenta de nuevo.");
        onError?.(e);
        return null;
      } finally {
        setUploading(false);
        setProgress(null);
      }
    },
    [parentId, playerId, onSuccess, onError]
  );

  return { upload, uploading, error, progress };
}

export interface UseTusUploadOptions {
  parentId: string;
  playerId: string;
  title?: string;
  onSuccess?: (videoId: string) => void;
  onError?: (error: Error) => void;
}

export interface UseTusUploadResult {
  uploadVideo: (file: File) => Promise<string | null>;
  uploading: boolean;
  error: Error | null;
  progress: number | null;
}

export function useTusUpload(options: UseTusUploadOptions): UseTusUploadResult {
  const { parentId, playerId, title, onSuccess, onError } = options;
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [progress, setProgress] = useState<number | null>(null);

  const uploadVideo = useCallback(
    async (file: File): Promise<string | null> => {
      setUploading(true);
      setError(null);
      setProgress(0);

      try {
        const {
          data: { session },
        } = await supabase.auth.getSession();
        if (!session?.access_token) {
          throw new Error("No hay sesión activa");
        }

        const credentials: BunnyUploadCredentials = await getBunnyUploadCredentials(
          { parent_id: parentId, player_id: playerId, title: title ?? file.name },
          session.access_token
        );

        const videoId = await uploadVideoTus(file, credentials, (bytesUploaded, bytesTotal) => {
          if (bytesTotal > 0) {
            setProgress(Math.round((bytesUploaded / bytesTotal) * 100));
          }
        });

        onSuccess?.(videoId);
        return videoId;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        // Mostrar mensaje de error al usuario usando toast
        toast.error(e.message || "Error al subir el vídeo. Verifica tu conexión y el tamaño del archivo.");
        onError?.(e);
        return null;
      } finally {
        setUploading(false);
        setProgress(null);
      }
    },
    [parentId, playerId, title, onSuccess, onError]
  );

  return { uploadVideo, uploading, error, progress };
}
