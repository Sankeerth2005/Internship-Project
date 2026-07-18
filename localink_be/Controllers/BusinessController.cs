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

        [HttpGet]
        public async Task<IActionResult> GetAllBusinesses()
        {
            return Ok(await _service.GetAllBusinessesAsync());
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetBusinessById(long id)
        {
            var business = await _service.GetByIdAsync(id);
            if (business == null) return NotFound();
            return Ok(business);
        }

        [Authorize(Roles = "client,businessowner")]
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

        [Authorize(Roles = "client,businessowner")]
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

        [Authorize(Roles = "client,businessowner")]
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

        [HttpGet("v1/businesses/{id}")]
        public async Task<IActionResult> GetById(long id)
        {
            var result = await _service.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpGet("search")]
        public async Task<IActionResult> SearchBusinesses(
            [FromQuery] string? query = "", 
            [FromQuery] string? sortBy = "distance", 
            [FromQuery] string? userPincode = "", 
            [FromServices] localink_be.Data.AppDbContext db = null!)
        {
            // Get user location from headers if available
            double? userLat = null;
            double? userLng = null;
            string? userCity = null;

            if (Request.Headers.ContainsKey("X-User-Latitude") && 
                Request.Headers.ContainsKey("X-User-Longitude"))
            {
                if (double.TryParse(Request.Headers["X-User-Latitude"], out var lat) &&
                    double.TryParse(Request.Headers["X-User-Longitude"], out var lng))
                {
                    userLat = lat;
                    userLng = lng;
                }
            }

            if (Request.Headers.ContainsKey("X-User-City"))
            {
                userCity = Request.Headers["X-User-City"].ToString();
            }

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

            return Ok(await _service.SearchBusinessesAsync(query, userLat, userLng, sortBy, userPincode, userCity));
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

        [Authorize(Roles = "client,businessowner")]
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

            var business = await db.Businesses.FindAsync(id);
            if (business == null) return NotFound(new { message = "Business not found" });

            if (business.UserId != userId) return Forbid();

            business.TemporaryClosureReason = dto.Reason;
            business.TemporaryClosureDays = dto.Days;
            business.TemporaryClosureStatus = "Pending";
            business.TemporaryClosureReopenDate = null;

            await db.SaveChangesAsync();

            // Notify admin
            await hubContext.Clients.Group("admin").SendAsync("ReceiveNotification", $"Business '{business.BusinessName}' has requested temporary closure for {dto.Days} days. Reason: {dto.Reason}");

            return Ok(new { success = true, message = "Closure request submitted for admin approval" });
        }

        [Authorize(Roles = "client,businessowner")]
        [HttpPost("{id}/cancel-temporary-closure")]
        public async Task<IActionResult> CancelTemporaryClosure(
            long id,
            [FromServices] localink_be.Data.AppDbContext db)
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

            await db.SaveChangesAsync();

            return Ok(new { success = true, message = "Business is now open / temporary closure cancelled" });
        }

        public class DeletionRequestDto
        {
            public string Reason { get; set; } = null!;
        }

        [Authorize(Roles = "client,businessowner")]
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

            var business = await db.Businesses.FindAsync(id);
            if (business == null) return NotFound(new { message = "Business not found" });

            if (business.UserId != userId) return Forbid();

            var adminDash = await db.AdminDashboards.FirstOrDefaultAsync(a => a.BusinessId == id);
            if (adminDash == null)
            {
                adminDash = new AdminDashboard
                {
                    BusinessId = id,
                    CreatedAt = DateTime.UtcNow
                };
                await db.AdminDashboards.AddAsync(adminDash);
            }

            adminDash.Status = BusinessStatus.DeletionRequested;
            adminDash.RejectionReason = dto.Reason;
            adminDash.UpdatedAt = DateTime.UtcNow;

            await db.SaveChangesAsync();

            // Notify admin
            await hubContext.Clients.Group("admin").SendAsync("ReceiveNotification", $"Business '{business.BusinessName}' has requested permanent deletion. Reason: {dto.Reason}");

            return Ok(new { success = true, message = "Permanent deletion request submitted for admin approval" });
        }
    }
}
