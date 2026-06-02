import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  /// Firestore doc ID under `chats/`
  final String chatId;

  /// The OTHER person's display name (shown in AppBar)
  final String otherUserName;

  /// The OTHER person's UID
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  });

  // ── Factory: open or create a chat between current user and a seller ──
  static Future<ChatScreen> forSale({
    required BuildContext context,
    required String sellerId,
    required String sellerName,
    required String saleId,
    required String saleTitle,
  }) async {
    final me = FirebaseAuth.instance.currentUser!;
    // Deterministic chatId: sort UIDs so the same pair always gets the same doc
    final ids = [me.uid, sellerId]..sort();
    final chatId = '${ids[0]}_${ids[1]}_$saleId';

    final ref = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants':  [me.uid, sellerId],
        'participantNames': {
          me.uid:   me.displayName ?? me.email ?? 'Buyer',
          sellerId: sellerName,
        },
        'saleId':        saleId,
        'saleTitle':     saleTitle,
        'lastMessage':   '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {me.uid: 0, sellerId: 0},
        'createdAt':     FieldValue.serverTimestamp(),
      });
    }
    return ChatScreen(
      chatId: chatId,
      otherUserName: sellerName,
      otherUserId: sellerId,
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _blue      = Color(0xFF2B5BA8);
  static const _darkBlue  = Color(0xFF1B3A6B);
  static const _lightBlue = Color(0xFFDFECFF);

  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _me         = FirebaseAuth.instance.currentUser!;
  bool  _sending    = false;

  CollectionReference get _msgs => FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId)
      .collection('messages');

  DocumentReference get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Mark my unread count as 0 ──────────────────────────────
  Future<void> _markRead() async {
    await _chatRef.update({'unreadCount.${_me.uid}': 0});
  }

  // ── Send a text message ────────────────────────────────────
  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _textCtrl.clear();
    setState(() => _sending = true);
    await _send(type: 'text', text: text);
    setState(() => _sending = false);
  }

  // ── Pick and send an image ─────────────────────────────────
  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (picked == null) return;
    setState(() => _sending = true);

    try {
      final file = File(picked.path);
      final fileName =
          '${widget.chatId}/${_me.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref('chat_images/$fileName');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _send(type: 'image', imageUrl: url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send image.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Core send ──────────────────────────────────────────────
  Future<void> _send({
    required String type,
    String text = '',
    String imageUrl = '',
  }) async {
    final now = FieldValue.serverTimestamp();
    final batch = FirebaseFirestore.instance.batch();

    // 1. Add message doc
    final msgRef = _msgs.doc();
    batch.set(msgRef, {
      'senderId':  _me.uid,
      'type':      type,        // 'text' | 'image'
      'text':      text,
      'imageUrl':  imageUrl,
      'sentAt':    now,
      'readBy':    [_me.uid],  // sender has "read" it immediately
    });

    // 2. Update chat metadata + increment other user's unread count
    batch.update(_chatRef, {
      'lastMessage':   type == 'image' ? '📷 Image' : text,
      'lastMessageAt': now,
      'unreadCount.${widget.otherUserId}':
          FieldValue.increment(1),
    });

    await batch.commit();
    _scrollToBottom();
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

  // ── Mark a message as read when rendered ──────────────────
  Future<void> _markMessageRead(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final readBy = List<String>.from(data['readBy'] ?? []);
    if (!readBy.contains(_me.uid)) {
      await _msgs.doc(doc.id).update({
        'readBy': FieldValue.arrayUnion([_me.uid]),
      });
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName,
                style: const TextStyle(
                    color: _darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            StreamBuilder<DocumentSnapshot>(
              stream: _chatRef.snapshots(),
              builder: (_, snap) {
                final title = (snap.data?.data()
                    as Map<String, dynamic>?)?['saleTitle'] as String?;
                if (title == null || title.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Text(title,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8E8E93)));
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),

          // ── Message list ─────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _msgs
                  .orderBy('sentAt', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _blue),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Say hello!',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc  = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _me.uid;

                    // Mark as read when rendered
                    if (!isMe) _markMessageRead(doc);

                    // Date separator
                    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
                    final showDate = i == 0 ||
                        !_sameDay(sentAt,
                            (docs[i - 1].data() as Map<String,
                                dynamic>)['sentAt'] as Timestamp?);

                    return Column(
                      children: [
                        if (showDate && sentAt != null)
                          _DateSeparator(date: sentAt),
                        _MessageBubble(
                          data: data,
                          isMe: isMe,
                          otherName: widget.otherUserName,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ────────────────────────────────────────
          _InputBar(
            controller: _textCtrl,
            sending: _sending,
            onSendText: _sendText,
            onSendImage: _sendImage,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime? a, Timestamp? bTs) {
    if (a == null || bTs == null) return false;
    final b = bTs.toDate();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final String otherName;

  const _MessageBubble({
    required this.data,
    required this.isMe,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    final type     = data['type'] as String? ?? 'text';
    final text     = data['text'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final sentAt   = (data['sentAt'] as Timestamp?)?.toDate();
    final readBy   = List<String>.from(data['readBy'] ?? []);
    final me       = FirebaseAuth.instance.currentUser!;
    final isRead   = isMe && readBy.length > 1; // other person has read it

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF2B5BA8)
                  : const Color(0xFFDFECFF),
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(16),
                topRight:    const Radius.circular(16),
                bottomLeft:  Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: type == 'image' && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      width: 220,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) => prog == null
                          ? child
                          : Container(
                              width: 220,
                              height: 160,
                              color: const Color(0xFFB8D0F8),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                  color: Color(0xFF2B5BA8), strokeWidth: 2),
                            ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),

          // Timestamp + read receipt
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sentAt != null)
                  Text(
                    DateFormat('h:mm a').format(sentAt),
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF8E8E93)),
                  ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 13,
                    color: isRead
                        ? const Color(0xFF2B5BA8)
                        : const Color(0xFF8E8E93),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Date separator
// ─────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final label = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day
        ? 'Today'
        : DateFormat('MMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF8E8E93))),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSendText;
  final VoidCallback onSendImage;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSendText,
    required this.onSendImage,
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
            // Image picker
            IconButton(
              icon: const Icon(Icons.image_outlined,
                  color: Color(0xFF2B5BA8), size: 26),
              onPressed: sending ? null : onSendImage,
            ),

            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message…',
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
                onSubmitted: (_) => onSendText(),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            sending
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                        color: Color(0xFF2B5BA8), strokeWidth: 2.5),
                  )
                : GestureDetector(
                    onTap: onSendText,
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