import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../home/chat.dart';

class ChatsInboxScreen extends StatelessWidget {
  const ChatsInboxScreen({super.key});

  static const _blue     = Color(0xFF2B5BA8);
  static const _darkBlue = Color(0xFF1B3A6B);

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chats',
          style: TextStyle(
            color: _darkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: me.uid)
                  .orderBy('lastMessageAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _blue),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _EmptyState();
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 76),
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final chatId = docs[i].id;

                    // Resolve other user
                    final participants =
                        List<String>.from(data['participants'] ?? []);
                    final otherId = participants.firstWhere(
                      (id) => id != me.uid,
                      orElse: () => '',
                    );
                    final names = Map<String, dynamic>.from(
                        data['participantNames'] ?? {});
                    final otherName =
                        names[otherId] as String? ?? 'Unknown';

                    // Unread badge
                    final unreadMap =
                        Map<String, dynamic>.from(data['unreadCount'] ?? {});
                    final unread = (unreadMap[me.uid] as int?) ?? 0;

                    // Last message
                    final lastMsg = data['lastMessage'] as String? ?? '';
                    final lastAt =
                        (data['lastMessageAt'] as Timestamp?)?.toDate();
                    final saleTitle = data['saleTitle'] as String? ?? '';

                    return _InboxTile(
                      chatId: chatId,
                      otherUserId: otherId,
                      otherName: otherName,
                      saleTitle: saleTitle,
                      lastMessage: lastMsg,
                      lastAt: lastAt,
                      unreadCount: unread,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Single inbox row
// ─────────────────────────────────────────────────────────────

class _InboxTile extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String otherName;
  final String saleTitle;
  final String lastMessage;
  final DateTime? lastAt;
  final int unreadCount;

  const _InboxTile({
    required this.chatId,
    required this.otherUserId,
    required this.otherName,
    required this.saleTitle,
    required this.lastMessage,
    required this.lastAt,
    required this.unreadCount,
  });

  String get _timeLabel {
    if (lastAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(lastAt!);
    if (diff.inMinutes < 1)  return 'now';
    if (diff.inHours < 1)    return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays < 7)     return DateFormat('EEE').format(lastAt!);
    return DateFormat('MMM d').format(lastAt!);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFFB8D0F8),
        child: Text(
          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF2B5BA8),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: TextStyle(
                fontWeight:
                    hasUnread ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
                color: const Color(0xFF1A1A2E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _timeLabel,
            style: TextStyle(
              fontSize: 11,
              color: hasUnread
                  ? const Color(0xFF2B5BA8)
                  : const Color(0xFF8E8E93),
              fontWeight:
                  hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (saleTitle.isNotEmpty)
            Text(
              saleTitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF2B5BA8),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  lastMessage.isEmpty ? 'Start a conversation' : lastMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasUnread
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFF8E8E93),
                    fontWeight: hasUnread
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B5BA8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserName: otherName,
            otherUserId: otherUserId,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFDFECFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                size: 40, color: Color(0xFF2B5BA8)),
          ),
          const SizedBox(height: 16),
          const Text('No conversations yet',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          const Text('Tap "Contact Seller" on a sale to start chatting.',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}