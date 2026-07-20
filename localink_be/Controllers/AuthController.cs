using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Linq;
using System.Threading.Tasks;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [AllowAnonymous]
    [ApiController]
    [Route("api/v1/auth")]
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

        // SEND OTP
        [HttpPost("forgot-password")]
        public async Task<IActionResult> SendOtp([FromBody] SendOtpRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { success = false, errors = ModelState });

            var result = await _authService.SendResetOtpAsync(request.Email, request.CaptchaToken);

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
    }
}