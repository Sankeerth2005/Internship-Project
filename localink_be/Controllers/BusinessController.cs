using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using localink_be.Models.DTOs;
using localink_be.Models.Entities;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{

    [ApiController]
    [Route("api/v1/business")]
    public class BusinessController : ControllerBase
    {
        private readonly IBusinessService _service;
        private readonly IConfiguration _config;

        public BusinessController(IBusinessService service, IConfiguration config)
        {
            _service = service;
            _config = config;
        }

        /// <summary>
        /// Legacy unpaginated dump. Mobile discovery uses GET /api/v1/businesses.
        /// Restricted to admin; prefer the paged discovery endpoint for consumers.
        /// </summary>
        [Obsolete("Use GET /api/v1/businesses for paged discovery.")]
        [Authorize(Roles = "admin")]
        [HttpGet]
        public async Task<IActionResult> GetAllBusinesses()
        {
            return Ok(await _service.GetAllBusinessesAsync());
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetBusinessById(
            long id,
            [FromServices] localink_be.Data.AppDbContext db)
        {
            var business = await _service.GetByIdAsync(id);
            if (business == null) return NotFound();

            // Public consumers only see Approved listings. Owners/admins may view any status.
            if (!IsPubliclyVisibleStatus(business.Status))
            {
                var userIdStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                var isAdmin = User.IsInRole("admin");
                var isOwner = false;
                if (!string.IsNullOrEmpty(userIdStr) && long.TryParse(userIdStr, out var uid))
                {
                    var ownerId = await db.Businesses
                        .Where(b => b.BusinessId == id)
                        .Select(b => (long?)b.UserId)
                        .FirstOrDefaultAsync();
                    isOwner = ownerId == uid;
                }

                if (!isAdmin && !isOwner)
                    return NotFound();
            }

            return Ok(business);
        }

        private static bool IsPubliclyVisibleStatus(string? status)
        {
            if (string.IsNullOrWhiteSpace(status)) return false;
            return status.Equals("Approved", StringComparison.OrdinalIgnoreCase)
                || status.Equals("Active", StringComparison.OrdinalIgnoreCase);
        }

        [Authorize(Roles = "user,client,businessowner")]
        [HttpPost("register")]
        public async Task<IActionResult> RegisterBusiness([FromBody] RegisterBusinessDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Validation failed",
                    errors = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                });
            }

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var businessId = await _service.RegisterBusinessAsync(dto, long.Parse(userId));

            return Ok(new
            {
                success = true,
                businessId
            });
        }

        [Authorize(Roles = "user,client,businessowner")]
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateBusiness(long id, [FromBody] UpdateBusinessDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Validation failed",
                    errors = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                });
            }

            var userIdStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();
            long currentUserId = long.Parse(userIdStr);
            bool isAdmin = User.IsInRole("admin");

            try
            {
                var result = await _service.UpdateBusinessFullAsync(id, dto, currentUserId, isAdmin);
                return !result ? NotFound(new { success = false, message = "Business not found" }) : Ok(new { success = true, data = result });
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = ex.Message });
            }
        }

        [Authorize(Roles = "user,client,businessowner,admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteBusiness(long id)
        {
            var userIdStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();
            long currentUserId = long.Parse(userIdStr);
            bool isAdmin = User.IsInRole("admin");

            try
            {
                var deleted = await _service.DeleteBusinessAsync(id, currentUserId, isAdmin);
                return deleted ? NoContent() : NotFound();
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = ex.Message });
            }
        }

        [Authorize]
        [HttpGet("my-businesses")]
        public async Task<IActionResult> GetMyBusinesses()
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var data = await _service.GetBusinessesByUserAsync(long.Parse(userId));
            return Ok(data);
        }
        [HttpGet("subcategories/{subcategoryId}/businesses")]
        public async Task<IActionResult> GetBySubcategory(int subcategoryId)
        {
            var result = await _service.GetBySubcategoryAsync(subcategoryId);
            return Ok(result);
        }

        [HttpGet("search")]
        public async Task<IActionResult> SearchBusinesses(
            [FromQuery] string? query = "",
            [FromQuery] string? sortBy = "distance",
            [FromQuery] string? userPincode = "",
            [FromQuery] double? latitude = null,
            [FromQuery] double? longitude = null,
            [FromQuery] double? radius = null,
            [FromQuery] int? categoryId = null,
            [FromQuery] int? subcategoryId = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] bool paged = false,
            [FromServices] localink_be.Data.AppDbContext db = null!)
        {
            double? userLat = latitude;
            double? userLng = longitude;
            string? userCity = null;

            if ((!userLat.HasValue || !userLng.HasValue)
                && Request.Headers.ContainsKey("X-User-Latitude")
                && Request.Headers.ContainsKey("X-User-Longitude")
                && double.TryParse(Request.Headers["X-User-Latitude"], out var lat)
                && double.TryParse(Request.Headers["X-User-Longitude"], out var lng))
            {
                userLat ??= lat;
                userLng ??= lng;
            }

            if (Request.Headers.ContainsKey("X-User-City"))
                userCity = Request.Headers["X-User-City"].ToString();

            if (db != null && !string.IsNullOrEmpty(query))
            {
                try
                {
                    var log = new localink_be.Models.Entities.SearchQueryLog
                    {
                        Query = query,
                        Timestamp = DateTime.UtcNow
                    };
                    if (userLat.HasValue && userLng.HasValue)
                    {
                        log.Latitude = userLat.Value;
                        log.Longitude = userLng.Value;
                    }
                    db.SearchQueryLogs.Add(log);
                    await db.SaveChangesAsync();
                }
                catch { /* Suppress DB logging errors */ }
            }

            var result = await _service.SearchBusinessesPagedAsync(
                query, userLat, userLng, sortBy, userPincode, userCity,
                radius, categoryId, subcategoryId, page, pageSize);

            // Legacy clients expect a bare array; opt into envelope with paged=true
            if (paged)
                return Ok(result);

            return Ok(result.Items);
        }

        [HttpGet("validate-pincode/{pincode}")]
        public async Task<IActionResult> ValidatePincode(string pincode)
        {
            using var client = new HttpClient();

            var apiKey = _config["Geoapify:ApiKey"] ?? throw new Exception("Geoapify API key missing");
            var url = $"https://api.geoapify.com/v1/geocode/search?text={pincode}&format=json&apiKey={apiKey}";

            var response = await client.GetAsync(url);

            if (!response.IsSuccessStatusCode)
                return BadRequest("Geoapify failed");

            var content = await response.Content.ReadAsStringAsync();

            return Content(content, "application/json");
        }

        public class TemporaryClosureRequestDto
        {
            public string Reason { get; set; } = null!;
            public int Days { get; set; }
        }

        [Authorize(Roles = "user,client,businessowner,admin")]
        [HttpPost("{id}/temporary-closure")]
        public async Task<IActionResult> RequestTemporaryClosure(
            long id, 
            [FromBody] TemporaryClosureRequestDto dto,
            [FromServices] localink_be.Data.AppDbContext db,
            [FromServices] Microsoft.AspNetCore.SignalR.IHubContext<localink_be.Hubs.NotificationHub> hubContext)
        {
            var userIdVal = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdVal)) return Unauthorized();
            var userId = long.Parse(userIdVal);

            if (dto == null || string.IsNullOrWhiteSpace(dto.Reason))
                return BadRequest(new { success = false, message = "Reason is required" });

            var days = dto.Days <= 0 ? 1 : dto.Days;
            if (days > 365) days = 365;

            var business = await db.Businesses.FindAsync(id);
            if (business == null) return NotFound(new { message = "Business not found" });

            if (business.UserId != userId) return Forbid();

            // Owner-applied immediately — no admin approval required.
            business.TemporaryClosureReason = dto.Reason.Trim();
            business.TemporaryClosureDays = days;
            business.TemporaryClosureStatus = "Approved";
            business.TemporaryClosureReopenDate = DateTime.UtcNow.AddDays(days);
            business.UpdatedAt = DateTime.UtcNow;

            await db.SaveChangesAsync();

            await hubContext.Clients.All.SendAsync("ReceiveNotification", $"BusinessUpdated:{id}");
            await hubContext.Clients.Group("admin").SendAsync(
                "ReceiveNotification",
                $"Business '{business.BusinessName}' was temporarily closed by the owner for {days} days. Reason: {dto.Reason.Trim()}");

            return Ok(new
            {
                success = true,
                message = "Business temporarily closed",
                reopenDate = business.TemporaryClosureReopenDate
            });
        }

        [Authorize(Roles = "user,client,businessowner,admin")]
        [HttpPost("{id}/cancel-temporary-closure")]
        public async Task<IActionResult> CancelTemporaryClosure(
            long id,
            [FromServices] localink_be.Data.AppDbContext db,
            [FromServices] Microsoft.AspNetCore.SignalR.IHubContext<localink_be.Hubs.NotificationHub> hubContext)
        {
            var userIdVal = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdVal)) return Unauthorized();
            var userId = long.Parse(userIdVal);

            var business = await db.Businesses.FindAsync(id);
            if (business == null) return NotFound(new { message = "Business not found" });

            if (business.UserId != userId) return Forbid();

            business.TemporaryClosureReason = null;
            business.TemporaryClosureDays = null;
            business.TemporaryClosureStatus = null;
            business.TemporaryClosureReopenDate = null;
            business.UpdatedAt = DateTime.UtcNow;

            await db.SaveChangesAsync();

            await hubContext.Clients.All.SendAsync("ReceiveNotification", $"BusinessUpdated:{id}");

            return Ok(new { success = true, message = "Business is now open / temporary closure cancelled" });
        }

        public class DeletionRequestDto
        {
            public string Reason { get; set; } = null!;
        }

        [Authorize(Roles = "user,client,businessowner,admin")]
        [HttpPost("{id}/request-deletion")]
        public async Task<IActionResult> RequestDeletion(
            long id,
            [FromBody] DeletionRequestDto dto,
            [FromServices] localink_be.Data.AppDbContext db,
            [FromServices] Microsoft.AspNetCore.SignalR.IHubContext<localink_be.Hubs.NotificationHub> hubContext)
        {
            var userIdVal = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdVal)) return Unauthorized();
            var userId = long.Parse(userIdVal);

            if (dto == null || string.IsNullOrWhiteSpace(dto.Reason))
                return BadRequest(new { success = false, message = "Reason is required" });

            var business = await db.Businesses.FindAsync(id);
            if (business == null) return NotFound(new { message = "Business not found" });

            if (business.UserId != userId) return Forbid();

            var businessName = business.BusinessName;

            // Owner deletes immediately — no admin approval required.
            try
            {
                await hubContext.Clients.All.SendAsync("ReceiveNotification", $"BusinessDeleted:{id}");
                await hubContext.Clients.Group("admin").SendAsync(
                    "ReceiveNotification",
                    $"Business '{businessName}' was permanently deleted by the owner. Reason: {dto.Reason.Trim()}");
            }
            catch { /* notifications must not block deletion */ }

            var deleted = await _service.DeleteBusinessAsync(id, userId, isAdmin: false);
            if (!deleted)
                return NotFound(new { message = "Business not found" });

            return Ok(new { success = true, message = "Business permanently deleted" });
        }
    }
}
