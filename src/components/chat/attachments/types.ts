export interface ChatAttachment {
  id: string;
  file: File;
  preview?: string;
  type: 'image' | 'video' | 'file';
  name: string;
  size: number;
}

export interface AttachmentMeta {
  url: string;
  name: string;
  size: number;
  type: string;
  mime: string;
  category: 'image' | 'video' | 'file';
}

export const ALLOWED_MIME: Record<string, 'image' | 'video' | 'file'> = {
  'image/jpeg': 'image',
  'image/png': 'image',
  'image/webp': 'image',
  'video/mp4': 'video',
  'video/webm': 'video',
  'video/quicktime': 'video',
  'application/pdf': 'file',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'file',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'file',
  'text/plain': 'file',
  'application/zip': 'file',
};

export const MAX_SIZES: Record<'image' | 'video' | 'file', number> = {
  image: 8 * 1024 * 1024,
  video: 50 * 1024 * 1024,
  file: 15 * 1024 * 1024,
};

export const MAX_COUNTS: Record<'image' | 'video' | 'file', number> = {
  image: 10,
  video: 5,
  file: 5,
};

export const formatFileSize = (bytes: number) => {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};
