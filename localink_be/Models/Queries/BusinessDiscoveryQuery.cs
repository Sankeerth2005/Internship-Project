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

        /// <summary>Search radius in kilometers. Null = use configured default when lat/lng present.</summary>
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
        /// When false and lat/lng provided, businesses outside radius are excluded.
        /// When true (no location), global catalog search is allowed.
        /// </summary>
        public bool RequireLocation { get; set; } = false;
    }
}
