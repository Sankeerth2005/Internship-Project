using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using localink_be.Data;
using localink_be.Models.DTOs;
using localink_be.Models.Entities;
using localink_be.Options;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class ReferralService : IReferralService
    {
        /// <summary>Unambiguous alphabet (no 0/O, 1/I/L) to reduce share typos.</summary>
        private static readonly char[] CodeAlphabet =
            "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray();

        private readonly AppDbContext _db;
        private readonly ReferralOptions _options;
        private readonly ILogger<ReferralService> _logger;

        public ReferralService(
            AppDbContext db,
            IOptions<ReferralOptions> options,
            ILogger<ReferralService> logger)
        {
            _db = db;
            _options = options.Value;
            _logger = logger;
        }

        public string? NormalizeReferralCode(string? rawCode)
        {
            if (string.IsNullOrWhiteSpace(rawCode))
                return null;

            var s = rawCode.Trim().ToUpperInvariant()
                .Replace(" ", string.Empty, StringComparison.Ordinal)
                .Replace("_", "-", StringComparison.Ordinal);

            var prefix = string.IsNullOrWhiteSpace(_options.CodePrefix)
                ? "VFS-"
                : _options.CodePrefix.Trim().ToUpperInvariant();
            if (!prefix.EndsWith('-'))
                prefix += "-";

            if (s.StartsWith(prefix, StringComparison.Ordinal))
                return s;

            // Allow body-only paste (e.g. AB12CD → VFS-AB12CD)
            var bodyLen = Math.Clamp(_options.CodeBodyLength, 4, 12);
            if (s.Length == bodyLen && s.All(c => CodeAlphabet.Contains(c)))
                return prefix + s;

            return s;
        }

        public async Task<string> GenerateUniqueReferralCodeAsync(CancellationToken cancellationToken = default)
        {
            var maxAttempts = Math.Clamp(_options.CodeGenerationMaxAttempts, 3, 32);
            for (var attempt = 0; attempt < maxAttempts; attempt++)
            {
                var code = CreateCandidateCode();
                var exists = await _db.Users.AsNoTracking()
                    .AnyAsync(u => u.ReferralCode == code, cancellationToken);
                if (!exists)
                    return code;
            }

            throw new InvalidOperationException("Unable to allocate a unique referral code. Please retry.");
        }

        public async Task EnsureReferralCodeAsync(User user, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(user);
            if (!string.IsNullOrWhiteSpace(user.ReferralCode))
                return;

            user.ReferralCode = await GenerateUniqueReferralCodeAsync(cancellationToken);
        }

        public async Task TryAttributeReferralAsync(
            User newUser,
            string? rawReferralCode,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(newUser);

            if (newUser.UserId <= 0)
                throw new InvalidOperationException("New user must be saved before referral attribution.");

            // Always ensure the new user gets their own permanent code.
            await EnsureReferralCodeAsync(newUser, cancellationToken);

            var code = NormalizeReferralCode(rawReferralCode);
            if (code is null)
            {
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

            // Immutable: already attributed
            if (newUser.ReferredByUserId.HasValue)
            {
                _logger.LogInformation(
                    "Skipping referral attribution for user {UserId}: already referred by {ReferrerId}",
                    newUser.UserId, newUser.ReferredByUserId);
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

            var alreadyInHistory = await _db.ReferralHistories.AsNoTracking()
                .AnyAsync(h => h.ReferredUserId == newUser.UserId, cancellationToken);
            if (alreadyInHistory)
            {
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

            var referrer = await _db.Users
                .FirstOrDefaultAsync(u => u.ReferralCode == code, cancellationToken);

            if (referrer is null)
            {
                _logger.LogInformation(
                    "Referral code {Code} not found during registration of user {UserId}; ignoring.",
                    code, newUser.UserId);
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

            // Self-referral (same account) — impossible for brand-new code ownership,
            // but guard if somehow the new user's code matches or IDs collide.
            if (referrer.UserId == newUser.UserId)
            {
                _logger.LogWarning("Self-referral blocked for user {UserId}", newUser.UserId);
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

            // Same mailbox / phone as referrer → treat as self-referral abuse
            // (includes Gmail +alias / dot-insensitive canonicalization).
            if (!string.IsNullOrWhiteSpace(newUser.Email)
                && !string.IsNullOrWhiteSpace(referrer.Email)
                && string.Equals(
                    CanonicalEmail(newUser.Email),
                    CanonicalEmail(referrer.Email),
                    StringComparison.Ordinal))
            {
                _logger.LogWarning("Self-referral (same mailbox) blocked for user {UserId}", newUser.UserId);
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

            if (!string.IsNullOrWhiteSpace(newUser.PhoneNumber)
                && !string.IsNullOrWhiteSpace(referrer.PhoneNumber)
                && string.Equals(newUser.PhoneNumber, referrer.PhoneNumber, StringComparison.Ordinal))
            {
                _logger.LogWarning("Self-referral (same phone) blocked for user {UserId}", newUser.UserId);
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

            newUser.ReferredByUserId = referrer.UserId;

            _db.ReferralHistories.Add(new ReferralHistory
            {
                ReferrerUserId = referrer.UserId,
                ReferredUserId = newUser.UserId,
                ReferralCode = code,
                CreatedAt = DateTime.UtcNow
            });

            try
            {
                // Persist attribution first — unique(referred_user_id) makes retries idempotent.
                await _db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException ex)
            {
                // Unique constraint on referred_user_id → race / duplicate; do not increment.
                _logger.LogWarning(ex,
                    "Referral attribution conflict for referred user {UserId}; treating as already attributed.",
                    newUser.UserId);

                foreach (var entry in _db.ChangeTracker.Entries<ReferralHistory>()
                             .Where(e => e.Entity.ReferredUserId == newUser.UserId
                                         && e.State == EntityState.Added)
                             .ToList())
                {
                    entry.State = EntityState.Detached;
                }

                var referredByProp = _db.Entry(newUser).Property(u => u.ReferredByUserId);
                if (referredByProp.IsModified)
                    referredByProp.CurrentValue = null;

                await EnsureReferralCodeAsync(newUser, cancellationToken);
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

            // Atomic increment only after history row committed (same ambient transaction when present).
            // Do not mutate tracked referrer.SuccessfulReferralCount — avoids lost updates under concurrency.
            await _db.Database.ExecuteSqlInterpolatedAsync(
                $"UPDATE dbo.users SET successful_referral_count = successful_referral_count + 1 WHERE user_id = {referrer.UserId}",
                cancellationToken);
        }

        public async Task<ReferralImpactDto> GetMyReferralImpactAsync(
            long userId,
            CancellationToken cancellationToken = default)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.UserId == userId, cancellationToken)
                ?? throw new KeyNotFoundException("User not found");

            if (string.IsNullOrWhiteSpace(user.ReferralCode))
            {
                await EnsureReferralCodeAsync(user, cancellationToken);
                await _db.SaveChangesAsync(cancellationToken);
            }

            // Prefer history count as source of truth if denormalized counter drifted.
            var historyCount = await _db.ReferralHistories.AsNoTracking()
                .CountAsync(h => h.ReferrerUserId == userId, cancellationToken);

            if (historyCount != user.SuccessfulReferralCount)
            {
                _logger.LogWarning(
                    "Referral count drift for user {UserId}: denormalized={Denorm}, history={History}. Reconciling.",
                    userId, user.SuccessfulReferralCount, historyCount);
                user.SuccessfulReferralCount = historyCount;
                await _db.SaveChangesAsync(cancellationToken);
            }

            var achievement = ReferralTagCalculator.FromCount(user.SuccessfulReferralCount, _options);
            var link = BuildReferralLink(user.ReferralCode!);

            return new ReferralImpactDto
            {
                ReferralCode = user.ReferralCode!,
                ReferralLink = link,
                SuccessfulReferrals = user.SuccessfulReferralCount,
                AchievementTier = achievement.Tier,
                AchievementTitle = achievement.Title,
                AchievementDisplayLabel = achievement.DisplayLabel,
                NextTier = achievement.NextTier,
                NextTitle = achievement.NextTitle,
                NextThreshold = achievement.NextThreshold,
                ProgressCurrent = achievement.ProgressCurrent,
                ProgressTarget = achievement.ProgressTarget,
                RemainingToNext = achievement.RemainingToNext,
                IsMaxTier = achievement.IsMaxTier,
                Milestones = new ReferralMilestonesDto
                {
                    Bronze = _options.Bronze,
                    Silver = _options.Silver,
                    Gold = _options.Gold
                }
            };
        }

        public async Task<int> BackfillMissingReferralCodesAsync(
            int maxUsers = 500,
            CancellationToken cancellationToken = default)
        {
            var limit = Math.Clamp(maxUsers, 1, 5000);
            var users = await _db.Users
                .Where(u => u.ReferralCode == null || u.ReferralCode == string.Empty)
                .OrderBy(u => u.UserId)
                .Take(limit)
                .ToListAsync(cancellationToken);

            if (users.Count == 0)
                return 0;

            var updated = 0;
            foreach (var user in users)
            {
                await EnsureReferralCodeAsync(user, cancellationToken);
                updated++;
            }

            await _db.SaveChangesAsync(cancellationToken);
            return updated;
        }

        private string BuildReferralLink(string referralCode)
        {
            var baseUrl = string.IsNullOrWhiteSpace(_options.InviteBaseUrl)
                ? "https://vocalforsanatan.com/invite"
                : _options.InviteBaseUrl.Trim().TrimEnd('/');

            var separator = baseUrl.Contains('?', StringComparison.Ordinal) ? "&" : "?";
            return $"{baseUrl}{separator}code={Uri.EscapeDataString(referralCode)}";
        }

        private string CreateCandidateCode()
        {
            var prefix = string.IsNullOrWhiteSpace(_options.CodePrefix)
                ? "VFS-"
                : _options.CodePrefix.Trim().ToUpperInvariant();
            if (!prefix.EndsWith('-'))
                prefix += "-";

            var bodyLen = Math.Clamp(_options.CodeBodyLength, 4, 12);
            var body = new char[bodyLen];
            var bytes = new byte[bodyLen];
            RandomNumberGenerator.Fill(bytes);
            for (var i = 0; i < bodyLen; i++)
                body[i] = CodeAlphabet[bytes[i] % CodeAlphabet.Length];

            return prefix + new string(body);
        }

        /// <summary>
        /// Canonical mailbox form for self-referral checks.
        /// Strips +tags; for Gmail/Googlemail also strips dots and normalizes domain.
        /// </summary>
        public static string CanonicalEmail(string email)
        {
            var trimmed = email.Trim().ToLowerInvariant();
            var at = trimmed.IndexOf('@');
            if (at <= 0 || at == trimmed.Length - 1)
                return trimmed;

            var local = trimmed[..at];
            var domain = trimmed[(at + 1)..];

            var plus = local.IndexOf('+');
            if (plus >= 0)
                local = local[..plus];

            if (domain is "gmail.com" or "googlemail.com")
            {
                local = local.Replace(".", string.Empty, StringComparison.Ordinal);
                domain = "gmail.com";
            }

            return $"{local}@{domain}";
        }
    }
}
