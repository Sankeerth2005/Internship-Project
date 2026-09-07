using localink_be.Options;

namespace localink_be.Services
{
    /// <summary>
    /// Centralized achievement-tier calculation. Do not duplicate this logic in UI layers
    /// for authoritative display — prefer server DTO fields; clients may mirror for offline UX only.
    /// </summary>
    public static class ReferralTagCalculator
    {
        public const string TierNone = "none";
        public const string TierBronze = "bronze";
        public const string TierSilver = "silver";
        public const string TierGold = "gold";

        public const string TitleMember = "Community Member";
        public const string TitleSupporter = "Community Supporter";
        public const string TitlePromoter = "Community Promoter";
        public const string TitleChampion = "Community Champion";

        public static ReferralAchievementResult FromCount(int successfulReferralCount, ReferralOptions options)
        {
            ArgumentNullException.ThrowIfNull(options);

            var count = Math.Max(0, successfulReferralCount);
            var bronze = Math.Max(1, options.Bronze);
            var silver = Math.Max(bronze + 1, options.Silver);
            var gold = Math.Max(silver + 1, options.Gold);

            if (count >= gold)
            {
                return new ReferralAchievementResult(
                    Tier: TierGold,
                    Title: TitleChampion,
                    DisplayLabel: "Gold Champion",
                    NextTier: null,
                    NextTitle: null,
                    NextThreshold: null,
                    ProgressCurrent: count,
                    ProgressTarget: gold,
                    RemainingToNext: 0,
                    IsMaxTier: true);
            }

            if (count >= silver)
            {
                return new ReferralAchievementResult(
                    Tier: TierSilver,
                    Title: TitlePromoter,
                    DisplayLabel: "Silver Promoter",
                    NextTier: TierGold,
                    NextTitle: TitleChampion,
                    NextThreshold: gold,
                    ProgressCurrent: count,
                    ProgressTarget: gold,
                    RemainingToNext: gold - count,
                    IsMaxTier: false);
            }

            if (count >= bronze)
            {
                return new ReferralAchievementResult(
                    Tier: TierBronze,
                    Title: TitleSupporter,
                    DisplayLabel: "Bronze Supporter",
                    NextTier: TierSilver,
                    NextTitle: TitlePromoter,
                    NextThreshold: silver,
                    ProgressCurrent: count,
                    ProgressTarget: silver,
                    RemainingToNext: silver - count,
                    IsMaxTier: false);
            }

            return new ReferralAchievementResult(
                Tier: TierNone,
                Title: TitleMember,
                DisplayLabel: TitleMember,
                NextTier: TierBronze,
                NextTitle: TitleSupporter,
                NextThreshold: bronze,
                ProgressCurrent: count,
                ProgressTarget: bronze,
                RemainingToNext: bronze - count,
                IsMaxTier: false);
        }

        /// <summary>
        /// Returns the milestone tier newly crossed when moving from <paramref name="previousCount"/>
        /// to <paramref name="newCount"/>, or null if no Bronze/Silver/Gold threshold was crossed.
        /// </summary>
        public static string? MilestoneNewlyAchieved(int previousCount, int newCount, ReferralOptions options)
        {
            var before = FromCount(previousCount, options).Tier;
            var after = FromCount(newCount, options).Tier;
            if (string.Equals(before, after, StringComparison.OrdinalIgnoreCase))
                return null;
            if (after is TierBronze or TierSilver or TierGold)
                return after;
            return null;
        }
    }

    public sealed record ReferralAchievementResult(
        string Tier,
        string Title,
        string DisplayLabel,
        string? NextTier,
        string? NextTitle,
        int? NextThreshold,
        int ProgressCurrent,
        int ProgressTarget,
        int RemainingToNext,
        bool IsMaxTier);
}
