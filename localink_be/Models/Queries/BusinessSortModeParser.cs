using localink_be.Models.Enums;

namespace localink_be.Models.Queries
{
    public static class BusinessSortModeParser
    {
        public static BusinessSortMode Parse(string? sortBy)
        {
            if (string.IsNullOrWhiteSpace(sortBy))
                return BusinessSortMode.Nearest;

            return sortBy.Trim().ToLowerInvariant() switch
            {
                "nearest" or "distance" or "nearby" => BusinessSortMode.Nearest,
                "alphabetical" or "name" or "a-z" or "az" or "name_asc" => BusinessSortMode.NameAsc,
                "alphabetical_desc" or "z-a" or "za" or "name_desc" => BusinessSortMode.NameDesc,
                "toprated" or "top_rated" or "rating" or "reviews" => BusinessSortMode.TopRated,
                "mostreviewed" or "most_reviewed" or "review_count" => BusinessSortMode.MostReviewed,
                "newest" or "recent" or "recentlyadded" or "recently_added" => BusinessSortMode.Newest,
                "mostpopular" or "most_popular" or "popularity" or "popular" => BusinessSortMode.MostPopular,
                _ => BusinessSortMode.Nearest
            };
        }

        public static string ToApiValue(BusinessSortMode mode) => mode switch
        {
            BusinessSortMode.Nearest => "nearest",
            BusinessSortMode.NameAsc => "alphabetical",
            BusinessSortMode.NameDesc => "alphabetical_desc",
            BusinessSortMode.TopRated => "top_rated",
            BusinessSortMode.MostReviewed => "most_reviewed",
            BusinessSortMode.Newest => "newest",
            BusinessSortMode.MostPopular => "most_popular",
            _ => "nearest"
        };
    }
}
