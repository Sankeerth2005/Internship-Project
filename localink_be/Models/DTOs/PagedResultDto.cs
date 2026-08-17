namespace localink_be.Models.DTOs
{
    public class PagedResultDto<T>
    {
        public IReadOnlyList<T> Items { get; set; } = Array.Empty<T>();
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalCount { get; set; }
        public int TotalPages => PageSize <= 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
        public bool HasNextPage => Page < TotalPages;
        public bool HasPreviousPage => Page > 1;

        /// <summary>Echo of applied radius in km (always null — distance ranks, it does not hide businesses).</summary>
        public double? AppliedRadiusKm { get; set; }

        /// <summary>Echo of applied sort key for clients.</summary>
        public string Sort { get; set; } = "nearest";
    }
}
