import React, { useEffect, useState } from 'react';
import { motion } from 'motion/react';
import { Sparkles, Heart } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface MatchMomentProps {
  onContinue: () => void;
}

export const MatchMoment: React.FC<MatchMomentProps> = ({ onContinue }) => {
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    setTimeout(() => setShowContent(true), 500);
  }, []);

  return (
    <div className="h-full flex flex-col items-center justify-center px-6 text-white relative overflow-hidden">
      {/* Animated background particles */}
      <div className="absolute inset-0 pointer-events-none">
        {[...Array(20)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1 h-1 rounded-full bg-gradient-to-r from-[#ff69b4] to-[#4169e1]"
            initial={{ 
              x: window.innerWidth / 2, 
              y: window.innerHeight / 2,
              scale: 0,
              opacity: 0 
            }}
            animate={{
              x: Math.random() * window.innerWidth,
              y: Math.random() * window.innerHeight,
              scale: [0, 1, 0],
              opacity: [0, 1, 0],
            }}
            transition={{
              duration: 2 + Math.random() * 2,
              delay: i * 0.1,
              ease: 'easeOut'
            }}
          />
        ))}
      </div>

      {/* Liquid field */}
      <motion.div
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.8, ease: 'easeOut' }}
        className="relative mb-12"
      >
        <div className="absolute inset-0 blur-3xl bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1] opacity-40 rounded-full" />
        
        {/* Floating avatars */}
        <div className="relative flex items-center gap-8">
          <motion.div
            initial={{ x: -100, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: 0.3, duration: 0.6 }}
            className="relative"
          >
            <div className="w-24 h-24 rounded-full border-4 border-[#ff1493] overflow-hidden">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop"
                alt="You"
                className="w-full h-full object-cover"
              />
            </div>
            <motion.div
              animate={{ scale: [1, 1.2, 1] }}
              transition={{ duration: 2, repeat: Infinity }}
              className="absolute -top-1 -right-1 w-6 h-6 rounded-full bg-gradient-to-br from-[#ff1493] to-[#c154c1] flex items-center justify-center"
            >
              <Heart className="w-3 h-3 text-white" fill="white" />
            </motion.div>
          </motion.div>

          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: [0, 1.5, 1] }}
            transition={{ delay: 0.6, duration: 0.5 }}
            className="w-12 h-12 rounded-full bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1] flex items-center justify-center"
          >
            <Sparkles className="w-6 h-6 text-white" />
          </motion.div>

          <motion.div
            initial={{ x: 100, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: 0.3, duration: 0.6 }}
            className="relative"
          >
            <div className="w-24 h-24 rounded-full border-4 border-[#4169e1] overflow-hidden">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop"
                alt="Match"
                className="w-full h-full object-cover"
              />
            </div>
            <motion.div
              animate={{ scale: [1, 1.2, 1] }}
              transition={{ duration: 2, repeat: Infinity, delay: 0.5 }}
              className="absolute -top-1 -left-1 w-6 h-6 rounded-full bg-gradient-to-br from-[#4169e1] to-[#c154c1] flex items-center justify-center"
            >
              <Heart className="w-3 h-3 text-white" fill="white" />
            </motion.div>
          </motion.div>
        </div>
      </motion.div>

      {/* Content */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: showContent ? 1 : 0, y: showContent ? 0 : 20 }}
        transition={{ delay: 1, duration: 0.6 }}
        className="text-center mb-8"
      >
        <h1 className="text-3xl font-light mb-3">
          It's a{' '}
          <span className="bg-gradient-to-r from-[#ff69b4] via-[#c154c1] to-[#4169e1] bg-clip-text text-transparent">
            connection
          </span>
        </h1>
        <p className="text-white/60">You and Sofia both feel the sync</p>
      </motion.div>

      {/* AI conversation starters */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: showContent ? 1 : 0, y: showContent ? 0 : 20 }}
        transition={{ delay: 1.2, duration: 0.6 }}
        className="w-full max-w-sm mb-8 space-y-3"
      >
        <div className="flex items-start gap-2 text-xs text-[#00bcd4]/80 mb-2">
          <Sparkles className="w-3 h-3 mt-0.5" />
          <span>AI conversation starters</span>
        </div>

        {[
          "You both love art and photography",
          "Similar views on gradual connections",
          "Shared interest in authentic conversations"
        ].map((starter, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 1.4 + i * 0.1 }}
            className="p-4 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10"
          >
            <p className="text-white/80 text-sm">{starter}</p>
          </motion.div>
        ))}
      </motion.div>

      {/* Continue button */}
      <motion.button
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: showContent ? 1 : 0, scale: showContent ? 1 : 0.9 }}
        transition={{ delay: 1.7, duration: 0.6 }}
        whileTap={{ scale: 0.95 }}
        onClick={onContinue}
        className="relative group w-full max-w-sm"
      >
        <div className="absolute inset-0 bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1] rounded-full blur-xl opacity-60 group-hover:opacity-80 transition-opacity" />
        <div className="relative px-8 py-4 bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1] rounded-full text-white">
          Start conversation
        </div>
      </motion.button>
    </div>
  );
};
