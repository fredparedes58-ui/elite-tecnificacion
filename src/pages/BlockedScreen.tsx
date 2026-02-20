import React from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { NeonButton } from '@/components/ui/NeonButton';
import { EliteCard } from '@/components/ui/EliteCard';
import { ShieldX, Clock, LogOut, Mail } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const BlockedScreen: React.FC = () => {
  const { profile, signOut } = useAuth();
  const navigate = useNavigate();

  const handleSignOut = async () => {
    await signOut();
    navigate('/');
  };

  return (
    <div className="min-h-screen bg-background cyber-grid flex items-center justify-center p-4">
      {/* Animated background */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/3 left-1/4 w-[600px] h-[600px] border border-neon-purple/10 rounded-full animate-pulse" />
        <div className="absolute bottom-1/3 right-1/4 w-[400px] h-[400px] border border-neon-cyan/10 rounded-full animate-pulse delay-500" />
        
        {/* Scan line effect */}
        <div className="absolute inset-0 scan-lines opacity-30" />
      </div>

      <EliteCard className="max-w-md w-full p-8 text-center relative z-10">
        {/* Icon */}
        <div className="relative mx-auto w-24 h-24 mb-6">
          <div className="absolute inset-0 bg-neon-purple/20 rounded-full animate-pulse" />
          <div className="absolute inset-2 bg-background rounded-full flex items-center justify-center border-2 border-neon-purple/50">
            <ShieldX className="w-10 h-10 text-neon-purple" />
          </div>
        </div>

        {/* Title */}
        <h1 className="font-orbitron font-bold text-2xl text-foreground mb-2">
          ACCESO PENDIENTE
        </h1>
        
        {/* Neon line */}
        <div className="w-32 h-[2px] bg-gradient-to-r from-neon-purple via-neon-cyan to-neon-purple mx-auto mb-6" />

        {/* Message */}
        <p className="text-muted-foreground font-rajdhani text-lg mb-6">
          Tu cuenta está pendiente de aprobación por el administrador. 
          Recibirás acceso completo una vez que tu cuenta sea verificada.
        </p>

        {/* User info */}
        <div className="bg-muted/30 rounded-lg p-4 mb-6 border border-border">
          <div className="flex items-center justify-center gap-2 text-muted-foreground">
            <Mail className="w-4 h-4" />
            <span className="font-rajdhani">{profile?.email}</span>
          </div>
        </div>

        {/* Status indicator */}
        <div className="flex items-center justify-center gap-3 mb-8">
          <div className="flex items-center gap-2 px-4 py-2 bg-yellow-500/10 border border-yellow-500/30 rounded-full">
            <Clock className="w-4 h-4 text-yellow-400" />
            <span className="text-yellow-400 font-rajdhani font-medium">Esperando Aprobación</span>
          </div>
        </div>

        {/* Action */}
        <NeonButton
          variant="purple"
          size="lg"
          className="w-full"
          onClick={handleSignOut}
        >
          <LogOut className="w-5 h-5 mr-2" />
          Cerrar Sesión
        </NeonButton>

        {/* Footer note */}
        <p className="mt-6 text-xs text-muted-foreground">
          Si crees que esto es un error, contacta al administrador de Elite 380.
        </p>
      </EliteCard>
    </div>
  );
};

export default BlockedScreen;
