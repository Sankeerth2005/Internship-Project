using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class ForgotPasswordRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(8)]
        [RegularExpression(@"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).+$",
        ErrorMessage = "Password must contain uppercase, lowercase and number")]
        public string NewPassword { get; set; } = string.Empty;
    }
}