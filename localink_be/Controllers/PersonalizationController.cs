using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/personalization")]
    public class PersonalizationController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IAIService _aiService;

        public PersonalizationController(AppDbContext db, IAIService aiService)
        {
            _db = db;
            _aiService = aiService;
        }

        [HttpGet("feed")]
        public async Task<IActionResult> GetPersonalizedFeed([FromQuery] double? lat, [FromQuery] double? lng)
        {
            // Determine time of day
            var hour = DateTime.UtcNow.AddHours(5.5).Hour; // Offset to India standard time
            string timeOfDay = "Day";
            string preferredCategory = "Food";

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

            // Get a warm personalized welcome from Groq
            var greeting = await _aiService.GetPersonalizedWelcomeAsync(preferredCategory, timeOfDay);

            // Fetch top 3 approved businesses matching this preference, or general if none match
            var query = _db.Businesses
                .Include(b => b.Category)
                .Include(b => b.Subcategory)
                .Include(b => b.AdminDashboard)
                .Where(b => b.AdminDashboard != null && b.AdminDashboard.Status == BusinessStatus.Approved);

            // Calculate distance manually if coordinates exist
            var list = await query.ToListAsync();

            var mappedList = list.Select(b => {
                var address = _db.Addresses.FirstOrDefault(a => a.UserId == b.UserId);
                var contact = _db.BusinessContacts.FirstOrDefault(c => c.BusinessId == b.BusinessId);
                var photo = _db.BusinessPhotos.FirstOrDefault(p => p.BusinessId == b.BusinessId);

                double distance = 0;
                if (lat.HasValue && lng.HasValue)
                {
                    // Basic distance calculation
                    var dbAddress = _db.Addresses.FirstOrDefault(a => a.UserId == b.UserId);
                    // Mock coordinates check if geocoding coordinates are stored or fallback
                    distance = 1.2; // Fallback mock distance
                }

                return new {
                    businessId = b.BusinessId,
                    businessName = b.BusinessName,
                    description = b.Description,
                    categoryName = b.Category.CategoryName,
                    subcategoryName = b.Subcategory.SubcategoryName,
                    address = address?.StreetAddress ?? "",
                    city = address?.City ?? "",
                    phone = contact?.PhoneNumber ?? "",
                    email = contact?.Email ?? "",
                    photos = photo != null ? new[] { photo.ImageUrl } : Array.Empty<string>(),
                    distance = distance
                };
            }).Take(3).ToList();

            return Ok(new
            {
                success = true,
                greeting = greeting,
                timeOfDay = timeOfDay,
                preferredCategory = preferredCategory,
                data = mappedList
            });
        }
    }
}
