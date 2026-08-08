using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class RefreshTokenRequest
    {
        [Required(ErrorMessage = "Refresh token is required")]
        [StringLength(512, MinimumLength = 32, ErrorMessage = "Invalid refresh token")]
        public string RefreshToken { get; set; } = string.Empty;
    }
}
