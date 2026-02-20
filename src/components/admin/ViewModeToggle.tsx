import React from 'react';
import { useViewMode } from '@/contexts/ViewModeContext';
import { NeonButton } from '@/components/ui/NeonButton';
import { Shield, Users, Eye } from 'lucide-react';
import { cn } from '@/lib/utils';

const ViewModeToggle: React.FC = () => {
  const { viewMode, setViewMode } = useViewMode();

  return (
    <div className="flex items-center gap-2 p-1 rounded-lg bg-background/50 border border-neon-cyan/20">
      <NeonButton
        variant={viewMode === 'admin' ? 'cyan' : 'outline'}
        size="sm"
        onClick={() => setViewMode('admin')}
        className={cn(
          'transition-all duration-300',
          viewMode === 'admin' && 'shadow-[0_0_15px_rgba(0,240,255,0.3)]'
        )}
      >
        <Shield className="w-4 h-4 mr-1" />
        Admin Pedro
      </NeonButton>
      <NeonButton
        variant={viewMode === 'parent' ? 'purple' : 'outline'}
        size="sm"
        onClick={() => setViewMode('parent')}
        className={cn(
          'transition-all duration-300',
          viewMode === 'parent' && 'shadow-[0_0_15px_rgba(168,85,247,0.3)]'
        )}
      >
        <Users className="w-4 h-4 mr-1" />
        Vista Padre
      </NeonButton>
      <div className="flex items-center gap-1 px-2 text-xs text-muted-foreground">
        <Eye className="w-3 h-3" />
        {viewMode === 'admin' ? 'Modo Administrador' : 'Simulando vista de padre'}
      </div>
    </div>
  );
};

export default ViewModeToggle;
