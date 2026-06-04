import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/create_listing/create_listing.dart';
import '../screens/home/chat.dart';
import '../screens/home/chat_inbox_screen.dart';
import '../screens/home/help.dart';
import '../screens/home/map_screen.dart';
import '../screens/home/notifications_screen.dart';
import '../screens/home/sales_details_screen.dart';
import '../screens/home/settings.dart';
import '../screens/home/splash_screen.dart';
import '../screens/navigation/bottom_nav_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import 'app_routes.dart';

/// Feature 5 — Centralized navigation with GoRouter.
///
///  * Named routes (see `AppRoutes.n*`) so call sites use `context.goNamed` /
///    `context.pushNamed` instead of hand-built `MaterialPageRoute`s.
///  * Auth guard via `redirect` + `refreshListenable` on the auth stream:
///    unauthenticated users are bounced to /login (except for the auth
///    screens + splash); authenticated users on an auth screen are sent home.
///  * Deep links: `/details/:id` and `/chat/:chatId` resolve their arguments
///    either from `extra` (in-app navigation) or from Firestore (cold deep
///    link / push tap), so notification + share links open the right screen.
class AppRouter {
  AppRouter._();

  static final _refresh = _AuthRefresh(FirebaseAuth.instance.authStateChanges());

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final loc = state.matchedLocation;

      final onSplash = loc == AppRoutes.splash;
      final onAuthFlow = loc == AppRoutes.login ||
          loc == AppRoutes.signup ||
          loc == AppRoutes.forgotPassword;

      // Let the splash screen run its own animation/redirect.
      if (onSplash) return null;

      if (!loggedIn && !onAuthFlow) return AppRoutes.login;
      if (loggedIn && onAuthFlow) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.nSplash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.nLogin,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: AppRoutes.nSignup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.nForgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.nHome,
        builder: (_, state) {
          final q = state.uri.queryParameters['q'] ?? '';
          final tab = int.tryParse(
                  state.uri.queryParameters['tab'] ?? '0') ??
              0;
          return BottomNavScreen(initialTab: tab, initialSearch: q);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.nProfile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.schedule,
        name: AppRoutes.nSchedule,
        builder: (_, __) => const ScheduleScreen(),
      ),
      GoRoute(
        path: AppRoutes.createListing,
        name: AppRoutes.nCreateListing,
        builder: (_, __) => const CreateListingScreen(),
      ),
      GoRoute(
        path: AppRoutes.map,
        name: AppRoutes.nMap,
        builder: (_, __) => const MapScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.nSettings,
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.help,
        name: AppRoutes.nHelp,
        builder: (_, __) => const HelpSupportPage(),
      ),
      GoRoute(
        path: AppRoutes.chatInboxScreen,
        name: AppRoutes.nChatInbox,
        builder: (_, __) => const ChatsInboxScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.nNotifications,
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ── Deep-linkable: Sale details ─────────────────────────────
      // In-app: context.pushNamed(nDetails, pathParameters:{'id': id},
      //                            extra: saleMap)
      // Deep link: /details/<id>  → fetched from Firestore.
      GoRoute(
        path: '${AppRoutes.details}/:id',
        name: AppRoutes.nDetails,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            return SaleDetailsScreen(
              sale: Map<String, dynamic>.from(extra),
            );
          }
          final id = state.pathParameters['id']!;
          return _SaleDetailsLoader(saleId: id);
        },
      ),

      // ── Deep-linkable: Individual chat ──────────────────────────
      GoRoute(
        path: '${AppRoutes.chat}/:chatId',
        name: AppRoutes.nChat,
        builder: (context, state) {
          final extra = state.extra;
          final chatId = state.pathParameters['chatId']!;
          if (extra is Map) {
            return ChatScreen(
              chatId: chatId,
              otherUserName: extra['otherUserName']?.toString() ?? 'Chat',
              otherUserId: extra['otherUserId']?.toString() ?? '',
            );
          }
          return _ChatLoader(chatId: chatId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}

/// Bridges a Firebase auth [Stream] into a [Listenable] so GoRouter re-runs
/// its `redirect` whenever the sign-in state changes.
class _AuthRefresh extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  _AuthRefresh(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Fetches a sale by id for cold deep links / push taps.
class _SaleDetailsLoader extends StatelessWidget {
  final String saleId;
  const _SaleDetailsLoader({required this.saleId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('sales').doc(saleId).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE8843A)),
            ),
          );
        }
        if (!snap.hasData || !(snap.data?.exists ?? false)) {
          return const Scaffold(
            body: Center(child: Text('This listing is no longer available.')),
          );
        }
        final data = Map<String, dynamic>.from(snap.data!.data()!);
        data['id'] = saleId;
        return SaleDetailsScreen(sale: data);
      },
    );
  }
}

/// Resolves chat metadata (other participant) for cold deep links.
class _ChatLoader extends StatelessWidget {
  final String chatId;
  const _ChatLoader({required this.chatId});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('chats').doc(chatId).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2B5BA8)),
            ),
          );
        }
        final data = snap.data?.data();
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('Conversation not found.')),
          );
        }
        final participants = List<String>.from(data['participants'] ?? []);
        final otherId = participants.firstWhere(
          (id) => id != me?.uid,
          orElse: () => '',
        );
        final names = Map<String, dynamic>.from(data['participantNames'] ?? {});
        return ChatScreen(
          chatId: chatId,
          otherUserName: names[otherId]?.toString() ?? 'Chat',
          otherUserId: otherId,
        );
      },
    );
  }
}
