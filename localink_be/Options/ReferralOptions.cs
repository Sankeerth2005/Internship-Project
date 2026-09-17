namespace localink_be.Options
{
    /// <summary>
    /// Configurable referral milestones and public invite link base.
    /// Counts are successful registrations only — never WhatsApp sends or link opens.
    /// </summary>
    public class ReferralOptions
    {
        public const string SectionName = "Referral";

        /// <summary>Successful referrals required for Bronze / Community Supporter.</summary>
        public int Bronze { get; set; } = 10;

        /// <summary>Successful referrals required for Silver / Community Promoter.</summary>
        public int Silver { get; set; } = 100;

        /// <summary>Successful referrals required for Gold / Community Champion.</summary>
        public int Gold { get; set; } = 1000;

        /// <summary>
        /// Public invite landing base, e.g. https://vocalforsanatan.com/invite
        /// Final link: {InviteBaseUrl}?code={ReferralCode}
        /// </summary>
        public string InviteBaseUrl { get; set; } = "https://vocalforsanatan.com/invite";

        /// <summary>
        /// Optional prefix for generated codes. Empty = short memorable body only (e.g. K7M2NP).
        /// Legacy VFS-… codes remain resolvable when looking up referrers.
        /// </summary>
        public string CodePrefix { get; set; } = "";

        /// <summary>Random segment length (default 6 → K7M2NP).</summary>
        public int CodeBodyLength { get; set; } = 6;

        /// <summary>Max attempts when generating a unique code.</summary>
        public int CodeGenerationMaxAttempts { get; set; } = 12;
    }
}
