import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { NeonButton } from '@/components/ui/NeonButton';
import { EliteCard } from '@/components/ui/EliteCard';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import SimpleRadarChart from '@/components/players/SimpleRadarChart';
import { 
  User, 
  MapPin, 
  Zap, 
  Check, 
  ChevronRight, 
  ChevronLeft,
  Trophy,
  Footprints
} from 'lucide-react';
import { cn } from '@/lib/utils';

const PLAYER_CATEGORIES = ['U8', 'U10', 'U12', 'U14', 'U16', 'U18'] as const;
const PLAYER_LEVELS = [
  { value: 'beginner', label: 'Principiante', stats: 30 },
  { value: 'intermediate', label: 'Intermedio', stats: 50 },
  { value: 'advanced', label: 'Avanzado', stats: 70 },
  { value: 'elite', label: 'Élite', stats: 85 },
] as const;

const POSITIONS = [
  'Portero',
  'Defensa Central',
  'Lateral Derecho',
  'Lateral Izquierdo',
  'Mediocampista Defensivo',
  'Mediocampista Central',
  'Mediocampista Ofensivo',
  'Extremo Derecho',
  'Extremo Izquierdo',
  'Delantero Centro',
];

interface PlayerFormData {
  name: string;
  birth_date: string;
  category: typeof PLAYER_CATEGORIES[number];
  level: typeof PLAYER_LEVELS[number]['value'];
  position: string;
  current_club: string;
  dominant_leg: 'right' | 'left' | 'both';
}

interface PlayerOnboardingWizardProps {
  onSubmit: (data: PlayerFormData) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

const steps = [
  { id: 1, title: 'Datos Básicos', icon: User },
  { id: 2, title: 'Nivel', icon: Zap },
  { id: 3, title: 'Confirmación', icon: Check },
];

const PlayerOnboardingWizard: React.FC<PlayerOnboardingWizardProps> = ({
  onSubmit,
  onCancel,
  loading,
}) => {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState<PlayerFormData>({
    name: '',
    birth_date: '',
    category: 'U10',
    level: 'beginner',
    position: '',
    current_club: '',
    dominant_leg: 'right',
  });

  const updateFormData = (field: keyof PlayerFormData, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const selectedLevel = PLAYER_LEVELS.find((l) => l.value === formData.level);
  const statsValue = selectedLevel?.stats || 50;

  const radarData = [
    { stat: 'PAC', value: statsValue, fullMark: 100 },
    { stat: 'SHO', value: statsValue, fullMark: 100 },
    { stat: 'PAS', value: statsValue, fullMark: 100 },
    { stat: 'DRI', value: statsValue, fullMark: 100 },
    { stat: 'DEF', value: statsValue, fullMark: 100 },
    { stat: 'PHY', value: statsValue, fullMark: 100 },
  ];

  const canProceed = () => {
    if (currentStep === 1) {
      return formData.name.length >= 2 && formData.category;
    }
    if (currentStep === 2) {
      return formData.level;
    }
    return true;
  };

  const handleNext = () => {
    if (currentStep < 3 && canProceed()) {
      setCurrentStep((prev) => prev + 1);
    }
  };

  const handleBack = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => prev - 1);
    }
  };

  const handleSubmit = async () => {
    await onSubmit(formData);
  };

  const slideVariants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 300 : -300,
      opacity: 0,
    }),
    center: {
      x: 0,
      opacity: 1,
    },
    exit: (direction: number) => ({
      x: direction < 0 ? 300 : -300,
      opacity: 0,
    }),
  };

  return (
    <div className="space-y-6">
      {/* Step Indicator */}
      <div className="flex items-center justify-center gap-2">
        {steps.map((step, index) => (
          <React.Fragment key={step.id}>
            <div
              className={cn(
                'flex items-center gap-2 px-4 py-2 rounded-full transition-all duration-300',
                currentStep === step.id
                  ? 'bg-neon-cyan/20 border border-neon-cyan/50 text-neon-cyan'
                  : currentStep > step.id
                  ? 'bg-green-500/20 border border-green-500/50 text-green-400'
                  : 'bg-muted/30 border border-border text-muted-foreground'
              )}
            >
              <step.icon className="w-4 h-4" />
              <span className="text-sm font-rajdhani font-medium hidden sm:inline">
                {step.title}
              </span>
            </div>
            {index < steps.length - 1 && (
              <div
                className={cn(
                  'w-8 h-0.5 transition-colors',
                  currentStep > step.id ? 'bg-green-500' : 'bg-border'
                )}
              />
            )}
          </React.Fragment>
        ))}
      </div>

      {/* Step Content */}
      <div className="min-h-[400px] relative overflow-hidden">
        <AnimatePresence mode="wait" custom={currentStep}>
          {currentStep === 1 && (
            <motion.div
              key="step1"
              custom={1}
              variants={slideVariants}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ duration: 0.3, ease: 'easeInOut' }}
              className="space-y-4"
            >
              <h3 className="text-xl font-orbitron text-neon-cyan text-center mb-6">
                Datos del Jugador
              </h3>

              <div className="space-y-4">
                <div>
                  <Label className="font-rajdhani">Nombre Completo *</Label>
                  <Input
                    value={formData.name}
                    onChange={(e) => updateFormData('name', e.target.value)}
                    placeholder="Nombre del jugador"
                    className="bg-muted/50 border-neon-cyan/30 mt-1"
                  />
                </div>

                <div>
                  <Label className="font-rajdhani">Fecha de Nacimiento</Label>
                  <Input
                    type="date"
                    value={formData.birth_date}
                    onChange={(e) => updateFormData('birth_date', e.target.value)}
                    className="bg-muted/50 border-neon-cyan/30 mt-1"
                  />
                </div>

                <div>
                  <Label className="font-rajdhani">Club Actual</Label>
                  <Input
                    value={formData.current_club}
                    onChange={(e) => updateFormData('current_club', e.target.value)}
                    placeholder="Ej: FC Barcelona"
                    className="bg-muted/50 border-neon-cyan/30 mt-1"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label className="font-rajdhani">Categoría *</Label>
                    <Select
                      value={formData.category}
                      onValueChange={(v) => updateFormData('category', v)}
                    >
                      <SelectTrigger className="bg-muted/50 border-neon-cyan/30 mt-1">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {PLAYER_CATEGORIES.map((cat) => (
                          <SelectItem key={cat} value={cat}>
                            {cat}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <Label className="font-rajdhani">Pierna Hábil</Label>
                    <Select
                      value={formData.dominant_leg}
                      onValueChange={(v) => updateFormData('dominant_leg', v)}
                    >
                      <SelectTrigger className="bg-muted/50 border-neon-cyan/30 mt-1">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="right">Derecha</SelectItem>
                        <SelectItem value="left">Izquierda</SelectItem>
                        <SelectItem value="both">Ambidiestro</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div>
                  <Label className="font-rajdhani">Posición</Label>
                  <Select
                    value={formData.position}
                    onValueChange={(v) => updateFormData('position', v)}
                  >
                    <SelectTrigger className="bg-muted/50 border-neon-cyan/30 mt-1">
                      <SelectValue placeholder="Selecciona posición" />
                    </SelectTrigger>
                    <SelectContent>
                      {POSITIONS.map((pos) => (
                        <SelectItem key={pos} value={pos}>
                          {pos}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </motion.div>
          )}

          {currentStep === 2 && (
            <motion.div
              key="step2"
              custom={1}
              variants={slideVariants}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ duration: 0.3, ease: 'easeInOut' }}
              className="space-y-6"
            >
              <h3 className="text-xl font-orbitron text-neon-cyan text-center mb-6">
                Nivel del Jugador
              </h3>

              <div className="grid grid-cols-2 gap-3">
                {PLAYER_LEVELS.map((level) => (
                  <button
                    key={level.value}
                    onClick={() => updateFormData('level', level.value)}
                    className={cn(
                      'p-4 rounded-xl border-2 transition-all duration-300',
                      formData.level === level.value
                        ? 'border-neon-cyan bg-neon-cyan/10 scale-105'
                        : 'border-border bg-muted/30 hover:border-neon-cyan/50'
                    )}
                  >
                    <div className="flex flex-col items-center gap-2">
                      <Zap
                        className={cn(
                          'w-6 h-6',
                          formData.level === level.value
                            ? 'text-neon-cyan'
                            : 'text-muted-foreground'
                        )}
                      />
                      <span className="font-rajdhani font-bold">{level.label}</span>
                      <Badge
                        variant="outline"
                        className={cn(
                          formData.level === level.value
                            ? 'border-neon-cyan/50 text-neon-cyan'
                            : 'border-border'
                        )}
                      >
                        Stats: {level.stats}
                      </Badge>
                    </div>
                  </button>
                ))}
              </div>

              <div className="bg-muted/30 rounded-xl p-4 border border-border">
                <p className="text-sm text-muted-foreground text-center">
                  Los stats iniciales (PAC, SHO, PAS, DRI, DEF, PHY) se
                  establecerán en <strong className="text-neon-cyan">{statsValue}</strong>{' '}
                  según el nivel seleccionado.
                </p>
              </div>
            </motion.div>
          )}

          {currentStep === 3 && (
            <motion.div
              key="step3"
              custom={1}
              variants={slideVariants}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ duration: 0.3, ease: 'easeInOut' }}
              className="space-y-6"
            >
              <h3 className="text-xl font-orbitron text-neon-cyan text-center mb-6">
                Confirmación
              </h3>

              {/* Elite Card Preview */}
              <div className="flex justify-center">
                <EliteCard className="w-72 relative overflow-hidden">
                  {/* Card Header */}
                  <div className="absolute top-0 left-0 right-0 h-20 bg-gradient-to-b from-neon-cyan/20 to-transparent" />
                  
                  <div className="relative z-10">
                    {/* Rating Badge */}
                    <div className="flex justify-between items-start mb-4">
                      <div className="flex flex-col items-center">
                        <span className="text-4xl font-orbitron font-bold text-neon-cyan">
                          {statsValue}
                        </span>
                        <Badge className="mt-1 bg-neon-cyan/20 text-neon-cyan border-neon-cyan/30">
                          {formData.category}
                        </Badge>
                      </div>
                      <Trophy className="w-8 h-8 text-neon-gold" />
                    </div>

                    {/* Player Name */}
                    <h4 className="text-xl font-orbitron font-bold text-foreground truncate mb-2">
                      {formData.name || 'NOMBRE'}
                    </h4>

                    {/* Position & Club */}
                    <div className="flex items-center gap-2 text-sm text-muted-foreground mb-4">
                      <MapPin className="w-4 h-4 text-neon-cyan" />
                      <span>{formData.position || 'Sin posición'}</span>
                      {formData.current_club && (
                        <>
                          <span>•</span>
                          <span>{formData.current_club}</span>
                        </>
                      )}
                    </div>

                    {/* Radar Chart */}
                    <div className="h-40 -mx-4">
                      <SimpleRadarChart data={radarData} />
                    </div>

                    {/* Footer Stats */}
                    <div className="flex justify-between text-xs text-muted-foreground mt-2 pt-2 border-t border-neon-cyan/20">
                      <div className="flex items-center gap-1">
                        <Footprints className="w-3 h-3" />
                        <span>
                          {formData.dominant_leg === 'right'
                            ? 'Derecha'
                            : formData.dominant_leg === 'left'
                            ? 'Izquierda'
                            : 'Ambidiestro'}
                        </span>
                      </div>
                      <div>
                        <span className="text-neon-cyan">
                          {selectedLevel?.label || 'Principiante'}
                        </span>
                      </div>
                    </div>
                  </div>
                </EliteCard>
              </div>

              <div className="text-center text-sm text-muted-foreground">
                <p>¿Todo listo? Haz clic en <strong>"Fichar Jugador"</strong> para completar el registro.</p>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Navigation Buttons */}
      <div className="flex gap-3">
        {currentStep === 1 ? (
          <NeonButton
            type="button"
            variant="outline"
            onClick={onCancel}
            className="flex-1"
          >
            Cancelar
          </NeonButton>
        ) : (
          <NeonButton
            type="button"
            variant="outline"
            onClick={handleBack}
            className="flex-1"
          >
            <ChevronLeft className="w-4 h-4 mr-2" />
            Anterior
          </NeonButton>
        )}

        {currentStep < 3 ? (
          <NeonButton
            type="button"
            variant="gradient"
            onClick={handleNext}
            className="flex-1"
            disabled={!canProceed()}
          >
            Siguiente
            <ChevronRight className="w-4 h-4 ml-2" />
          </NeonButton>
        ) : (
          <NeonButton
            type="button"
            variant="gradient"
            onClick={handleSubmit}
            className="flex-1"
            disabled={loading}
          >
            {loading ? 'Fichando...' : '⚽ Fichar Jugador'}
          </NeonButton>
        )}
      </div>
    </div>
  );
};

export default PlayerOnboardingWizard;
