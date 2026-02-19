import React from 'react';
import { motion } from 'motion/react';
import { ChevronLeft, Sparkles, Heart, MessageCircle, Eye, Shield, Check } from 'lucide-react';

interface SubscriptionProps {
  onBack: () => void;
}

interface Feature {
  icon: React.ReactNode;
  label: string;
  description: string;
}

export const Subscription: React.FC<SubscriptionProps> = ({ onBack }) => {
  const features: Feature[] = [
    {
      icon: <Eye className="w-5 h-5" />,
      label: 'See Who Likes You',
      description: 'View all profiles that expressed interest',
    },
    {
      icon: <MessageCircle className="w-5 h-5" />,
      label: 'Unlimited Messaging',
      description: 'Connect with anyone without limits',
    },
    {
      icon: <Sparkles className="w-5 h-5" />,
      label: 'Deeper AI Insights',
      description: 'Advanced compatibility analysis and suggestions',
    },
    {
      icon: <Heart className="w-5 h-5" />,
      label: 'Priority Connections',
      description: 'Your profile shown to compatible matches first',
    },
    {
      icon: <Shield className="w-5 h-5" />,
      label: 'Enhanced Safety',
      description: 'Additional verification and privacy controls',
    },
  ];

  return (
    <div className="h-full flex flex-col text-white overflow-y-auto">
      {/* Header */}
      <div className="px-6 pt-12 pb-6 bg-[#0a0a14]/40 backdrop-blur-xl border-b border-white/5 sticky top-0 z-10">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full bg-white/5 backdrop-blur-xl border border-white/10 flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <h1 className="text-xl font-light">Premium</h1>
        </div>
      </div>

      {/* Hero section */}
      <div className="px-6 py-8">
        <div className="text-center mb-8">
          <div className="w-20 h-20 mx-auto mb-4 rounded-full bg-gradient-to-br from-[#ffb3d9]/20 to-[#7db9e8]/20 backdrop-blur-xl border border-[#7db9e8]/30 flex items-center justify-center">
            <Sparkles className="w-10 h-10 text-[#7db9e8]" />
          </div>
          <h2 className="text-2xl font-light mb-2">Deepen Your Connections</h2>
          <p className="text-white/60 text-sm leading-relaxed">
            Unlock features that help you find meaningful relationships faster
          </p>
        </div>

        {/* Features list */}
        <div className="space-y-3 mb-8">
          {features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              className="p-4 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10"
            >
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#7db9e8]/20 to-[#a2d5f2]/20 backdrop-blur-xl border border-[#7db9e8]/30 flex items-center justify-center text-[#7db9e8] flex-shrink-0">
                  {feature.icon}
                </div>
                <div className="flex-1">
                  <div className="text-white text-sm font-light mb-1">
                    {feature.label}
                  </div>
                  <div className="text-white/60 text-xs">
                    {feature.description}
                  </div>
                </div>
                <Check className="w-5 h-5 text-[#a2e8cb] flex-shrink-0 mt-2" />
              </div>
            </motion.div>
          ))}
        </div>

        {/* Plan options */}
        <div className="space-y-3 mb-6">
          {/* 3 Month Plan */}
          <motion.button
            whileTap={{ scale: 0.98 }}
            className="w-full p-5 rounded-3xl bg-gradient-to-br from-[#7db9e8]/10 to-[#a2d5f2]/10 backdrop-blur-xl border-2 border-[#7db9e8]/30 hover:border-[#7db9e8]/50 transition-all relative overflow-hidden"
          >
            {/* Best value badge */}
            <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-gradient-to-r from-[#ffb3d9] to-[#ffc9e3] text-xs text-white font-light">
              Best Value
            </div>

            <div className="text-left">
              <div className="text-white text-lg font-light mb-1">3 Months</div>
              <div className="text-[#7db9e8] text-2xl font-light mb-2">$29.99</div>
              <div className="text-white/60 text-xs">Save 40% • $10/month</div>
            </div>
          </motion.button>

          {/* 1 Month Plan */}
          <motion.button
            whileTap={{ scale: 0.98 }}
            className="w-full p-5 rounded-3xl bg-white/5 backdrop-blur-xl border border-white/10 hover:bg-white/10 transition-all"
          >
            <div className="text-left">
              <div className="text-white text-lg font-light mb-1">1 Month</div>
              <div className="text-white/90 text-2xl font-light mb-2">$19.99</div>
              <div className="text-white/60 text-xs">Renews monthly</div>
            </div>
          </motion.button>
        </div>

        {/* AI insight about premium */}
        <div className="p-5 rounded-3xl bg-gradient-to-br from-[#ffb3d9]/10 to-[#ffc9e3]/10 backdrop-blur-xl border border-[#ffb3d9]/20 mb-6">
          <div className="flex items-start gap-3">
            <Sparkles className="w-5 h-5 text-[#ffb3d9] mt-0.5 flex-shrink-0" />
            <div>
              <div className="text-[#ffb3d9] text-sm mb-1 font-light">
                Personalized Insight
              </div>
              <p className="text-white/70 text-sm leading-relaxed">
                Based on your profile, premium features could help you connect with 3 highly compatible matches currently interested
              </p>
            </div>
          </div>
        </div>

        {/* CTA button */}
        <motion.button
          whileTap={{ scale: 0.98 }}
          className="w-full py-4 rounded-2xl bg-gradient-to-r from-[#7db9e8] to-[#a2d5f2] text-white font-light mb-4"
        >
          Continue
        </motion.button>

        {/* Fine print */}
        <p className="text-white/40 text-xs text-center leading-relaxed">
          Cancel anytime. By continuing, you agree to our terms. Auto-renewal can be turned off in account settings.
        </p>
      </div>
    </div>
  );
};
