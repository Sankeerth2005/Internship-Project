import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/app_error_formatter.dart';
import '../../../../core/storage/user_prefs_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../shared/presentation/widgets/app_back_button.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../shared/presentation/widgets/app_dialog.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../data/models/referral_impact.dart';
import '../../providers/referral_provider.dart';
import '../../utils/referral_share_helper.dart';

class ReferralDashboardScreen extends ConsumerStatefulWidget {
  const ReferralDashboardScreen({super.key});

  @override
  ConsumerState<ReferralDashboardScreen> createState() =>
      _ReferralDashboardScreenState();
}

class _ReferralDashboardScreenState
    extends ConsumerState<ReferralDashboardScreen> {
  bool _celebrationChecked = false;

  @override
  Widget build(BuildContext context) {
    final impactAsync = ref.watch(referralImpactProvider);

    ref.listen<AsyncValue<ReferralImpact>>(referralImpactProvider,
        (prev, next) {
      next.whenData((impact) => _maybeCelebrate(impact));
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBackButton(onPressed: () => context.pop()),
        ),
        title: const Text(
          'My Referral Impact',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: impactAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppErrorFormatter.format(err),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.mutedTextColor),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Retry',
                  onPressed: () => ref.invalidate(referralImpactProvider),
                ),
              ],
            ),
          ),
        ),
        data: (impact) => RefreshIndicator(
          color: AppTheme.accentColor,
          onRefresh: () async {
            _celebrationChecked = false;
            ref.invalidate(referralImpactProvider);
            await ref.read(referralImpactProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _StatCard(
                label: 'Successful Referrals',
                value: '${impact.successfulReferrals}',
                icon: Icons.groups_rounded,
              ),
              const SizedBox(height: 14),
              _AchievementCard(impact: impact),
              const SizedBox(height: 14),
              _ProgressCard(impact: impact),
              const SizedBox(height: 14),
              _CodeCard(
                code: impact.referralCode,
                link: impact.referralLink,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Invite Friends',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () => _shareNative(impact),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF128C7E),
                  side: const BorderSide(color: Color(0xFF128C7E)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.chat_rounded),
                label: const Text(
                  'Refer via WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () => _shareWhatsApp(impact),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyLink(impact),
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Copy Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textColor,
                        side: const BorderSide(color: AppTheme.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareNative(impact),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textColor,
                        side: const BorderSide(color: AppTheme.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'A referral counts only after the invited person successfully registers. Sending a message or opening a link alone does not count.',
                style: TextStyle(
                  color: AppTheme.softMutedTextColor,
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _maybeCelebrate(ReferralImpact impact) async {
    if (_celebrationChecked) return;
    _celebrationChecked = true;

    final tier = impact.achievementTier.toLowerCase();
    if (tier != 'bronze' && tier != 'silver' && tier != 'gold') return;

    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    final userId = auth.userId;
    if (userId <= 0) return;

    final seen = await UserPrefsStore.hasSeenReferralCelebration(
      userId: userId,
      tier: tier,
    );
    if (seen || !mounted) return;

    await UserPrefsStore.markReferralCelebrationSeen(
      userId: userId,
      tier: tier,
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        title: 'Congratulations!',
        message:
            'You have achieved:\n\n${impact.tierEmoji} ${impact.achievementDisplayLabel}\n\n'
            'Thank you for helping grow the VocalForSanatan community!',
        icon: Text(impact.tierEmoji, style: const TextStyle(fontSize: 48)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _message(ReferralImpact impact) => ReferralShareHelper.buildMessage(
        referralCode: impact.referralCode,
        referralLink: impact.referralLink,
      );

  Future<void> _shareWhatsApp(ReferralImpact impact) async {
    final uri = ReferralShareHelper.whatsappShareUri(_message(impact));
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        AppFeedback.showError(
          context,
          'Could not open WhatsApp. Try Share instead.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'WhatsApp is unavailable on this device.',
        );
      }
    }
  }

  Future<void> _shareNative(ReferralImpact impact) async {
    await SharePlus.instance.share(
      ShareParams(
        text: _message(impact),
        subject: 'Join Vocal for Sanatan',
      ),
    );
  }

  Future<void> _copyLink(ReferralImpact impact) async {
    await Clipboard.setData(ClipboardData(text: impact.referralLink));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    AppFeedback.showSuccess(context, 'Referral link copied');
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final ReferralImpact impact;

  const _AchievementCard({required this.impact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withValues(alpha: 0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Achievement',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (impact.tierEmoji.isNotEmpty) impact.tierEmoji,
              impact.achievementDisplayLabel,
            ].where((e) => e.isNotEmpty).join(' '),
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            impact.achievementTitle,
            style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ReferralImpact impact;

  const _ProgressCard({required this.impact});

  @override
  Widget build(BuildContext context) {
    final ratio = impact.progressTarget <= 0
        ? 1.0
        : (impact.progressCurrent / impact.progressTarget).clamp(0.0, 1.0);

    final nextLine = impact.isMaxTier
        ? 'Congratulations! You are a Community Champion.\nNo additional milestone currently available.'
        : '${impact.remainingToNext} more successful referrals to reach ${impact.nextTitle ?? 'next milestone'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Milestone',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nextLine,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppTheme.borderColor,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${impact.progressCurrent} / ${impact.progressTarget}',
            style: const TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final String code;
  final String link;

  const _CodeCard({required this.code, required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Referral Code',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            code,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            link,
            style: const TextStyle(
              color: AppTheme.softMutedTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
