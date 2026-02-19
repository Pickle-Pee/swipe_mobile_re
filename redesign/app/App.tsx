import React, { useState } from 'react';
import { Onboarding } from './components/Onboarding';
import { RegistrationFlow } from './components/RegistrationFlow';
import { PersonalityFlow } from './components/PersonalityFlow';
import { Profile } from './components/Profile';
import { Discovery } from './components/Discovery';
import { MatchMoment } from './components/MatchMoment';
import { Chat } from './components/Chat';
import { DevNavigation } from './components/DevNavigation';
import { AllChats } from './components/AllChats';
import { UserProfile } from './components/UserProfile';
import { DiscoveryCardScroll } from './components/DiscoveryCardScroll';
import { Settings } from './components/Settings';
import { Likes } from './components/Likes';
import { Subscription } from './components/Subscription';

export type Screen = 
  | 'onboarding' 
  | 'registration' 
  | 'personality' 
  | 'profile' 
  | 'discovery' 
  | 'match' 
  | 'chat'
  | 'allChats'
  | 'userProfile'
  | 'settings'
  | 'likes'
  | 'subscription'
  | 'discoveryScroll';

export interface UserData {
  name?: string;
  age?: number;
  gender?: string;
  city?: string;
  interests?: string[];
  connectionType?: string;
  communicationTraits?: string[];
  socialPreferences?: string[];
}

function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('onboarding');
  const [userData, setUserData] = useState<UserData>({});

  const navigateToScreen = (screen: Screen) => {
    setCurrentScreen(screen);
  };

  const updateUserData = (data: Partial<UserData>) => {
    setUserData(prev => ({ ...prev, ...data }));
  };

  return (
    <div className="relative h-screen w-full overflow-hidden bg-[#0f0f1a]">
      {/* Background liquid gradient - softer colors */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-[-20%] left-[-10%] w-[60%] h-[60%] rounded-full bg-gradient-to-br from-[#7db9e8]/15 via-[#b8a9dc]/15 to-[#a2d5f2]/15 blur-[100px] animate-pulse" />
        <div className="absolute bottom-[-20%] right-[-10%] w-[70%] h-[70%] rounded-full bg-gradient-to-tl from-[#ffb3d9]/15 via-[#d8a8dc]/15 to-[#7db9e8]/15 blur-[120px] animate-pulse" style={{ animationDelay: '2s' }} />
      </div>

      {/* Screen content */}
      <div className="relative z-10 h-full">
        {currentScreen === 'onboarding' && (
          <Onboarding onNext={() => navigateToScreen('registration')} />
        )}
        {currentScreen === 'registration' && (
          <RegistrationFlow 
            onComplete={() => navigateToScreen('personality')}
            userData={userData}
            updateUserData={updateUserData}
          />
        )}
        {currentScreen === 'personality' && (
          <PersonalityFlow 
            onComplete={() => navigateToScreen('discovery')}
            userData={userData}
            updateUserData={updateUserData}
          />
        )}
        {currentScreen === 'profile' && (
          <Profile 
            userData={userData}
            onBack={() => navigateToScreen('discovery')}
          />
        )}
        {currentScreen === 'discovery' && (
          <Discovery 
            onMatch={() => navigateToScreen('match')}
            onViewProfile={() => navigateToScreen('profile')}
            onAllChats={() => navigateToScreen('allChats')}
          />
        )}
        {currentScreen === 'match' && (
          <MatchMoment 
            onContinue={() => navigateToScreen('chat')}
          />
        )}
        {currentScreen === 'chat' && (
          <Chat 
            onBack={() => navigateToScreen('discovery')}
          />
        )}
        {currentScreen === 'allChats' && (
          <AllChats 
            onBack={() => navigateToScreen('discovery')}
            onChatSelect={() => navigateToScreen('chat')}
            onSettings={() => navigateToScreen('settings')}
          />
        )}
        {currentScreen === 'userProfile' && (
          <UserProfile 
            onBack={() => navigateToScreen('discovery')}
            isOwnProfile={false}
          />
        )}
        {currentScreen === 'settings' && (
          <Settings 
            onBack={() => navigateToScreen('discovery')}
          />
        )}
        {currentScreen === 'likes' && (
          <Likes 
            onBack={() => navigateToScreen('discovery')}
            onUpgrade={() => navigateToScreen('subscription')}
            onProfileView={() => navigateToScreen('userProfile')}
          />
        )}
        {currentScreen === 'subscription' && (
          <Subscription 
            onBack={() => navigateToScreen('likes')}
          />
        )}
        {currentScreen === 'discoveryScroll' && (
          <DiscoveryCardScroll 
            onPass={() => {}}
            onConnect={() => navigateToScreen('match')}
          />
        )}
      </div>

      {/* Dev Navigation */}
      <DevNavigation
        currentScreen={currentScreen}
        onNavigate={navigateToScreen}
      />
    </div>
  );
}

export default App;