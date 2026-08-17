using localink_be.Models.DTOs;

namespace localink_be.Services.Interfaces
{
    public interface IPersonalizationService
    {
        Task<PersonalizedFeedResult> GetFeedAsync(
            double latitude,
            double longitude,
            double? radiusKm,
            long? userId,
            IReadOnlyDictionary<int, int>? categoryAffinity,
            CancellationToken cancellationToken = default);
    }

    public sealed class PersonalizedFeedResult
    {
        public string TimeOfDay { get; set; } = "Day";
        public string PreferredCategory { get; set; } = "Services";
        public string Greeting { get; set; } = "Namaste! Welcome back.";
        public double? AppliedRadiusKm { get; set; }
        public IReadOnlyList<PersonalizedFeedItem> Items { get; set; } = Array.Empty<PersonalizedFeedItem>();
        public string? Message { get; set; }
    }

    public sealed class PersonalizedFeedItem
    {
        public long BusinessId { get; set; }
        public string BusinessName { get; set; } = "";
        public string Description { get; set; } = "";
        public string CategoryName { get; set; } = "";
        public string SubcategoryName { get; set; } = "";
        public string Address { get; set; } = "";
        public string City { get; set; } = "";
        public string Phone { get; set; } = "";
        public string Email { get; set; } = "";
        public List<string> Photos { get; set; } = new();
        public double? DistanceKm { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public double Score { get; set; }
        public string Reason { get; set; } = "";
    }
}
