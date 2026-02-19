import React from 'react';
import { motion } from 'motion/react';
import { ChevronLeft, MapPin, Sparkles, Shield } from 'lucide-react';
import type { UserData } from '../App';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface ProfileProps {
  userData: UserData;
  onBack: () => void;
}

export const Profile: React.FC<ProfileProps> = ({ userData, onBack }) => {
  return (
    <div className="h-full overflow-y-auto text-white">
      {/* Header with back button */}
      <div className="absolute top-0 left-0 right-0 z-20 px-6 pt-12 pb-4">
        <button
          onClick={onBack}
          className="w-10 h-10 rounded-full bg-black/40 backdrop-blur-xl border border-white/10 flex items-center justify-center"
        >
          <ChevronLeft className="w-5 h-5" />
        </button>
      </div>

      {/* Profile photo container with liquid shape */}
      <div className="relative h-[50vh] overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-[#ff1493]/30 via-[#c154c1]/30 to-[#4169e1]/30">
          <ImageWithFallback
            src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&h=700&fit=crop"
            alt={userData.name || 'Profile'}
            className="w-full h-full object-cover opacity-90"
          />
        </div>

        {/* Liquid bottom edge */}
        <div className="absolute bottom-0 left-0 right-0 h-8">
          <svg viewBox="0 0 1440 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
            <path
              d="M0 48h1440V24c-120 12-240 24-360 18-120-6-240-24-360-12-120 12-240 30-360 24-120-6-240-24-360-12v0z"
              fill="#0a0a14"
            />
          </svg>
        </div>
      </div>

      {/* Content */}
      <div className="relative px-6 pb-8 -mt-6">
        {/* Name and basic info */}
        <div className="mb-6">
          <h1 className="text-3xl font-light mb-2">
            {userData.name}, {userData.age}
          </h1>
          
          <div className="flex items-center gap-2 text-white/70 mb-4">
            <MapPin className="w-4 h-4" />
            <span>{userData.city}</span>
          </div>

          <div className="flex items-center gap-2">
            <div className="px-3 py-1.5 rounded-full bg-[#00ff88]/10 backdrop-blur-xl border border-[#00ff88]/30 flex items-center gap-2">
              <Shield className="w-3 h-3 text-[#00ff88]" />
              <span className="text-xs text-[#00ff88]">Verified</span>
            </div>
          </div>
        </div>

        {/* Personality insight */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <Sparkles className="w-4 h-4 text-[#00bcd4]" />
            <h3 className="text-sm text-white/60">Personality insight</h3>
          </div>
          
          <div className="p-5 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10">
            <p className="text-white/80 leading-relaxed">
              {userData.connectionType && `Prefers ${userData.connectionType} connection. `}
              {userData.communicationTraits && userData.communicationTraits.length > 0 && 
                `Communicates in a ${userData.communicationTraits.slice(0, 2).join(' and ').toLowerCase()} way.`
              }
            </p>
          </div>
        </div>

        {/* Communication style */}
        {userData.communicationTraits && userData.communicationTraits.length > 0 && (
          <div className="mb-6">
            <h3 className="text-sm text-white/60 mb-3">Communication style</h3>
            <div className="flex flex-wrap gap-2">
              {userData.communicationTraits.map((trait) => (
                <span
                  key={trait}
                  className="px-4 py-2 rounded-full bg-gradient-to-r from-[#ff1493]/10 via-[#c154c1]/10 to-[#4169e1]/10 backdrop-blur-xl border border-[#4169e1]/30 text-sm"
                >
                  {trait}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Social preferences */}
        {userData.socialPreferences && userData.socialPreferences.length > 0 && (
          <div className="mb-6">
            <h3 className="text-sm text-white/60 mb-3">Social comfort</h3>
            <div className="flex flex-wrap gap-2">
              {userData.socialPreferences.map((pref) => (
                <span
                  key={pref}
                  className="px-4 py-2 rounded-full bg-white/5 backdrop-blur-xl border border-white/10 text-sm"
                >
                  {pref}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Interests */}
        {userData.interests && userData.interests.length > 0 && (
          <div className="mb-6">
            <h3 className="text-sm text-white/60 mb-3">Interests</h3>
            <div className="flex flex-wrap gap-2">
              {userData.interests.map((interest) => (
                <span
                  key={interest}
                  className="px-4 py-2 rounded-full bg-white/5 backdrop-blur-xl border border-white/10 text-sm"
                >
                  {interest}
                </span>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
