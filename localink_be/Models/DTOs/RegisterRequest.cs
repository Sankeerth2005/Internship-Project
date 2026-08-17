using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
namespace localink_be.Models.DTOs
{
    public class RegisterRequest
    {
        [Required(ErrorMessage = "User type is required")]
        [RegularExpression(@"^(client|businessowner|user)$", ErrorMessage = "User type must be client, businessowner, or user")]
        public string UserType { get; set; } = string.Empty;

        [Required(ErrorMessage = "Name is required")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Name must be between 2 and 100 characters")]
        [RegularExpression(@"^[a-zA-Z\s\-\.']+$", ErrorMessage = "Name can only contain letters, spaces, hyphens, dots, and apostrophes")]
        public string Name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid email format")]
        [RegularExpression(@"^[a-zA-Z0-9](?:[a-zA-Z0-9._%+-]*[a-zA-Z0-9])?@[a-zA-Z0-9](?:[a-zA-Z0-9.-]*[a-zA-Z0-9])?\.[a-zA-Z]{2,}$",
            ErrorMessage = "Email must be a valid address (no trailing dots before @)")]
        [StringLength(256, ErrorMessage = "Email cannot exceed 256 characters")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Phone number is required")]
        [RegularExpression(@"^[0-9]{7,15}$", ErrorMessage = "Phone number must be between 7 and 15 digits")]
        public string Phone { get; set; } = string.Empty;

        [Required(ErrorMessage = "Country code is required")]
        [RegularExpression(@"^\+?[1-9]\d{0,3}$", ErrorMessage = "Country code must be in format +XX or XX (e.g., +91, 1, 44)")]
        public string CountryCode { get; set; } = string.Empty;

        [Required(ErrorMessage = "Password is required")]
        [StringLength(128, MinimumLength = 8, ErrorMessage = "Password must be between 8 and 128 characters")]
        [RegularExpression(@"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$",
        ErrorMessage = "Password must contain uppercase, lowercase, number, and special character")]
        public string Password { get; set; } = string.Empty;

        [StringLength(100, ErrorMessage = "Country cannot exceed 100 characters")]
        public string Country { get; set; } = string.Empty;

        [StringLength(100, ErrorMessage = "State cannot exceed 100 characters")]
        public string State { get; set; } = string.Empty;

        [StringLength(100, ErrorMessage = "City cannot exceed 100 characters")]
        public string City { get; set; } = string.Empty;

        [StringLength(500, ErrorMessage = "Street address cannot exceed 500 characters")]
        public string Street { get; set; } = string.Empty;

        [RegularExpression(@"^[A-Za-z0-9\-\s]{3,10}$", ErrorMessage = "Invalid pincode format (3-10 characters)")]
        public string Pincode { get; set; } = string.Empty;
    }
}