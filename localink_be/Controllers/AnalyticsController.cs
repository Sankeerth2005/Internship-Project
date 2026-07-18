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

        [HttpPost("business/{id}/view")]
        public async Task<IActionResult> IncrementView(long id)
        {
            var business = await _db.Businesses.AnyAsync(b => b.BusinessId == id);
            if (!business) return NotFound("Business not found");

            var metric = await _db.BusinessMetrics.FirstOrDefaultAsync(m => m.BusinessId == id);
            if (metric == null)
            {
                metric = new BusinessMetric
                {
                    BusinessId = id,
                    Views = 1,
                    UpdatedAt = DateTime.UtcNow
                };
                _db.BusinessMetrics.Add(metric);
            }
            else
            {
                metric.Views++;
                metric.UpdatedAt = DateTime.UtcNow;
            }

            await _db.SaveChangesAsync();
            return Ok(new { success = true, views = metric.Views });
        }

        [HttpPost("business/{id}/click")]
        public async Task<IActionResult> IncrementClick(long id)
        {
            var business = await _db.Businesses.AnyAsync(b => b.BusinessId == id);
            if (!business) return NotFound("Business not found");

            var metric = await _db.BusinessMetrics.FirstOrDefaultAsync(m => m.BusinessId == id);
            if (metric == null)
            {
                metric = new BusinessMetric
                {
                    BusinessId = id,
                    ContactClicks = 1,
                    UpdatedAt = DateTime.UtcNow
                };
                _db.BusinessMetrics.Add(metric);
            }
            else
            {
                metric.ContactClicks++;
                metric.UpdatedAt = DateTime.UtcNow;
            }

            await _db.SaveChangesAsync();
            return Ok(new { success = true, clicks = metric.ContactClicks });
        }

        [HttpGet("business/{id}")]
        public async Task<IActionResult> GetMetrics(long id)
        {
            var business = await _db.Businesses.FirstOrDefaultAsync(b => b.BusinessId == id);
            if (business == null) return NotFound("Business not found");

            var metric = await _db.BusinessMetrics.FirstOrDefaultAsync(m => m.BusinessId == id);
            var favoritesCount = await _db.Favorites.CountAsync(f => f.BusinessId == id);

            if (metric != null && metric.FavoritesCount != favoritesCount)
            {
                metric.FavoritesCount = favoritesCount;
                await _db.SaveChangesAsync();
            }

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

        [HttpPost("ai-insights/{id}")]
        public async Task<IActionResult> GetAiInsights(long id)
        {
            var business = await _db.Businesses.FirstOrDefaultAsync(b => b.BusinessId == id);
            if (business == null) return NotFound("Business not found");

            var metric = await _db.BusinessMetrics.FirstOrDefaultAsync(m => m.BusinessId == id);
            var favoritesCount = await _db.Favorites.CountAsync(f => f.BusinessId == id);

            int views = metric?.Views ?? 0;
            int clicks = metric?.ContactClicks ?? 0;

            var insights = await _aiService.GetBusinessInsightsAsync(views, favoritesCount, clicks, business.BusinessName);
            return Ok(new { success = true, data = insights });
        }

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

    }
}
