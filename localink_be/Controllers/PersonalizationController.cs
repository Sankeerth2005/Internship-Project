using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;
using localink_be.Models.DTOs;
using localink_be.Models.Enums;
using localink_be.Models.Queries;
using localink_be.Services.Implementations;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/personalization")]
    [EnableRateLimiting("AiPolicy")]
    public class PersonalizationController : ControllerBase
    {
        private const int FeedPageSize = 20;
        private const int FeedTake = 5;

        private readonly IAIService _aiService;
        private readonly IBusinessDiscoveryService _discoveryService;
        private readonly BusinessDiscoveryOptions _discoveryOptions;

        public PersonalizationController(
            IAIService aiService,
            IBusinessDiscoveryService discoveryService,
            IOptions<BusinessDiscoveryOptions> discoveryOptions)
        {
            _aiService = aiService;
            _discoveryService = discoveryService;
            _discoveryOptions = discoveryOptions.Value;
        }

        /// <summary>
        /// Location-scoped AI "For You" feed.
        /// Returns nearby approved businesses only (same radius defaults as discovery).
        /// When lat/lng are missing, returns an empty feed with locationRequired=true.
        /// </summary>
        [HttpGet("feed")]
        public async Task<IActionResult> GetPersonalizedFeed(
            [FromQuery] double? lat,
            [FromQuery] double? lng,
            [FromQuery] double? latitude,
            [FromQuery] double? longitude,
            [FromQuery] double? radius = null,
            CancellationToken cancellationToken = default)
        {
            // Prefer explicit lat/lng; also accept latitude/longitude aliases used elsewhere.
            lat ??= latitude;
            lng ??= longitude;
            ResolveLocationFromHeaders(ref lat, ref lng);

            var hour = DateTime.UtcNow.AddHours(5.5).Hour; // IST
            string timeOfDay;
            string preferredCategory;

            if (hour >= 5 && hour < 12)
            {
                timeOfDay = "Morning";
                preferredCategory = "Bakery & Cafe";
            }
            else if (hour >= 12 && hour < 17)
            {
                timeOfDay = "Afternoon";
                preferredCategory = "Restaurants & Dining";
            }
            else if (hour >= 17 && hour < 22)
            {
                timeOfDay = "Evening";
                preferredCategory = "Services & Wellness";
            }
            else
            {
                timeOfDay = "Night";
                preferredCategory = "Dining & Convenience";
            }

            var greeting = await _aiService.GetPersonalizedWelcomeAsync(preferredCategory, timeOfDay);

            if (!IsValidCoordinate(lat, lng))
            {
                return Ok(new
                {
                    success = true,
                    greeting,
                    timeOfDay,
                    preferredCategory,
                    locationRequired = true,
                    message = "Enable location to see nearby recommendations for you.",
                    appliedRadiusKm = (double?)null,
                    data = Array.Empty<object>()
                });
            }

            var discovery = await _discoveryService.DiscoverAsync(new BusinessDiscoveryQuery
            {
                Latitude = lat,
                Longitude = lng,
                RadiusKm = radius,
                Sort = BusinessSortMode.Nearest,
                Page = 1,
                PageSize = FeedPageSize,
                RequireLocation = true
            }, cancellationToken);

            var nearby = discovery.Items ?? Array.Empty<BusinessDto>();

            // Soft preference for time-of-day category among nearby only — never expands radius.
            var preferred = preferredCategory.ToLowerInvariant();
            var matching = nearby
                .Where(b => CategoryMatches(b.CategoryName, preferred))
                .ToList();
            var others = nearby
                .Where(b => !CategoryMatches(b.CategoryName, preferred))
                .ToList();

            var selected = matching.Concat(others).Take(FeedTake).ToList();

            if (matching.Count == 0 && selected.Count > 0)
            {
                preferredCategory = selected[0].CategoryName ?? preferredCategory;
            }

            var mappedList = selected.Select(b => new
            {
                businessId = b.Id,
                businessName = b.Name,
                description = b.Description,
                categoryName = b.CategoryName ?? "",
                subcategoryName = b.SubcategoryName ?? "",
                address = b.StreetAddress ?? "",
                city = b.City ?? "",
                phone = b.PhoneNumber ?? "",
                email = b.Email ?? "",
                photos = b.Photos != null && b.Photos.Count > 0
                    ? b.Photos
                    : (b.PrimaryImage != null ? new List<string> { b.PrimaryImage } : new List<string>()),
                distance = b.Distance.HasValue ? Math.Round(b.Distance.Value, 2) : 0d,
                latitude = b.Latitude,
                longitude = b.Longitude
            }).ToList();

            return Ok(new
            {
                success = true,
                greeting,
                timeOfDay,
                preferredCategory,
                locationRequired = false,
                message = mappedList.Count == 0
                    ? "No businesses found near your location right now."
                    : (string?)null,
                appliedRadiusKm = discovery.AppliedRadiusKm ?? _discoveryOptions.DefaultRadiusKm,
                data = mappedList
            });
        }

        private static bool CategoryMatches(string? categoryName, string preferredLower)
        {
            if (string.IsNullOrWhiteSpace(categoryName)) return false;
            var name = categoryName.ToLowerInvariant();
            return name.Contains(preferredLower) || preferredLower.Contains(name);
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
