import { useState, useCallback } from 'react';
import { toast } from 'sonner';
import { supabase } from '@/integrations/supabase/client';
import {
  ChatAttachment, AttachmentMeta,
  ALLOWED_MIME, MAX_SIZES, MAX_COUNTS, formatFileSize,
} from './types';

export const useAttachments = () => {
  const [attachments, setAttachments] = useState<ChatAttachment[]>([]);
  const [uploading, setUploading] = useState(false);

  const addFiles = useCallback((files: FileList | File[]) => {
    const fileArr = Array.from(files);
    const errors: string[] = [];

    setAttachments(prev => {
      const next = [...prev];

      for (const file of fileArr) {
        const category = ALLOWED_MIME[file.type];
        if (!category) {
          errors.push(`${file.name}: tipo no permitido`);
          continue;
        }
        if (file.size > MAX_SIZES[category]) {
          errors.push(`${file.name}: excede ${formatFileSize(MAX_SIZES[category])}`);
          continue;
        }
        const countOfType = next.filter(a => a.type === category).length;
        if (countOfType >= MAX_COUNTS[category]) {
          errors.push(`Máx. ${MAX_COUNTS[category]} ${category === 'image' ? 'imágenes' : category === 'video' ? 'videos' : 'archivos'}`);
          continue;
        }

        const id = `att-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
        const preview = category === 'image' ? URL.createObjectURL(file) : undefined;
        next.push({ id, file, preview, type: category, name: file.name, size: file.size });
      }

      if (errors.length) toast.error(errors.join('\n'));
      return next;
    });
  }, []);

  const removeAttachment = useCallback((id: string) => {
    setAttachments(prev => {
      const att = prev.find(a => a.id === id);
      if (att?.preview) URL.revokeObjectURL(att.preview);
      return prev.filter(a => a.id !== id);
    });
  }, []);

  const clearAttachments = useCallback(() => {
    setAttachments(prev => {
      prev.forEach(a => { if (a.preview) URL.revokeObjectURL(a.preview); });
      return [];
    });
  }, []);

  const uploadAll = useCallback(async (conversationId: string): Promise<AttachmentMeta[]> => {
    if (attachments.length === 0) return [];
    setUploading(true);

    try {
      const results: AttachmentMeta[] = [];

      for (const att of attachments) {
        const ext = att.name.split('.').pop() || 'bin';
        const path = `${conversationId}/${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;

        const { error } = await supabase.storage
          .from('chat-attachments')
          .upload(path, att.file, { contentType: att.file.type });

        if (error) throw error;

        const { data: urlData } = supabase.storage
          .from('chat-attachments')
          .getPublicUrl(path);

        // Since bucket is private, use createSignedUrl for access
        const { data: signedData } = await supabase.storage
          .from('chat-attachments')
          .createSignedUrl(path, 60 * 60 * 24 * 365); // 1 year

        results.push({
          url: signedData?.signedUrl || urlData.publicUrl,
          name: att.name,
          size: att.size,
          type: ext,
          mime: att.file.type,
          category: att.type,
        });
      }

      return results;
    } catch (err) {
      console.error('Upload error:', err);
      toast.error('Error al subir archivos');
      return [];
    } finally {
      setUploading(false);
    }
  }, [attachments]);

  return { attachments, addFiles, removeAttachment, clearAttachments, uploadAll, uploading };
};
