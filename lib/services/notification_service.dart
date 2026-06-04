import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_model.dart';

/// Top-level background handler. MUST be a top-level (or static) function and
/// annotated so it survives release tree-shaking. Registered in `main.dart`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main(); nothing heavy should run here.
  // The OS displays the notification tray entry automatically for messages
  // that contain a `notification` payload.
  debugPrint('BG message: ${message.messageId}');
}

/// Feature 4 — Notifications.
///
/// Responsibilities:
///   * Request permission (iOS + Android 13+).
///   * Register/refresh the device FCM token under the user doc.
///   * Show a heads-up local notification when a push arrives in foreground.
///   * Write a durable `notifications/{id}` record so the in-app list and the
///     unread badge work even without a live push.
///
/// NOTE ON ACTUAL PUSH DELIVERY: a client app cannot securely send a push to
/// another device (that needs the FCM server key). The pattern used here is:
/// the client writes a notification *record* to Firestore, and a Cloud
/// Function (`functions/index.js`, included in this delivery) listens for new
/// records and sends the real FCM push to the recipient's stored token(s).
/// In foreground, the recipient also gets the heads-up via this service.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'yardsale_default',
    'Yard Sale Notifications',
    description: 'Sale activity, interest, and messages',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Call once after sign-in (and once at startup if already signed in).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Local notifications (for foreground heads-up display)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 3. Show foreground messages as a local notification.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // 4. Token registration + refresh.
    await _registerToken();
    _fcm.onTokenRefresh.listen((t) => _saveToken(t));
  }

  Future<void> _registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Remove this device's token on logout so the user stops receiving pushes.
  Future<void> clearToken() async {
    final uid = _auth.currentUser?.uid;
    final token = await _fcm.getToken();
    if (uid != null && token != null) {
      await _db.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    }
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Firestore notification records ─────────────────────────────────

  /// Writes a durable notification record for [userId]. The Cloud Function
  /// turns this into an actual push; this also powers the in-app list.
  Future<void> createRecord(AppNotification notification) async {
    await _db.collection('notifications').add(notification.toMap());
  }

  /// Convenience builders for the three sale events in the spec.
  Future<void> notifyInterest({
    required String sellerId,
    required String buyerName,
    required String saleId,
    required String saleTitle,
  }) {
    return createRecord(AppNotification(
      id: '',
      userId: sellerId,
      title: 'New interest in your sale',
      body: '$buyerName is interested in "$saleTitle".',
      type: NotificationType.interest,
      saleId: saleId,
    ));
  }

  Future<void> notifyPurchased({
    required String sellerId,
    required String buyerName,
    required String saleId,
    required String saleTitle,
  }) {
    return createRecord(AppNotification(
      id: '',
      userId: sellerId,
      title: 'Item purchased',
      body: '$buyerName purchased "$saleTitle".',
      type: NotificationType.purchased,
      saleId: saleId,
    ));
  }

  Future<void> notifySaleCompleted({
    required String userId,
    required String saleTitle,
    required String saleId,
  }) {
    return createRecord(AppNotification(
      id: '',
      userId: userId,
      title: 'Sale completed',
      body: 'Your sale "$saleTitle" is now marked complete.',
      type: NotificationType.saleComplete,
      saleId: saleId,
    ));
  }

  // ── Reads / mutations for the list screen ──────────────────────────

  Stream<List<AppNotification>> myNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(AppNotification.fromDoc).toList());
  }

  Stream<int> unreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((q) => q.docs.length);
  }

  Future<void> markRead(String id) =>
      _db.collection('notifications').doc(id).update({'read': true});

  Future<void> markAllRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final unread = await _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
