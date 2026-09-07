using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    /// <summary>
    /// Read-only referral APIs. Counts and attribution are never accepted from the client.
    /// </summary>
    [ApiController]
    [Authorize]
    [Route("api/v1/referral")]
    public class ReferralController : ControllerBase
    {
        private readonly IReferralService _referralService;

        public ReferralController(IReferralService referralService)
        {
            _referralService = referralService;
        }

        /// <summary>My Referral Impact dashboard payload.</summary>
        [HttpGet("me")]
        public async Task<IActionResult> GetMyImpact(CancellationToken cancellationToken)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !long.TryParse(userIdClaim, out var userId))
                return Unauthorized(new { success = false, message = "Unauthorized" });

            var data = await _referralService.GetMyReferralImpactAsync(userId, cancellationToken);
            return Ok(new { success = true, data });
        }
    }
}
