import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Sparkles, MapPin, X, Heart, MessageCircle } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface DiscoveryProps {
  onMatch: () => void;
  onViewProfile: () => void;
  onAllChats: () => void;
}

const mockProfiles = [
  {
    name: 'Emma',
    age: 27,
    city: 'San Francisco',
    interests: ['Art', 'Travel', 'Music'],
    insight: 'Values emotional depth and authentic conversation',
    syncScore: 87,
  },
  {
    name: 'Sofia',
    age: 25,
    city: 'New York',
    interests: ['Photography', 'Nature', 'Food'],
    insight: 'Prefers gradual connection with thoughtful communication',
    syncScore: 92,
  },
];

export const Discovery: React.FC<DiscoveryProps> = ({ onMatch, onViewProfile, onAllChats }) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [direction, setDirection] = useState<'left' | 'right' | null>(null);

  const currentProfile = mockProfiles[currentIndex];

  const handleAction = (action: 'pass' | 'connect') => {
    setDirection(action === 'pass' ? 'left' : 'right');
    
    setTimeout(() => {
      if (action === 'connect') {
        onMatch();
      } else {
        setDirection(null);
        setCurrentIndex((prev) => (prev + 1) % mockProfiles.length);
      }
    }, 300);
  };

  if (!currentProfile) return null;

  return (
    <div className="h-full flex flex-col text-white">
      {/* Header */}
      <div className="px-6 pt-12 pb-4">
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-light">Discovery</h1>
          <button 
            onClick={onAllChats}
            className="p-2 rounded-full bg-white/5 backdrop-blur-xl border border-white/10"
          >
            <MessageCircle className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Profile card */}
      <div className="flex-1 px-6 pb-8 flex items-center">
        <motion.div
          key={currentIndex}
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ 
            scale: 1, 
            opacity: 1,
            x: direction === 'left' ? -400 : direction === 'right' ? 400 : 0,
            rotate: direction === 'left' ? -20 : direction === 'right' ? 20 : 0,
          }}
          transition={{ duration: 0.3 }}
          className="w-full aspect-[3/4] relative rounded-[32px] overflow-hidden"
        >
          {/* Background gradient as image placeholder */}
          <div className="absolute inset-0 bg-gradient-to-br from-[#ffb3d9]/25 via-[#d8a8dc]/25 to-[#7db9e8]/25">
            <ImageWithFallback
              src={`https://images.unsplash.com/photo-${currentIndex === 0 ? '1494790108377-be9c29b29330' : '1534528741775-53994a69daeb'}?w=500&h=700&fit=crop`}
              alt={currentProfile.name}
              className="w-full h-full object-cover opacity-90"
            />
          </div>

          {/* AI Sync indicator */}
          <div className="absolute top-6 left-6 flex items-center gap-2 px-4 py-2 rounded-full bg-black/40 backdrop-blur-xl border border-white/10">
            <Sparkles className="w-4 h-4 text-[#7db9e8]" />
            <span className="text-white text-sm font-light">{currentProfile.syncScore}% sync</span>
          </div>

          {/* Safety aura indicator */}
          <div className="absolute top-6 right-6 w-10 h-10 rounded-full bg-gradient-to-br from-[#a2e8cb]/20 to-[#7db9e8]/20 backdrop-blur-xl border border-[#a2e8cb]/30 flex items-center justify-center">
            <div className="w-2 h-2 rounded-full bg-[#a2e8cb]" />
          </div>

          {/* Content overlay */}
          <div className="absolute inset-x-0 bottom-0 p-6 bg-gradient-to-t from-black/90 via-black/50 to-transparent">
            {/* Name and age */}
            <h2 className="text-3xl font-light mb-2">
              {currentProfile.name}, {currentProfile.age}
            </h2>

            {/* Location */}
            <div className="flex items-center gap-2 mb-4 text-white/70">
              <MapPin className="w-4 h-4" />
              <span className="text-sm">{currentProfile.city}</span>
            </div>

            {/* AI insight */}
            <div className="p-4 rounded-2xl bg-white/10 backdrop-blur-xl border border-white/20 mb-4">
              <div className="flex items-start gap-2">
                <Sparkles className="w-4 h-4 text-[#00bcd4] mt-0.5 flex-shrink-0" />
                <p className="text-white/90 text-sm leading-relaxed">
                  {currentProfile.insight}
                </p>
              </div>
            </div>

            {/* Interests */}
            <div className="flex flex-wrap gap-2">
              {currentProfile.interests.map((interest) => (
                <span
                  key={interest}
                  className="px-3 py-1.5 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 text-xs text-white"
                >
                  {interest}
                </span>
              ))}
            </div>
          </div>
        </motion.div>
      </div>

      {/* Action buttons */}
      <div className="px-6 pb-10">
        <div className="flex items-center justify-center gap-6">
          {/* Pass */}
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => handleAction('pass')}
            className="w-16 h-16 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 flex items-center justify-center hover:bg-white/15 transition-colors"
          >
            <X className="w-7 h-7 text-white/70" />
          </motion.button>

          {/* Connect */}
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => handleAction('connect')}
            className="relative group"
          >
            <div className="absolute inset-0 bg-gradient-to-r from-[#ffb3d9] via-[#d8a8dc] to-[#7db9e8] rounded-full blur-xl opacity-50 group-hover:opacity-70 transition-opacity" />
            <div className="relative w-20 h-20 rounded-full bg-gradient-to-r from-[#ffb3d9] via-[#d8a8dc] to-[#7db9e8] flex items-center justify-center">
              <Heart className="w-9 h-9 text-white" fill="white" />
            </div>
          </motion.button>
        </div>
      </div>
    </div>
  );
};