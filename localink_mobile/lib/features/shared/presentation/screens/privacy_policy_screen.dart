import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_back_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(onPressed: () => context.pop()),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF1A1918),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Last Updated: July 2026',
                'Vocal for Sanatan ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '1. Information We Collect',
                '''• **Account Information**: Name, email, phone number, profile picture
• **Location Data**: Country, state, city, pincode, street address
• **Business Data**: Business listings, photos, catalog items (for business owners)
• **Usage Data**: App interactions, preferences, search history
• **Device Information**: Device type, OS version, unique identifiers''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '2. How We Use Your Information',
                '''• **Service Delivery**: To provide and improve our local business discovery platform
• **Authentication**: To verify and secure your account
• **Location Services**: To show businesses near you
• **Communication**: To send important updates about your account
• **Analytics**: To understand app usage and improve features
• **Support**: To respond to your inquiries and feedback''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '3. Data Sharing & Disclosure',
                '''We do not sell your personal data. We may share information only when:
• **With Your Consent**: When you explicitly authorize sharing
• **Service Providers**: With trusted third parties who help operate our app
• **Legal Requirements**: When required by law or to protect our rights
• **Business Transfers**: In connection with a merger or sale''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '4. Data Security',
                '''We implement industry-standard security measures including:
• Encryption of data in transit and at rest
• Secure authentication with JWT tokens
• Regular security audits and updates
• Access controls and authentication requirements''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '5. Your Rights & Choices',
                '''You have the right to:
• **Access**: Request a copy of your personal data
• **Correct**: Update or correct your information
• **Delete**: Request deletion of your account and data
• **Opt-out**: Disable certain data collection features
• **Export**: Receive your data in a portable format''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '6. Data Retention',
                '''We retain your data only as long as necessary to:
• Provide our services
• Comply with legal obligations
• Resolve disputes
• Enforce our agreements

Upon account deletion, your personal data is permanently removed within 30 days.''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '7. Children\'s Privacy',
                '''Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13. If we become aware of such collection, we will take immediate steps to delete it.''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '8. International Data Transfers',
                '''Your information may be transferred to and processed in countries other than your own. We ensure adequate protection is in place to safeguard your data in accordance with this Privacy Policy.''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '9. Changes to This Policy',
                '''We may update this Privacy Policy from time to time. We will notify you of significant changes by:
• Posting the new policy in the app
• Sending you an email notification
• Displaying a prominent notice in the app''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '10. Contact Us',
                '''If you have questions about this Privacy Policy, please contact us:
• **Email**: privacy.vocalforsanatan@gmail.com
• **In-App**: Use the Support screen in the app

We will respond to your inquiries within 30 days.''',
              ),
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
                  child: const Text(
                    'I Understand',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFFFF6600),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF1A1918),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF5F5C58),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
