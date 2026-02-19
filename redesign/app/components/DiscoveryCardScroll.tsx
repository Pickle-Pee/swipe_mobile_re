import React, { useRef } from 'react';
import { motion } from 'motion/react';
import { Sparkles, MapPin, Heart, X } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface DiscoveryCardScrollProps {
  onPass: () => void;
  onConnect: () => void;
}

export const DiscoveryCardScroll: React.FC<DiscoveryCardScrollProps> = ({ onPass, onConnect }) => {
  const scrollRef = useRef<HTMLDivElement>(null);

  const profile = {
    name: 'Emma',
    age: 27,
    city: 'San Francisco',
    photos: [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&h=600&fit=crop',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&h=600&fit=crop',
    ],
    personality: {
      archetype: 'The Enthusiast',
      traits: ['Warm', 'Expressive', 'Curious'],
      insight: 'Values emotional depth and authentic conversation. Loves exploring new ideas through meaningful dialogue.',
    },
    communicationStyle: 'Warm • Direct • Enthusiastic',
    interests: ['Art', 'Travel', 'Music', 'Philosophy', 'Cooking'],
    bio: 'Life is a canvas and I'm painting it with curiosity. Artist by day, stargazer by night. Looking for someone who sees magic in the mundane.',
    syncScore: 87,
  };

  return (
    <div className="h-full flex flex-col text-white">
      {/* Header */}
      <div className="px-6 pt-12 pb-4">
        <h1 className="text-xl font-light">Discovery</h1>
      </div>

      {/* Scrollable card container */}
      <div className="flex-1 px-6 pb-8 overflow-hidden">
        <div
          ref={scrollRef}
          className="h-full overflow-y-auto rounded-[32px] bg-white/5 backdrop-blur-xl border border-white/10"
        >
          {/* AI Sync header */}
          <div className="sticky top-0 z-10 px-6 pt-6 pb-4 bg-gradient-to-b from-[#0a0a14]/95 to-transparent backdrop-blur-xl">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-black/40 backdrop-blur-xl border border-[#7db9e8]/20">
                <Sparkles className="w-4 h-4 text-[#7db9e8]" />
                <span className="text-white text-sm font-light">{profile.syncScore}% sync</span>
              </div>

              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#a2e8cb]/20 to-[#7db9e8]/20 backdrop-blur-xl border border-[#a2e8cb]/30 flex items-center justify-center">
                <div className="w-2 h-2 rounded-full bg-[#a2e8cb]" />
              </div>
            </div>
          </div>

          {/* Photos */}
          <div className="px-6 mb-6 space-y-4">
            {profile.photos.map((photo, index) => (
              <div key={index} className="aspect-[3/4] rounded-2xl overflow-hidden">
                <ImageWithFallback
                  src={photo}
                  alt={`${profile.name} photo ${index + 1}`}
                  className="w-full h-full object-cover"
                />
              </div>
            ))}
          </div>

          {/* Content */}
          <div className="px-6 pb-6 space-y-4">
            {/* Name, age, city */}
            <div>
              <h2 className="text-3xl font-light mb-2">
                {profile.name}, {profile.age}
              </h2>
              <div className="flex items-center gap-2 text-white/60">
                <MapPin className="w-4 h-4" />
                <span>{profile.city}</span>
              </div>
            </div>

            {/* Personality insight */}
            <div className="p-5 rounded-3xl bg-gradient-to-br from-[#7db9e8]/10 to-[#a2d5f2]/10 backdrop-blur-xl border border-[#7db9e8]/20">
              <div className="flex items-start gap-3 mb-3">
                <Sparkles className="w-5 h-5 text-[#7db9e8] mt-0.5 flex-shrink-0" />
                <div>
                  <div className="text-[#7db9e8] text-sm mb-1 font-light">
                    Personality: {profile.personality.archetype}
                  </div>
                  <p className="text-white/80 text-sm leading-relaxed">
                    {profile.personality.insight}
                  </p>
                </div>
              </div>
              
              <div className="flex flex-wrap gap-2">
                {profile.personality.traits.map((trait) => (
                  <span
                    key={trait}
                    className="px-3 py-1.5 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 text-xs text-white"
                  >
                    {trait}
                  </span>
                ))}
              </div>
            </div>

            {/* Communication style */}
            <div className="p-5 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10">
              <h3 className="text-white/90 text-sm mb-2 font-light">Communication Style</h3>
              <p className="text-white/70 text-sm">{profile.communicationStyle}</p>
            </div>

            {/* Bio */}
            <div className="p-5 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10">
              <h3 className="text-white/90 text-sm mb-2 font-light">About</h3>
              <p className="text-white/70 text-sm leading-relaxed">{profile.bio}</p>
            </div>

            {/* Interests */}
            <div className="p-5 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10">
              <h3 className="text-white/90 text-sm mb-3 font-light">Interests</h3>
              <div className="flex flex-wrap gap-2">
                {profile.interests.map((interest) => (
                  <span
                    key={interest}
                    className="px-4 py-2 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 text-sm text-white"
                  >
                    {interest}
                  </span>
                ))}
              </div>
            </div>

            {/* Compatibility hint */}
            <div className="p-5 rounded-3xl bg-gradient-to-br from-[#ffb3d9]/10 to-[#ffc9e3]/10 backdrop-blur-xl border border-[#ffb3d9]/20">
              <div className="flex items-start gap-2">
                <Sparkles className="w-4 h-4 text-[#ffb3d9] mt-0.5 flex-shrink-0" />
                <div>
                  <div className="text-[#ffb3d9] text-xs mb-1 font-light">Compatibility Insight</div>
                  <p className="text-white/80 text-sm">
                    Your communication styles complement each other. Both value authenticity and depth in conversation.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Action buttons */}
      <div className="px-6 pb-10">
        <div className="flex items-center justify-center gap-6">
          {/* Pass */}
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={onPass}
            className="w-16 h-16 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 flex items-center justify-center hover:bg-white/15 transition-colors"
          >
            <X className="w-7 h-7 text-white/70" />
          </motion.button>

          {/* Connect */}
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={onConnect}
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