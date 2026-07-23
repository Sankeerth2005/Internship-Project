using System.ComponentModel.DataAnnotations;

public class ResetPasswordWithOtpRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [RegularExpression(@"^[0-9]{6}$", ErrorMessage = "OTP must be exactly 6 digits")]
    public string Otp { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    [RegularExpression(@"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).+$",
    ErrorMessage = "Password must contain uppercase, lowercase and number")]
    public string NewPassword { get; set; } = string.Empty;
}