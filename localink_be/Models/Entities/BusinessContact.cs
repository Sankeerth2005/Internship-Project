using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using NetTopologySuite.Geometries;

namespace localink_be.Models.Entities
{
    [Table("business_contact")]
    public class BusinessContact
    {
        [Key]
        [Column("contact_id")]
        public long ContactId { get; set; }

        [Column("business_id")]
        [Required(ErrorMessage = "BusinessId is required")]
        public long BusinessId { get; set; }

        [Column("phone_code")]
        [Required(ErrorMessage = "Phone code is required")]
        [RegularExpression(@"^\+?[1-9]\d{0,3}$", ErrorMessage = "Phone code must be in format +XX or XX (e.g., +91, 1, 44)")]
        public string PhoneCode { get; set; } = string.Empty;

        [Column("phone_number")]
        [Required(ErrorMessage = "Phone number is required")]
        [RegularExpression(@"^[3-9][0-9]{9}$", ErrorMessage = "Phone number must be 10 digits starting with 3–9")]
        public string PhoneNumber { get; set; } = string.Empty;

        [Column("email")]
        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid email format")]
        public string Email { get; set; } = string.Empty;

        [Column("website")]
        public string Website { get; set; } = string.Empty;

        [Column("street_address")]
        [Required(ErrorMessage = "Street address is required")]
        [StringLength(200, ErrorMessage = "Street address cannot exceed 200 characters")]
        public string StreetAddress { get; set; } = string.Empty;

        [Column("city")]
        [Required(ErrorMessage = "City is required")]
        public string City { get; set; } = string.Empty;

        [Column("state")]
        [Required(ErrorMessage = "State is required")]
        public string State { get; set; } = string.Empty;

        [Column("country")]
        [Required(ErrorMessage = "Country is required")]
        public string Country { get; set; } = string.Empty;

        [Column("pincode")]
        [RegularExpression(@"^$|^[A-Za-z0-9\-\s]{3,10}$", ErrorMessage = "Invalid pincode format")]
        public string Pincode { get; set; } = string.Empty;

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; }

        [Column("latitude")]
        public double? Latitude { get; set; }

        [Column("longitude")]
        public double? Longitude { get; set; }

        /// <summary>
        /// SQL Server geography point (SRID 4326). Synced from lat/lng by DB trigger.
        /// NTS uses (X=longitude, Y=latitude).
        /// </summary>
        [Column("geo_location")]
        public Point? GeoLocation { get; set; }

        public Business Business { get; set; } = null!;
    }
}
