using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using localink_be.Data;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;
using System.Security.Claims;
using System.Threading.Tasks;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/business/{businessId}/hours")]
    public class BusinessHoursController : ControllerBase
    {
        private readonly IHoursService _hoursService;
        private readonly AppDbContext _db;

        public BusinessHoursController(IHoursService hoursService, AppDbContext db)
        {
            _hoursService = hoursService;
            _db = db;
        }

        private long GetCurrentUserId()
        {
            var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (long.TryParse(idClaim, out long id)) return id;
            throw new UnauthorizedAccessException("Invalid token");
        }

        private bool IsAdmin() =>
            User.IsInRole("admin") ||
            string.Equals(User.FindFirst(ClaimTypes.Role)?.Value, "admin", StringComparison.OrdinalIgnoreCase);

        private async Task EnsureOwnsBusinessAsync(long businessId)
        {
            if (IsAdmin()) return;
            var userId = GetCurrentUserId();
            var owns = await _db.Businesses.AnyAsync(b => b.BusinessId == businessId && b.UserId == userId);
            if (!owns)
                throw new UnauthorizedAccessException("You do not own this business");
        }

        [Authorize(Roles = "client,businessowner,admin")]
        [HttpPost]
        public async Task<IActionResult> CreateOrReplaceBusinessHours(long businessId, [FromBody] System.Collections.Generic.List<DayHoursDto> dto)
        {
            try
            {
                await EnsureOwnsBusinessAsync(businessId);
                var hoursDto = new BusinessHoursDto { Days = dto };
                var result = await _hoursService.CreateOrReplaceBusinessHoursAsync(businessId, hoursDto);
                return Ok(result);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetBusinessHours(long businessId)
        {
            var hours = await _hoursService.GetBusinessHoursAsync(businessId);
            if (hours == null)
                return NotFound();

            return Ok(hours);
        }
    }
}
