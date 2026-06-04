import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Feature 4 — register the background message handler before runApp.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize push/local notifications once the user is (or becomes) signed in.
  // Calling init() is idempotent, so it's safe on every auth change.
  if (FirebaseAuth.instance.currentUser != null) {
    await NotificationService.instance.init();
  }
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      NotificationService.instance.init();
    }
  });

  runApp(const MyApp());
}
