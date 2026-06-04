import 'package:flutter/material.dart';

/// A reusable, scrollable legal document page used for both Terms of Service
/// and Privacy Policy. Pass a [title] and a list of [LegalSection]s.
///
/// NOTE: the text below is generic placeholder content for a yard-sale
/// marketplace app and is **not** legal advice. Replace it with text reviewed
/// by a professional before any real launch.
class LegalScreen extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  const LegalScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

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
        title: Text(
          title,
          style: const TextStyle(
            color: _darkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Last updated: $lastUpdated',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8E8E93),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          ...sections.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.heading,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.body,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF3A3A3C),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'YardSales App  •  v1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}

// ── Content: Terms of Service ──────────────────────────────────────────
const termsOfServiceSections = <LegalSection>[
  LegalSection(
    '1. Acceptance of Terms',
    'By creating an account or using YardSales App ("the App"), you agree to '
        'these Terms of Service. If you do not agree, please do not use the App. '
        'These terms apply to all buyers and sellers.',
  ),
  LegalSection(
    '2. Using the App',
    'You must be at least 18 years old to use YardSales App. You are '
        'responsible for keeping your account credentials secure and for all '
        'activity that happens under your account.',
  ),
  LegalSection(
    '3. Listings',
    'Sellers are solely responsible for the accuracy of their listings, '
        'including item descriptions, prices, photos, dates, and pickup '
        'locations. You may not list illegal, stolen, counterfeit, or '
        'prohibited items.',
  ),
  LegalSection(
    '4. Transactions',
    'YardSales App is a discovery and messaging platform only. We do not '
        'process payments, handle shipping, or take part in any sale. All '
        'transactions happen directly between buyers and sellers, who are '
        'responsible for arranging payment and pickup safely.',
  ),
  LegalSection(
    '5. User Conduct',
    'You agree not to harass other users, post spam, impersonate others, or '
        'misuse the messaging feature. We may suspend or remove accounts that '
        'violate these terms.',
  ),
  LegalSection(
    '6. Disclaimer',
    'The App is provided "as is" without warranties of any kind. We are not '
        'liable for the conduct of any user or the condition, safety, or '
        'legality of any item listed.',
  ),
  LegalSection(
    '7. Changes',
    'We may update these terms from time to time. Continued use of the App '
        'after changes take effect means you accept the revised terms.',
  ),
  LegalSection(
    '8. Contact',
    'Questions about these terms? Email us at support@yardsalesapp.com.',
  ),
];

// ── Content: Privacy Policy ────────────────────────────────────────────
const privacyPolicySections = <LegalSection>[
  LegalSection(
    '1. Information We Collect',
    'We collect the information you provide when you sign up (name, email, '
        'phone, and role), the listings and photos you create, messages you '
        'send, and your approximate location when you enable location services '
        'to find nearby sales.',
  ),
  LegalSection(
    '2. How We Use Your Information',
    'We use your information to operate core features: showing nearby sales, '
        'enabling buyer–seller chat, sending notifications about your sales and '
        'messages, and improving the App.',
  ),
  LegalSection(
    '3. Firebase & Third Parties',
    'YardSales App uses Google Firebase for authentication, database '
        '(Firestore), image storage, and push notifications (FCM). Map features '
        'use Google Maps. These providers process data under their own privacy '
        'policies.',
  ),
  LegalSection(
    '4. Notifications',
    'If you enable push notifications, we store a device token to deliver '
        'alerts about interest in your listings and new messages. You can turn '
        'notifications off at any time in your device settings.',
  ),
  LegalSection(
    '5. Data Sharing',
    'We do not sell your personal data. Your display name is visible to users '
        'you chat with. Listing details you post are visible to other users of '
        'the App.',
  ),
  LegalSection(
    '6. Your Choices',
    'You can edit your profile, delete your listings, and request account '
        'deletion at any time from the Settings screen. Deleting your account '
        'removes your profile and listings.',
  ),
  LegalSection(
    '7. Security',
    'We rely on Firebase security rules to restrict access so that only you '
        'can modify your own data and only chat participants can read their '
        'conversations. No system is perfectly secure, so please use a strong, '
        'unique password.',
  ),
  LegalSection(
    '8. Contact',
    'Privacy questions? Email us at support@yardsalesapp.com.',
  ),
];
