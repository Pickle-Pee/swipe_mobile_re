class Routes {
  static const bootstrap = '/bootstrap';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const authPhone = '/auth/phone';
  static const register = '/register';
  static const discover = '/discover';
  static const publicProfile = '/discover/profile/:id';
  static const match = '/match/:userId';
  static const chats = '/chats';
  static const chat = '/chat/:id';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const profilePreview = '/profile/preview';
  static const likes = '/likes';
  static const settings = '/settings';
  static const accountSettings = '/settings/account';
  static const discoveryPreferences = '/settings/discovery';
  static const deleteAccount = '/settings/account/delete';
  static const appInformation = '/settings/about';
  static const premium = '/premium';

  static const loginPhone = '$authPhone?intent=login';
  static const registrationPhone = '$authPhone?intent=registration';

  static String publicProfileFor(int userId) => '/discover/profile/$userId';
  static String publicProfileFromLikesFor(int userId) =>
      '/discover/profile/$userId?source=likes';
  static String matchFor(int userId) => '/match/$userId';
  static String chatFor(int chatId) => '/chat/$chatId';
}
