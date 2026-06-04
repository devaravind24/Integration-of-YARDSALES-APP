import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Live Chat with support.
///
/// A functional Firestore-backed support thread stored at
/// `support_chats/{uid}/messages`. The user's messages are saved in real time;
/// a lightweight auto-responder posts an acknowledgment so the experience is
/// interactive even without a human agent online. A real support team can read
/// and reply to these threads from a console.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  static const _blue = Color(0xFF2B5BA8);
  static const _darkBlue = Color(0xFF1B3A6B);
  static const _lightBlue = Color(0xFFDFECFF);

  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _user = FirebaseAuth.instance.currentUser;
  bool _sending = false;

  CollectionReference<Map<String, dynamic>> get _msgs =>
      FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_user?.uid ?? 'anonymous')
          .collection('messages');

  @override
  void initState() {
    super.initState();
    _seedWelcomeIfEmpty();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Posts a one-time welcome message from support when the thread is empty.
  Future<void> _seedWelcomeIfEmpty() async {
    final existing = await _msgs.limit(1).get();
    if (existing.docs.isEmpty) {
      await _msgs.add({
        'fromSupport': true,
        'text':
            'Hi! 👋 Welcome to YardSales support. How can we help you today? '
                'Our team is online Mon–Fri, 9 am – 5 pm PT.',
        'sentAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _textCtrl.clear();
    setState(() => _sending = true);

    try {
      await _msgs.add({
        'fromSupport': false,
        'senderId': _user?.uid,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();

      // Lightweight auto-acknowledgment (stands in for a live agent).
      await Future.delayed(const Duration(milliseconds: 700));
      await _msgs.add({
        'fromSupport': true,
        'text': _autoReply(text),
        'sentAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _autoReply(String userText) {
    final t = userText.toLowerCase();
    if (t.contains('refund') || t.contains('money') || t.contains('pay')) {
      return 'YardSales doesn\'t process payments — sales happen directly '
          'between buyer and seller. For payment disputes, please contact '
          'the other party through the listing chat.';
    }
    if (t.contains('listing') || t.contains('post') || t.contains('sell')) {
      return 'To manage a listing, open your Profile and tap the listing to '
          'edit or delete it. Need anything else?';
    }
    if (t.contains('password') || t.contains('login') || t.contains('sign')) {
      return 'For sign-in trouble, use "Forgot Password?" on the login screen '
          'to reset via email. Let us know if that doesn\'t work.';
    }
    return 'Thanks for reaching out! A support agent will follow up by email '
        'shortly. In the meantime, feel free to share more details here.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.support_agent, color: _blue, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Chat',
                  style: TextStyle(
                    color: _darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'YardSales Support',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _msgs.orderBy('sentAt', descending: false).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _blue),
                  );
                }
                final docs = snap.data?.docs ?? [];
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data();
                    final fromSupport = data['fromSupport'] as bool? ?? false;
                    final text = data['text'] as String? ?? '';
                    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
                    return _Bubble(
                      text: text,
                      isMe: !fromSupport,
                      time: sentAt,
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _textCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? time;

  const _Bubble({required this.text, required this.isMe, this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF2B5BA8) : const Color(0xFFDFECFF),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
              child: Text(
                DateFormat('h:mm a').format(time!),
                style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E5EA))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type your message…',
                  hintStyle:
                      const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            sending
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                        color: Color(0xFF2B5BA8), strokeWidth: 2.5),
                  )
                : GestureDetector(
                    onTap: onSend,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2B5BA8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
