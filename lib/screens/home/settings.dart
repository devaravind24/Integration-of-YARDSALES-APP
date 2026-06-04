import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../routes/app_routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _locationEnabled = true;
  String _radius = '10 miles';

  static const _blue = Color(0xFF2B5BA8);
  static const _darkBlue = Color(0xFF1B3A6B);

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
        title: const Text(
          'Settings',
          style: TextStyle(
            color: _darkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        children: [
          // ── Account ────────────────────────────────────────────
          _SectionHeader(title: 'Account'),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (_, snap) {
              final user = snap.data;
              final name = (user?.displayName ?? '').trim();
              final email = user?.email ?? '';
              return _SettingsTile(
                icon: Icons.person_outline,
                label: name.isNotEmpty ? name : 'Your Account',
                subtitle: email,
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => context.pushNamed(AppRoutes.nProfile),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            subtitle: 'Update your login password',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showChangePasswordDialog(context),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Preferences ────────────────────────────────────────
          _SectionHeader(title: 'Preferences'),
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDFECFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_outlined, color: _blue, size: 20),
            ),
            title: const Text('Push Notifications',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: const Text('Get alerts for nearby yard sales',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            value: _notifications,
            activeColor: _blue,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDFECFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on_outlined, color: _blue, size: 20),
            ),
            title: const Text('Location Services',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: const Text('Allow app to use your location',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            value: _locationEnabled,
            activeColor: _blue,
            onChanged: (v) => setState(() => _locationEnabled = v),
          ),

          // Search radius
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFECFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.radar, color: _blue, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Search Radius',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      Text('Show sales within this range',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: _radius,
                  underline: const SizedBox(),
                  style: const TextStyle(color: _blue, fontWeight: FontWeight.w600),
                  items: ['5 miles', '10 miles', '25 miles', '50 miles']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) { if (v != null) setState(() => _radius = v); },
                ),
              ],
            ),
          ),

          const Divider(height: 24, indent: 16, endIndent: 16),

          // ── Danger Zone ────────────────────────────────────────
          _SectionHeader(title: 'Account Actions'),
          _SettingsTile(
            icon: Icons.logout,
            label: 'Sign Out',
            iconColor: Colors.orange,
            labelColor: Colors.orange,
            onTap: () => _showSignOutDialog(context),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            label: 'Delete Account',
            iconColor: Colors.red,
            labelColor: Colors.red,
            onTap: () => _showDeleteDialog(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────

  void _showChangePasswordDialog(BuildContext context) {
    final ctrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password (min 6 characters)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B5BA8)),
              onPressed: saving
                  ? null
                  : () async {
                      final newPass = ctrl.text.trim();
                      if (newPass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Password must be at least 6 characters.')),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        await FirebaseAuth.instance.currentUser
                            ?.updatePassword(newPass);
                        if (context.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                e.message ?? 'Failed to update password.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(context);
              await NotificationService.instance.clearToken();
              await AuthService().signOut();
              if (context.mounted) {
                context.goNamed(AppRoutes.nLogin);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This is permanent and cannot be undone. All your data will be erased.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              // TODO: delete account logic
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8E8E93),
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2B5BA8);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? blue, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: labelColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}