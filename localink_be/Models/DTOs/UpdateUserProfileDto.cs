using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class UpdateUserProfileDto
    {
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

        [Required(ErrorMessage = "Country code is required")]
        [RegularExpression(@"^[+]?[0-9]{1,4}$", ErrorMessage = "Phone code must be between 1 and 4 digits, optionally starting with +")]
        public string CountryCode { get; set; } = "";

        [StringLength(500000, ErrorMessage = "Profile picture data too large")]
        public string? ProfilePicture { get; set; }

        [Required(ErrorMessage = "Address is required")]
        public AddressDto Address { get; set; } = new();
    }
}