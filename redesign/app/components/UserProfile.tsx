import React from 'react';
import { motion } from 'motion/react';
import { ChevronLeft, Sparkles, MapPin, Shield, Edit3 } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface UserProfileProps {
  onBack: () => void;
  isOwnProfile?: boolean;
}

export const UserProfile: React.FC<UserProfileProps> = ({ onBack, isOwnProfile = false }) => {
  const profileData = {
    name: 'Sofia',
    age: 25,
    city: 'New York',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=500&fit=crop',
    personality: {
      archetype: 'The Observer',
      traits: ['Calm', 'Observant', 'Open'],
      insight: 'Prefers gradual connection with thoughtful communication. Values depth over breadth in conversations.',
    },
    communicationStyle: 'Thoughtful • Authentic • Considerate',
    interests: ['Photography', 'Nature', 'Food', 'Art', 'Travel'],
    bio: 'Finding beauty in the quiet moments. Street photographer by passion, curious soul by nature. I believe the best connections grow slowly, like a photograph developing.',
    safetyScore: 95,
  };

  return (
    <div className="h-full flex flex-col text-white overflow-y-auto">
      {/* Header */}
      <div className="absolute top-0 left-0 right-0 z-20 px-6 pt-12 pb-4 bg-gradient-to-b from-[#0a0a14] to-transparent">
        <div className="flex items-center justify-between">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          {isOwnProfile && (
            <button className="w-10 h-10 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 flex items-center justify-center">
              <Edit3 className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>

      {/* Profile photo */}
      <div className="relative h-[50vh] flex-shrink-0">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-[#0a0a14]">
          <ImageWithFallback
            src={profileData.avatar}
            alt={profileData.name}
            className="w-full h-full object-cover"
          />
        </div>

        {/* Safety indicator */}
        <div className="absolute top-20 right-6 flex items-center gap-2 px-4 py-2 rounded-full bg-black/40 backdrop-blur-xl border border-[#a2e8cb]/30">
          <Shield className="w-4 h-4 text-[#a2e8cb]" />
          <span className="text-white/90 text-sm font-light">Verified</span>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 px-6 pb-8 -mt-8 relative z-10">
        {/* Name and location */}
        <div className="mb-6">
          <h1 className="text-3xl font-light mb-2">
            {profileData.name}, {profileData.age}
          </h1>
          <div className="flex items-center gap-2 text-white/60">
            <MapPin className="w-4 h-4" />
            <span>{profileData.city}</span>
          </div>
        </div>

        {/* Personality insight block */}
        <div className="mb-6 p-5 rounded-3xl bg-gradient-to-br from-[#7db9e8]/10 to-[#a2d5f2]/10 backdrop-blur-xl border border-[#7db9e8]/20">
          <div className="flex items-start gap-3 mb-3">
            <Sparkles className="w-5 h-5 text-[#7db9e8] mt-0.5 flex-shrink-0" />
            <div>
              <div className="text-[#7db9e8] text-sm mb-1 font-light">
                Personality: {profileData.personality.archetype}
              </div>
              <p className="text-white/80 text-sm leading-relaxed">
                {profileData.personality.insight}
              </p>
            </div>
          </div>
          
          <div className="flex flex-wrap gap-2 mt-4">
            {profileData.personality.traits.map((trait) => (
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
        <div className="mb-6 p-5 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10">
          <h3 className="text-white/90 text-sm mb-2 font-light">Communication Style</h3>
          <p className="text-white/70 text-sm">{profileData.communicationStyle}</p>
        </div>

        {/* Bio */}
        {profileData.bio && (
          <div className="mb-6 p-5 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10">
            <h3 className="text-white/90 text-sm mb-2 font-light">About</h3>
            <p className="text-white/70 text-sm leading-relaxed">{profileData.bio}</p>
          </div>
        )}

        {/* Interests */}
        <div className="mb-6 p-5 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10">
          <h3 className="text-white/90 text-sm mb-3 font-light">Interests</h3>
          <div className="flex flex-wrap gap-2">
            {profileData.interests.map((interest) => (
              <span
                key={interest}
                className="px-4 py-2 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 text-sm text-white"
              >
                {interest}
              </span>
            ))}
          </div>
        </div>

        {/* Safety score */}
        <div className="p-5 rounded-3xl bg-gradient-to-br from-[#a2e8cb]/10 to-[#7db9e8]/10 backdrop-blur-xl border border-[#a2e8cb]/20">
          <div className="flex items-center gap-3">
            <Shield className="w-5 h-5 text-[#a2e8cb]" />
            <div className="flex-1">
              <div className="text-white/90 text-sm mb-1 font-light">Safety Verified</div>
              <div className="text-white/60 text-xs">Profile verified • Active community member</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
