import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronLeft, MapPin } from 'lucide-react';
import type { UserData } from '../App';

interface RegistrationFlowProps {
  onComplete: () => void;
  userData: UserData;
  updateUserData: (data: Partial<UserData>) => void;
}

const interests = [
  'Art', 'Music', 'Travel', 'Food', 'Sports', 'Reading', 
  'Photography', 'Gaming', 'Nature', 'Technology', 'Fitness', 'Dancing'
];

export const RegistrationFlow: React.FC<RegistrationFlowProps> = ({ 
  onComplete, 
  userData, 
  updateUserData 
}) => {
  const [step, setStep] = useState(1);
  const [name, setName] = useState(userData.name || '');
  const [age, setAge] = useState(userData.age?.toString() || '');
  const [gender, setGender] = useState(userData.gender || '');
  const [city, setCity] = useState(userData.city || '');
  const [selectedInterests, setSelectedInterests] = useState<string[]>(userData.interests || []);

  const handleNext = () => {
    if (step === 1 && name) {
      updateUserData({ name });
      setStep(2);
    } else if (step === 2 && age) {
      updateUserData({ age: parseInt(age) });
      setStep(3);
    } else if (step === 3 && gender) {
      updateUserData({ gender });
      setStep(4);
    } else if (step === 4 && city) {
      updateUserData({ city });
      setStep(5);
    } else if (step === 5 && selectedInterests.length > 0) {
      updateUserData({ interests: selectedInterests });
      onComplete();
    }
  };

  const handleBack = () => {
    if (step > 1) setStep(step - 1);
  };

  const toggleInterest = (interest: string) => {
    setSelectedInterests(prev => 
      prev.includes(interest) 
        ? prev.filter(i => i !== interest)
        : [...prev, interest]
    );
  };

  const isStepValid = () => {
    switch (step) {
      case 1: return name.length >= 2;
      case 2: return age && parseInt(age) >= 18 && parseInt(age) <= 99;
      case 3: return gender !== '';
      case 4: return city.length >= 2;
      case 5: return selectedInterests.length >= 3;
      default: return false;
    }
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
          {[1, 2, 3, 4, 5].map((i) => (
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
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <AnimatePresence mode="wait">
          {step === 1 && (
            <motion.div
              key="name"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h2 className="text-2xl font-light">What's your name?</h2>
              <p className="text-white/60 text-sm">This is how others will see you</p>
              
              <div className="relative">
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Your name"
                  className="w-full px-6 py-4 bg-white/5 backdrop-blur-xl border border-white/10 rounded-3xl text-white placeholder:text-white/40 focus:outline-none focus:border-[#4169e1]/50 transition-colors"
                  autoFocus
                />
              </div>
            </motion.div>
          )}

          {step === 2 && (
            <motion.div
              key="age"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h2 className="text-2xl font-light">How old are you?</h2>
              <p className="text-white/60 text-sm">Your age helps us find compatible connections</p>
              
              <div className="relative">
                <input
                  type="number"
                  value={age}
                  onChange={(e) => setAge(e.target.value)}
                  placeholder="Your age"
                  className="w-full px-6 py-4 bg-white/5 backdrop-blur-xl border border-white/10 rounded-3xl text-white placeholder:text-white/40 focus:outline-none focus:border-[#4169e1]/50 transition-colors"
                  autoFocus
                />
              </div>
            </motion.div>
          )}

          {step === 3 && (
            <motion.div
              key="gender"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h2 className="text-2xl font-light">Your gender</h2>
              <p className="text-white/60 text-sm">Help us understand you better</p>
              
              <div className="space-y-3">
                {['Woman', 'Man', 'Non-binary', 'Prefer not to say'].map((option) => (
                  <button
                    key={option}
                    onClick={() => setGender(option)}
                    className={`w-full px-6 py-4 rounded-3xl backdrop-blur-xl border transition-all ${
                      gender === option
                        ? 'bg-gradient-to-r from-[#ff1493]/20 via-[#c154c1]/20 to-[#4169e1]/20 border-[#4169e1]/50'
                        : 'bg-white/5 border-white/10 hover:border-white/20'
                    }`}
                  >
                    <span className="text-white">{option}</span>
                  </button>
                ))}
              </div>
            </motion.div>
          )}

          {step === 4 && (
            <motion.div
              key="city"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h2 className="text-2xl font-light">Where are you?</h2>
              <p className="text-white/60 text-sm">Your city serves as an emotional anchor</p>
              
              <div className="relative">
                <MapPin className="absolute left-6 top-1/2 -translate-y-1/2 w-5 h-5 text-[#00bcd4]" />
                <input
                  type="text"
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  placeholder="Your city"
                  className="w-full pl-14 pr-6 py-4 bg-white/5 backdrop-blur-xl border border-white/10 rounded-3xl text-white placeholder:text-white/40 focus:outline-none focus:border-[#4169e1]/50 transition-colors"
                  autoFocus
                />
              </div>
            </motion.div>
          )}

          {step === 5 && (
            <motion.div
              key="interests"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h2 className="text-2xl font-light">Your interests</h2>
              <p className="text-white/60 text-sm">Select at least 3 things you enjoy</p>
              
              <div className="flex flex-wrap gap-3">
                {interests.map((interest) => (
                  <button
                    key={interest}
                    onClick={() => toggleInterest(interest)}
                    className={`px-5 py-3 rounded-full backdrop-blur-xl border transition-all ${
                      selectedInterests.includes(interest)
                        ? 'bg-gradient-to-r from-[#ff1493]/20 via-[#c154c1]/20 to-[#4169e1]/20 border-[#4169e1]/50'
                        : 'bg-white/5 border-white/10 hover:border-white/20'
                    }`}
                  >
                    <span className="text-white text-sm">{interest}</span>
                  </button>
                ))}
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
          Continue
        </div>
      </motion.button>
    </div>
  );
};
