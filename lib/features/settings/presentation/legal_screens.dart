import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Legal canonical language is English; these screens are intentionally
/// not localized.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.termsAndConditions)),
      body: const SafeArea(
        child: _LegalBody(sections: _termsSections),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      body: const SafeArea(
        child: _LegalBody(sections: _privacySections),
      ),
    );
  }
}

class _LegalBody extends StatelessWidget {
  const _LegalBody({required this.sections});

  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      itemCount: sections.length,
      itemBuilder: (_, index) {
        final (title, body) = sections[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(body, style: AppTypography.body),
            ],
          ),
        );
      },
    );
  }
}

const List<(String, String)> _termsSections = [
  (
    '1. Acceptance of Terms',
    'These Terms & Conditions govern your use of GISMAT, a dating '
        'application operated in the Republic of Azerbaijan. By creating an '
        'account or using the app you agree to be bound by these Terms. If '
        'you do not agree, do not use GISMAT.',
  ),
  (
    '2. Eligibility — 18+ Only',
    'You must be at least 18 years old to create an account or use GISMAT. '
        'By registering you confirm that you are 18 or older and that all '
        'information you provide, including your date of birth, is accurate. '
        'Accounts found to belong to minors are removed immediately.',
  ),
  (
    '3. Your Account',
    'You are responsible for keeping your login credentials confidential '
        'and for all activity that happens under your account. You may '
        'operate only one account, and it must represent you personally — '
        'impersonating another person is prohibited.',
  ),
  (
    '4. Subscriptions and Payments',
    'GISMAT offers optional paid plans: Pro at 3 AZN per week and Max at '
        '5 AZN per week. There is no free trial and no refunds are provided '
        'for any period, in whole or in part. You may cancel at any time; '
        'cancellation takes effect at the end of the current paid period, '
        'and you keep plan benefits until then. Prices may change with '
        'advance notice; changes never apply retroactively to a period you '
        'have already paid for.',
  ),
  (
    '5. Acceptable Use',
    'You agree not to: harass, threaten, or defame other users; post '
        'sexually explicit, violent, or illegal content; solicit money or '
        'financial information from other users; advertise commercial '
        'services; use bots or automation; scrape or collect other users\' '
        'data; or attempt to access accounts or systems that are not yours.',
  ),
  (
    '6. Safety',
    'GISMAT is a place to meet people, not a background-checking service. '
        'We do not verify the identity of every user. Exercise caution when '
        'communicating with or meeting people: meet in public places, tell '
        'someone you trust about your plans, and never send money to anyone '
        'you meet on the app. Use the in-app Report and Block tools whenever '
        'someone makes you uncomfortable.',
  ),
  (
    '7. Content You Post',
    'You keep ownership of the photos and text you upload, and you grant '
        'GISMAT a non-exclusive licence to display that content inside the '
        'app so the service can function. You must own or have the right to '
        'use everything you post. We may remove content that violates these '
        'Terms.',
  ),
  (
    '8. Termination',
    'We may suspend or permanently terminate your account, without refund, '
        'if you violate these Terms, applicable law, or the safety of other '
        'users — including for fake profiles, harassment, underage use, or '
        'financial scams. You may delete your account at any time from '
        'Settings.',
  ),
  (
    '9. Disclaimers and Liability',
    'GISMAT is provided "as is" without warranties of any kind. To the '
        'maximum extent permitted by law, GISMAT is not liable for damages '
        'arising from your use of the app or from interactions with other '
        'users, whether online or in person.',
  ),
  (
    '10. Changes to These Terms',
    'We may update these Terms from time to time. Material changes will be '
        'announced in the app. Continuing to use GISMAT after a change takes '
        'effect means you accept the updated Terms.',
  ),
  (
    '11. Governing Law and Contact',
    'These Terms are governed by the laws of the Republic of Azerbaijan. '
        'Questions about these Terms can be sent to '
        'ramizzmammadov@gmail.com.',
  ),
];

const List<(String, String)> _privacySections = [
  (
    '1. Introduction',
    'This Privacy Policy explains what data GISMAT collects, how it is '
        'used, and the choices you have. GISMAT is operated in the Republic '
        'of Azerbaijan and is designed to collect only what the service '
        'needs to work.',
  ),
  (
    '2. Data We Collect',
    'When you register and use GISMAT we collect: your email address; '
        'profile details you provide (name, date of birth, gender, '
        'interests, bio); the photos you upload; your approximate location '
        'while the app is in use; and basic technical data such as device '
        'type and app version.',
  ),
  (
    '3. Location — What Others See',
    'Your exact location and coordinates are NEVER shown to other users. '
        'Other users only ever see an approximate distance (for example '
        '"≈2 km away"), which is deliberately imprecise. Precise coordinates '
        'are used solely to compute these approximate distances and are not '
        'exposed through the app or its APIs.',
  ),
  (
    '4. How We Use Your Data',
    'We use your data to operate the service: showing your profile to '
        'other users, matching you with people nearby, delivering messages '
        'and notifications, processing subscriptions, and keeping the '
        'community safe (for example, reviewing reports of abuse).',
  ),
  (
    '5. What Other Users Can See',
    'Other users see your first name, age, photos, bio, verification '
        'badge, and approximate distance. They never see your email address, '
        'exact location, date of birth, or account settings.',
  ),
  (
    '6. Sharing With Third Parties',
    'We do not sell your personal data. We share data only with the '
        'infrastructure providers needed to run the app (hosting, storage, '
        'and push-notification delivery), and with authorities when the law '
        'requires it.',
  ),
  (
    '7. Data Retention',
    'Your data is kept while your account is active. If you delete your '
        'account, your profile, photos, messages, and location data are '
        'permanently deleted from our systems.',
  ),
  (
    '8. Your Rights — Deletion and Access',
    'You may delete your account and all associated data at any time from '
        'Settings → Delete account. You may also contact us to request a '
        'copy of your data, correction of inaccurate data, or deletion. We '
        'respond to such requests without undue delay.',
  ),
  (
    '9. Security',
    'Data is transmitted over encrypted connections and stored with '
        'access controls. No system is perfectly secure, but we take '
        'reasonable technical and organisational measures to protect your '
        'information.',
  ),
  (
    '10. Children',
    'GISMAT is strictly for adults aged 18 and over. We do not knowingly '
        'collect data from anyone under 18, and we delete such accounts as '
        'soon as they are identified.',
  ),
  (
    '11. Changes and Contact',
    'We may update this Privacy Policy; material changes will be announced '
        'in the app. For any privacy question or request, contact '
        'ramizzmammadov@gmail.com.',
  ),
];
