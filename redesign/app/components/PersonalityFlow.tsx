import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronLeft, Sparkles } from 'lucide-react';
import type { UserData } from '../App';

interface PersonalityFlowProps {
  onComplete: () => void;
  userData: UserData;
  updateUserData: (data: Partial<UserData>) => void;
}

const connectionTypes = [
  { value: 'gradual', label: 'Gradual connection', description: 'Taking time to build trust' },
  { value: 'emotional', label: 'Emotional connection', description: 'Deep conversations matter' },
  { value: 'open', label: 'Open exploration', description: 'Curious about possibilities' },
  { value: 'aligned', label: 'Clear alignment', description: 'Seeking shared values' },
];

const communicationTraits = [
  'Calm', 'Observant', 'Open', 'Logical', 'Emotional', 'Active'
];

const socialEnvironments = [
  'One-on-one', 'Small group', 'Planned meetings', 'Spontaneous interaction'
];

export const PersonalityFlow: React.FC<PersonalityFlowProps> = ({ 
  onComplete, 
  userData,
  updateUserData 
}) => {
  const [step, setStep] = useState(1);
  const [connectionType, setConnectionType] = useState(userData.connectionType || '');
  const [communication, setCommunication] = useState<string[]>(userData.communicationTraits || []);
  const [social, setSocial] = useState<string[]>(userData.socialPreferences || []);

  const handleNext = () => {
    if (step === 1 && connectionType) {
      updateUserData({ connectionType });
      setStep(2);
    } else if (step === 2 && communication.length >= 2) {
      updateUserData({ communicationTraits: communication });
      setStep(3);
    } else if (step === 3 && social.length >= 2) {
      updateUserData({ socialPreferences: social });
      setStep(4);
    } else if (step === 4) {
      onComplete();
    }
  };

  const handleBack = () => {
    if (step > 1) setStep(step - 1);
  };

  const toggleTrait = (trait: string, list: string[], setter: (val: string[]) => void, max: number) => {
    if (list.includes(trait)) {
      setter(list.filter(t => t !== trait));
    } else if (list.length < max) {
      setter([...list, trait]);
    }
  };

  const isStepValid = () => {
    switch (step) {
      case 1: return connectionType !== '';
      case 2: return communication.length >= 2 && communication.length <= 3;
      case 3: return social.length >= 2 && social.length <= 3;
      case 4: return true;
      default: return false;
    }
  };

  const getPersonalityInsight = () => {
    const connectionLabel = connectionTypes.find(c => c.value === connectionType)?.label || '';
    const commTraits = communication.slice(0, 2).join(' and ').toLowerCase();
    return `Prefers ${connectionLabel.toLowerCase()} with ${commTraits} communication`;
  };

  return (
    <div className="h-full flex flex-col px-6 pt-16 pb-8 text-white">
      {/* Header */}
      <div className="mb-8">
        <button 
          onClick={handleBack}
          className="mb-6 text-white/60 hover:text-white transition-colors"
        >
          <ChevronLeft className="w-6 h-6" />
        </button>

        {/* Progress indicator */}
        <div className="flex gap-1 mb-8">
          {[1, 2, 3, 4].map((i) => (
            <motion.div
              key={i}
              className={`h-1 flex-1 rounded-full ${
                i <= step 
                  ? 'bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1]' 
                  : 'bg-white/10'
              }`}
              initial={{ scaleX: 0 }}
              animate={{ scaleX: i <= step ? 1 : 0.3 }}
              transition={{ duration: 0.3 }}
            />
          ))}
        </div>

        <div className="flex items-center gap-2 mb-4">
          <Sparkles className="w-4 h-4 text-[#00bcd4]" />
          <span className="text-xs text-[#00bcd4]/80">Building your personality insight</span>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <AnimatePresence mode="wait">
          {step === 1 && (
            <motion.div
              key="connection"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h2 className="text-2xl font-light">What kind of connection are you looking for?</h2>
              
              <div className="space-y-3">
                {connectionTypes.map((type) => (
                  <button
                    key={type.value}
                    onClick={() => setConnectionType(type.value)}
                    className={`w-full p-5 rounded-3xl backdrop-blur-xl border transition-all text-left ${
                      connectionType === type.value
                        ? 'bg-gradient-to-br from-[#ff1493]/20 via-[#c154c1]/20 to-[#4169e1]/20 border-[#4169e1]/50'
                        : 'bg-white/5 border-white/10 hover:border-white/20'
                    }`}
                  >
                    <div className="text-white font-light mb-1">{type.label}</div>
                    <div className="text-white/50 text-sm">{type.description}</div>
                  </button>
                ))}
              </div>
            </motion.div>
          )}

          {step === 2 && (
            <motion.div
              key="communication"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h2 className="text-2xl font-light">How do you usually communicate?</h2>
              <p className="text-white/60 text-sm">Select 2-3 traits that describe you</p>
              
              <div className="grid grid-cols-2 gap-3">
                {communicationTraits.map((trait) => (
                  <button
                    key={trait}
                    onClick={() => toggleTrait(trait, communication, setCommunication, 3)}
                    className={`p-4 rounded-2xl backdrop-blur-xl border transition-all ${
                      communication.includes(trait)
                        ? 'bg-gradient-to-br from-[#ff1493]/20 via-[#c154c1]/20 to-[#4169e1]/20 border-[#4169e1]/50'
                        : 'bg-white/5 border-white/10 hover:border-white/20'
                    }`}
                  >
                    <span className="text-white">{trait}</span>
                  </button>
                ))}
              </div>
            </motion.div>
          )}

          {step === 3 && (
            <motion.div
              key="social"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h2 className="text-2xl font-light">What social environments feel most comfortable?</h2>
              <p className="text-white/60 text-sm">Select 2-3 preferences</p>
              
              <div className="space-y-3">
                {socialEnvironments.map((env) => (
                  <button
                    key={env}
                    onClick={() => toggleTrait(env, social, setSocial, 3)}
                    className={`w-full p-4 rounded-2xl backdrop-blur-xl border transition-all ${
                      social.includes(env)
                        ? 'bg-gradient-to-br from-[#ff1493]/20 via-[#c154c1]/20 to-[#4169e1]/20 border-[#4169e1]/50'
                        : 'bg-white/5 border-white/10 hover:border-white/20'
                    }`}
                  >
                    <span className="text-white">{env}</span>
                  </button>
                ))}
              </div>
            </motion.div>
          )}

          {step === 4 && (
            <motion.div
              key="result"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="space-y-8"
            >
              <div className="text-center">
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: 0.2, type: 'spring' }}
                  className="w-20 h-20 mx-auto mb-6 rounded-full bg-gradient-to-br from-[#ff1493] via-[#c154c1] to-[#4169e1] flex items-center justify-center"
                >
                  <Sparkles className="w-10 h-10 text-white" />
                </motion.div>

                <h2 className="text-2xl font-light mb-4">Your personality insight</h2>
              </div>

              <div className="p-6 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10">
                <p className="text-white/80 leading-relaxed text-center">
                  {getPersonalityInsight()}
                </p>
              </div>

              <div className="space-y-3">
                <div className="p-4 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10">
                  <div className="text-white/50 text-xs mb-1">Communication style</div>
                  <div className="text-white">{communication.join(', ')}</div>
                </div>

                <div className="p-4 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10">
                  <div className="text-white/50 text-xs mb-1">Social comfort</div>
                  <div className="text-white">{social.join(', ')}</div>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Continue button */}
      <motion.button
        onClick={handleNext}
        disabled={!isStepValid()}
        className={`relative w-full mt-8 group ${!isStepValid() ? 'opacity-40' : ''}`}
        whileTap={isStepValid() ? { scale: 0.98 } : {}}
      >
        <div className="absolute inset-0 bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1] rounded-full blur-lg opacity-60 group-hover:opacity-80 transition-opacity" />
        <div className="relative px-8 py-4 bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1] rounded-full text-white">
          {step === 4 ? 'Start exploring' : 'Continue'}
        </div>
      </motion.button>
    </div>
  );
};
