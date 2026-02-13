import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';
import { cn } from '@/lib/utils';

interface BackButtonProps {
  fallback?: string;
  className?: string;
}

const BackButton: React.FC<BackButtonProps> = ({ fallback = '/dashboard', className }) => {
  const navigate = useNavigate();

  const handleBack = () => {
    if (window.history.length > 2) {
      navigate(-1);
    } else {
      navigate(fallback);
    }
  };

  return (
    <button
      onClick={handleBack}
      className={cn(
        'flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors font-rajdhani text-sm group',
        className
      )}
    >
      <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
      <span>Volver</span>
    </button>
  );
};

export default BackButton;
