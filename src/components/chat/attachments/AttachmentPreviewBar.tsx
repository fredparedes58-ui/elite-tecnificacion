import React from 'react';
import { X, Image, Film, FileText } from 'lucide-react';
import { ChatAttachment, formatFileSize } from './types';
import { cn } from '@/lib/utils';

interface Props {
  attachments: ChatAttachment[];
  onRemove: (id: string) => void;
}

const iconMap = {
  image: Image,
  video: Film,
  file: FileText,
};

const AttachmentPreviewBar: React.FC<Props> = ({ attachments, onRemove }) => {
  if (attachments.length === 0) return null;

  return (
    <div className="flex gap-2 overflow-x-auto py-2 px-1">
      {attachments.map(att => {
        const Icon = iconMap[att.type];
        return (
          <div
            key={att.id}
            className={cn(
              'relative flex-shrink-0 rounded-lg border border-neon-cyan/20 bg-muted/50 overflow-hidden group',
              att.type === 'image' ? 'w-20 h-20' : 'w-36 h-20 flex items-center gap-2 px-2'
            )}
          >
            {att.type === 'image' && att.preview ? (
              <img src={att.preview} alt={att.name} className="w-full h-full object-cover" />
            ) : (
              <>
                <Icon className="w-6 h-6 text-neon-cyan flex-shrink-0" />
                <div className="min-w-0 flex-1">
                  <p className="text-xs font-medium truncate">{att.name}</p>
                  <p className="text-[10px] text-muted-foreground">{formatFileSize(att.size)}</p>
                </div>
              </>
            )}
            <button
              onClick={() => onRemove(att.id)}
              className="absolute top-0.5 right-0.5 w-5 h-5 rounded-full bg-destructive text-destructive-foreground flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
            >
              <X className="w-3 h-3" />
            </button>
          </div>
        );
      })}
    </div>
  );
};

export default AttachmentPreviewBar;
