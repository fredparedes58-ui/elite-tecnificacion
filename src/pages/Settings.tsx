import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import Layout from '@/components/layout/Layout';
import BackButton from '@/components/layout/BackButton';
import { EliteCard } from '@/components/ui/EliteCard';
import { NeonButton } from '@/components/ui/NeonButton';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { Globe, Phone, Mail, User, Save, Loader2, Settings as SettingsIcon } from 'lucide-react';

const Settings: React.FC = () => {
  const { user, profile, isLoading, isAdmin, refreshProfile } = useAuth();
  const { toast } = useToast();

  const [fullName, setFullName] = useState(profile?.full_name || '');
  const [phone, setPhone] = useState(profile?.phone || '');
  const [language, setLanguage] = useState('es');
  const [saving, setSaving] = useState(false);

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

  if (!user) return <Navigate to="/auth" replace />;
  if (isAdmin) return <Navigate to="/admin/settings" replace />;

  const handleSave = async () => {
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
      toast({ title: '✅ Ajustes guardados', description: 'Tus datos han sido actualizados.' });
    } catch {
      toast({ title: 'Error', description: 'No se pudo guardar.', variant: 'destructive' });
    } finally {
      setSaving(false);
    }
  };

  return (
    <Layout>
      <div className="container mx-auto px-4 py-8 max-w-2xl space-y-6">
        <div>
          <BackButton />
          <h1 className="font-orbitron font-bold text-3xl gradient-text mt-2 mb-1">
            <SettingsIcon className="w-7 h-7 inline-block mr-2 -mt-1" />
            Ajustes
          </h1>
          <p className="text-muted-foreground font-rajdhani">
            Configura tu experiencia en Elite 380
          </p>
        </div>

        {/* Language */}
        <EliteCard className="p-6 space-y-4">
          <h2 className="font-orbitron font-semibold text-lg flex items-center gap-2">
            <Globe className="w-5 h-5 text-neon-cyan" />
            Idioma
          </h2>
          <div>
            <Label htmlFor="language" className="mb-2 block text-sm text-muted-foreground">
              Idioma de la interfaz
            </Label>
            <Select value={language} onValueChange={setLanguage}>
              <SelectTrigger className="bg-muted/50 border-neon-cyan/30">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="es">🇪🇸 Español</SelectItem>
                <SelectItem value="en">🇬🇧 English</SelectItem>
                <SelectItem value="ca">🏳️ Català</SelectItem>
              </SelectContent>
            </Select>
            <p className="text-xs text-muted-foreground mt-2">
              El idioma se aplicará a toda la interfaz (próximamente)
            </p>
          </div>
        </EliteCard>

        {/* Contact Info */}
        <EliteCard className="p-6 space-y-4">
          <h2 className="font-orbitron font-semibold text-lg flex items-center gap-2">
            <User className="w-5 h-5 text-neon-purple" />
            Datos de Contacto
          </h2>

          <div>
            <Label htmlFor="fullName" className="flex items-center gap-2 mb-2">
              <User className="w-4 h-4 text-neon-cyan" />
              Nombre Completo
            </Label>
            <Input
              id="fullName"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="Tu nombre"
              className="bg-muted/50 border-neon-cyan/30"
            />
          </div>

          <div>
            <Label className="flex items-center gap-2 mb-2">
              <Mail className="w-4 h-4 text-neon-purple" />
              Email
            </Label>
            <Input value={profile?.email || ''} disabled className="bg-muted/30 border-muted cursor-not-allowed" />
            <p className="text-xs text-muted-foreground mt-1">El email no puede ser modificado</p>
          </div>

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

          <NeonButton
            variant="gradient"
            onClick={handleSave}
            disabled={saving}
            className="w-full mt-2"
          >
            {saving ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <Save className="w-4 h-4 mr-2" />}
            Guardar Cambios
          </NeonButton>
        </EliteCard>
      </div>
    </Layout>
  );
};

export default Settings;
