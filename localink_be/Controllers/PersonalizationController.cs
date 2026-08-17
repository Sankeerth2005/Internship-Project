using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/personalization")]
    [EnableRateLimiting("AiPolicy")]
    public class PersonalizationController : ControllerBase
    {
        private readonly IPersonalizationService _personalizationService;

        public PersonalizationController(IPersonalizationService personalizationService)
        {
            _personalizationService = personalizationService;
        }

        /// <summary>
        /// Location-ranked personalized "For You" feed.
        /// Uses the caller's current coordinates; farther businesses remain eligible.
        /// </summary>
        [HttpGet("feed")]
        public async Task<IActionResult> GetPersonalizedFeed(
            [FromQuery] double? lat,
            [FromQuery] double? lng,
            [FromQuery] double? latitude,
            [FromQuery] double? longitude,
            [FromQuery] double? radius = null,
            [FromQuery] string? categoryAffinity = null,
            CancellationToken cancellationToken = default)
        {
            lat ??= latitude;
            lng ??= longitude;
            ResolveLocationFromHeaders(ref lat, ref lng);

            if (!IsValidCoordinate(lat, lng))
            {
                return Ok(new
                {
                    success = true,
                    greeting = "Namaste! Enable location to unlock personalized nearby recommendations.",
                    timeOfDay = ResolveTimeOfDayLabel(),
                    preferredCategory = "Nearby",
                    locationRequired = true,
                    message = "Enable location to see nearby recommendations for you.",
                    appliedRadiusKm = (double?)null,
                    data = Array.Empty<object>()
                });
            }

            var affinity = ParseCategoryAffinity(categoryAffinity);
            var userId = TryGetUserId();

            var feed = await _personalizationService.GetFeedAsync(
                lat!.Value,
                lng!.Value,
                radius,
                userId,
                affinity,
                cancellationToken);

            var mapped = feed.Items.Select(b => new
            {
                businessId = b.BusinessId,
                businessName = b.BusinessName,
                description = b.Description,
                categoryName = b.CategoryName,
                subcategoryName = b.SubcategoryName,
                address = b.Address,
                city = b.City,
                phone = b.Phone,
                email = b.Email,
                photos = b.Photos,
                distance = b.DistanceKm,
                latitude = b.Latitude,
                longitude = b.Longitude,
                score = b.Score,
                reason = b.Reason
            }).ToList();

            return Ok(new
            {
                success = true,
                greeting = feed.Greeting,
                timeOfDay = feed.TimeOfDay,
                preferredCategory = feed.PreferredCategory,
                locationRequired = false,
                message = feed.Message,
                appliedRadiusKm = feed.AppliedRadiusKm,
                data = mapped
            });
        }

        private static Dictionary<int, int>? ParseCategoryAffinity(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;
            // Format: "12:3,45:1,7:8" (categoryId:weight)
            var map = new Dictionary<int, int>();
            foreach (var part in raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                var bits = part.Split(':', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                if (bits.Length != 2) continue;
                if (!int.TryParse(bits[0], out var id) || !int.TryParse(bits[1], out var weight)) continue;
                if (id <= 0 || weight <= 0) continue;
                map[id] = weight;
            }
            return map.Count == 0 ? null : map;
        }

        private long? TryGetUserId()
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (long.TryParse(claim, out var id) && id > 0) return id;
            return null;
        }

        private static string ResolveTimeOfDayLabel()
        {
            var hour = DateTime.UtcNow.AddHours(5.5).Hour;
            if (hour >= 5 && hour < 12) return "Morning";
            if (hour >= 12 && hour < 17) return "Afternoon";
            if (hour >= 17 && hour < 22) return "Evening";
            return "Night";
        }

        private static bool IsValidCoordinate(double? lat, double? lng)
        {
            if (!lat.HasValue || !lng.HasValue) return false;
            if (lat is < -90 or > 90) return false;
            if (lng is < -180 or > 180) return false;
            if (lat == 0 && lng == 0) return false;
            return true;
        }

        private void ResolveLocationFromHeaders(ref double? latitude, ref double? longitude)
        {
            if (latitude.HasValue && longitude.HasValue) return;

            if (Request.Headers.ContainsKey("X-User-Latitude")
                && Request.Headers.ContainsKey("X-User-Longitude")
                && double.TryParse(Request.Headers["X-User-Latitude"], out var headerLat)
                && double.TryParse(Request.Headers["X-User-Longitude"], out var headerLng))
            {
                latitude ??= headerLat;
                longitude ??= headerLng;
            }
        }
    }
}
