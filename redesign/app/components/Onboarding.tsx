import React, { useEffect, useState } from 'react';
import { motion } from 'motion/react';
import { Sparkles } from 'lucide-react';
import logoImage from 'figma:asset/308bd4c623d6a3b4a42374653d7c7cbeed78a876.png';

interface OnboardingProps {
  onNext: () => void;
}

export const Onboarding: React.FC<OnboardingProps> = ({ onNext }) => {
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    setTimeout(() => setShowContent(true), 500);
  }, []);

  return (
    <div className="h-full flex flex-col items-center justify-center px-6 text-white">
      {/* Animated logo */}
      <motion.div
        initial={{ scale: 0.5, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 1, ease: 'easeOut' }}
        className="mb-8"
      >
        <div className="relative">
          <div className="absolute inset-0 blur-3xl bg-gradient-to-r from-[#ff69b4] via-[#9b59b6] to-[#4169e1] opacity-60 rounded-full" />
          <img 
            src={logoImage} 
            alt="Logo" 
            className="w-32 h-32 relative z-10"
          />
        </div>
      </motion.div>

      {/* AI presence indicator */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: showContent ? 1 : 0, y: showContent ? 0 : 20 }}
        transition={{ delay: 0.8, duration: 0.6 }}
        className="flex items-center gap-2 mb-6"
      >
        <Sparkles className="w-5 h-5 text-[#00bcd4]" />
        <span className="text-sm text-[#00bcd4]/80">AI-powered connection</span>
      </motion.div>

      {/* Main text */}
      <motion.h1
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: showContent ? 1 : 0, y: showContent ? 0 : 20 }}
        transition={{ delay: 1, duration: 0.6 }}
        className="text-3xl font-light text-center mb-4"
      >
        Welcome to emotional
        <br />
        <span className="bg-gradient-to-r from-[#ff69b4] via-[#c154c1] to-[#4169e1] bg-clip-text text-transparent font-normal">
          intelligence
        </span>
      </motion.h1>

      <motion.p
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: showContent ? 1 : 0, y: showContent ? 0 : 20 }}
        transition={{ delay: 1.2, duration: 0.6 }}
        className="text-center text-white/60 mb-12 max-w-sm"
      >
        An AI-native experience designed to understand who you are and help you find meaningful connections.
      </motion.p>

      {/* CTA Button with liquid morph */}
      <motion.button
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: showContent ? 1 : 0, scale: showContent ? 1 : 0.9 }}
        transition={{ delay: 1.4, duration: 0.6 }}
        whileTap={{ scale: 0.95 }}
        onClick={onNext}
        className="relative group"
      >
        <div className="absolute inset-0 bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1] rounded-full blur-xl opacity-60 group-hover:opacity-80 transition-opacity" />
        <div className="relative px-12 py-4 bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1] rounded-full text-white font-light">
          Begin your journey
        </div>
      </motion.button>

      {/* Floating particles */}
      <div className="absolute inset-0 pointer-events-none">
        {[...Array(6)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-2 h-2 rounded-full bg-gradient-to-r from-[#ff69b4] to-[#4169e1]"
            initial={{ 
              x: Math.random() * window.innerWidth, 
              y: window.innerHeight + 20,
              opacity: 0 
            }}
            animate={{
              y: -20,
              opacity: [0, 1, 0],
            }}
            transition={{
              duration: 4 + Math.random() * 3,
              repeat: Infinity,
              delay: i * 0.8,
              ease: 'linear'
            }}
            style={{
              left: `${10 + i * 15}%`,
            }}
          />
        ))}
      </div>
    </div>
  );
};
