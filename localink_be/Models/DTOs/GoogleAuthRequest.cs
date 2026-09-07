using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class GoogleAuthRequest
    {
        [Required(ErrorMessage = "Google ID token is required")]
        public string IdToken { get; set; } = string.Empty;

        /// <summary>
        /// Optional referrer code for brand-new Google accounts only.
        /// Ignored when signing in to an existing account.
        /// </summary>
        [StringLength(32, ErrorMessage = "Referral code cannot exceed 32 characters")]
        public string? ReferralCode { get; set; }
    }
}
