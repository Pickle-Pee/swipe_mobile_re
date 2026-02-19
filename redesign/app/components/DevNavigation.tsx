import React from 'react';
import { Screen } from '../App';

interface DevNavigationProps {
  currentScreen: Screen;
  onNavigate: (screen: Screen) => void;
}

const screens: { value: Screen; label: string }[] = [
  { value: 'onboarding', label: 'Onboard' },
  { value: 'registration', label: 'Register' },
  { value: 'personality', label: 'Personality' },
  { value: 'discovery', label: 'Discovery' },
  { value: 'profile', label: 'Profile' },
  { value: 'match', label: 'Match' },
  { value: 'chat', label: 'Chat' },
];

export const DevNavigation: React.FC<DevNavigationProps> = ({ currentScreen, onNavigate }) => {
  // Only show in development
  if (import.meta.env.PROD) return null;

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50 bg-black/90 backdrop-blur-xl border-t border-white/10">
      <div className="overflow-x-auto">
        <div className="flex gap-2 p-3 min-w-max">
          {screens.map((screen) => (
            <button
              key={screen.value}
              onClick={() => onNavigate(screen.value)}
              className={`px-3 py-1.5 rounded-full text-xs transition-all ${
                currentScreen === screen.value
                  ? 'bg-gradient-to-r from-[#ff1493] via-[#c154c1] to-[#4169e1] text-white'
                  : 'bg-white/10 text-white/60 hover:bg-white/20'
              }`}
            >
              {screen.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};
