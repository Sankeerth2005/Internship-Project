using System.Collections.Generic;

namespace localink_be.Models.DTOs
{
    public class UpdateBusinessDto
    {
        public string BusinessName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public int SubcategoryId { get; set; }

        public string PhoneCode { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Website { get; set; } = string.Empty;

        public string City { get; set; } = string.Empty;
        public string StreetAddress { get; set; } = string.Empty;
        public string State { get; set; } = string.Empty;
        public string Country { get; set; } = string.Empty;
        public string Pincode { get; set; } = string.Empty;
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public string? Photo { get; set; }
        public List<DayHoursDto> Hours { get; set; } = new List<DayHoursDto>();
    }
}