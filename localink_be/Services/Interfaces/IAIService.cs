namespace localink_be.Services.Interfaces
{
    public interface IAIService
    {
        Task<string[]> GetReviewSuggestionsAsync(string draftText, int rating, string businessName);
        Task<string?> GetReviewSummaryAsync(string[] reviews, double averageRating, int totalReviews, string businessName);
        Task<string?> GenerateDescriptionAsync(string businessName, string category, string[] keywords);
        Task<string?> ChatSearchAsync(string message, string chatHistoryJson);
        Task<string?> GetBusinessInsightsAsync(int views, int favorites, int clicks, string businessName);
        Task<string?> GetPersonalizedWelcomeAsync(string categoryPref, string timeOfDay);
    }
}
