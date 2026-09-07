/// Server-derived referral dashboard payload (`GET /api/v1/referral/me`).
class ReferralImpact {
  final String referralCode;
  final String referralLink;
  final int successfulReferrals;
  final String achievementTier;
  final String achievementTitle;
  final String achievementDisplayLabel;
  final String? nextTier;
  final String? nextTitle;
  final int? nextThreshold;
  final int progressCurrent;
  final int progressTarget;
  final int remainingToNext;
  final bool isMaxTier;
  final int bronzeMilestone;
  final int silverMilestone;
  final int goldMilestone;

  const ReferralImpact({
    required this.referralCode,
    required this.referralLink,
    required this.successfulReferrals,
    required this.achievementTier,
    required this.achievementTitle,
    required this.achievementDisplayLabel,
    required this.nextTier,
    required this.nextTitle,
    required this.nextThreshold,
    required this.progressCurrent,
    required this.progressTarget,
    required this.remainingToNext,
    required this.isMaxTier,
    required this.bronzeMilestone,
    required this.silverMilestone,
    required this.goldMilestone,
  });

  factory ReferralImpact.fromJson(Map<String, dynamic> json) {
    final milestones = json['milestones'] is Map
        ? Map<String, dynamic>.from(json['milestones'] as Map)
        : <String, dynamic>{};

    return ReferralImpact(
      referralCode: (json['referralCode'] ?? '').toString(),
      referralLink: (json['referralLink'] ?? '').toString(),
      successfulReferrals: _asInt(json['successfulReferrals']),
      achievementTier: (json['achievementTier'] ?? 'none').toString(),
      achievementTitle:
          (json['achievementTitle'] ?? 'Community Member').toString(),
      achievementDisplayLabel:
          (json['achievementDisplayLabel'] ?? 'Community Member').toString(),
      nextTier: json['nextTier']?.toString(),
      nextTitle: json['nextTitle']?.toString(),
      nextThreshold: json['nextThreshold'] == null
          ? null
          : _asInt(json['nextThreshold']),
      progressCurrent: _asInt(json['progressCurrent']),
      progressTarget: _asInt(json['progressTarget']),
      remainingToNext: _asInt(json['remainingToNext']),
      isMaxTier: json['isMaxTier'] == true,
      bronzeMilestone: _asInt(milestones['bronze'] ?? 10),
      silverMilestone: _asInt(milestones['silver'] ?? 100),
      goldMilestone: _asInt(milestones['gold'] ?? 1000),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String get tierEmoji {
    switch (achievementTier.toLowerCase()) {
      case 'bronze':
        return '🥉';
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      default:
        return '';
    }
  }
}
