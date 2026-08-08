using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [AllowAnonymous]
    [ApiController]
    [Route("api/v1/auth")]
    [EnableRateLimiting("AuthPolicy")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        private IActionResult ValidateRequest()
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(x => x.Value?.Errors.Count > 0)
                    .Select(x => new
                    {
                        field = x.Key,
                        errors = x.Value!.Errors.Select(e => e.ErrorMessage)
                    });

                return BadRequest(new
                {
                    success = false,
                    message = "Validation failed",
                    errors
                });
            }

            return null!;
        }

        // LOGIN
        [HttpPost("sessions")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            var result = await _authService.LoginAsync(request);

            return Ok(new
            {
                success = true,
                data = result
            });
        }

        // REFRESH ACCESS TOKEN (keeps mobile users signed in across access-token expiry)
        [HttpPost("refresh")]
        public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            var result = await _authService.RefreshSessionAsync(request.RefreshToken);

            return Ok(new
            {
                success = true,
                data = result
            });
        }

        // LOGOUT — revoke refresh token so the device session ends intentionally
        [HttpPost("logout")]
        public async Task<IActionResult> Logout([FromBody] LogoutRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            await _authService.LogoutAsync(request.RefreshToken);

            return Ok(new
            {
                success = true,
                message = "Logged out successfully"
            });
        }

        // REGISTER
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            var result = await _authService.RegisterAsync(request);

            return Ok(new
            {
                success = true,
                message = result
            });
        }

        // GOOGLE SIGN-IN
        [HttpPost("google")]
        public async Task<IActionResult> GoogleSignIn([FromBody] GoogleAuthRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            var result = await _authService.GoogleSignInAsync(request.IdToken);

            return Ok(new
            {
                success = true,
                data = result
            });
        }

        // SEND OTP
        [HttpPost("forgot-password")]
        public async Task<IActionResult> SendOtp([FromBody] SendOtpRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            var result = await _authService.SendResetOtpAsync(request.Email);

            return Ok(new
            {
                success = true,
                message = result
            });
        }

        // RESET PASSWORD
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordWithOtpRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            var result = await _authService.VerifyOtpAndResetPasswordAsync(
                request.Email,
                request.Otp,
                request.NewPassword
            );

            return Ok(new
            {
                success = true,
                message = result
            });
        }

        // CHANGE PASSWORD (authenticated)
        [Authorize]
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !long.TryParse(userIdClaim, out var userId))
                return Unauthorized(new { success = false, message = "Unauthorized" });

            var result = await _authService.ChangePasswordAsync(userId, request);

            return Ok(new
            {
                success = true,
                message = result
            });
        }
    }
}
