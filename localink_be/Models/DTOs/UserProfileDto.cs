using System.ComponentModel.DataAnnotations;

public class UserProfileDto
{
    public long UserId { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string FullName { get; set; } = "";

    [Required]
    [EmailAddress]
    [MaxLength(100)]
    public string Email { get; set; } = "";

    [Phone]
    [MaxLength(15)]
    public string? Phone { get; set; }

    public AddressDto Address { get; set; } = new();
}

public class AddressDto
{
    [MaxLength(200)]
    public string? Street { get; set; }

    [Required(ErrorMessage = "City is required")]
    [MaxLength(100)]
    public string? City { get; set; }

    [Required(ErrorMessage = "State is required")]
    [MaxLength(100)]
    public string? State { get; set; }

    [Required(ErrorMessage = "Country is required")]
    [MaxLength(100)]
    public string? Country { get; set; }

    [RegularExpression(@"^$|^[A-Za-z0-9\-\s]{3,10}$", ErrorMessage = "Invalid pincode format")]
    [MaxLength(10)]
    public string? Pincode { get; set; }
}