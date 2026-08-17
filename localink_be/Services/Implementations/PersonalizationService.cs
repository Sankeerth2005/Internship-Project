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
    /// Candidates come from global distance-ordered discovery (no km cutoff);
    /// ranking blends distance decay, popularity, rating, favorites affinity, and time-of-day relevance.
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
            _ = radiusKm;
            var (timeOfDay, preferredLabel, preferredKeywords) = ResolveTimeOfDayContext();
            var greeting = await _aiService.GetPersonalizedWelcomeAsync(preferredLabel, timeOfDay)
                ?? $"Namaste! Here are personalized {preferredLabel.ToLowerInvariant()} picks near you.";

            var discovery = await _discoveryService.DiscoverAsync(new BusinessDiscoveryQuery
            {
                Latitude = latitude,
                Longitude = longitude,
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
                    AppliedRadiusKm = null,
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
                    Description = b.Description ?? "",
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
                AppliedRadiusKm = null,
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
    }
}
