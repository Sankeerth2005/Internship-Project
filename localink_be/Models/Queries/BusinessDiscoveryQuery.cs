using localink_be.Models.Enums;

namespace localink_be.Models.Queries
{
    /// <summary>
    /// Enterprise discovery query. All filtering/sorting/pagination happens in SQL.
    /// </summary>
    public class BusinessDiscoveryQuery
    {
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        /// <summary>
        /// Optional search radius in kilometers. Ignored as a visibility cutoff;
        /// eligible matching businesses are ranked by distance instead.
        /// </summary>
        public double? RadiusKm { get; set; }

        public string? Search { get; set; }
        public int? CategoryId { get; set; }
        public int? SubcategoryId { get; set; }
        public string? UserPincode { get; set; }
        public string? UserCity { get; set; }

        public BusinessSortMode Sort { get; set; } = BusinessSortMode.Nearest;

        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;

        /// <summary>
        /// When true and lat/lng are missing, return an empty page (location-gated features).
        /// When false, discovery still runs using non-distance ranking.
        /// </summary>
        public bool RequireLocation { get; set; } = false;
    }
}
