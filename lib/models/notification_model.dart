import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types raised by the app. Stored as a plain string in
/// Firestore so it stays forward-compatible if new kinds are added later.
class NotificationType {
  static const interest    = 'interest';     // a buyer expressed interest
  static const purchased   = 'purchased';    // an item was purchased
  static const saleComplete = 'sale_complete'; // a sale was completed
  static const message     = 'message';       // new chat message
  static const generic     = 'generic';
}

/// A single notification record persisted under `notifications/{id}`.
///
/// Mirrors the FCM payload so the same object can be built either from a
/// Firestore document (history list) or from an incoming `RemoteMessage`.
class AppNotification {
  final String id;
  final String userId;   // recipient uid
  final String title;
  final String body;
  final String type;
  final String? saleId;  // deep-link target (optional)
  final String? chatId;  // deep-link target (optional)
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = NotificationType.generic,
    this.saleId,
    this.chatId,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      type: d['type'] as String? ?? NotificationType.generic,
      saleId: d['saleId'] as String?,
      chatId: d['chatId'] as String?,
      read: d['read'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Map used when writing the document. `createdAt` uses a server timestamp
  /// so ordering is consistent across clients.
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        if (saleId != null) 'saleId': saleId,
        if (chatId != null) 'chatId': chatId,
        'read': read,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
