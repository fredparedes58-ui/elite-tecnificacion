import React from 'react';
import { FileText, Download, Film } from 'lucide-react';
import { AttachmentMeta, formatFileSize } from './types';
import { cn } from '@/lib/utils';

interface Props {
  attachments: AttachmentMeta[];
  isMe: boolean;
}

const MessageAttachments: React.FC<Props> = ({ attachments, isMe }) => {
  if (!attachments || attachments.length === 0) return null;

  const images = attachments.filter(a => a.category === 'image');
  const videos = attachments.filter(a => a.category === 'video');
  const files = attachments.filter(a => a.category === 'file');

  return (
    <div className="space-y-2 mt-1">
      {/* Images grid */}
      {images.length > 0 && (
        <div className={cn('grid gap-1', images.length === 1 ? 'grid-cols-1' : 'grid-cols-2')}>
          {images.map((img, i) => (
            <a key={i} href={img.url} target="_blank" rel="noopener noreferrer" className="block rounded-lg overflow-hidden">
              <img
                src={img.url}
                alt={img.name}
                className="w-full max-h-48 object-cover rounded-lg hover:opacity-90 transition-opacity"
                loading="lazy"
              />
            </a>
          ))}
        </div>
      )}

      {/* Videos */}
      {videos.map((vid, i) => (
        <div key={i} className="rounded-lg overflow-hidden">
          <video
            src={vid.url}
            controls
            preload="metadata"
            className="w-full max-h-48 rounded-lg"
          />
          <div className={cn('flex items-center gap-1 mt-0.5 text-[10px]', isMe ? 'text-background/60' : 'text-muted-foreground')}>
            <Film className="w-3 h-3" />
            {vid.name} · {formatFileSize(vid.size)}
          </div>
        </div>
      ))}

      {/* Files */}
      {files.map((file, i) => (
        <a
          key={i}
          href={file.url}
          target="_blank"
          rel="noopener noreferrer"
          className={cn(
            'flex items-center gap-2 p-2 rounded-lg transition-colors',
            isMe ? 'bg-background/10 hover:bg-background/20' : 'bg-muted/30 hover:bg-muted/50'
          )}
        >
          <FileText className={cn('w-5 h-5 flex-shrink-0', isMe ? 'text-background/80' : 'text-neon-cyan')} />
          <div className="min-w-0 flex-1">
            <p className="text-xs font-medium truncate">{file.name}</p>
            <p className={cn('text-[10px]', isMe ? 'text-background/60' : 'text-muted-foreground')}>
              {formatFileSize(file.size)} · {file.type.toUpperCase()}
            </p>
          </div>
          <Download className={cn('w-4 h-4 flex-shrink-0', isMe ? 'text-background/60' : 'text-muted-foreground')} />
        </a>
      ))}
    </div>
  );
};

export default MessageAttachments;
