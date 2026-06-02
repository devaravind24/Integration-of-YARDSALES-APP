import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/navigation/bottom_nav_screen.dart';
import 'screens/home/sales_details_screen.dart';
import 'screens/home/splash_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/create_listing/create_listing.dart';
import 'screens/home/map_screen.dart';
import 'screens/home/settings.dart';
import 'screens/home/help.dart';
import 'screens/home/chat_inbox_screen.dart';
import 'screens/home/chat.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yard Sale Treasure Map',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.signup: (_) => const SignupScreen(),
        AppRoutes.home: (_) => const BottomNavScreen(),
        AppRoutes.schedule: (_) => const ScheduleScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.createListing: (_) => const CreateListingScreen(),
        AppRoutes.map: (_) => const MapScreen(),
        AppRoutes.settings: (_) => const SettingsPage(),
        AppRoutes.help: (_) => const HelpSupportPage(),
        AppRoutes.chatInboxScreen: (_) => const ChatsInboxScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.details) {
          final sale = settings.arguments as Map<String, dynamic>? ?? {};
          final saleStr = sale.map((k, v) => MapEntry(k, v.toString()));
          return MaterialPageRoute(
            builder: (_) => SaleDetailsScreen(sale: saleStr),
          );
        }
        return null;
      },
    );
  }
}
