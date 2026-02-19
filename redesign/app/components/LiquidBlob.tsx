import React from 'react';
import { motion } from 'motion/react';

interface LiquidBlobProps {
  className?: string;
  color?: string;
  delay?: number;
}

export const LiquidBlob: React.FC<LiquidBlobProps> = ({ 
  className = '', 
  color = 'from-[#ff1493] to-[#4169e1]',
  delay = 0 
}) => {
  return (
    <motion.div
      className={`absolute rounded-full bg-gradient-to-br ${color} blur-3xl opacity-30 ${className}`}
      animate={{
        scale: [1, 1.2, 1],
        rotate: [0, 90, 0],
        borderRadius: [
          '60% 40% 30% 70% / 60% 30% 70% 40%',
          '30% 60% 70% 40% / 50% 60% 30% 60%',
          '60% 40% 30% 70% / 60% 30% 70% 40%',
        ],
      }}
      transition={{
        duration: 8,
        repeat: Infinity,
        delay: delay,
        ease: 'easeInOut',
      }}
    />
  );
};
