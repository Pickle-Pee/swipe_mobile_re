import React from 'react';
import { motion } from 'motion/react';
import { ChevronLeft, Sparkles, Settings } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface AllChatsProps {
  onBack: () => void;
  onChatSelect: () => void;
  onSettings: () => void;
}

interface ChatPreview {
  id: number;
  name: string;
  avatar: string;
  communicationStyle: string;
  lastMessage: string;
  timestamp: string;
  aiTone: 'calm' | 'energetic' | 'thoughtful';
  unread?: boolean;
}

const mockChats: ChatPreview[] = [
  {
    id: 1,
    name: 'Sofia',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop',
    communicationStyle: 'Calm • Observant',
    lastMessage: "I'm really into street photography and portraits...",
    timestamp: '2:37 PM',
    aiTone: 'calm',
    unread: true,
  },
  {
    id: 2,
    name: 'Emma',
    avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
    communicationStyle: 'Warm • Expressive',
    lastMessage: 'Would love to hear more about your travels!',
    timestamp: 'Yesterday',
    aiTone: 'energetic',
  },
  {
    id: 3,
    name: 'Maya',
    avatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100&h=100&fit=crop',
    communicationStyle: 'Thoughtful • Deep',
    lastMessage: 'That book sounds fascinating...',
    timestamp: 'Tuesday',
    aiTone: 'thoughtful',
  },
];

const aiToneColors = {
  calm: 'from-[#7db9e8]/20 to-[#a2d5f2]/20',
  energetic: 'from-[#ffb3d9]/20 to-[#ffc9e3]/20',
  thoughtful: 'from-[#b8a9dc]/20 to-[#d1c4f0]/20',
};

export const AllChats: React.FC<AllChatsProps> = ({ onBack, onChatSelect, onSettings }) => {
  return (
    <div className="h-full flex flex-col text-white">
      {/* Header */}
      <div className="px-6 pt-12 pb-4 bg-[#0a0a14]/40 backdrop-blur-xl border-b border-white/5">
        <div className="flex items-center justify-between mb-4">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full bg-white/5 backdrop-blur-xl border border-white/10 flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          
          <h1 className="text-xl font-light">Messages</h1>
          
          <button
            onClick={onSettings}
            className="w-10 h-10 rounded-full bg-white/5 backdrop-blur-xl border border-white/10 flex items-center justify-center"
          >
            <Settings className="w-5 h-5" />
          </button>
        </div>

        {/* AI Insight */}
        <div className="p-4 rounded-2xl bg-gradient-to-r from-[#7db9e8]/10 to-[#a2d5f2]/10 backdrop-blur-xl border border-[#7db9e8]/20">
          <div className="flex items-start gap-2">
            <Sparkles className="w-4 h-4 text-[#7db9e8] mt-0.5 flex-shrink-0" />
            <p className="text-white/80 text-sm leading-relaxed">
              Your connections appreciate thoughtful, genuine communication
            </p>
          </div>
        </div>
      </div>

      {/* Chat list */}
      <div className="flex-1 overflow-y-auto px-4 py-4">
        {mockChats.map((chat, index) => (
          <motion.button
            key={chat.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            onClick={onChatSelect}
            className="w-full mb-3 p-4 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10 hover:bg-white/10 transition-all"
          >
            <div className="flex items-start gap-4">
              {/* Avatar with status */}
              <div className="relative flex-shrink-0">
                <div className="w-14 h-14 rounded-full overflow-hidden border-2 border-[#7db9e8]/30">
                  <ImageWithFallback
                    src={chat.avatar}
                    alt={chat.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                {chat.unread && (
                  <div className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-gradient-to-r from-[#ffb3d9] to-[#ffc9e3] border-2 border-[#0a0a14] flex items-center justify-center">
                    <span className="text-[10px] text-white font-medium">1</span>
                  </div>
                )}
              </div>

              {/* Content */}
              <div className="flex-1 text-left">
                <div className="flex items-center justify-between mb-1">
                  <h3 className="font-light text-white">{chat.name}</h3>
                  <span className="text-xs text-white/40">{chat.timestamp}</span>
                </div>
                
                <div className="text-xs text-white/50 mb-2">
                  {chat.communicationStyle}
                </div>

                <p className="text-sm text-white/60 line-clamp-1">
                  {chat.lastMessage}
                </p>
              </div>

              {/* AI tone indicator */}
              <div className={`flex-shrink-0 w-2 h-2 rounded-full bg-gradient-to-br ${aiToneColors[chat.aiTone]} border border-current mt-6`} />
            </div>
          </motion.button>
        ))}
      </div>
    </div>
  );
};