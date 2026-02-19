import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ChevronLeft, ChevronRight, User, MessageSquare, Shield, Bell, Sparkles, LogOut } from 'lucide-react';

interface SettingsProps {
  onBack: () => void;
}

interface SettingItem {
  icon: React.ReactNode;
  label: string;
  description?: string;
  onClick?: () => void;
  toggle?: boolean;
  value?: boolean;
  onToggle?: () => void;
}

export const Settings: React.FC<SettingsProps> = ({ onBack }) => {
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [aiSuggestionsEnabled, setAiSuggestionsEnabled] = useState(true);

  const accountSettings: SettingItem[] = [
    {
      icon: <User className="w-5 h-5" />,
      label: 'Edit Profile',
      description: 'Update your photos and information',
    },
    {
      icon: <Sparkles className="w-5 h-5" />,
      label: 'Personality Settings',
      description: 'Adjust your communication preferences',
    },
  ];

  const communicationSettings: SettingItem[] = [
    {
      icon: <MessageSquare className="w-5 h-5" />,
      label: 'Communication Pace',
      description: 'Gradual',
    },
    {
      icon: <Sparkles className="w-5 h-5" />,
      label: 'AI Suggestions',
      description: 'Get conversation recommendations',
      toggle: true,
      value: aiSuggestionsEnabled,
      onToggle: () => setAiSuggestionsEnabled(!aiSuggestionsEnabled),
    },
  ];

  const privacySettings: SettingItem[] = [
    {
      icon: <Shield className="w-5 h-5" />,
      label: 'Privacy Controls',
      description: 'Manage who can see your profile',
    },
    {
      icon: <Bell className="w-5 h-5" />,
      label: 'Notifications',
      description: 'Message and match alerts',
      toggle: true,
      value: notificationsEnabled,
      onToggle: () => setNotificationsEnabled(!notificationsEnabled),
    },
  ];

  const renderSettingGroup = (title: string, items: SettingItem[]) => (
    <div className="mb-6">
      <h3 className="text-white/50 text-xs uppercase tracking-wider mb-3 px-6">
        {title}
      </h3>
      <div className="space-y-2 px-4">
        {items.map((item, index) => (
          <motion.button
            key={index}
            whileTap={{ scale: 0.98 }}
            onClick={item.toggle ? item.onToggle : item.onClick}
            className="w-full p-4 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10 hover:bg-white/10 transition-all"
          >
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 flex items-center justify-center text-[#7db9e8]">
                {item.icon}
              </div>

              <div className="flex-1 text-left">
                <div className="text-white text-sm font-light mb-0.5">
                  {item.label}
                </div>
                {item.description && (
                  <div className="text-white/50 text-xs">
                    {item.description}
                  </div>
                )}
              </div>

              {item.toggle ? (
                <div
                  className={`w-12 h-7 rounded-full transition-colors ${
                    item.value
                      ? 'bg-gradient-to-r from-[#7db9e8] to-[#a2d5f2]'
                      : 'bg-white/20'
                  }`}
                >
                  <motion.div
                    animate={{ x: item.value ? 20 : 0 }}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                    className="w-6 h-6 rounded-full bg-white mt-0.5 ml-0.5"
                  />
                </div>
              ) : (
                <ChevronRight className="w-5 h-5 text-white/30" />
              )}
            </div>
          </motion.button>
        ))}
      </div>
    </div>
  );

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
          <h1 className="text-xl font-light">Settings</h1>
        </div>
      </div>

      {/* Settings groups */}
      <div className="flex-1 py-6">
        {renderSettingGroup('Account', accountSettings)}
        {renderSettingGroup('Communication', communicationSettings)}
        {renderSettingGroup('Privacy & Notifications', privacySettings)}

        {/* AI Insight */}
        <div className="px-4 mb-6">
          <div className="p-5 rounded-3xl bg-gradient-to-br from-[#7db9e8]/10 to-[#a2d5f2]/10 backdrop-blur-xl border border-[#7db9e8]/20">
            <div className="flex items-start gap-3">
              <Sparkles className="w-5 h-5 text-[#7db9e8] mt-0.5 flex-shrink-0" />
              <div>
                <div className="text-[#7db9e8] text-sm mb-1 font-light">
                  Your Communication Profile
                </div>
                <p className="text-white/70 text-sm leading-relaxed">
                  You're currently set to prefer gradual, thoughtful connections. Your communication style is resonating well with your matches.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Logout */}
        <div className="px-4 mb-8">
          <motion.button
            whileTap={{ scale: 0.98 }}
            className="w-full p-4 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10 hover:bg-white/10 transition-all"
          >
            <div className="flex items-center justify-center gap-3">
              <LogOut className="w-5 h-5 text-white/70" />
              <span className="text-white/70 text-sm font-light">Log Out</span>
            </div>
          </motion.button>
        </div>
      </div>
    </div>
  );
};
