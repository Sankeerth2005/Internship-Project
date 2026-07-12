using System.Net.Http.Headers;
using System.Text.Json;
using localink_be.Services.Interfaces;
using localink_be.Data;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace localink_be.Services.Implementations
{
    public class AIService : IAIService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _config;
        private readonly ILogger<AIService> _logger;
        private readonly AppDbContext _db;

        public AIService(IConfiguration config, ILogger<AIService> logger, AppDbContext db)
        {
            _config = config;
            _logger = logger;
            _db = db;
            _httpClient = new HttpClient();
            _httpClient.DefaultRequestHeaders.Authorization = 
                new AuthenticationHeaderValue("Bearer", _config["Groq:ApiKey"]);
        }

        public async Task<string[]> GetReviewSuggestionsAsync(string draftText, int rating, string businessName)
        {
            try
            {
                var prompt = BuildPrompt(draftText, rating, businessName);
                
                var requestBody = new
                {
                    model = "llama-3.1-8b-instant",
                    messages = new[]
                    {
                        new { role = "system", content = "You are a helpful assistant that improves business reviews. Provide 3 improved versions of the user's review draft. Each version should be concise (max 2 sentences), natural, and helpful. Return ONLY a JSON array with 3 strings, no markdown." },
                        new { role = "user", content = prompt }
                    },
                    temperature = 0.7,
                    max_tokens = 300
                };

                var response = await _httpClient.PostAsJsonAsync(
                    "https://api.groq.com/openai/v1/chat/completions", 
                    requestBody);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("Groq API error: {StatusCode}", response.StatusCode);
                    return Array.Empty<string>();
                }

                var result = await response.Content.ReadFromJsonAsync<GroqResponse>();
                var content = result?.choices?.FirstOrDefault()?.message?.content;

                if (string.IsNullOrEmpty(content))
                    return Array.Empty<string>();

                // Parse the JSON array from the response
                try
                {
                    var suggestions = JsonSerializer.Deserialize<string[]>(content);
                    return suggestions?.Where(s => !string.IsNullOrWhiteSpace(s)).ToArray() 
                        ?? Array.Empty<string>();
                }
                catch (JsonException)
                {
                    // Fallback: split by newlines if not valid JSON
                    return content.Split('\n')
                        .Where(s => !string.IsNullOrWhiteSpace(s) && s.Length > 10)
                        .Take(3)
                        .ToArray();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting AI review suggestions");
                return Array.Empty<string>();
            }
        }

        private string BuildPrompt(string draftText, int rating, string businessName)
        {
            var sentiment = rating >= 4 ? "positive" : rating >= 3 ? "neutral" : "negative";
            
            return $@"User is writing a {sentiment} review (rated {rating}/5 stars) for business '{businessName}'.
Current draft: ""{draftText}""

Provide 3 improved versions of this review. Each should be:
- Natural and conversational
- Specific and helpful
- 1-2 sentences max
- Match the sentiment of the {rating}-star rating

Return as JSON array: [""suggestion1"", ""suggestion2"", ""suggestion3""]";
        }

        public async Task<string?> GetReviewSummaryAsync(string[] reviews, double averageRating, int totalReviews, string businessName)
        {
            try
            {
                if (reviews == null || reviews.Length == 0)
                    return null;

                var prompt = BuildSummaryPrompt(reviews, averageRating, totalReviews, businessName);
                
                var requestBody = new
                {
                    model = "llama-3.1-8b-instant",
                    messages = new[]
                    {
                        new { role = "system", content = "You are a helpful assistant that summarizes business reviews. Provide a concise, natural summary of what people are saying about a business. Keep it under 2 sentences. Be balanced and highlight common themes." },
                        new { role = "user", content = prompt }
                    },
                    temperature = 0.5,
                    max_tokens = 200
                };

                var response = await _httpClient.PostAsJsonAsync(
                    "https://api.groq.com/openai/v1/chat/completions", 
                    requestBody);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("Groq API error: {StatusCode}", response.StatusCode);
                    return null;
                }

                var result = await response.Content.ReadFromJsonAsync<GroqResponse>();
                var content = result?.choices?.FirstOrDefault()?.message?.content;

                if (string.IsNullOrWhiteSpace(content))
                    return null;

                // Clean up the response - remove quotes if present
                content = content.Trim().Trim('"');
                
                return content;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting AI review summary");
                return null;
            }
        }

        private string BuildSummaryPrompt(string[] reviews, double averageRating, int totalReviews, string businessName)
        {
            var reviewTexts = string.Join("\n- ", reviews.Take(20)); // Limit to 20 reviews for token efficiency
            var sentiment = averageRating >= 4 ? "positive" : averageRating >= 3 ? "mixed" : "negative";
            
            return $@"Analyze these {totalReviews} reviews for '{businessName}' (average rating: {averageRating:F1}/5 stars, overall {sentiment} sentiment):

Review excerpts:
- {reviewTexts}

Provide a concise summary (max 2 sentences) of what people commonly say about this business. 
Focus on:
- Overall experience themes
- Service quality
- Atmosphere or ambiance
- Value for money

Return only the summary text, no quotes or markdown.";
        }

        public async Task<string?> GenerateDescriptionAsync(string businessName, string category, string[] keywords)
        {
            try
            {
                var keywordsStr = string.Join(", ", keywords);
                var prompt = $"Generate a professional, engaging business description for a business named '{businessName}' in the category '{category}'. Key highlights/keywords to include: {keywordsStr}. Keep it friendly, inviting, and strictly under 4 sentences. Return only the description text, without any introductory words or quotes.";

                var requestBody = new
                {
                    model = "llama-3.1-8b-instant",
                    messages = new[]
                    {
                        new { role = "system", content = "You are a professional copywriter that writes engaging, concise business descriptions." },
                        new { role = "user", content = prompt }
                    },
                    temperature = 0.7,
                    max_tokens = 200
                };

                var response = await _httpClient.PostAsJsonAsync(
                    "https://api.groq.com/openai/v1/chat/completions", 
                    requestBody);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("Groq API error: {StatusCode}", response.StatusCode);
                    return null;
                }

                var result = await response.Content.ReadFromJsonAsync<GroqResponse>();
                var content = result?.choices?.FirstOrDefault()?.message?.content;
                return content?.Trim()?.Trim('"');
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating business description");
                return null;
            }
        }

        public async Task<string?> ChatSearchAsync(string message, string chatHistoryJson)
        {
            try
            {
                // Fetch approved businesses
                var businesses = await _db.Businesses
                    .Where(b => _db.AdminDashboards.Any(a => a.BusinessId == b.BusinessId && a.Status == BusinessStatus.Approved))
                    .Select(b => new
                    {
                        b.BusinessName,
                        Category = b.Category != null ? b.Category.CategoryName : "",
                        Subcategory = b.Subcategory != null ? b.Subcategory.SubcategoryName : "",
                        b.Description,
                        AverageRating = _db.BusinessReviews.Where(r => r.BusinessId == b.BusinessId).Average(r => (double?)r.Rating) ?? 0,
                        Contact = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => new { c.City, c.State, c.PhoneNumber }).FirstOrDefault()
                    })
                    .ToListAsync();

                var businessesJson = JsonSerializer.Serialize(businesses);

                var systemMessage = $@"You are 'Vocal for Sanatan Assistant', a friendly and helpful AI guide for local businesses.
Here is the JSON list of all approved businesses currently registered in our database:
{businessesJson}

Use this database to answer the user's queries.
Rules:
- Recommend matching businesses from our database list and explain why (e.g. based on ratings, features, or location).
- If no matching business exists in the list, politely inform the user that we don't have that type of business listed yet.
- Keep your responses warm, helpful, and concise (max 3 sentences).";

                var messagesList = new System.Collections.Generic.List<object>();
                messagesList.Add(new { role = "system", content = systemMessage });

                if (!string.IsNullOrWhiteSpace(chatHistoryJson))
                {
                    try
                    {
                        var history = JsonSerializer.Deserialize<JsonElement[]>(chatHistoryJson);
                        foreach (var msg in history)
                        {
                            if (msg.TryGetProperty("role", out var r) && msg.TryGetProperty("content", out var c))
                            {
                                messagesList.Add(new { role = r.GetString(), content = c.GetString() });
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to parse chat history");
                    }
                }

                messagesList.Add(new { role = "user", content = message });

                var requestBody = new
                {
                    model = "llama-3.1-8b-instant",
                    messages = messagesList.ToArray(),
                    temperature = 0.7,
                    max_tokens = 300
                };

                var response = await _httpClient.PostAsJsonAsync(
                    "https://api.groq.com/openai/v1/chat/completions", 
                    requestBody);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("Groq API error: {StatusCode}", response.StatusCode);
                    return "Sorry, I am having trouble connecting to my brain right now. Please try again in a moment.";
                }

                var result = await response.Content.ReadFromJsonAsync<GroqResponse>();
                var content = result?.choices?.FirstOrDefault()?.message?.content;
                return content?.Trim();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in AI Chat Search");
                return "Sorry, an unexpected error occurred. Please try again.";
            }
        }
    }

    public class GroqResponse
    {
        public Choice[] choices { get; set; } = Array.Empty<Choice>();
    }

    public class Choice
    {
        public Message message { get; set; } = new Message();
    }

    public class Message
    {
        public string content { get; set; } = string.Empty;
    }
}
