/// Central route names/paths.
abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/signin';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';

  static const discover = '/discover';
  static const nearby = '/nearby';
  static const chats = '/chats';
  static const me = '/me';

  static const pokes = '/pokes';
  static const notifications = '/notifications';
  static const paywall = '/paywall';
  static const settings = '/settings';
  static const blockedUsers = '/settings/blocked';
  static const safety = '/safety';
  static const terms = '/legal/terms';
  static const privacy = '/legal/privacy';
  static const verify = '/verify';
  static const editProfile = '/profile/edit';
  static const admin = '/admin';

  static String chat(String conversationId) => '/chat/$conversationId';
  static String user(String userId) => '/user/$userId';
}
