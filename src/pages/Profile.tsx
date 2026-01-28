import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import Layout from '@/components/layout/Layout';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { 
  User, 
  Mail, 
  Phone, 
  Calendar, 
  Save, 
  Lock, 
  Loader2,
  Shield,
  Eye,
  EyeOff
} from 'lucide-react';

const Profile: React.FC = () => {
  const { user, profile, isLoading, refreshProfile } = useAuth();
  const { toast } = useToast();
  
  const [fullName, setFullName] = useState(profile?.full_name || '');
  const [phone, setPhone] = useState(profile?.phone || '');
  const [saving, setSaving] = useState(false);
  
  const [showPasswordForm, setShowPasswordForm] = useState(false);
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [changingPassword, setChangingPassword] = useState(false);

  // Update state when profile loads
  React.useEffect(() => {
    if (profile) {
      setFullName(profile.full_name || '');
      setPhone(profile.phone || '');
    }
  }, [profile]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-neon-cyan/30 border-t-neon-cyan rounded-full animate-spin" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/auth" replace />;
  }

  const handleSaveProfile = async () => {
    if (!user) return;
    
    setSaving(true);
    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          full_name: fullName.trim() || null,
          phone: phone.trim() || null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', user.id);

      if (error) throw error;

      await refreshProfile();
      toast({
        title: '✅ Perfil actualizado',
        description: 'Tus datos han sido guardados correctamente',
      });
    } catch (error) {
      console.error('Error updating profile:', error);
      toast({
        title: 'Error',
        description: 'No se pudo actualizar el perfil',
        variant: 'destructive',
      });
    } finally {
      setSaving(false);
    }
  };

  const handleChangePassword = async () => {
    if (newPassword !== confirmPassword) {
      toast({
        title: 'Error',
        description: 'Las contraseñas no coinciden',
        variant: 'destructive',
      });
      return;
    }

    if (newPassword.length < 6) {
      toast({
        title: 'Error',
        description: 'La contraseña debe tener al menos 6 caracteres',
        variant: 'destructive',
      });
      return;
    }

    setChangingPassword(true);
    try {
      const { error } = await supabase.auth.updateUser({
        password: newPassword,
      });

      if (error) throw error;

      toast({
        title: '✅ Contraseña actualizada',
        description: 'Tu contraseña ha sido cambiada correctamente',
      });
      
      setShowPasswordForm(false);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (error: any) {
      console.error('Error changing password:', error);
      toast({
        title: 'Error',
        description: error.message || 'No se pudo cambiar la contraseña',
        variant: 'destructive',
      });
    } finally {
      setChangingPassword(false);
    }
  };

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8 max-w-2xl">
        {/* Header */}
        <div className="mb-8">
          <h1 className="font-orbitron font-bold text-3xl md:text-4xl gradient-text mb-2">
            Mi Perfil
          </h1>
          <p className="text-muted-foreground font-rajdhani">
            Gestiona tu información personal
          </p>
        </div>

        {/* Profile Card */}
        <EliteCard className="p-6 mb-6">
          <div className="flex items-center gap-4 mb-6">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 border border-neon-cyan/30 flex items-center justify-center">
              <User className="w-8 h-8 text-neon-cyan" />
            </div>
            <div>
              <h2 className="font-orbitron font-bold text-xl">
                {profile?.full_name || 'Usuario'}
              </h2>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Mail className="w-4 h-4" />
                <span>{profile?.email}</span>
              </div>
            </div>
          </div>

          <div className="space-y-4">
            {/* Full Name */}
            <div>
              <Label htmlFor="fullName" className="flex items-center gap-2 mb-2">
                <User className="w-4 h-4 text-neon-cyan" />
                Nombre Completo
              </Label>
              <Input
                id="fullName"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder="Tu nombre completo"
                className="bg-muted/50 border-neon-cyan/30"
              />
            </div>

            {/* Email (readonly) */}
            <div>
              <Label className="flex items-center gap-2 mb-2">
                <Mail className="w-4 h-4 text-neon-purple" />
                Email
              </Label>
              <Input
                value={profile?.email || ''}
                disabled
                className="bg-muted/30 border-muted cursor-not-allowed"
              />
              <p className="text-xs text-muted-foreground mt-1">
                El email no puede ser modificado
              </p>
            </div>

            {/* Phone */}
            <div>
              <Label htmlFor="phone" className="flex items-center gap-2 mb-2">
                <Phone className="w-4 h-4 text-neon-cyan" />
                Teléfono
              </Label>
              <Input
                id="phone"
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+34 600 000 000"
                className="bg-muted/50 border-neon-cyan/30"
              />
            </div>

            {/* Registration Date */}
            <div>
              <Label className="flex items-center gap-2 mb-2">
                <Calendar className="w-4 h-4 text-neon-purple" />
                Fecha de Registro
              </Label>
              <Input
                value={profile?.created_at ? format(new Date(profile.created_at), "d 'de' MMMM, yyyy", { locale: es }) : '-'}
                disabled
                className="bg-muted/30 border-muted cursor-not-allowed"
              />
            </div>

            <NeonButton
              variant="gradient"
              onClick={handleSaveProfile}
              disabled={saving}
              className="w-full mt-4"
            >
              {saving ? (
                <Loader2 className="w-4 h-4 animate-spin mr-2" />
              ) : (
                <Save className="w-4 h-4 mr-2" />
              )}
              Guardar Cambios
            </NeonButton>
          </div>
        </EliteCard>

        {/* Password Section */}
        <EliteCard className="p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-neon-purple/10">
                <Lock className="w-5 h-5 text-neon-purple" />
              </div>
              <div>
                <h3 className="font-orbitron font-semibold">Seguridad</h3>
                <p className="text-sm text-muted-foreground">Cambiar contraseña</p>
              </div>
            </div>
            <NeonButton
              variant="outline"
              size="sm"
              onClick={() => setShowPasswordForm(!showPasswordForm)}
            >
              <Shield className="w-4 h-4 mr-2" />
              {showPasswordForm ? 'Cancelar' : 'Cambiar'}
            </NeonButton>
          </div>

          {showPasswordForm && (
            <div className="space-y-4 pt-4 border-t border-neon-purple/20">
              {/* New Password */}
              <div>
                <Label htmlFor="newPassword" className="mb-2 block">Nueva Contraseña</Label>
                <div className="relative">
                  <Input
                    id="newPassword"
                    type={showPassword ? 'text' : 'password'}
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    placeholder="Mínimo 6 caracteres"
                    className="bg-muted/50 border-neon-purple/30 pr-10"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Confirm Password */}
              <div>
                <Label htmlFor="confirmPassword" className="mb-2 block">Confirmar Contraseña</Label>
                <Input
                  id="confirmPassword"
                  type={showPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Repite la contraseña"
                  className="bg-muted/50 border-neon-purple/30"
                />
              </div>

              <NeonButton
                variant="purple"
                onClick={handleChangePassword}
                disabled={changingPassword || !newPassword || !confirmPassword}
                className="w-full"
              >
                {changingPassword ? (
                  <Loader2 className="w-4 h-4 animate-spin mr-2" />
                ) : (
                  <Lock className="w-4 h-4 mr-2" />
                )}
                Actualizar Contraseña
              </NeonButton>
            </div>
          )}
        </EliteCard>
      </div>
    </Layout>
  );
};

export default Profile;
