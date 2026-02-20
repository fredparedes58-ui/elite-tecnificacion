import React, { useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { EliteCard } from '@/components/ui/EliteCard';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { NeonButton } from '@/components/ui/NeonButton';
import { toast } from 'sonner';
import { Mail, Loader2, X } from 'lucide-react';
import { z } from 'zod';

interface ForgotPasswordModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const emailSchema = z.string().email('Email inválido');

export const ForgotPasswordModal: React.FC<ForgotPasswordModalProps> = ({
  isOpen,
  onClose,
}) => {
  const [email, setEmail] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validar email
    try {
      emailSchema.parse(email);
    } catch (err) {
      if (err instanceof z.ZodError) {
        setError(err.errors[0].message);
        return;
      }
    }

    setIsSubmitting(true);

    try {
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      });

      if (resetError) {
        // No revelamos si el email existe o no por seguridad
        console.error('Error enviando email de recuperación:', resetError);
        toast.error('Error al enviar el email. Verifica que el email sea correcto e intenta de nuevo.');
        setError('Error al enviar el email');
      } else {
        toast.success('Revisa tu correo para restablecer tu contraseña');
        setEmail('');
        onClose();
      }
    } catch (error) {
      console.error('Error inesperado:', error);
      toast.error('Error inesperado. Intenta de nuevo más tarde.');
      setError('Error inesperado');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
      <div className="w-full max-w-md relative">
        <EliteCard className="p-6 md:p-8">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <h2 className="font-orbitron font-bold text-2xl gradient-text">
              ¿Olvidaste tu contraseña?
            </h2>
            <button
              onClick={onClose}
              className="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="Cerrar"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <p className="text-muted-foreground text-sm mb-4">
              Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.
            </p>

            <div className="space-y-2">
              <Label htmlFor="reset-email" className="text-foreground font-rajdhani">
                Email
              </Label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <Input
                  id="reset-email"
                  type="email"
                  value={email}
                  onChange={(e) => {
                    setEmail(e.target.value);
                    setError(null);
                  }}
                  placeholder="tu@email.com"
                  className="pl-10 bg-input border-border focus:border-neon-cyan"
                  disabled={isSubmitting}
                  autoFocus
                />
              </div>
              {error && (
                <p className="text-destructive text-sm">{error}</p>
              )}
            </div>

            <div className="flex gap-3 mt-6">
              <NeonButton
                type="button"
                variant="outline"
                onClick={onClose}
                disabled={isSubmitting}
                className="flex-1"
              >
                Cancelar
              </NeonButton>
              <NeonButton
                type="submit"
                variant="cyan"
                disabled={isSubmitting || !email}
                className="flex-1"
              >
                {isSubmitting ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    Enviando...
                  </>
                ) : (
                  'Enviar enlace'
                )}
              </NeonButton>
            </div>
          </form>
        </EliteCard>
      </div>
    </div>
  );
};
