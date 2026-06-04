import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

/// Feature 4 — Notification list screen.
///
/// Shows the signed-in user's notifications newest-first, with per-item and
/// bulk "mark as read" support. Styling matches the blue/white chat inbox.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _blue = Color(0xFF2B5BA8);
  static const _darkBlue = Color(0xFF1B3A6B);

  IconData _iconFor(String type) {
    switch (type) {
      case NotificationType.interest:
        return Icons.favorite_border;
      case NotificationType.purchased:
        return Icons.shopping_bag_outlined;
      case NotificationType.saleComplete:
        return Icons.check_circle_outline;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none;
    }
  }

  String _timeLabel(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(at);
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;

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
          'Notifications',
          style: TextStyle(
            color: _darkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => service.markAllRead(),
            child: const Text(
              'Mark all read',
              style: TextStyle(color: _blue, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: service.myNotifications(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _blue),
                  );
                }
                if (snap.hasError) {
                  return const _Empty(
                    message:
                        'Could not load notifications.\nPull down to retry.',
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const _Empty(message: 'No notifications yet.');
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (ctx, i) {
                    final n = items[i];
                    return ListTile(
                      onTap: () => service.markRead(n.id),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: n.read
                              ? const Color(0xFFF2F2F7)
                              : const Color(0xFFDFECFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_iconFor(n.type),
                            color: _blue, size: 22),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight:
                              n.read ? FontWeight.w500 : FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      subtitle: Text(
                        n.body,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8E8E93)),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _timeLabel(n.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF8E8E93)),
                          ),
                          if (!n.read) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: _blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
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

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});

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
            child: const Icon(Icons.notifications_none,
                size: 40, color: Color(0xFF2B5BA8)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }
}
