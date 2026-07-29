using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class UserProfileDto
    {
        public long UserId { get; set; }
        
        [Required(ErrorMessage = "Full name is required")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Full name must be between 2 and 100 characters")]
        [RegularExpression(@"^[a-zA-Z\s\-\.']+$", ErrorMessage = "Name can only contain letters, spaces, hyphens, dots, and apostrophes")]
        public string FullName { get; set; } = "";

        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid email format")]
        [RegularExpression(@"^[^\s@]+@[^\s@]+\.[^\s@]+$", ErrorMessage = "Email must be a valid email address")]
        [StringLength(256, ErrorMessage = "Email cannot exceed 256 characters")]
        public string Email { get; set; } = "";

        [Required(ErrorMessage = "Phone number is required")]
        [RegularExpression(@"^[+]?[0-9]{7,15}$", ErrorMessage = "Phone number must be between 7 and 15 digits, optionally starting with +")]
        [StringLength(15, ErrorMessage = "Phone number cannot exceed 15 characters")]
        public string Phone { get; set; } = "";

        public string CountryCode { get; set; } = string.Empty;

        [StringLength(500000, ErrorMessage = "Profile picture data too large")]
        public string? ProfilePicture { get; set; }

        public AddressDto Address { get; set; } = new();
    }

    public class AddressDto
    {
        [StringLength(500, ErrorMessage = "Street address cannot exceed 500 characters")]
        public string? Street { get; set; }

        [Required(ErrorMessage = "City is required")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "City must be between 2 and 100 characters")]
        [RegularExpression(@"^[a-zA-Z\s\-\.']+$", ErrorMessage = "City can only contain letters, spaces, hyphens, dots, and apostrophes")]
        public string? City { get; set; }

        [Required(ErrorMessage = "State is required")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "State must be between 2 and 100 characters")]
        [RegularExpression(@"^[a-zA-Z\s\-\.']+$", ErrorMessage = "State can only contain letters, spaces, hyphens, dots, and apostrophes")]
        public string? State { get; set; }

        [Required(ErrorMessage = "Country is required")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Country must be between 2 and 100 characters")]
        [RegularExpression(@"^[a-zA-Z\s\-\.']+$", ErrorMessage = "Country can only contain letters, spaces, hyphens, dots, and apostrophes")]
        public string? Country { get; set; }

        [Required(ErrorMessage = "Pincode is required")]
        [RegularExpression(@"^[A-Za-z0-9\-\s]{3,15}$", ErrorMessage = "Pincode must be 3-15 characters and can contain letters, numbers, hyphens, and spaces")]
        [StringLength(15, ErrorMessage = "Pincode cannot exceed 15 characters")]
        public string? Pincode { get; set; }
    }
}