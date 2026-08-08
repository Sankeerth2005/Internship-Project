using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class LoginRequest
    {
        [Required(ErrorMessage = "Username or email is required")]
        [StringLength(256, ErrorMessage = "Username or email cannot exceed 256 characters")]
        public string UsernameOrEmail { get; set; } = string.Empty;

        [Required(ErrorMessage = "Password is required")]
        [StringLength(128, ErrorMessage = "Password cannot exceed 128 characters")]
        public string Password { get; set; } = string.Empty;
    }
}
