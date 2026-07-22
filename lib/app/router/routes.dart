class Routes {
  static const onboarding = '/onboarding';
  static const authPhone = '/auth/phone';
  static const register = '/register';
  static const discover = '/discover';
  static const publicProfile = '/discover/profile/:id';
  static const match = '/match/:userId';
  static const chats = '/chats';
  static const chat = '/chat/:id';
  static const profile = '/profile';
  static const likes = '/likes';
  static const settings = '/settings';
  static const premium = '/premium';

  static String publicProfileFor(int userId) => '/discover/profile/$userId';
  static String matchFor(int userId) => '/match/$userId';
  static String chatFor(int chatId) => '/chat/$chatId';
}
