import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../profile/edit_profile_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isShopping = true;

  final AuthService _auth = AuthService();

  String _displayName = 'Loading...';
  String _email = '';

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();

    _loadProfile();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) {
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _email = user.email ?? '';

      if ((user.displayName ?? '').trim().isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _displayName = user.displayName!.trim();
        });

        return;
      }
    }

    final resolved = await _auth.resolveDisplayName();

    if (!mounted) return;

    setState(() {
      _displayName = resolved;
      _email = user?.email ?? '';
    });
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    context.goNamed(AppRoutes.nLogin);
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        _displayName.isNotEmpty ? _displayName.trim()[0].toUpperCase() : "?";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    // Show back button ONLY when Profile was pushed onto the
                    // stack (e.g. from the Home page's profile icon). When
                    // Profile is the bottom-nav tab, canPop() is false and
                    // we render a spacer so the title stays centered.
                    if (context.canPop())
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        'PROFILE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// PROFILE IMAGE
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8843A),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          color: Colors.black.withOpacity(0.10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 42,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openEditProfile,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _email,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 10),

              TextButton.icon(
                onPressed: _openEditProfile,
                icon: const Icon(Icons.edit_outlined),
                label: const Text("Edit Profile"),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Both sellers and shoppers can add sales to the map.\n'
                      'Sellers create listings with photos.\n'
                      'Shoppers map sales from newspapers and websites.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleToggle(
                            label: "I am Shopping",
                            selected: _isShopping,
                            onTap: () {
                              setState(() {
                                _isShopping = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleToggle(
                            label: "I am Selling",
                            selected: !_isShopping,
                            onTap: () {
                              setState(() {
                                _isShopping = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFE8843A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Subscriptions",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _ProfileOption(
                      icon: Icons.person_outline,
                      label: "Personal Information",
                      onTap: _openEditProfile,
                    ),
                    _ProfileOption(
                      icon: Icons.settings_outlined,
                      label: "Settings",
                      onTap: () => context.pushNamed(AppRoutes.nSettings),
                    ),
                    _ProfileOption(
                      icon: Icons.notifications_outlined,
                      label: "Notifications",
                      onTap: () {},
                    ),
                    _ProfileOption(
                      icon: Icons.help_outline,
                      label: "Help",
                      onTap: () => context.pushNamed(AppRoutes.nHelp),
                    ),
                    _ProfileOption(
                      icon: Icons.logout,
                      label: "Logout",
                      onTap: _logout,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: selected ? Colors.white : Colors.grey.shade100,
          border: Border.all(
            color: selected ? Colors.orange.shade300 : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: Colors.black87,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}