namespace localink_be.Models.DTOs
{
    public class BusinessDto
    {
        public long Id { get; set; }   
        public string Name { get; set; } = null!;
        public string Description { get; set; } = null!;
        public string CategoryName { get; set; } = null!;
        public string SubcategoryName { get; set; } = null!;

    public string? PhoneNumber { get; set; }
    public string? PhoneCode { get; set; }
    public string? Email { get; set; }

    public string? Country { get; set; }

    public string? Pincode { get; set; }

    public string? StreetAddress { get; set; }

        public string? City { get; set; }
        public string? State { get; set; }
        public string? Status {get; set;}
        public string? PrimaryImage { get; set; }
        public int SubcategoryId { get; set; }
        public int CategoryId { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public double? Distance { get; set; } 
        public double AverageRating { get; set; }
        public int TotalReviews { get; set; }

        public bool IsTemporarilyClosed { get; set; }
        public string? TemporaryClosureReason { get; set; }
        public string? TemporaryClosureStatus { get; set; }
        public int? TemporaryClosureDays { get; set; }
        public DateTime? TemporaryClosureReopenDate { get; set; }
        public List<string>? Photos { get; set; }
        public List<DayHoursDto>? Hours { get; set; }
    }
}