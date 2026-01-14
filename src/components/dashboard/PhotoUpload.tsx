import React, { useRef } from 'react';
import { NeonButton } from '@/components/ui/NeonButton';
import { Camera, Upload, X } from 'lucide-react';

interface PhotoUploadProps {
  currentPhoto?: string | null;
  onUpload: (file: File) => Promise<void>;
  loading?: boolean;
}

const PhotoUpload: React.FC<PhotoUploadProps> = ({ currentPhoto, onUpload, loading }) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = React.useState<string | null>(null);
  const [selectedFile, setSelectedFile] = React.useState<File | null>(null);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      const reader = new FileReader();
      reader.onload = () => {
        setPreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleUpload = async () => {
    if (selectedFile) {
      await onUpload(selectedFile);
      setPreview(null);
      setSelectedFile(null);
    }
  };

  const handleCancel = () => {
    setPreview(null);
    setSelectedFile(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const displayImage = preview || currentPhoto;

  return (
    <div className="flex flex-col items-center gap-4">
      {/* Photo Display */}
      <div className="relative w-32 h-32 rounded-xl overflow-hidden border-2 border-neon-cyan/30 bg-gradient-to-br from-neon-cyan/10 to-neon-purple/10">
        {displayImage ? (
          <img
            src={displayImage}
            alt="Player photo"
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <Camera className="w-12 h-12 text-neon-cyan/30" />
          </div>
        )}
        {preview && (
          <button
            onClick={handleCancel}
            className="absolute top-1 right-1 w-6 h-6 rounded-full bg-destructive flex items-center justify-center"
          >
            <X className="w-4 h-4 text-white" />
          </button>
        )}
      </div>

      {/* File Input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        capture="environment"
        onChange={handleFileSelect}
        className="hidden"
      />

      {/* Buttons */}
      {preview ? (
        <div className="flex gap-2">
          <NeonButton variant="outline" size="sm" onClick={handleCancel}>
            Cancelar
          </NeonButton>
          <NeonButton
            variant="gradient"
            size="sm"
            onClick={handleUpload}
            disabled={loading}
          >
            {loading ? 'Subiendo...' : 'Confirmar'}
          </NeonButton>
        </div>
      ) : (
        <NeonButton
          variant="cyan"
          size="sm"
          onClick={() => fileInputRef.current?.click()}
        >
          <Upload className="w-4 h-4 mr-2" />
          Subir Foto
        </NeonButton>
      )}

      <p className="text-xs text-muted-foreground text-center">
        Soporta JPG, PNG, HEIC y otros formatos
      </p>
    </div>
  );
};

export default PhotoUpload;
