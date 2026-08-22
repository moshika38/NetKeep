import 'package:flutter/material.dart';
import 'package:netkeep/services/ad_manager.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.bar.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalLayout(
      appBarTitle: 'Terms & Conditions',
      badge: 'Terms of Service',
      title: 'Terms & Conditions',
      meta: 'Application: NetKeep • Effective Date: August 14, 2026',
      footer: '© 2026 SAPM (NetKeep). All rights reserved.',
      children: [
        _LegalParagraph(
          'These terms and conditions apply to the NetKeep app for mobile '
          'devices, together with any related services operated by SAPM '
          '(collectively, the "Application"). SAPM is hereby referred to as '
          'the "Service Provider".',
        ),
        _LegalParagraph(
          'By downloading or using the Application, you agree to these Terms '
          'and Conditions. You should read them carefully before using the '
          'Application.',
        ),
        _LegalHeading('License to Use the Application'),
        _LegalParagraph(
          'Subject to compliance with these Terms, the Service Provider grants '
          'you a limited, non-exclusive, non-transferable, revocable license '
          'to install and use the Application on a mobile device for personal '
          'or internal business purposes. Reverse engineering, decompiling, or '
          'modifying the source code is strictly prohibited.',
        ),
        _LegalHeading('Intellectual Property'),
        _LegalParagraph(
          'The Service Provider retains all intellectual property rights in '
          'the Application, including code, design, trademarks, service marks, '
          'trade names, and logos. Unauthorized copying, modification, or '
          'distribution is prohibited.',
        ),
        _LegalHeading('User Eligibility & Termination'),
        _LegalParagraph(
          'You must be at least 18 years of age to use the Application. '
          'Access may be suspended or terminated immediately if you breach '
          'these terms or engage in unlawful activities.',
        ),
        _LegalHeading('User-Generated Content & Acceptable Use'),
        _LegalParagraph(
          'You agree not to upload or post content that is illegal, '
          'defamatory, abusive, infringing on intellectual property rights, '
          'spam, or misleading. The Service Provider reserves the right to '
          'moderate, filter, or remove violating content.',
        ),
        _LegalHeading('Third-Party Services'),
        _LegalParagraph(
          'The Application integrates third-party services that operate under '
          'their own terms:',
        ),
        _LegalLinkBullet('AdMob Terms of Service'),
        _LegalLinkBullet('Facebook Terms of Service'),
        _LegalHeading('Device & Network Responsibilities'),
        _LegalCallout.warning(
          label: 'Device Security:',
          text: 'Do not root or jailbreak your device. Modifying the OS can '
              'expose your device to security vulnerabilities and malware, '
              'causing the Application to malfunction.',
        ),
        _LegalParagraph(
          'Certain functions require an active internet connection. You are '
          'responsible for any mobile carrier data charges (including roaming '
          'fees) incurred while using the Application.',
        ),
        _LegalHeading('Limitation of Liability'),
        _LegalParagraph(
          'To the fullest extent permitted by law, the Service Provider shall '
          'not be liable for any indirect, incidental, consequential, or '
          'punitive damages resulting from the use or inability to use the '
          'Application.',
        ),
        _LegalHeading('DSA Compliance (Digital Services Act)'),
        _LegalParagraph(
          null,
          spans: [
            TextSpan(
              text: 'For users in the European Union, the Service Provider '
                  'maintains a single point of contact at ',
            ),
            TextSpan(text: 'moshika38@gmail.com', style: _kLinkStyle),
            TextSpan(
              text: ' for regulatory and notice-and-action inquiries in '
                  'accordance with DSA obligations.',
            ),
          ],
        ),
        _LegalHeading('Governing Law'),
        _LegalParagraph(
          'These Terms are governed by the laws of the jurisdiction in which '
          'the Service Provider is established, excluding conflict of law '
          'rules.',
        ),
        _LegalHeading('Contact Us'),
        _LegalParagraph(
          'For questions or suggestions regarding these Terms and Conditions, '
          'reach out via:',
        ),
        _LegalParagraph(
          null,
          spans: [
            TextSpan(text: 'Email: '),
            TextSpan(text: 'moshika38@gmail.com', style: _kLinkStyle),
          ],
        ),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalLayout(
      appBarTitle: 'Privacy Policy',
      badge: 'Legal Document',
      title: 'Privacy Policy',
      meta: 'Application: NetKeep • Effective Date: August 14, 2026',
      footer: '© 2026 SAPM (NetKeep). All rights reserved.',
      children: [
        _LegalParagraph(
          'This privacy policy applies to the NetKeep app for mobile devices, '
          'together with any related services operated by SAPM (collectively, '
          'the "Application"). SAPM is hereby referred to as the "Service '
          'Provider".',
        ),
        _LegalHeading('Information Collection and Use'),
        _LegalParagraph(
          'The Application collects information when you download and use it. '
          'This information may include information such as:',
        ),
        _LegalBullet("Your device's Internet Protocol (IP) address"),
        _LegalBullet(
          'The pages of the Application that you visit, the time and date of '
          'your visit, and the time spent on those pages',
        ),
        _LegalBullet('The time spent on the Application'),
        _LegalBullet('Your mobile operating system'),
        _LegalParagraph(
          'For a better experience while using the Application, the Service '
          'Provider may require you to provide certain personally identifiable '
          'information. The information requested will be retained and used as '
          'described in this privacy policy.',
        ),
        _LegalHeading('Cookies and Tracking Technologies'),
        _LegalParagraph(
          'The Application or its third-party SDKs may use cookies, SDKs, '
          'pixels, and similar technologies to support functionality, '
          'analytics, or service delivery. Where required by applicable law, '
          'the Service Provider will obtain consent before using non-essential '
          'tracking technologies.',
        ),
        _LegalHeading('Your Rights'),
        _LegalParagraph(
          null,
          spans: [
            TextSpan(
              text: 'You may request access to, correction of, or deletion of '
                  'your personal data held by the Service Provider. To exercise '
                  'these rights, or to withdraw consent where processing is '
                  'based on consent, contact the Service Provider at ',
            ),
            TextSpan(text: 'moshika38@gmail.com', style: _kLinkStyle),
            TextSpan(text: '.'),
          ],
        ),
        _LegalHeading('California Privacy Rights (CCPA/CPRA)'),
        _LegalParagraph(
          null,
          spans: [
            TextSpan(
              text: 'If you are a California resident, you have the right to '
                  'know what personal information is collected, the right to '
                  'delete personal information, the right to opt out of the '
                  'sale or sharing of personal information, and the right to '
                  'non-discrimination for exercising these rights. To exercise '
                  'your rights, contact: ',
            ),
            TextSpan(text: 'moshika38@gmail.com', style: _kLinkStyle),
            TextSpan(text: '.'),
          ],
        ),
        _LegalHeading('Third Party Access'),
        _LegalParagraph(
          'Only aggregated, anonymized data is periodically transmitted to '
          'external services to aid the Service Provider in improving the '
          'Application and their service. The Application utilizes third-party '
          'services that have their own Privacy Policies:',
        ),
        _LegalLinkBullet('AdMob Privacy Policy'),
        _LegalLinkBullet('Facebook Privacy Policy'),
        _LegalHeading('International Data Transfers'),
        _LegalParagraph(
          'The Service Provider or its third-party providers may transfer '
          'personal data outside your country of residence, including outside '
          'the European Economic Area (EEA). Mechanisms used include:',
        ),
        _LegalBullet(
          'Standard Contractual Clauses (SCCs) approved by the European '
          'Commission',
        ),
        _LegalBullet('Adequacy decisions or other legally recognized transfer mechanisms'),
        _LegalBullet('Your consent, where required and legally permitted'),
        _LegalHeading('Opt-Out Rights & Deletion'),
        _LegalCallout.note(
          text: 'You can stop all collection of information by simply '
              'uninstalling the Application using the standard uninstall '
              'processes available for your mobile device.',
        ),
        _LegalParagraph(
          null,
          spans: [
            TextSpan(
              text: 'To request permanent deletion of your personal data, '
                  'email ',
            ),
            TextSpan(text: 'moshika38@gmail.com', style: _kLinkStyle),
            TextSpan(text: '.'),
          ],
        ),
        _LegalHeading('Data Retention Policy'),
        _LegalBullet(
          'Retained for the duration of use plus 12 months thereafter.',
          boldLabel: 'User Provided Data:',
        ),
        _LegalBullet(
          'Retained for up to 24 months from collection.',
          boldLabel: 'Automatically Collected Data:',
        ),
        _LegalBullet(
          'Retained indefinitely.',
          boldLabel: 'Aggregated and Anonymized Data:',
        ),
        _LegalHeading("Children's Privacy"),
        _LegalParagraph(
          'The Application is not intended for children under 18 years of age. '
          'The Service Provider does not knowingly collect personally '
          'identifiable information from children under 18. If discovered, '
          'such data will be immediately deleted.',
        ),
        _LegalHeading('Security'),
        _LegalParagraph(
          'Physical, electronic, and procedural safeguards are maintained to '
          'protect the confidentiality and security of your information '
          'processed by the Service Provider.',
        ),
        _LegalHeading('Data Breach Notification'),
        _LegalParagraph(
          'In case of a data breach affecting your personal information, the '
          'Service Provider will notify you according to applicable legal '
          'requirements.',
        ),
        _LegalHeading('Changes to this Policy'),
        _LegalParagraph(
          'This Privacy Policy may be updated periodically. Any material '
          'changes will be published here with an updated effective date.',
        ),
        _LegalHeading('Contact Us'),
        _LegalParagraph(
          'If you have any questions regarding privacy while using the '
          'Application, please contact:',
        ),
        _LegalParagraph(
          null,
          spans: [
            TextSpan(text: 'Email: '),
            TextSpan(text: 'moshika38@gmail.com', style: _kLinkStyle),
          ],
        ),
      ],
    );
  }
}

const _kLinkStyle = TextStyle(
  color: AppColors.primaryColor,
  fontWeight: FontWeight.w600,
  decoration: TextDecoration.underline,
  decorationColor: Color(0x6600F0FF),
);

const _kWarningCalloutBg = Color(0x1AFFB800);
const _kNoteCalloutBg = Color(0x1A00FFA3);

const _kBoldStyle = TextStyle(color: AppColors.white, fontWeight: FontWeight.w700);

class _LegalLayout extends StatelessWidget {
  final String appBarTitle;
  final String badge;
  final String title;
  final String meta;
  final String footer;
  final List<Widget> children;

  const _LegalLayout({
    required this.appBarTitle,
    required this.badge,
    required this.title,
    required this.meta,
    required this.footer,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AdManager.instance.showAdIfReady(
          onComplete: () {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: NetKeepAppBar(title: appBarTitle),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegalBadge(text: badge),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: textTheme.titleLarge!.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    style: textTheme.bodySmall!.copyWith(fontSize: 12),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1),
                  ),
                  ...children,
                  _LegalFooter(text: footer),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalBadge extends StatelessWidget {
  final String text;
  const _LegalBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _LegalHeading extends StatelessWidget {
  final String text;
  const _LegalHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.primaryColor, width: 3),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegalParagraph extends StatelessWidget {
  final String? text;
  final List<InlineSpan>? spans;
  const _LegalParagraph(this.text, {this.spans});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 13.5,
      height: 1.6,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: text != null
          ? Text(text!, style: style)
          : Text.rich(TextSpan(style: style, children: spans)),
    );
  }
}

class _LegalBullet extends StatelessWidget {
  final String text;
  final String? boldLabel;
  const _LegalBullet(this.text, {this.boldLabel});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 13.5,
      height: 1.6,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  if (boldLabel != null)
                    TextSpan(text: '$boldLabel ', style: _kBoldStyle),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLinkBullet extends StatelessWidget {
  final String text;
  const _LegalLinkBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: _kLinkStyle.copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalCallout extends StatelessWidget {
  final String label;
  final String text;
  final Color accent;
  final Color background;

  const _LegalCallout.warning({required this.label, required this.text})
      : accent = AppColors.warningColor,
        background = _kWarningCalloutBg;

  const _LegalCallout.note({required this.text})
      : label = '',
        accent = AppColors.secondaryColor,
        background = _kNoteCalloutBg;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 13,
      height: 1.6,
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(
              text: label == '' ? '' : '$label ',
              style: _kBoldStyle.copyWith(color: accent),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  final String text;
  const _LegalFooter({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11.5),
      ),
    );
  }
}
