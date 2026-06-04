/// Centralized route *path* constants.
///
/// These are consumed by GoRouter (see `app_router.dart`). Keeping them as
/// plain string constants means existing `Navigator.pushNamed` call sites and
/// the new `context.go/pushNamed` call sites can share the same source of
/// truth, which keeps the GoRouter migration low-risk.
class AppRoutes {
  static const splash          = '/';
  static const login           = '/login';
  static const signup          = '/signup';
  static const forgotPassword  = '/forgot-password';
  static const home            = '/home';
  static const profile         = '/profile';
  static const details         = '/details';
  static const schedule        = '/schedule';
  static const createListing   = '/create-listing';
  static const map             = '/map';
  static const settings        = '/settings';
  static const help            = '/help';
  static const chatInboxScreen = '/chat-inbox';
  static const chat            = '/chat';          // Feature 1: individual chat
  static const notifications   = '/notifications'; // Feature 4

  /// Named-route identifiers (used by GoRouter `name:` + `pushNamed`).
  static const nSplash         = 'splash';
  static const nLogin          = 'login';
  static const nSignup         = 'signup';
  static const nForgotPassword = 'forgotPassword';
  static const nHome           = 'home';
  static const nProfile        = 'profile';
  static const nDetails        = 'details';
  static const nSchedule       = 'schedule';
  static const nCreateListing  = 'createListing';
  static const nMap            = 'map';
  static const nSettings       = 'settings';
  static const nHelp           = 'help';
  static const nChatInbox      = 'chatInbox';
  static const nChat           = 'chat';
  static const nNotifications  = 'notifications';
}
