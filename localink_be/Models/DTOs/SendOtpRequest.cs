using System.ComponentModel.DataAnnotations;

public class SendOtpRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
}
