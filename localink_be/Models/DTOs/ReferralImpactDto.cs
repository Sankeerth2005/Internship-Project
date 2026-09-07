namespace localink_be.Models.DTOs
{
    /// <summary>Read-only referral dashboard payload. Counts are server-derived only.</summary>
    public class ReferralImpactDto
    {
        public string ReferralCode { get; set; } = string.Empty;
        public string ReferralLink { get; set; } = string.Empty;
        public int SuccessfulReferrals { get; set; }

        /// <summary>none | bronze | silver | gold</summary>
        public string AchievementTier { get; set; } = "none";

        /// <summary>e.g. Community Supporter</summary>
        public string AchievementTitle { get; set; } = "Community Member";

        /// <summary>e.g. Bronze Supporter</summary>
        public string AchievementDisplayLabel { get; set; } = "Community Member";

        public string? NextTier { get; set; }
        public string? NextTitle { get; set; }
        public int? NextThreshold { get; set; }
        public int ProgressCurrent { get; set; }
        public int ProgressTarget { get; set; }
        public int RemainingToNext { get; set; }
        public bool IsMaxTier { get; set; }

        public ReferralMilestonesDto Milestones { get; set; } = new();
    }

    public class ReferralMilestonesDto
    {
        public int Bronze { get; set; }
        public int Silver { get; set; }
        public int Gold { get; set; }
    }
}
