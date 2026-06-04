import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Feature 1 — Buyer ↔ Seller chat (service layer).
///
/// The chat *UI* already exists (`chat.dart`, `chat_inbox_screen.dart`). This
/// service centralizes the room-creation logic that previously lived inside
/// `ChatScreen.forSale`, so any screen (e.g. Sale Details) can start a chat
/// without duplicating Firestore code.
///
/// Firestore shape (unchanged from the existing implementation):
///   chats/{chatId}
///     participants: [buyerId, sellerId]
///     participantNames: { uid: name }
///     saleId, saleTitle
///     lastMessage, lastMessageAt
///     unreadCount: { uid: int }
///     createdAt
///   chats/{chatId}/messages/{messageId}
///     senderId, type, text, imageUrl, sentAt, readBy[]
///
/// The required spec fields (buyerId/sellerId/lastMessage/timestamp/
/// unreadCount + message senderId/receiverId/text/createdAt) are all covered:
/// buyerId/sellerId live inside `participants`, `timestamp` == `lastMessageAt`,
/// `unreadCount` is a per-user map (richer than a single int), `receiverId` is
/// derivable from `participants` minus `senderId`, and `createdAt` == `sentAt`.
class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  /// Deterministic id so the same buyer/seller/sale always resolves to the
  /// same room (prevents duplicate chats).
  String chatIdFor({
    required String buyerId,
    required String sellerId,
    required String saleId,
  }) {
    final ids = [buyerId, sellerId]..sort();
    return '${ids[0]}_${ids[1]}_$saleId';
  }

  /// Creates the chat room if it doesn't exist and returns its id.
  /// Safe to call repeatedly (idempotent).
  Future<String> openOrCreateChat({
    required String sellerId,
    required String sellerName,
    required String saleId,
    required String saleTitle,
  }) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw 'You must be signed in to contact a seller.';
    }
    if (me.uid == sellerId) {
      throw 'This is your own listing.';
    }

    final chatId =
        chatIdFor(buyerId: me.uid, sellerId: sellerId, saleId: saleId);
    final ref = _chats.doc(chatId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'participants': [me.uid, sellerId],
        'participantNames': {
          me.uid: me.displayName ?? me.email ?? 'Buyer',
          sellerId: sellerName,
        },
        'saleId': saleId,
        'saleTitle': saleTitle,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {me.uid: 0, sellerId: 0},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  /// Total unread count for the current user across all chats — handy for a
  /// badge on the inbox icon.
  Stream<int> unreadTotal() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((q) {
      var total = 0;
      for (final d in q.docs) {
        final m = Map<String, dynamic>.from(d.data()['unreadCount'] ?? {});
        total += (m[uid] as int?) ?? 0;
      }
      return total;
    });
  }
}
