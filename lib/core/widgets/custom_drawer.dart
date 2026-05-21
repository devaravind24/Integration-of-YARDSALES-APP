import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import 'yard_sale_logo.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Color(0xFF2B5BA8)),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const YardSaleLogo(size: 50, wordmarkSize: 13, gap: 4),
                  const SizedBox(height: 6),
                  const Text(
                    'Yard Sale Treasure Map',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Text(
                    'San Jose, CA',
                    style:
                        TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (_, snap) {
                      final name = (snap.data?.displayName ?? '').trim();
                      final email = snap.data?.email ?? '';
                      final fallback = email.contains('@')
                          ? email.split('@').first
                          : '';
                      final shown = name.isNotEmpty ? name : fallback;
                      if (shown.isEmpty) return const SizedBox.shrink();
                      return Text(
                        'Signed in as $shown',
                        style: const TextStyle(
                          color: Color(0xFF2B5BA8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    _DrawerItem(
                      icon: Icons.edit_outlined,
                      label: 'Edit Profile',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                    ),
                    _DrawerItem(
                      icon: Icons.location_on_outlined,
                      label: 'Explore',
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerItem(
                      icon: Icons.bookmark_outline,
                      label: 'Saved',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.schedule),
                    ),
                    _DrawerItem(icon: Icons.tag,                 label: 'Updates',        onTap: () {}),
                    _DrawerItem(icon: Icons.email_outlined,      label: 'Notifications',  onTap: () {}),
                    _DrawerItem(icon: Icons.chat_bubble_outline, label: 'Chats',          onTap: () {}),
                    _DrawerItem(icon: Icons.settings_outlined,   label: 'Settings',       onTap: () {}),
                    _DrawerItem(icon: Icons.help_outline,        label: 'Help & Support', onTap: () {}),
                    _DrawerItem(
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () => _logout(context),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),

            // ── READY TO SELL CTA (always pinned to bottom) ─
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.createListing);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFECFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8D0F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone_android,
                            color: Color(0xFF2B5BA8), size: 30),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Ready to Sell?',
                                style: TextStyle(
                                    color: Color(0xFF1B3A6B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            SizedBox(height: 2),
                            Text(
                              'List your items and reach nearby buyers',
                              style: TextStyle(
                                  color: Color(0xFF2B5BA8), fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF1A1A2E), size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: color)),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }
}
