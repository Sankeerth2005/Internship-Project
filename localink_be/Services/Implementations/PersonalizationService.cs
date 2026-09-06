using localink_be.Data;
using localink_be.Models.Enums;
using localink_be.Models.Queries;
using localink_be.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace localink_be.Services.Implementations
{
    /// <summary>
    /// Personalized feed ranked from the user's current coordinates.
    /// Candidates are limited to the nearby radius (default 30 km).
    /// Ranking blends distance decay, popularity, rating, favorites affinity, and time-of-day relevance.
    /// </summary>
    public class PersonalizationService : IPersonalizationService
    {
        private const int CandidatePageSize = 40;
        private const int FeedTake = 8;

        private readonly IBusinessDiscoveryService _discoveryService;
        private readonly IAIService _aiService;
        private readonly IFavoritesService _favoritesService;
        private readonly AppDbContext _db;

        public PersonalizationService(
            IBusinessDiscoveryService discoveryService,
            IAIService aiService,
            IFavoritesService favoritesService,
            AppDbContext db,
            IOptions<BusinessDiscoveryOptions> options)
        {
            _discoveryService = discoveryService;
            _aiService = aiService;
            _favoritesService = favoritesService;
            _db = db;
            _ = options;
        }

        public async Task<PersonalizedFeedResult> GetFeedAsync(
            double latitude,
            double longitude,
            double? radiusKm,
            long? userId,
            IReadOnlyDictionary<int, int>? categoryAffinity,
            CancellationToken cancellationToken = default)
        {
            var (timeOfDay, preferredLabel, preferredKeywords) = ResolveTimeOfDayContext();
            var greeting = NormalizeGreeting(
                await _aiService.GetPersonalizedWelcomeAsync(preferredLabel, timeOfDay),
                preferredLabel,
                timeOfDay);

            var discovery = await _discoveryService.DiscoverAsync(new BusinessDiscoveryQuery
            {
                Latitude = latitude,
                Longitude = longitude,
                RadiusKm = radiusKm,
                Sort = BusinessSortMode.Nearest,
                Page = 1,
                PageSize = CandidatePageSize,
                RequireLocation = true
            }, cancellationToken);

            var nearby = (discovery.Items ?? Array.Empty<Models.DTOs.BusinessDto>())
                .Where(b => !b.IsTemporarilyClosed)
                .ToList();

            if (nearby.Count == 0)
            {
                return new PersonalizedFeedResult
                {
                    TimeOfDay = timeOfDay,
                    PreferredCategory = preferredLabel,
                    Greeting = greeting,
                    AppliedRadiusKm = discovery.AppliedRadiusKm,
                    Items = Array.Empty<PersonalizedFeedItem>(),
                    Message = "No businesses found near your location right now."
                };
            }

            var favoriteIds = new HashSet<long>();
            var favoriteCategoryIds = new HashSet<int>();
            if (userId.HasValue && userId.Value > 0)
            {
                try
                {
                    var ids = await _favoritesService.GetUserFavoritesAsync(userId.Value);
                    favoriteIds = ids.ToHashSet();
                    if (favoriteIds.Count > 0)
                    {
                        var cats = await _db.Businesses.AsNoTracking()
                            .Where(b => favoriteIds.Contains(b.BusinessId))
                            .Select(b => b.CategoryId)
                            .Distinct()
                            .ToListAsync(cancellationToken);
                        favoriteCategoryIds = cats.ToHashSet();
                    }
                }
                catch
                {
                    // Affinity is optional — continue without it.
                }
            }

            var idsNearby = nearby.Select(b => b.Id).ToList();
            var metrics = await _db.BusinessMetrics.AsNoTracking()
                .Where(m => idsNearby.Contains(m.BusinessId))
                .ToDictionaryAsync(m => m.BusinessId, cancellationToken);

            var maxPopularity = 1.0;
            foreach (var b in nearby)
            {
                metrics.TryGetValue(b.Id, out var m);
                var pop = (m?.Views ?? 0) + (m?.FavoritesCount ?? 0) * 3.0 + (m?.ContactClicks ?? 0) * 2.0;
                if (pop > maxPopularity) maxPopularity = pop;
            }

            var affinityMax = 1;
            if (categoryAffinity != null && categoryAffinity.Count > 0)
            {
                affinityMax = Math.Max(1, categoryAffinity.Values.DefaultIfEmpty(0).Max());
            }

            var scored = nearby.Select(b =>
            {
                metrics.TryGetValue(b.Id, out var m);
                var distanceKm = b.Distance;
                var distanceScore = distanceKm.HasValue
                    ? Math.Exp(-distanceKm.Value / 12.0)
                    : 0.0;

                var popularityRaw = (m?.Views ?? 0) + (m?.FavoritesCount ?? 0) * 3.0 + (m?.ContactClicks ?? 0) * 2.0;
                var popularityScore = Math.Log10(1 + popularityRaw) / Math.Log10(1 + maxPopularity);

                var ratingScore = Math.Clamp(b.AverageRating / 5.0, 0, 1);
                if (b.TotalReviews <= 0) ratingScore *= 0.5;

                var affinityScore = 0.0;
                if (favoriteIds.Contains(b.Id)) affinityScore = 1.0;
                else if (favoriteCategoryIds.Contains(b.CategoryId)) affinityScore = 0.65;
                else if (categoryAffinity != null && categoryAffinity.TryGetValue(b.CategoryId, out var usage))
                    affinityScore = Math.Clamp(usage / (double)affinityMax, 0, 1) * 0.8;

                var timeScore = CategoryMatchesKeywords(b.CategoryName, b.SubcategoryName, preferredKeywords) ? 1.0 : 0.0;

                // Weighted blend — proximity dominates, but farther businesses remain eligible.
                var score =
                    distanceScore * 0.42 +
                    popularityScore * 0.18 +
                    ratingScore * 0.15 +
                    affinityScore * 0.15 +
                    timeScore * 0.10;

                var reason = BuildReason(distanceKm ?? double.PositiveInfinity, affinityScore, timeScore, popularityScore);

                return new PersonalizedFeedItem
                {
                    BusinessId = b.Id,
                    BusinessName = b.Name ?? "",
                    Description = BuildItemDescription(b, timeOfDay, reason),
                    CategoryName = b.CategoryName ?? "",
                    SubcategoryName = b.SubcategoryName ?? "",
                    Address = b.StreetAddress ?? "",
                    City = b.City ?? "",
                    Phone = b.PhoneNumber ?? "",
                    Email = b.Email ?? "",
                    Photos = b.Photos != null && b.Photos.Count > 0
                        ? b.Photos
                        : (b.PrimaryImage != null ? new List<string> { b.PrimaryImage } : new List<string>()),
                    DistanceKm = distanceKm.HasValue ? Math.Round(distanceKm.Value, 2) : null,
                    Latitude = b.Latitude,
                    Longitude = b.Longitude,
                    Score = Math.Round(score, 4),
                    Reason = reason
                };
            })
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.DistanceKm ?? double.MaxValue)
            .Take(FeedTake)
            .ToList();

            var preferredCategory = preferredLabel;
            if (scored.Count > 0)
            {
                var topTimeMatch = scored.FirstOrDefault(s =>
                    CategoryMatchesKeywords(s.CategoryName, s.SubcategoryName, preferredKeywords));
                if (topTimeMatch != null && !string.IsNullOrWhiteSpace(topTimeMatch.CategoryName))
                    preferredCategory = topTimeMatch.CategoryName;
                else if (!string.IsNullOrWhiteSpace(scored[0].CategoryName))
                    preferredCategory = scored[0].CategoryName;
            }

            return new PersonalizedFeedResult
            {
                TimeOfDay = timeOfDay,
                PreferredCategory = preferredCategory,
                Greeting = greeting,
                AppliedRadiusKm = discovery.AppliedRadiusKm,
                Items = scored,
                Message = scored.Count == 0
                    ? "No businesses found near your location right now."
                    : null
            };
        }

        private static (string TimeOfDay, string PreferredLabel, string[] Keywords) ResolveTimeOfDayContext()
        {
            var hour = DateTime.UtcNow.AddHours(5.5).Hour; // IST
            if (hour >= 5 && hour < 12)
                return ("Morning", "Cafes & Breakfast", new[] { "bakery", "cafe", "coffee", "breakfast", "tea" });
            if (hour >= 12 && hour < 17)
                return ("Afternoon", "Restaurants & Cafes", new[] { "restaurant", "dining", "cafe", "food", "lunch" });
            if (hour >= 17 && hour < 22)
                return ("Evening", "Services & Wellness", new[] { "service", "wellness", "fitness", "salon", "spa", "shopping", "retail" });
            return ("Night", "Dining & Essentials", new[] { "restaurant", "convenience", "pharmacy", "hospital", "grocery" });
        }

        private static bool CategoryMatchesKeywords(string? category, string? subcategory, string[] keywords)
        {
            var hay = $"{category} {subcategory}".ToLowerInvariant();
            if (string.IsNullOrWhiteSpace(hay)) return false;
            return keywords.Any(k => hay.Contains(k, StringComparison.Ordinal));
        }

        private static string BuildReason(double distanceKm, double affinity, double time, double popularity)
        {
            if (affinity >= 0.9) return "Based on your favorites";
            if (affinity >= 0.5) return "Matches categories you like";
            if (time >= 1.0 && distanceKm <= 5) return "Great nearby pick for this time of day";
            if (popularity >= 0.6) return "Popular near you";
            if (distanceKm < 1) return "Very close to you";
            return "Nearby recommendation";
        }

        private static string BuildItemDescription(Models.DTOs.BusinessDto b, string timeOfDay, string reason)
        {
            var stored = (b.Description ?? "").Trim();
            if (stored.Length >= 24 && !LooksLikeFeedLabel(stored))
                return stored;

            var name = string.IsNullOrWhiteSpace(b.Name) ? "This business" : b.Name.Trim();
            var category = string.IsNullOrWhiteSpace(b.CategoryName) ? "local spot" : b.CategoryName.Trim();
            var place = !string.IsNullOrWhiteSpace(b.City)
                ? b.City.Trim()
                : (!string.IsNullOrWhiteSpace(b.StreetAddress) ? b.StreetAddress.Trim() : "your area");
            var period = string.IsNullOrWhiteSpace(timeOfDay) ? "today" : timeOfDay.Trim().ToLowerInvariant();
            var why = string.IsNullOrWhiteSpace(reason) ? "a nearby recommendation" : reason.Trim().ToLowerInvariant();

            return $"{name} is a {category} in {place}. {char.ToUpperInvariant(why[0])}{why[1..]} for your {period} — tap to see hours, photos, and contact details.";
        }

        private static string NormalizeGreeting(string? ai, string preferredLabel, string timeOfDay)
        {
            var period = string.IsNullOrWhiteSpace(timeOfDay) ? "day" : timeOfDay.Trim().ToLowerInvariant();
            var category = string.IsNullOrWhiteSpace(preferredLabel) ? "local" : preferredLabel.Trim().ToLowerInvariant();
            var fallback = $"Namaste! Here are personalized {category} picks within 30 km of you this {period}. Scroll for nearby businesses with a short note on why they were chosen.";

            if (string.IsNullOrWhiteSpace(ai))
                return fallback;

            var text = ai.Trim().Trim('"').Replace('\n', ' ');
            while (text.Contains("  ", StringComparison.Ordinal))
                text = text.Replace("  ", " ", StringComparison.Ordinal);

            var compact = text.Replace(" ", "", StringComparison.Ordinal).Replace("-", "", StringComparison.Ordinal).ToLowerInvariant();
            if (compact is "morningfeed" or "afternoonfeed" or "eveningfeed" or "nightfeed"
                or "morning" or "afternoon" or "evening" or "night"
                or "morningguide" or "afternoonguide" or "eveningguide" or "nightguide")
                return fallback;

            if (text.Length < 28)
                return fallback;

            return text;
        }

        private static bool LooksLikeFeedLabel(string value)
        {
            var compact = value.Replace(" ", "", StringComparison.Ordinal)
                .Replace("-", "", StringComparison.Ordinal)
                .Replace("_", "", StringComparison.Ordinal)
                .ToLowerInvariant();
            return compact is "morningfeed" or "afternoonfeed" or "eveningfeed" or "nightfeed"
                or "morning" or "afternoon" or "evening" or "night";
        }
    }
}
