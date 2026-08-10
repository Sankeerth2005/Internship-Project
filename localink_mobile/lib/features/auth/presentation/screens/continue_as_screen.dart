import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/role_routes.dart';
import '../../../../core/network/app_error_formatter.dart';
import '../../data/models/authorized_experiences.dart';
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

/// Post-authentication experience chooser (Continue As User / Business Owner).
class ContinueAsScreen extends ConsumerStatefulWidget {
  const ContinueAsScreen({super.key});

  @override
  ConsumerState<ContinueAsScreen> createState() => _ContinueAsScreenState();
}

class _ContinueAsScreenState extends ConsumerState<ContinueAsScreen> {
  AuthorizedExperiencesDto? _caps;
  String? _loadError;
  bool _loadingCaps = true;
  bool _selecting = false;
  String? _selectingExperience;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCapabilities());
  }

  Future<void> _loadCapabilities() async {
    setState(() {
      _loadingCaps = true;
      _loadError = null;
    });
    try {
      final caps =
          await ref.read(authProvider.notifier).loadAuthorizedExperiences();
      if (!mounted) return;

      // Admin accounts skip Continue As.
      if (RoleRoutes.isAdmin(caps.accountType)) {
        context.go(RoleRoutes.homeForRole(caps.accountType));
        return;
      }

      setState(() {
        _caps = caps;
        _loadingCaps = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = AppErrorFormatter.format(e);
        _loadingCaps = false;
      });
    }
  }

  Future<void> _continueAs(String experience) async {
    if (_selecting) return;
    setState(() {
      _selecting = true;
      _selectingExperience = experience;
    });
    HapticFeedback.lightImpact();

    try {
      final result =
          await ref.read(authProvider.notifier).selectExperience(experience);
      if (!mounted) return;

      if (result.allowed) {
        HapticFeedback.mediumImpact();
        context.go(RoleRoutes.routeForDestination(result.destination));
        return;
      }

      // Unauthorized Owner → existing business registration flow.
      if (RoleRoutes.normalize(result.destination) == 'register-business') {
        HapticFeedback.mediumImpact();
        AppFeedback.showWarning(
          context,
          result.message ??
              'Register your business to access the Business Owner portal.',
        );
        context.go('/register-business');
        return;
      }

      AppFeedback.showError(
        context,
        result.message ?? 'You are not authorized for that experience.',
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      AppFeedback.showError(context, AppErrorFormatter.format(e));
    } finally {
      if (mounted) {
        setState(() {
          _selecting = false;
          _selectingExperience = null;
        });
      }
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

    return Scaffold(
      backgroundColor: _Tok.white,
      body: AppBackground(
        showCenterWarmth: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hPad, _Tok.xxl, hPad, _Tok.xxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandIconBadge.om(size: 64)),
                    const SizedBox(height: _Tok.lg),
                    const Text(
                      'Welcome to Vocal for Sanatan 🙏',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _Tok.charcoal,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: _Tok.sm),
                    const Text(
                      'How would you like to continue?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _Tok.medText,
                      ),
                    ),
                    const SizedBox(height: _Tok.xxl),
                    if (_loadingCaps)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _Tok.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else if (_loadError != null)
                      _ErrorBlock(
                        message: _loadError!,
                        onRetry: _loadCapabilities,
                        onSignOut: _signOut,
                      )
                    else ...[
                      _ExperienceCard(
                        icon: Icons.person_rounded,
                        title: 'User',
                        subtitle: 'Discover and support local businesses',
                        buttonLabel: 'Continue as User',
                        enabled: !_selecting && (_caps?.canContinueAsUser ?? true),
                        isLoading:
                            _selecting && _selectingExperience == 'user',
                        onPressed: () => _continueAs('user'),
                      ),
                      const SizedBox(height: _Tok.lg),
                      _ExperienceCard(
                        icon: Icons.storefront_rounded,
                        title: 'Business Owner',
                        subtitle:
                            'Manage your business and connect with customers',
                        buttonLabel: 'Continue as Business Owner',
                        enabled: !_selecting,
                        isLoading: _selecting &&
                            _selectingExperience == 'businessowner',
                        emphasized: true,
                        onPressed: () => _continueAs('businessowner'),
                      ),
                      const SizedBox(height: _Tok.xl),
                      TextButton(
                        onPressed: _selecting ? null : _signOut,
                        child: const Text(
                          'Sign out',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: _Tok.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool enabled;
  final bool isLoading;
  final bool emphasized;
  final VoidCallback onPressed;

  const _ExperienceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_Tok.lg),
      decoration: BoxDecoration(
        color: _Tok.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emphasized ? _Tok.primary.withValues(alpha: 0.35) : _Tok.border,
          width: emphasized ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _Tok.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _Tok.primary, size: 24),
              ),
              const SizedBox(width: _Tok.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Tok.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _Tok.medText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: _Tok.lg),
          AppButton(
            label: buttonLabel,
            onPressed: enabled ? onPressed : null,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  const _ErrorBlock({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.wifi_off_rounded, color: _Tok.muted, size: 40),
        const SizedBox(height: _Tok.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: _Tok.medText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: _Tok.lg),
        AppButton(label: 'Try again', onPressed: onRetry),
        TextButton(
          onPressed: onSignOut,
          child: const Text(
            'Sign out',
            style: TextStyle(
              fontFamily: 'Inter',
              color: _Tok.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
