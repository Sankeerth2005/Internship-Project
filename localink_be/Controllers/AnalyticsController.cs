using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/analytics")]
    public class AnalyticsController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IAIService _aiService;

        public AnalyticsController(AppDbContext db, IAIService aiService)
        {
            _db = db;
            _aiService = aiService;
        }

        private long? TryGetUserId()
        {
            var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return long.TryParse(idClaim, out var id) ? id : null;
        }

        private bool IsAdmin() =>
            User.IsInRole("admin") ||
            string.Equals(User.FindFirst(ClaimTypes.Role)?.Value, "admin", StringComparison.OrdinalIgnoreCase);

        private async Task<bool> OwnsBusinessAsync(long businessId)
        {
            if (IsAdmin()) return true;
            var userId = TryGetUserId();
            if (userId == null) return false;
            return await _db.Businesses.AnyAsync(b => b.BusinessId == businessId && b.UserId == userId);
        }

        [HttpPost("business/{id}/view")]
        [AllowAnonymous]
        public async Task<IActionResult> IncrementView(long id)
        {
            var exists = await _db.Businesses.AnyAsync(b => b.BusinessId == id);
            if (!exists) return NotFound("Business not found");

            var rows = await _db.Database.ExecuteSqlInterpolatedAsync(
                $"UPDATE business_metric SET views = views + 1, updated_at = {DateTime.UtcNow} WHERE business_id = {id}");
            if (rows == 0)
            {
                _db.BusinessMetrics.Add(new BusinessMetric
                {
                    BusinessId = id,
                    Views = 1,
                    UpdatedAt = DateTime.UtcNow
                });
                try
                {
                    await _db.SaveChangesAsync();
                }
                catch (DbUpdateException)
                {
                    await _db.Database.ExecuteSqlInterpolatedAsync(
                        $"UPDATE business_metric SET views = views + 1, updated_at = {DateTime.UtcNow} WHERE business_id = {id}");
                }
            }

            var views = await _db.BusinessMetrics.Where(m => m.BusinessId == id).Select(m => m.Views).FirstOrDefaultAsync();
            return Ok(new { success = true, views });
        }

        [HttpPost("business/{id}/click")]
        [AllowAnonymous]
        public async Task<IActionResult> IncrementClick(long id)
        {
            var exists = await _db.Businesses.AnyAsync(b => b.BusinessId == id);
            if (!exists) return NotFound("Business not found");

            var rows = await _db.Database.ExecuteSqlInterpolatedAsync(
                $"UPDATE business_metric SET contact_clicks = contact_clicks + 1, updated_at = {DateTime.UtcNow} WHERE business_id = {id}");
            if (rows == 0)
            {
                _db.BusinessMetrics.Add(new BusinessMetric
                {
                    BusinessId = id,
                    ContactClicks = 1,
                    UpdatedAt = DateTime.UtcNow
                });
                try
                {
                    await _db.SaveChangesAsync();
                }
                catch (DbUpdateException)
                {
                    await _db.Database.ExecuteSqlInterpolatedAsync(
                        $"UPDATE business_metric SET contact_clicks = contact_clicks + 1, updated_at = {DateTime.UtcNow} WHERE business_id = {id}");
                }
            }

            var clicks = await _db.BusinessMetrics.Where(m => m.BusinessId == id).Select(m => m.ContactClicks).FirstOrDefaultAsync();
            return Ok(new { success = true, clicks });
        }

        [Authorize(Roles = "client,businessowner,admin")]
        [HttpGet("business/{id}")]
        public async Task<IActionResult> GetMetrics(long id)
        {
            if (!await OwnsBusinessAsync(id))
                return Forbid();

            var business = await _db.Businesses.FirstOrDefaultAsync(b => b.BusinessId == id);
            if (business == null) return NotFound("Business not found");

            var metric = await _db.BusinessMetrics.FirstOrDefaultAsync(m => m.BusinessId == id);
            var favoritesCount = await _db.Favorites.CountAsync(f => f.BusinessId == id);

            return Ok(new
            {
                success = true,
                data = new
                {
                    businessId = id,
                    views = metric?.Views ?? 0,
                    favorites = favoritesCount,
                    clicks = metric?.ContactClicks ?? 0
                }
            });
        }

        [Authorize(Roles = "client,businessowner,admin")]
        [HttpPost("ai-insights/{id}")]
        public async Task<IActionResult> GetAiInsights(long id)
        {
            if (!await OwnsBusinessAsync(id))
                return Forbid();

            var business = await _db.Businesses.FirstOrDefaultAsync(b => b.BusinessId == id);
            if (business == null) return NotFound("Business not found");

            var metric = await _db.BusinessMetrics.FirstOrDefaultAsync(m => m.BusinessId == id);
            var favoritesCount = await _db.Favorites.CountAsync(f => f.BusinessId == id);

            int views = metric?.Views ?? 0;
            int clicks = metric?.ContactClicks ?? 0;

            var insights = await _aiService.GetBusinessInsightsAsync(views, favoritesCount, clicks, business.BusinessName);
            return Ok(new { success = true, data = insights });
        }

        [Authorize(Roles = "admin")]
        [HttpGet("heatmap")]
        public async Task<IActionResult> GetHeatmapData()
        {
            var businesses = await _db.Businesses
                .Include(b => b.AdminDashboard)
                .Where(b => b.AdminDashboard != null && b.AdminDashboard.Status == BusinessStatus.Approved)
                .Select(b => new
                {
                    b.BusinessName,
                    Latitude = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Latitude)
                        .FirstOrDefault(),
                    Longitude = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Longitude)
                        .FirstOrDefault()
                })
                .ToListAsync();

            var mappedBusinesses = businesses.Select(b => new
            {
                businessName = b.BusinessName,
                latitude = b.Latitude,
                longitude = b.Longitude
            }).ToList();

            var searchLogs = await _db.SearchQueryLogs
                .OrderByDescending(s => s.Timestamp)
                .Take(50)
                .Select(s => new {
                    query = s.Query,
                    latitude = s.Latitude,
                    longitude = s.Longitude
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                businesses = mappedBusinesses,
                searches = searchLogs
            });
        }

        [Authorize(Roles = "admin")]
        [HttpGet("insights")]
        public async Task<IActionResult> GetInsights()
        {
            var categoryMetrics = await _db.Businesses
                .Include(b => b.Category)
                .Join(_db.BusinessMetrics,
                    b => b.BusinessId,
                    m => m.BusinessId,
                    (b, m) => new { b.Category.CategoryName, m.Views, m.ContactClicks, m.FavoritesCount })
                .GroupBy(x => x.CategoryName)
                .Select(g => new
                {
                    Category = g.Key,
                    TotalViews = g.Sum(x => x.Views),
                    TotalClicks = g.Sum(x => x.ContactClicks),
                    TotalFavorites = g.Sum(x => x.FavoritesCount)
                })
                .ToListAsync();

            var totalBusinesses = await _db.Businesses.CountAsync();
            var totalUsers = await _db.Users.CountAsync();
            var activeUsers = await _db.Users.CountAsync(u => u.AccountType == "user");

            return Ok(new
            {
                success = true,
                data = new
                {
                    categoryMetrics,
                    overview = new
                    {
                        totalBusinesses,
                        totalUsers,
                        activeUsers
                    }
                }
            });
        }
    }
}
