import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ChevronLeft, Sparkles, Lock, Heart } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface LikesProps {
  onBack: () => void;
  onUpgrade: () => void;
  onProfileView: () => void;
}

interface LikeProfile {
  id: number;
  name: string;
  age: number;
  photo: string;
  syncScore: number;
  locked: boolean;
  compatibilityHint?: string;
}

const mockLikes: LikeProfile[] = [
  {
    id: 1,
    name: 'Maya',
    age: 26,
    photo: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=300&h=400&fit=crop',
    syncScore: 89,
    locked: false,
    compatibilityHint: 'Shares your love for deep conversations',
  },
  {
    id: 2,
    name: 'Alex',
    age: 28,
    photo: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=400&fit=crop',
    syncScore: 85,
    locked: false,
    compatibilityHint: 'Similar communication pace',
  },
  {
    id: 3,
    name: '???',
    age: 0,
    photo: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=300&h=400&fit=crop',
    syncScore: 0,
    locked: true,
  },
  {
    id: 4,
    name: '???',
    age: 0,
    photo: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&h=400&fit=crop',
    syncScore: 0,
    locked: true,
  },
];

export const Likes: React.FC<LikesProps> = ({ onBack, onUpgrade, onProfileView }) => {
  const [selectedView, setSelectedView] = useState<'grid' | 'list'>('grid');

  const unlockedCount = mockLikes.filter(like => !like.locked).length;
  const lockedCount = mockLikes.filter(like => like.locked).length;

  return (
    <div className="h-full flex flex-col text-white">
      {/* Header */}
      <div className="px-6 pt-12 pb-4 bg-[#0a0a14]/40 backdrop-blur-xl border-b border-white/5">
        <div className="flex items-center gap-4 mb-4">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full bg-white/5 backdrop-blur-xl border border-white/10 flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <h1 className="text-xl font-light flex-1">Who Likes You</h1>
        </div>

        {/* Count info */}
        <div className="p-4 rounded-2xl bg-gradient-to-r from-[#ffb3d9]/10 to-[#ffc9e3]/10 backdrop-blur-xl border border-[#ffb3d9]/20">
          <div className="flex items-center gap-2">
            <Heart className="w-5 h-5 text-[#ffb3d9]" fill="currentColor" />
            <span className="text-white/90 text-sm">
              {unlockedCount + lockedCount} people are interested in connecting
            </span>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-4 py-6">
        {/* Grid view */}
        <div className="grid grid-cols-2 gap-4">
          {mockLikes.map((like, index) => (
            <motion.button
              key={like.id}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: index * 0.1 }}
              onClick={like.locked ? onUpgrade : onProfileView}
              className="relative aspect-[3/4] rounded-3xl overflow-hidden"
            >
              {/* Image */}
              <div className={`absolute inset-0 ${like.locked ? 'blur-lg scale-110' : ''}`}>
                <ImageWithFallback
                  src={like.photo}
                  alt={like.name}
                  className="w-full h-full object-cover"
                />
              </div>

              {/* Gradient overlay */}
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />

              {/* Locked overlay */}
              {like.locked && (
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-14 h-14 rounded-full bg-black/60 backdrop-blur-xl border border-white/20 flex items-center justify-center">
                    <Lock className="w-7 h-7 text-white/80" />
                  </div>
                </div>
              )}

              {/* Content */}
              {!like.locked && (
                <div className="absolute inset-x-0 bottom-0 p-4">
                  {/* Sync score */}
                  <div className="flex items-center gap-2 mb-2">
                    <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-black/40 backdrop-blur-xl border border-[#7db9e8]/30">
                      <Sparkles className="w-3 h-3 text-[#7db9e8]" />
                      <span className="text-white text-xs font-light">{like.syncScore}%</span>
                    </div>
                  </div>

                  {/* Name and age */}
                  <h3 className="text-white text-lg font-light mb-1">
                    {like.name}, {like.age}
                  </h3>

                  {/* Compatibility hint */}
                  {like.compatibilityHint && (
                    <p className="text-white/70 text-xs line-clamp-2">
                      {like.compatibilityHint}
                    </p>
                  )}
                </div>
              )}
            </motion.button>
          ))}
        </div>

        {/* Unlock prompt */}
        {lockedCount > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mt-6 p-6 rounded-3xl bg-gradient-to-br from-[#7db9e8]/10 to-[#a2d5f2]/10 backdrop-blur-xl border border-[#7db9e8]/20"
          >
            <div className="flex items-start gap-3 mb-4">
              <Sparkles className="w-5 h-5 text-[#7db9e8] mt-0.5 flex-shrink-0" />
              <div>
                <div className="text-[#7db9e8] text-sm mb-1 font-light">
                  Unlock All Connections
                </div>
                <p className="text-white/70 text-sm leading-relaxed">
                  See everyone who's interested and discover deeper compatibility insights
                </p>
              </div>
            </div>

            <motion.button
              whileTap={{ scale: 0.98 }}
              onClick={onUpgrade}
              className="w-full py-3 rounded-2xl bg-gradient-to-r from-[#7db9e8] to-[#a2d5f2] text-white text-sm font-light"
            >
              Learn More
            </motion.button>
          </motion.div>
        )}

        {/* AI insight */}
        <div className="mt-6 p-5 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10">
          <div className="flex items-start gap-2">
            <Sparkles className="w-4 h-4 text-[#7db9e8] mt-0.5 flex-shrink-0" />
            <p className="text-white/70 text-sm leading-relaxed">
              These connections show high compatibility with your communication style and preferences
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
