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

            // Strip legacy brand prefix so VFS-K7M2NP and K7M2NP resolve the same.
            if (s.StartsWith("VFS-", StringComparison.Ordinal))
                s = s["VFS-".Length..];

            var configuredPrefix = (_options.CodePrefix ?? string.Empty).Trim().ToUpperInvariant();
            if (!string.IsNullOrEmpty(configuredPrefix))
            {
                if (!configuredPrefix.EndsWith('-'))
                    configuredPrefix += "-";
                if (s.StartsWith(configuredPrefix, StringComparison.Ordinal))
                    s = s[configuredPrefix.Length..];
            }

            var bodyLen = Math.Clamp(_options.CodeBodyLength, 4, 12);
            if (s.Length == bodyLen && s.All(c => CodeAlphabet.Contains(c)))
                return s;

            // Accept any remaining unambiguous body (e.g. older lengths) for lookup.
            if (s.Length is >= 4 and <= 12 && s.All(c => CodeAlphabet.Contains(c)))
                return s;

            return null;
        }

        public async Task<string> GenerateUniqueReferralCodeAsync(CancellationToken cancellationToken = default)
        {
            var maxAttempts = Math.Clamp(_options.CodeGenerationMaxAttempts, 3, 32);
            for (var attempt = 0; attempt < maxAttempts; attempt++)
            {
                var code = CreateCandidateCode();
                if (!await ReferralCodeTakenAsync(code, cancellationToken))
                    return code;
            }

            throw new InvalidOperationException("Unable to allocate a unique referral code. Please retry.");
        }

        public async Task EnsureReferralCodeAsync(User user, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(user);

            // Migrate legacy VFS-XXXXXX → XXXXXX in place (same body; old links still work).
            if (!string.IsNullOrWhiteSpace(user.ReferralCode)
                && user.ReferralCode.StartsWith("VFS-", StringComparison.OrdinalIgnoreCase))
            {
                var body = NormalizeReferralCode(user.ReferralCode);
                if (!string.IsNullOrEmpty(body)
                    && !await ReferralCodeTakenAsync(body, cancellationToken, excludeUserId: user.UserId))
                {
                    user.ReferralCode = body;
                    return;
                }
            }

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

            // AsNoTracking — never keep the referrer in the change tracker.
            // A tracked referrer with a stale SuccessfulReferralCount can overwrite the
            // atomic SQL increment on a later SaveChanges (e.g. IssueSessionAsync).
            var referrer = await FindReferrerInfoAsync(code, cancellationToken);

            if (referrer is null)
            {
                _logger.LogInformation(
                    "Referral code {Code} not found during registration of user {UserId}; ignoring.",
                    code, newUser.UserId);
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

            if (referrer.UserId == newUser.UserId)
            {
                _logger.LogWarning("Self-referral blocked for user {UserId}", newUser.UserId);
                await _db.SaveChangesAsync(cancellationToken);
                return;
            }

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

            // Drop any accidentally tracked copy of the referrer before we mutate counts.
            DetachTrackedUser(referrer.UserId);

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

            // Atomic increment only after history row committed.
            // Keep referrer detached so a later SaveChanges cannot write stale count=0.
            DetachTrackedUser(referrer.UserId);
            var rows = await _db.Database.ExecuteSqlInterpolatedAsync(
                $"UPDATE dbo.users SET successful_referral_count = successful_referral_count + 1 WHERE user_id = {referrer.UserId}",
                cancellationToken);

            if (rows != 1)
            {
                _logger.LogWarning(
                    "Referral count increment affected {Rows} rows for referrer {ReferrerId} (expected 1).",
                    rows, referrer.UserId);
            }
            else
            {
                _logger.LogInformation(
                    "Referral attributed: referrer {ReferrerId} ← user {UserId} code {Code}",
                    referrer.UserId, newUser.UserId, code);
            }
        }

        public async Task<ReferralImpactDto> GetMyReferralImpactAsync(
            long userId,
            CancellationToken cancellationToken = default)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.UserId == userId, cancellationToken)
                ?? throw new KeyNotFoundException("User not found");

            await EnsureReferralCodeAsync(user, cancellationToken);
            if (_db.ChangeTracker.HasChanges())
                await _db.SaveChangesAsync(cancellationToken);

            // Source of truth: users who actually registered with this referrer.
            // History should match; if increment was overwritten by EF, referred_by still shows joins.
            var attributedCount = await _db.Users.AsNoTracking()
                .CountAsync(u => u.ReferredByUserId == userId, cancellationToken);

            var historyCount = await _db.ReferralHistories.AsNoTracking()
                .CountAsync(h => h.ReferrerUserId == userId, cancellationToken);

            if (attributedCount > historyCount)
            {
                await BackfillMissingHistoryAsync(userId, user.ReferralCode!, cancellationToken);
                historyCount = await _db.ReferralHistories.AsNoTracking()
                    .CountAsync(h => h.ReferrerUserId == userId, cancellationToken);
            }

            var trueCount = Math.Max(attributedCount, historyCount);

            if (trueCount != user.SuccessfulReferralCount)
            {
                _logger.LogWarning(
                    "Referral count drift for user {UserId}: denormalized={Denorm}, referredBy={Attributed}, history={History}. Reconciling to {True}.",
                    userId, user.SuccessfulReferralCount, attributedCount, historyCount, trueCount);
                user.SuccessfulReferralCount = trueCount;
                await _db.SaveChangesAsync(cancellationToken);
            }

            var achievement = ReferralTagCalculator.FromCount(trueCount, _options);
            var link = BuildReferralLink(user.ReferralCode!);

            return new ReferralImpactDto
            {
                ReferralCode = user.ReferralCode!,
                ReferralLink = link,
                SuccessfulReferrals = trueCount,
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
                .Where(u =>
                    u.ReferralCode == null
                    || u.ReferralCode == string.Empty
                    || u.ReferralCode.StartsWith("VFS-"))
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
            var bodyLen = Math.Clamp(_options.CodeBodyLength, 4, 12);
            var body = new char[bodyLen];
            var bytes = new byte[bodyLen];
            RandomNumberGenerator.Fill(bytes);
            for (var i = 0; i < bodyLen; i++)
                body[i] = CodeAlphabet[bytes[i] % CodeAlphabet.Length];

            var code = new string(body);
            var prefix = (_options.CodePrefix ?? string.Empty).Trim().ToUpperInvariant();
            if (string.IsNullOrEmpty(prefix))
                return code;

            if (!prefix.EndsWith('-'))
                prefix += "-";
            return prefix + code;
        }

        private async Task<bool> ReferralCodeTakenAsync(
            string code,
            CancellationToken cancellationToken,
            long? excludeUserId = null)
        {
            var legacy = "VFS-" + code;
            var query = _db.Users.AsNoTracking()
                .Where(u => u.ReferralCode == code || u.ReferralCode == legacy);
            if (excludeUserId.HasValue)
                query = query.Where(u => u.UserId != excludeUserId.Value);
            return await query.AnyAsync(cancellationToken);
        }

        private sealed record ReferrerInfo(long UserId, string? Email, string? PhoneNumber);

        private async Task<ReferrerInfo?> FindReferrerInfoAsync(
            string code,
            CancellationToken cancellationToken)
        {
            var legacy = "VFS-" + code;
            return await _db.Users.AsNoTracking()
                .Where(u => u.ReferralCode == code || u.ReferralCode == legacy)
                .Select(u => new ReferrerInfo(u.UserId, u.Email, u.PhoneNumber))
                .FirstOrDefaultAsync(cancellationToken);
        }

        private void DetachTrackedUser(long userId)
        {
            foreach (var entry in _db.ChangeTracker.Entries<User>()
                         .Where(e => e.Entity.UserId == userId)
                         .ToList())
            {
                entry.State = EntityState.Detached;
            }
        }

        /// <summary>
        /// Inserts missing referral_history rows for users who already have referred_by_user_id set
        /// (repairs cases where count was overwritten after attribution).
        /// </summary>
        private async Task BackfillMissingHistoryAsync(
            long referrerUserId,
            string referralCode,
            CancellationToken cancellationToken)
        {
            var referredIds = await _db.Users.AsNoTracking()
                .Where(u => u.ReferredByUserId == referrerUserId)
                .Select(u => u.UserId)
                .ToListAsync(cancellationToken);

            if (referredIds.Count == 0)
                return;

            var existing = await _db.ReferralHistories.AsNoTracking()
                .Where(h => h.ReferrerUserId == referrerUserId)
                .Select(h => h.ReferredUserId)
                .ToListAsync(cancellationToken);

            var existingSet = existing.ToHashSet();
            var code = string.IsNullOrWhiteSpace(referralCode) ? "LEGACY" : referralCode;
            if (code.Length > 16)
                code = code[..16];

            var added = 0;
            foreach (var referredId in referredIds)
            {
                if (existingSet.Contains(referredId))
                    continue;

                _db.ReferralHistories.Add(new ReferralHistory
                {
                    ReferrerUserId = referrerUserId,
                    ReferredUserId = referredId,
                    ReferralCode = code,
                    CreatedAt = DateTime.UtcNow
                });
                added++;
            }

            if (added == 0)
                return;

            try
            {
                await _db.SaveChangesAsync(cancellationToken);
                _logger.LogInformation(
                    "Backfilled {Count} referral_history row(s) for referrer {ReferrerId}",
                    added, referrerUserId);
            }
            catch (DbUpdateException ex)
            {
                _logger.LogWarning(ex,
                    "Referral history backfill conflict for referrer {ReferrerId}; continuing with counts.",
                    referrerUserId);

                foreach (var entry in _db.ChangeTracker.Entries<ReferralHistory>()
                             .Where(e => e.State == EntityState.Added)
                             .ToList())
                {
                    entry.State = EntityState.Detached;
                }
            }
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
