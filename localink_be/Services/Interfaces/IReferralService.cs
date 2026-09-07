using localink_be.Models.DTOs;
using localink_be.Models.Entities;

namespace localink_be.Services.Interfaces
{
    public interface IReferralService
    {
        /// <summary>Normalize user-entered / link referral codes for lookup.</summary>
        string? NormalizeReferralCode(string? rawCode);

        /// <summary>Generate a unique VFS-… code not present in the database.</summary>
        Task<string> GenerateUniqueReferralCodeAsync(CancellationToken cancellationToken = default);

        /// <summary>
        /// Ensures <paramref name="user"/> has a permanent referral code (mutates entity; caller saves).
        /// </summary>
        Task EnsureReferralCodeAsync(User user, CancellationToken cancellationToken = default);

        /// <summary>
        /// If <paramref name="rawReferralCode"/> is valid, permanently attributes the new user to the referrer,
        /// inserts referral_history, and atomically increments the referrer's successful count.
        /// Soft-fails (no throw) on invalid/self/duplicate so registration is never blocked by a bad code.
        /// Must run inside the caller's DB transaction after the new user row exists (has UserId).
        /// </summary>
        Task TryAttributeReferralAsync(User newUser, string? rawReferralCode, CancellationToken cancellationToken = default);

        /// <summary>Read-only dashboard for the authenticated user.</summary>
        Task<ReferralImpactDto> GetMyReferralImpactAsync(long userId, CancellationToken cancellationToken = default);

        /// <summary>Assign codes to legacy users missing referral_code. Returns number updated.</summary>
        Task<int> BackfillMissingReferralCodesAsync(int maxUsers = 500, CancellationToken cancellationToken = default);
    }
}
