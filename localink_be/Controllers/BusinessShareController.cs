using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using localink_be.Models.DTOs;
using localink_be.Services.Implementations;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/shares")]
    public class BusinessShareController : ControllerBase
    {
        private readonly IBusinessShareService _shareService;

        public BusinessShareController(IBusinessShareService shareService)
        {
            _shareService = shareService;
        }

        [Authorize]
        [HttpPost("business")]
        public async Task<IActionResult> CreateBusinessShare(
            [FromBody] CreateSingleBusinessShareRequest request,
            CancellationToken cancellationToken)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, message = "Validation failed" });

            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var (success, message, data) = await _shareService.CreateSingleBusinessShareAsync(
                userId.Value,
                request.BusinessId,
                cancellationToken);

            if (!success)
                return BadRequest(new { success = false, message });

            return Ok(new { success = true, message, data });
        }

        [Authorize]
        [HttpPost("favorites")]
        public async Task<IActionResult> CreateFavoritesShare(
            [FromBody] CreateFavoritesShareRequest request,
            CancellationToken cancellationToken)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var (success, message, data) = await _shareService.CreateFavoritesShareAsync(
                userId.Value,
                request,
                cancellationToken);

            if (!success)
                return BadRequest(new { success = false, message });

            return Ok(new { success = true, message, data });
        }

        /// <summary>Public read-only view of a shared snapshot (no private user data beyond display name).</summary>
        [AllowAnonymous]
        [HttpGet("{publicToken}")]
        public async Task<IActionResult> GetShare(
            string publicToken,
            CancellationToken cancellationToken)
        {
            if (BusinessShareService.NormalizeToken(publicToken) == null)
                return NotFound(new { success = false, message = "Share not found" });

            var view = await _shareService.GetShareByPublicTokenAsync(publicToken, cancellationToken);
            if (view == null)
                return NotFound(new { success = false, message = "Share not found" });

            return Ok(new { success = true, data = view });
        }

        private long? GetCurrentUserId()
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(claim) || !long.TryParse(claim, out var userId))
                return null;
            return userId;
        }
    }
}
