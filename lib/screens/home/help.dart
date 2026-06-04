import 'package:flutter/material.dart';

import 'legal_screen.dart';
import 'support_chat_screen.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  static const _blue     = Color(0xFF2B5BA8);
  static const _darkBlue = Color(0xFF1B3A6B);
  static const _lightBlue = Color(0xFFDFECFF);

  final List<bool> _open = List.filled(5, false);

  final _faqs = const [
    (
      q: 'How do I create a yard sale listing?',
      a: 'Tap the "+" button on the home screen. Fill in your sale details — date, time, address, and a description of what you\'re selling. Add photos to attract more buyers.'
    ),
    (
      q: 'How do I find yard sales near me?',
      a: 'Enable Location Services in Settings. The map on the home screen shows all active sales within your selected search radius.'
    ),
    (
      q: 'Can I edit or delete my listing?',
      a: 'Yes! Go to your profile, tap the listing you want to change, and select Edit or Delete from the options.'
    ),
    (
      q: 'How do I contact a seller?',
      a: 'Open a yard sale listing and tap "Contact Seller". This opens a direct message thread with the host.'
    ),
    (
      q: 'Is the app free to use?',
      a: 'Completely free — for both buyers and sellers. No listing fees, no commissions.'
    ),
  ];

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
          'Help & Support',
          style: TextStyle(
            color: _darkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Banner ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _lightBlue,
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
                  child: const Icon(Icons.support_agent, color: _blue, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How can we help?',
                        style: TextStyle(
                          color: _darkBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Browse FAQs or reach out directly.',
                        style: TextStyle(color: _blue, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── FAQs ────────────────────────────────────────────────
          const _SectionLabel('FREQUENTLY ASKED QUESTIONS'),
          const SizedBox(height: 8),
          ...List.generate(_faqs.length, (i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E5EA)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: Text(
                  _faqs[i].q,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                ),
                trailing: Icon(
                  _open[i] ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: _blue,
                ),
                onExpansionChanged: (v) => setState(() => _open[i] = v),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      _faqs[i].a,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF3A3A3C),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // ── Contact ─────────────────────────────────────────────
          const _SectionLabel('CONTACT US'),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.email_outlined,
            label: 'Email Support',
            subtitle: 'support@yardsalesapp.com',
            onTap: () => _snack(context, 'Email support coming soon!'),
          ),
          _ContactTile(
            icon: Icons.chat_bubble_outline,
            label: 'Live Chat',
            subtitle: 'Mon–Fri, 9 am – 5 pm PT',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportChatScreen()),
            ),
          ),
          _ContactTile(
            icon: Icons.bug_report_outlined,
            label: 'Report a Bug',
            subtitle: 'Help us improve the app',
            onTap: () => _showBugDialog(context),
          ),

          const SizedBox(height: 24),

          // ── Legal ───────────────────────────────────────────────
          const _SectionLabel('LEGAL'),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalScreen(
                  title: 'Terms of Service',
                  lastUpdated: 'June 2026',
                  sections: termsOfServiceSections,
                ),
              ),
            ),
          ),
          _ContactTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalScreen(
                  title: 'Privacy Policy',
                  lastUpdated: 'June 2026',
                  sections: privacyPolicySections,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'YardSales App  •  v1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showBugDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report a Bug'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the issue you encountered…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5BA8)),
            onPressed: () {
              Navigator.pop(context);
              // TODO: send bug report to backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report submitted — thank you!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8E8E93),
          letterSpacing: 1.1,
        ),
      );
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5EA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDFECFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2B5BA8), size: 20),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey))
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}