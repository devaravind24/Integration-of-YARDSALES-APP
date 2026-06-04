import 'package:flutter/material.dart';

import 'routes/app_router.dart';

/// Root app widget.
///
/// Migrated to `MaterialApp.router` so navigation is driven by the centralized
/// GoRouter config (Feature 5). The previous `routes:`/`onGenerateRoute:` map
/// has been replaced by `AppRouter.router`.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Yard Sale Treasure Map',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
