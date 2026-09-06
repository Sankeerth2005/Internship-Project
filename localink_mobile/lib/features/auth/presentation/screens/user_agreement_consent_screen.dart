import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/role_routes.dart';
import '../../../../core/network/app_error_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../../shared/presentation/widgets/app_background.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../shared/presentation/widgets/brand_icon_badge.dart';

class _Tok {
  static const Color primary = Color(0xFFFF6600);
  static const Color primaryLight = Color(0xFFFFF0E6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1A1918);
  static const Color medText = Color(0xFF5F5C58);
  static const Color muted = Color(0xFF9F9B96);
  static const Color surface = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// One-time User Agreement & Consent gate for newly created accounts.
/// Shown after auth and before Continue As / app access.
class UserAgreementConsentScreen extends ConsumerStatefulWidget {
  const UserAgreementConsentScreen({super.key});

  @override
  ConsumerState<UserAgreementConsentScreen> createState() =>
      _UserAgreementConsentScreenState();
}

class _UserAgreementConsentScreenState
    extends ConsumerState<UserAgreementConsentScreen> {
  bool _accepted = false;
  bool _submitting = false;

  Future<void> _agreeAndContinue() async {
    if (!_accepted || _submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.lightImpact();

    try {
      await ref.read(authProvider.notifier).acceptUserAgreement();
      if (!mounted) return;

      final auth = ref.read(authProvider);
      if (auth is! AuthAuthenticated) {
        context.go('/welcome');
        return;
      }

      HapticFeedback.mediumImpact();
      context.go(RoleRoutes.resolvePostAuthRoute(
        accountType: auth.userType,
        activeExperience: auth.activeExperience,
        needsExperienceSelection: auth.needsExperienceSelection,
        needsUserAgreement: auth.needsUserAgreement,
      ));
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      AppFeedback.showError(context, AppErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthAuthenticated && auth is! AuthLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/welcome');
      });
    }

    final size = MediaQuery.of(context).size;
    final hPad = size.width < 600 ? _Tok.xl : _Tok.xxl;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _Tok.white,
        body: AppBackground(
          showCenterWarmth: true,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, _Tok.xl, hPad, _Tok.lg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: BrandIconBadge.om(size: 56)),
                          const SizedBox(height: _Tok.lg),
                          const Text(
                            'Vocal for Sanatan – User Agreement & Consent',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _Tok.charcoal,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: _Tok.sm),
                          const Text(
                            'Welcome to Vocal for Sanatan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _Tok.primary,
                            ),
                          ),
                          const SizedBox(height: _Tok.md),
                          const Text(
                            'Vocal for Sanatan is a digital platform created to help users discover, connect with and support businesses and service providers listed on the platform.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _Tok.medText,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: _Tok.lg),
                          Container(
                            padding: const EdgeInsets.all(_Tok.md),
                            decoration: BoxDecoration(
                              color: _Tok.primaryLight,
                              borderRadius: BorderRadius.circular(_Tok.md),
                              border: Border.all(
                                color: _Tok.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Text(
                              'By selecting “I Agree & Continue”, you confirm that you have read, understood and agreed to the following Terms of Use, Privacy Policy, Disclaimer and Community Guidelines.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _Tok.charcoal,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: _Tok.xxl),
                          ..._sections.map(
                            (section) => Padding(
                              padding: const EdgeInsets.only(bottom: _Tok.xl),
                              child: _AgreementSection(
                                title: section.$1,
                                body: section.$2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    _Tok.md,
                    hPad,
                    bottomPad + _Tok.md,
                  ),
                  decoration: const BoxDecoration(
                    color: _Tok.white,
                    border: Border(
                      top: BorderSide(color: _Tok.border),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: _submitting
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _accepted = !_accepted);
                                },
                          borderRadius: BorderRadius.circular(_Tok.sm),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _accepted,
                                    onChanged: _submitting
                                        ? null
                                        : (value) {
                                            HapticFeedback.selectionClick();
                                            setState(
                                              () => _accepted = value ?? false,
                                            );
                                          },
                                    activeColor: _Tok.primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: _Tok.sm),
                                const Expanded(
                                  child: Text(
                                    'I have read and agree to the User Agreement, Privacy Policy, Disclaimer and Community Guidelines.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _Tok.charcoal,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: _Tok.md),
                        AppButton(
                          label: 'I Agree & Continue',
                          isLoading: _submitting,
                          onPressed:
                              _accepted && !_submitting ? _agreeAndContinue : null,
                        ),
                        const SizedBox(height: _Tok.sm),
                        TextButton(
                          onPressed: _submitting ? null : _signOut,
                          child: const Text(
                            'Sign out',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _Tok.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgreementSection extends StatelessWidget {
  final String title;
  final String body;

  const _AgreementSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_Tok.lg),
      decoration: BoxDecoration(
        color: _Tok.surface,
        borderRadius: BorderRadius.circular(_Tok.lg),
        border: Border.all(color: _Tok.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _Tok.charcoal,
            ),
          ),
          const SizedBox(height: _Tok.sm),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: _Tok.medText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

const List<(String, String)> _sections = [
  (
    '1. Platform Purpose',
    'Vocal for Sanatan provides a platform for discovering and connecting with businesses, professionals, service providers and other listings.\n\n'
        'The platform may allow users to:\n\n'
        '• Search and discover businesses.\n'
        '• View business information and contact details.\n'
        '• Contact businesses through available communication options.\n'
        '• Save or favourite businesses.\n'
        '• Submit reviews or feedback.\n'
        '• Submit or manage business listings.\n'
        '• Share business information, photographs and other content.\n'
        '• Use location-based search and related features.\n\n'
        'Vocal for Sanatan is a platform for discovery and connection. It does not itself guarantee, endorse or certify the quality, legality, authenticity, safety or performance of every business or service listed on the platform.',
  ),
  (
    '2. Business Information',
    'Business owners and authorised representatives are responsible for ensuring that information submitted by them is accurate, current and lawful.\n\n'
        'This may include:\n\n'
        '• Business name\n'
        '• Owner/contact information\n'
        '• Address\n'
        '• Phone number\n'
        '• Email\n'
        '• Business category\n'
        '• Services/products\n'
        '• Pricing information\n'
        '• Photographs\n'
        '• Operating hours\n'
        '• Website/social-media information\n'
        '• Licences or verification information where applicable\n\n'
        'Vocal for Sanatan may verify, modify, reject, suspend or remove a listing where information appears inaccurate, misleading, unlawful, fraudulent or inconsistent with platform policies.',
  ),
  (
    '3. No Guarantee or Endorsement',
    'A business appearing on Vocal for Sanatan does not automatically mean that Vocal for Sanatan recommends, certifies, guarantees or endorses that business.\n\n'
        'Users should independently verify:\n\n'
        '• Identity of the business.\n'
        '• Product/service quality.\n'
        '• Price.\n'
        '• Availability.\n'
        '• Licences and registrations.\n'
        '• Warranty/guarantee.\n'
        '• Delivery commitments.\n'
        '• Payment terms.\n'
        '• Other relevant business conditions.\n\n'
        'Any transaction or agreement between a user and a business is primarily between those parties.',
  ),
  (
    '4. User Responsibility',
    'Users agree to use the application lawfully and responsibly.\n\n'
        'Users must not:\n\n'
        '• Provide false or misleading information.\n'
        '• Create fraudulent business listings.\n'
        '• Impersonate another person or business.\n'
        '• Upload content they do not have the right to use.\n'
        '• Post defamatory, abusive, threatening or hateful content.\n'
        '• Promote illegal activities.\n'
        '• Use the platform for fraud, scams or harassment.\n'
        '• Upload malware or harmful code.\n'
        '• Attempt to gain unauthorised access to the application.\n'
        '• Manipulate ratings or reviews.\n'
        '• Use the platform to discriminate against individuals or communities unlawfully.',
  ),
  (
    '5. Reviews and User-Generated Content',
    'Users may be permitted to submit reviews, ratings, photographs or other content.\n\n'
        'Users are responsible for the content they submit and confirm that they have the necessary rights to submit such content.\n\n'
        'Vocal for Sanatan may review, moderate, edit, restrict or remove content that violates applicable law or platform policies.\n\n'
        'Fake reviews, paid manipulation, abusive content and misleading claims are prohibited.',
  ),
  (
    '6. Community & Sanatan Values',
    'Vocal for Sanatan is intended to support and connect businesses and members of the Sanatan community.\n\n'
        'The platform must not be used to promote:\n\n'
        '• Violence.\n'
        '• Hatred.\n'
        '• Threats.\n'
        '• Harassment.\n'
        '• Illegal activities.\n'
        '• Discriminatory content.\n'
        '• Content prohibited under applicable Indian law.\n\n'
        'Religious or cultural expression must remain respectful and within applicable law.',
  ),
  (
    '7. Privacy & Personal Data',
    'Vocal for Sanatan may collect and process information required to provide its services, such as account information, contact information, business information, device information and location information where applicable.',
  ),
];
