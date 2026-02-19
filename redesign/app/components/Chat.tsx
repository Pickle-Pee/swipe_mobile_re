import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ChevronLeft, Sparkles, Send } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface ChatProps {
  onBack: () => void;
}

interface Message {
  id: number;
  text: string;
  sender: 'user' | 'other';
  timestamp: string;
}

export const Chat: React.FC<ChatProps> = ({ onBack }) => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 1,
      text: "Hey! I saw we both love photography 📸",
      sender: 'other',
      timestamp: '2:34 PM'
    },
    {
      id: 2,
      text: "Yes! What kind of photography do you enjoy?",
      sender: 'user',
      timestamp: '2:36 PM'
    },
    {
      id: 3,
      text: "I'm really into street photography and portraits. There's something magical about capturing authentic moments.",
      sender: 'other',
      timestamp: '2:37 PM'
    },
  ]);

  const [inputValue, setInputValue] = useState('');
  const [showAISuggestion, setShowAISuggestion] = useState(true);

  const aiSuggestion = "That sounds fascinating! I'd love to see some of your work.";

  const handleSend = () => {
    if (!inputValue.trim()) return;

    const newMessage: Message = {
      id: messages.length + 1,
      text: inputValue,
      sender: 'user',
      timestamp: new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
    };

    setMessages([...messages, newMessage]);
    setInputValue('');
    setShowAISuggestion(true);
  };

  const handleAISuggestion = () => {
    setInputValue(aiSuggestion);
    setShowAISuggestion(false);
  };

  return (
    <div className="h-full flex flex-col text-white">
      {/* Header */}
      <div className="px-6 pt-12 pb-4 border-b border-white/5 bg-[#0a0a14]/80 backdrop-blur-xl">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full bg-white/5 backdrop-blur-xl border border-white/10 flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <div className="flex items-center gap-3 flex-1">
            <div className="w-12 h-12 rounded-full border-2 border-[#7db9e8] overflow-hidden">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop"
                alt="Sofia"
                className="w-full h-full object-cover"
              />
            </div>

            <div>
              <div className="font-light">Sofia</div>
              <div className="text-xs text-white/50">Calm • Observant • Open</div>
            </div>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-6 py-6 space-y-4">
        {messages.map((message) => (
          <motion.div
            key={message.id}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className={`flex ${message.sender === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-[75%] ${
                message.sender === 'user'
                  ? 'bg-gradient-to-r from-[#ffb3d9]/15 via-[#d8a8dc]/15 to-[#7db9e8]/15 backdrop-blur-xl border border-[#7db9e8]/30'
                  : 'bg-white/5 backdrop-blur-xl border border-white/10'
              } px-4 py-3 rounded-3xl`}
            >
              <p className="text-white/90 text-sm leading-relaxed mb-1">{message.text}</p>
              <span className="text-xs text-white/40">{message.timestamp}</span>
            </div>
          </motion.div>
        ))}
      </div>

      {/* AI suggestion card */}
      {showAISuggestion && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 20 }}
          className="px-6 pb-2"
        >
          <button
            onClick={handleAISuggestion}
            className="w-full p-4 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10 text-left hover:bg-white/10 transition-colors"
          >
            <div className="flex items-start gap-2">
              <Sparkles className="w-4 h-4 text-[#00bcd4] mt-0.5 flex-shrink-0" />
              <div className="flex-1">
                <div className="text-xs text-[#00bcd4]/80 mb-1">AI suggestion</div>
                <p className="text-white/80 text-sm">{aiSuggestion}</p>
              </div>
            </div>
          </button>
        </motion.div>
      )}

      {/* Input area */}
      <div className="px-6 pb-8 pt-4">
        <div className="relative flex items-center gap-3">
          <div className="flex-1 relative">
            <input
              type="text"
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSend()}
              placeholder="Type a message..."
              className="w-full px-5 py-3 bg-white/5 backdrop-blur-xl border border-white/10 rounded-full text-white placeholder:text-white/40 focus:outline-none focus:border-[#4169e1]/50 transition-colors pr-12"
            />

            <button
              className="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-white/10 backdrop-blur-xl border border-white/10 flex items-center justify-center hover:bg-white/15 transition-colors"
            >
              <Sparkles className="w-4 h-4 text-[#00bcd4]" />
            </button>
          </div>

          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={handleSend}
            disabled={!inputValue.trim()}
            className={`w-12 h-12 rounded-full flex items-center justify-center transition-all ${
              inputValue.trim()
                ? 'bg-gradient-to-r from-[#ffb3d9] via-[#d8a8dc] to-[#7db9e8]'
                : 'bg-white/5 border border-white/10'
            }`}
          >
            <Send className={`w-5 h-5 ${inputValue.trim() ? 'text-white' : 'text-white/40'}`} />
          </motion.button>
        </div>
      </div>
    </div>
  );
};