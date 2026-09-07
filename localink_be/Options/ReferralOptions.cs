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

        /// <summary>Prefix for generated codes (VFS-AB12CD).</summary>
        public string CodePrefix { get; set; } = "VFS-";

        /// <summary>Random segment length after the prefix (default 6 → VFS-XXXXXX).</summary>
        public int CodeBodyLength { get; set; } = 6;

        /// <summary>Max attempts when generating a unique code.</summary>
        public int CodeGenerationMaxAttempts { get; set; } = 12;
    }
}
