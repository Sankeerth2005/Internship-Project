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

        public async Task<string?> GetBusinessInsightsAsync(int views, int favorites, int clicks, string businessName)
        {
            try
            {
                var prompt = $"Write 3 bulleted business recommendations/insights for a business named '{businessName}' based on the weekly metrics: Views = {views}, Favorites = {favorites}, Contact Clicks = {clicks}. Keep the recommendations extremely concise (max 1 sentence per bullet), constructive, and formatted with emojis. Do not output any introductory or concluding text, only the 3 bullet points.";
                
                var requestBody = new
                {
                    model = "llama-3.1-8b-instant",
                    messages = new[]
                    {
                        new { role = "system", content = "You are a senior business analytics advisor." },
                        new { role = "user", content = prompt }
                    },
                    temperature = 0.7,
                    max_tokens = 250
                };

                var response = await _httpClient.PostAsJsonAsync("https://api.groq.com/openai/v1/chat/completions", requestBody);
                if (!response.IsSuccessStatusCode) return "• Keep posting updates to gain more views.\n• Add high-quality photos to attract favorites.\n• Verify your contact info matches client search locations.";

                var result = await response.Content.ReadFromJsonAsync<GroqResponse>();
                return result?.choices?.FirstOrDefault()?.message?.content?.Trim();
            }
            catch
            {
                return "• Post updates regularly to build engagement.\n• Showcase premium offers on your profile page.\n• Verify your address details are precise.";
            }
        }

        public async Task<string?> GetPersonalizedWelcomeAsync(string categoryPref, string timeOfDay)
        {
            try
            {
                var prompt = $"Write a personalized welcoming message for a local user. The current time of day is {timeOfDay}. Their favorite local category is {categoryPref}. Keep it warm, spiritual (with a subtle 'Namaste' or traditional vibe), and under 2 sentences. Do not use placeholders.";
                
                var requestBody = new
                {
                    model = "llama-3.1-8b-instant",
                    messages = new[]
                    {
                        new { role = "system", content = "You are a warm local guide assistant." },
                        new { role = "user", content = prompt }
                    },
                    temperature = 0.7,
                    max_tokens = 150
                };

                var response = await _httpClient.PostAsJsonAsync("https://api.groq.com/openai/v1/chat/completions", requestBody);
                if (!response.IsSuccessStatusCode) return $"Namaste! Good {timeOfDay}. Discover the finest local {categoryPref} businesses around you today.";

                var result = await response.Content.ReadFromJsonAsync<GroqResponse>();
                return result?.choices?.FirstOrDefault()?.message?.content?.Trim();
            }
            catch
            {
                return $"Namaste! Wishing you a wonderful {timeOfDay}. Explore local services and businesses near you.";
            }
        }

        public async Task<string?> TranscribeAudioAsync(Microsoft.AspNetCore.Http.IFormFile file)
        {
            try
            {
                using var content = new MultipartFormDataContent();
                
                var fileStream = file.OpenReadStream();
                var streamContent = new StreamContent(fileStream);
                streamContent.Headers.ContentType = new MediaTypeHeaderValue(file.ContentType ?? "audio/m4a");
                content.Add(streamContent, "file", file.FileName);
                
                content.Add(new StringContent("whisper-large-v3-turbo"), "model");
                content.Add(new StringContent("en"), "language");

                var response = await _httpClient.PostAsync("https://api.groq.com/openai/v1/audio/transcriptions", content);

                if (!response.IsSuccessStatusCode)
                {
                    var error = await response.Content.ReadAsStringAsync();
                    _logger.LogError("Groq Whisper API error: {StatusCode} - {Error}", response.StatusCode, error);
                    return null;
                }

                var result = await response.Content.ReadFromJsonAsync<JsonElement>();
                if (result.TryGetProperty("text", out var textProp))
                {
                    return textProp.GetString();
                }
                
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error transcribing audio with Groq");
                return null;
            }
        }

        public async Task<(bool isFlagged, string reason)> ModerateContentAsync(string content)
        {
            if (string.IsNullOrWhiteSpace(content)) return (false, string.Empty);

            try
            {
                var prompt = $@"Analyze the following user review for any inappropriate content, hate speech, spam, extreme profanity, or harassment.
If it is inappropriate, respond with exactly: FLAG: [Reason for flagging]
If it is fine, respond with exactly: OK

Content to review: ""{content}""";
                
                var requestBody = new
                {
                    model = "llama-3.1-8b-instant",
                    messages = new[]
                    {
                        new { role = "system", content = "You are a strict automated moderation assistant." },
                        new { role = "user", content = prompt }
                    },
                    temperature = 0.1,
                    max_tokens = 50
                };

                var response = await _httpClient.PostAsJsonAsync("https://api.groq.com/openai/v1/chat/completions", requestBody);

                if (!response.IsSuccessStatusCode)
                {
                    return (false, string.Empty); // Default to allow if API fails
                }

                var result = await response.Content.ReadFromJsonAsync<GroqResponse>();
                var aiResponse = result?.choices?.FirstOrDefault()?.message?.content?.Trim() ?? string.Empty;

                if (aiResponse.StartsWith("FLAG:", StringComparison.OrdinalIgnoreCase))
                {
                    var reason = aiResponse.Substring(5).Trim();
                    return (true, reason);
                }

                return (false, string.Empty);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in automated moderation");
                return (false, string.Empty);
            }
        }
    }

    public class GroqResponse
    {
        public Choice[] choices { get; set; } = Array.Empty<Choice>();
    }

    public class Choice
    {
        public GroqMessage message { get; set; } = new GroqMessage();
    }

    public class GroqMessage
    {
        public string content { get; set; } = string.Empty;
    }
}
