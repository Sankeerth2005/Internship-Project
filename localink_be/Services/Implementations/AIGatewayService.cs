using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.EntityFrameworkCore;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    /// <summary>
    /// AIGatewayService - Centralized AI service for all Groq API operations
    /// Implements caching, retry logic, and fallback mechanisms
    /// </summary>
    public class AIGatewayService : IAIGatewayService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _config;
        private readonly ILogger<AIGatewayService> _logger;
        private readonly IMemoryCache _memoryCache;
        private readonly localink_be.Data.AppDbContext _db;
        
        // Groq API configuration
        private const string GROQ_BASE_URL = "https://api.groq.com/openai/v1";
        private const string WHISPER_MODEL = "whisper-1";
        private const string LLM_MODEL = "llama3-8b-8192";
        
        // Cache configuration
        private static readonly TimeSpan CACHE_TTL = TimeSpan.FromHours(24);
        private const int MAX_RETRIES = 3;
        private const int RETRY_DELAY_MS = 1000;

        public AIGatewayService(
            IHttpClientFactory httpClientFactory,
            IConfiguration config,
            ILogger<AIGatewayService> logger,
            IMemoryCache memoryCache,
            localink_be.Data.AppDbContext db)
        {
            _config = config;
            _logger = logger;
            _memoryCache = memoryCache;
            _db = db;
            _httpClient = httpClientFactory.CreateClient("GroqAI");
            _httpClient.DefaultRequestHeaders.Authorization = 
                new AuthenticationHeaderValue("Bearer", _config["Groq:ApiKey"] ?? "");
            _httpClient.BaseAddress = new Uri(GROQ_BASE_URL);
            _httpClient.Timeout = TimeSpan.FromSeconds(60);
        }

        #region Speech-to-Text

        /// <summary>
        /// Transcribe audio using Groq Whisper API with caching and retry logic
        /// </summary>
        public async Task<TranscriptionResult> TranscribeAudioAsync(byte[] audioData, string? language = null)
        {
            if (audioData == null || audioData.Length == 0)
            {
                return new TranscriptionResult 
                { 
                    Success = false, 
                    Error = "No audio data provided",
                    UsedFallback = false
                };
            }

            // Generate cache key based on audio hash (first 1KB for performance)
            var audioHash = ComputeHash(audioData);
            var cacheKey = $"transcribe:{language ?? "auto"}:{audioHash}";

            // Check cache
            if (_memoryCache.TryGetValue(cacheKey, out TranscriptionResult? cachedResult) && cachedResult != null)
            {
                _logger.LogInformation("Cache HIT for transcription: {CacheKey}", cacheKey);
                return cachedResult;
            }

            // Try API with retries
            for (int attempt = 1; attempt <= MAX_RETRIES; attempt++)
            {
                try
                {
                    _logger.LogInformation("Transcription attempt {Attempt}/{MaxRetries}", attempt, MAX_RETRIES);

                    var content = new MultipartFormDataContent();
                    
                    // Add audio file
                    var audioContent = new ByteArrayContent(audioData);
                    audioContent.Headers.ContentType = new MediaTypeHeaderValue("audio/webm");
                    content.Add(audioContent, "file", "audio.webm");
                    content.Add(new StringContent(WHISPER_MODEL), "model");
                    
                    if (!string.IsNullOrEmpty(language))
                    {
                        content.Add(new StringContent(language), "language");
                    }
                    content.Add(new StringContent("json"), "response_format");

                    var response = await _httpClient.PostAsync("/audio/transcriptions", content);

                    if (response.IsSuccessStatusCode)
                    {
                        var result = await response.Content.ReadFromJsonAsync<WhisperResponse>();
                        
                        if (!string.IsNullOrEmpty(result?.Text))
                        {
                            // Clean up transcription: remove trailing punctuation and normalize
                            var cleanedTranscript = CleanTranscription(result.Text.Trim());
                            
                            var transcriptionResult = new TranscriptionResult
                            {
                                Success = true,
                                Transcript = cleanedTranscript,
                                Language = result.Language ?? language ?? "en",
                                UsedFallback = false
                            };

                            // Cache the result
                            CacheResult(cacheKey, transcriptionResult);
                            
                            _logger.LogInformation("Transcription successful: {Length} chars", transcriptionResult.Transcript?.Length ?? 0);
                            return transcriptionResult;
                        }
                    }
                    else
                    {
                        var errorContent = await response.Content.ReadAsStringAsync();
                        _logger.LogWarning("Transcription API error: {StatusCode} - {Error}", 
                            response.StatusCode, errorContent);
                        
                        // Only retry on transient errors
                        if ((int)response.StatusCode < 500 && response.StatusCode != System.Net.HttpStatusCode.TooManyRequests)
                        {
                            break; // Don't retry client errors
                        }
                    }

                    // Wait before retry
                    if (attempt < MAX_RETRIES)
                    {
                        await Task.Delay(RETRY_DELAY_MS * attempt);
                    }
                }
                catch (TaskCanceledException)
                {
                    _logger.LogWarning("Transcription timeout on attempt {Attempt}", attempt);
                    if (attempt == MAX_RETRIES)
                    {
                        return new TranscriptionResult 
                        { 
                            Success = false, 
                            Error = "Transcription service timeout. Please try again.",
                            UsedFallback = false
                        };
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Transcription error on attempt {Attempt}", attempt);
                    if (attempt == MAX_RETRIES)
                    {
                        return new TranscriptionResult 
                        { 
                            Success = false, 
                            Error = "Transcription service unavailable. Please try using browser speech recognition.",
                            UsedFallback = false
                        };
                    }
                }
            }

            return new TranscriptionResult 
            { 
                Success = false, 
                Error = "Failed to transcribe audio after multiple attempts. Please try using browser speech recognition.",
                UsedFallback = false
            };
        }

        #endregion

        #region Translation

        /// <summary>
        /// Translate text using Groq LLM with aggressive caching
        /// </summary>
        public async Task<TranslationResult> TranslateTextAsync(string text, string targetLang, string? sourceLang = null)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return new TranslationResult 
                { 
                    Success = true, 
                    TranslatedText = "",
                    SourceLang = sourceLang ?? "en",
                    TargetLang = targetLang,
                    UsedFallback = false
                };
            }

            // Don't translate IDs, numbers, URLs, or very short text
            if (ShouldSkipTranslation(text))
            {
                return new TranslationResult 
                { 
                    Success = true, 
                    TranslatedText = text,
                    SourceLang = sourceLang ?? "en",
                    TargetLang = targetLang,
                    UsedFallback = false
                };
            }

            // Generate cache key
            var cacheKey = $"translation:{targetLang.ToLower()}:{ComputeHash(text)}";

            // Check cache
            if (_memoryCache.TryGetValue(cacheKey, out TranslationResult? cachedResult) && cachedResult != null)
            {
                _logger.LogDebug("Cache HIT for translation: {CacheKey}", cacheKey);
                return cachedResult;
            }

            // Check database persistent cache
            try
            {
                var dbCached = await _db.TranslationCaches.FirstOrDefaultAsync(t => t.CacheKey == cacheKey);
                if (dbCached != null)
                {
                    var translationResult = new TranslationResult
                    {
                        Success = true,
                        TranslatedText = dbCached.TranslatedText,
                        SourceLang = sourceLang ?? "en",
                        TargetLang = targetLang,
                        UsedFallback = false
                    };
                    _memoryCache.Set(cacheKey, translationResult, CACHE_TTL);
                    _logger.LogInformation("Database Cache HIT for translation: {CacheKey}", cacheKey);
                    return translationResult;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to query database translation cache for key: {CacheKey}", cacheKey);
            }

            // Try API with retries
            for (int attempt = 1; attempt <= MAX_RETRIES; attempt++)
            {
                try
                {
                    var prompt = BuildTranslationPrompt(text, targetLang, sourceLang);
                    
                    var requestBody = new
                    {
                        model = LLM_MODEL,
                        messages = new[]
                        {
                            new { 
                                role = "system", 
                                content = $"You are a professional translator. Translate the following text to {GetLanguageName(targetLang)}. " +
                                          "Return ONLY the translated text, nothing else. Do not add quotes, explanations, or notes." 
                            },
                            new { role = "user", content = prompt }
                        },
                        temperature = 0.3,
                        max_tokens = 1000
                    };

                    var response = await _httpClient.PostAsJsonAsync("/chat/completions", requestBody);

                    if (response.IsSuccessStatusCode)
                    {
                        var result = await response.Content.ReadFromJsonAsync<GroqChatResponse>();
                        var translatedText = result?.Choices?.FirstOrDefault()?.Message?.Content?.Trim();

                        if (!string.IsNullOrEmpty(translatedText))
                        {
                            // Clean up the response - remove quotes if present
                            translatedText = translatedText.Trim('"', '\'', '`');

                            var translationResult = new TranslationResult
                            {
                                Success = true,
                                TranslatedText = translatedText,
                                SourceLang = sourceLang ?? "en",
                                TargetLang = targetLang,
                                UsedFallback = false
                            };

                            // Cache the result in memory
                            CacheResult(cacheKey, translationResult);

                            // Save to database cache
                            try
                            {
                                var dbEntry = new localink_be.Models.Entities.TranslationCache
                                {
                                    CacheKey = cacheKey,
                                    OriginalText = text,
                                    TranslatedText = translatedText,
                                    TargetLang = targetLang,
                                    CreatedAt = DateTime.UtcNow
                                };
                                _db.TranslationCaches.Add(dbEntry);
                                await _db.SaveChangesAsync();
                            }
                            catch (Exception ex)
                            {
                                _logger.LogWarning(ex, "Failed to persist translation cache in database for key: {CacheKey}", cacheKey);
                            }
                            
                            _logger.LogDebug("Translation successful: {SourceLang} -> {TargetLang}", 
                                translationResult.SourceLang, translationResult.TargetLang);
                            
                            return translationResult;
                        }
                    }
                    else
                    {
                        var errorContent = await response.Content.ReadAsStringAsync();
                        _logger.LogWarning("Translation API error: {StatusCode} - {Error}", 
                            response.StatusCode, errorContent);
                        
                        if ((int)response.StatusCode < 500 && response.StatusCode != System.Net.HttpStatusCode.TooManyRequests)
                        {
                            break;
                        }
                    }

                    if (attempt < MAX_RETRIES)
                    {
                        await Task.Delay(RETRY_DELAY_MS * attempt);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Translation error on attempt {Attempt}", attempt);
                    if (attempt == MAX_RETRIES)
                    {
                        // Return original text as fallback
                        return new TranslationResult 
                        { 
                            Success = true, // Return success with original text
                            TranslatedText = text,
                            SourceLang = sourceLang ?? "en",
                            TargetLang = targetLang,
                            UsedFallback = true,
                            Error = "Translation service unavailable. Returning original text."
                        };
                    }
                }
            }

            // Final fallback - return original
            return new TranslationResult 
            { 
                Success = true,
                TranslatedText = text,
                SourceLang = sourceLang ?? "en",
                TargetLang = targetLang,
                UsedFallback = true,
                Error = "Translation failed. Returning original text."
            };
        }

        #endregion

        #region Intent Parsing

        /// <summary>
        /// Parse user intent from natural language for smart search
        /// </summary>
        public async Task<IntentResult> ParseIntentAsync(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return new IntentResult 
                { 
                    Success = true, 
                    Intent = "search",
                    Query = ""
                };
            }

            // Generate cache key
            var cacheKey = $"intent:{ComputeHash(text.ToLower().Trim())}";

            // Check cache
            if (_memoryCache.TryGetValue(cacheKey, out IntentResult? cachedResult) && cachedResult != null)
            {
                _logger.LogDebug("Cache HIT for intent: {CacheKey}", cacheKey);
                return cachedResult;
            }

            // Try API with retries
            for (int attempt = 1; attempt <= MAX_RETRIES; attempt++)
            {
                try
                {
                    var requestBody = new
                    {
                        model = LLM_MODEL,
                        messages = new[]
                        {
                            new { 
                                role = "system", 
                                content = @"You are a search query parser. Analyze the user's search query and return a STRICT JSON object with these fields:
{
  ""intent"": ""search"" | ""navigate"" | ""filter"" | ""information"",
  ""category"": ""restaurant"" | ""hospital"" | ""school"" | ""shop"" | ""bank"" | ""repair"" | ""beauty"" | ""automotive"" | ""electronics"" | ""travel"" | ""fitness"" | ""home services"" | null,
  ""query"": ""the core search terms"",
  ""openNow"": true/false,
  ""radiusKm"": number (default 5, max 50) or null
}

Examples:
Input: ""best biryani near me""
Output: { ""intent"": ""search"", ""category"": ""restaurant"", ""query"": ""biryani"", ""openNow"": false, ""radiusKm"": 5 }

Input: ""open hospitals within 10km""
Output: { ""intent"": ""filter"", ""category"": ""hospital"", ""query"": """", ""openNow"": true, ""radiusKm"": 10 }

Input: ""show me mechanics open now""
Output: { ""intent"": ""filter"", ""category"": ""repair"", ""query"": ""mechanic"", ""openNow"": true, ""radiusKm"": null }

Return ONLY the JSON object, no markdown, no explanation."
                            },
                            new { role = "user", content = $"Parse this query: \"{text}\"" }
                        },
                        temperature = 0.1,
                        max_tokens = 200,
                        response_format = new { type = "json_object" }
                    };

                    var response = await _httpClient.PostAsJsonAsync("/chat/completions", requestBody);

                    if (response.IsSuccessStatusCode)
                    {
                        var result = await response.Content.ReadFromJsonAsync<GroqChatResponse>();
                        var content = result?.Choices?.FirstOrDefault()?.Message?.Content;

                        if (!string.IsNullOrEmpty(content))
                        {
                            try
                            {
                                // Parse the JSON response
                                var parsedIntent = JsonSerializer.Deserialize<ParsedIntent>(content, new JsonSerializerOptions
                                {
                                    PropertyNameCaseInsensitive = true
                                });

                                if (parsedIntent != null)
                                {
                                    var intentResult = new IntentResult
                                    {
                                        Success = true,
                                        Intent = parsedIntent.Intent ?? "search",
                                        Category = parsedIntent.Category,
                                        Query = parsedIntent.Query ?? text,
                                        OpenNow = parsedIntent.OpenNow,
                                        RadiusKm = parsedIntent.RadiusKm,
                                        Metadata = new Dictionary<string, object>
                                        {
                                            ["originalQuery"] = text,
                                            ["parsedAt"] = DateTime.UtcNow.ToString("O")
                                        }
                                    };

                                    // Cache the result
                                    CacheResult(cacheKey, intentResult);
                                    
                                    _logger.LogInformation("Intent parsed: {Intent} | Category: {Category} | Query: {Query}",
                                        intentResult.Intent, intentResult.Category, intentResult.Query);
                                    
                                    return intentResult;
                                }
                            }
                            catch (JsonException ex)
                            {
                                _logger.LogWarning(ex, "Failed to parse intent JSON: {Content}", content);
                            }
                        }
                    }
                    else
                    {
                        var errorContent = await response.Content.ReadAsStringAsync();
                        _logger.LogWarning("Intent API error: {StatusCode} - {Error}", 
                            response.StatusCode, errorContent);
                        
                        if ((int)response.StatusCode < 500 && response.StatusCode != System.Net.HttpStatusCode.TooManyRequests)
                        {
                            break;
                        }
                    }

                    if (attempt < MAX_RETRIES)
                    {
                        await Task.Delay(RETRY_DELAY_MS * attempt);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Intent parsing error on attempt {Attempt}", attempt);
                }
            }

            // Fallback - use basic keyword parsing
            var fallbackResult = ParseIntentFallback(text);
            
            _logger.LogInformation("Using fallback intent parsing for: {Text}", text);
            
            return fallbackResult;
        }

        #endregion

        #region Health Check

        /// <summary>
        /// Check if AI services are available
        /// </summary>
        public async Task<bool> HealthCheckAsync()
        {
            try
            {
                // Simple health check by making a minimal request
                var requestBody = new
                {
                    model = LLM_MODEL,
                    messages = new[] { new { role = "user", content = "Hi" } },
                    max_tokens = 1
                };

                var response = await _httpClient.PostAsJsonAsync("/chat/completions", requestBody);
                return response.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        #endregion

        #region JSON Translation

        /// <summary>
        /// Translate JSON content to target language while preserving structure
        /// Uses batch translation for efficiency with caching
        /// </summary>
        public async Task<JsonTranslationResult> TranslateJsonAsync(string json, string targetLang)
        {
            if (string.IsNullOrWhiteSpace(json))
            {
                return new JsonTranslationResult
                {
                    Success = true,
                    TranslatedJson = json,
                    TargetLang = targetLang,
                    UsedFallback = false
                };
            }

            // Skip translation for English
            if (targetLang.Equals("en", StringComparison.OrdinalIgnoreCase))
            {
                return new JsonTranslationResult
                {
                    Success = true,
                    TranslatedJson = json,
                    TargetLang = targetLang,
                    UsedFallback = false
                };
            }

            // Generate cache key based on JSON hash and target language
            var jsonHash = ComputeHash(json);
            var cacheKey = $"json:translation:{targetLang.ToLower()}:{jsonHash}";

            // Check cache
            if (_memoryCache.TryGetValue(cacheKey, out JsonTranslationResult? cachedResult) && cachedResult != null)
            {
                _logger.LogDebug("Cache HIT for JSON translation: {CacheKey}", cacheKey);
                return cachedResult;
            }

            // Check database persistent cache
            try
            {
                var dbCached = await _db.TranslationCaches.FirstOrDefaultAsync(t => t.CacheKey == cacheKey);
                if (dbCached != null)
                {
                    var translationResult = new JsonTranslationResult
                    {
                        Success = true,
                        TranslatedJson = dbCached.TranslatedText,
                        TargetLang = targetLang,
                        UsedFallback = false
                    };
                    _memoryCache.Set(cacheKey, translationResult, CACHE_TTL);
                    _logger.LogInformation("Database Cache HIT for JSON translation: {CacheKey}", cacheKey);
                    return translationResult;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to query database JSON translation cache for key: {CacheKey}", cacheKey);
            }

            // Try API with retries
            for (int attempt = 1; attempt <= MAX_RETRIES; attempt++)
            {
                try
                {
                    _logger.LogDebug("JSON Translation attempt {Attempt}/{MaxRetries} to {TargetLang}", 
                        attempt, MAX_RETRIES, targetLang);

                    var prompt = BuildJsonTranslationPrompt(json, targetLang);
                    
                    var requestBody = new
                    {
                        model = LLM_MODEL,
                        messages = new[]
                        {
                            new { 
                                role = "system", 
                                content = $@"You are a JSON translation expert. Your task is to translate ALL text values in the provided JSON to {GetLanguageName(targetLang)}.

STRICT RULES:
1. Translate ONLY string values - NEVER translate property names (keys)
2. NEVER translate: IDs, numbers, URLs, email addresses, dates/timestamps, GUIDs, coordinates
3. Preserve the exact JSON structure and data types
4. Return ONLY valid JSON - no markdown, no explanations, no code blocks
5. If a value is already in the target language, keep it unchanged
6. Maintain all special characters, formatting, and whitespace within strings

EXAMPLE:
Input: {{""name"":""Coffee Shop"",""address"":""123 Main St"",""id"":""12345"",""rating"":4.5}}
Output: {{""name"":""Kaffeehaus"",""address"":""123 Hauptstraße"",""id"":""12345"",""rating"":4.5}}

Return ONLY the translated JSON object." 
                            },
                            new { role = "user", content = prompt }
                        },
                        temperature = 0.1,
                        max_tokens = 4000,
                        response_format = new { type = "json_object" }
                    };

                    var response = await _httpClient.PostAsJsonAsync("/chat/completions", requestBody);

                    if (response.IsSuccessStatusCode)
                    {
                        var result = await response.Content.ReadFromJsonAsync<GroqChatResponse>();
                        var translatedJson = result?.Choices?.FirstOrDefault()?.Message?.Content?.Trim();

                        if (!string.IsNullOrEmpty(translatedJson))
                        {
                            // Validate the returned JSON
                            try
                            {
                                using var doc = JsonDocument.Parse(translatedJson);
                                
                                var translationResult = new JsonTranslationResult
                                {
                                    Success = true,
                                    TranslatedJson = translatedJson,
                                    TargetLang = targetLang,
                                    UsedFallback = false
                                };

                                // Cache the result (24 hours) in memory
                                CacheResult(cacheKey, translationResult);

                                // Save to database cache
                                try
                                {
                                    var dbEntry = new localink_be.Models.Entities.TranslationCache
                                    {
                                        CacheKey = cacheKey,
                                        OriginalText = json,
                                        TranslatedText = translatedJson,
                                        TargetLang = targetLang,
                                        CreatedAt = DateTime.UtcNow
                                    };
                                    _db.TranslationCaches.Add(dbEntry);
                                    await _db.SaveChangesAsync();
                                }
                                catch (Exception ex)
                                {
                                    _logger.LogWarning(ex, "Failed to persist JSON translation cache in database for key: {CacheKey}", cacheKey);
                                }
                                
                                _logger.LogInformation("JSON Translation successful to {TargetLang}", targetLang);
                                return translationResult;
                            }
                            catch (JsonException ex)
                            {
                                _logger.LogWarning(ex, "Invalid JSON returned from translation API: {Json}", translatedJson);
                                // Continue to retry or fallback
                            }
                        }
                    }
                    else
                    {
                        var errorContent = await response.Content.ReadAsStringAsync();
                        _logger.LogWarning("JSON Translation API error: {StatusCode} - {Error}", 
                            response.StatusCode, errorContent);
                        
                        if ((int)response.StatusCode < 500 && response.StatusCode != System.Net.HttpStatusCode.TooManyRequests)
                        {
                            break; // Don't retry client errors
                        }
                    }

                    if (attempt < MAX_RETRIES)
                    {
                        await Task.Delay(RETRY_DELAY_MS * attempt);
                    }
                }
                catch (TaskCanceledException)
                {
                    _logger.LogWarning("JSON Translation timeout on attempt {Attempt}", attempt);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "JSON Translation error on attempt {Attempt}", attempt);
                }
            }

            // Fallback - return original JSON
            _logger.LogWarning("JSON Translation failed after {MaxRetries} attempts. Returning original JSON.", MAX_RETRIES);
            
            return new JsonTranslationResult
            {
                Success = true, // Return success with original to avoid breaking API
                TranslatedJson = json,
                TargetLang = targetLang,
                UsedFallback = true,
                Error = "Translation service unavailable. Returning original content."
            };
        }

        private static string BuildJsonTranslationPrompt(string json, string targetLang)
        {
            return $"Translate the following JSON to {GetLanguageName(targetLang)}. Remember: translate ONLY string values, NEVER keys, IDs, numbers, URLs, or emails.\n\n{json}";
        }

        #endregion

        #region Helper Methods

        private void CacheResult<T>(string key, T value)
        {
            var options = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(CACHE_TTL)
                .SetPriority(CacheItemPriority.Normal);

            _memoryCache.Set(key, value, options);
            _logger.LogDebug("Cached result for key: {Key}", key);
        }

        private static string CleanTranscription(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return text;
            
            // Remove trailing punctuation: period, comma, question mark, exclamation, semicolon, colon
            text = text.TrimEnd('.', ',', '?', '!', ';', ':');
            
            // Remove any extra whitespace
            text = text.Trim();
            
            return text;
        }

        private static string ComputeHash(string input)
        {
            // Simple hash for cache key generation
            var bytes = Encoding.UTF8.GetBytes(input);
            var hash = System.Security.Cryptography.SHA256.HashData(bytes);
            return Convert.ToBase64String(hash)[..16]; // First 16 chars for shorter keys
        }

        private static string ComputeHash(byte[] input)
        {
            // Use first 1KB of audio for performance
            var dataToHash = input.Length > 1024 ? input[..1024] : input;
            var hash = System.Security.Cryptography.SHA256.HashData(dataToHash);
            return Convert.ToBase64String(hash)[..16];
        }

        private static bool ShouldSkipTranslation(string text)
        {
            // Skip translation for IDs, numbers, URLs, emails
            if (string.IsNullOrWhiteSpace(text) || text.Length < 2)
                return true;

            // Check if it's just a number or ID
            if (text.All(c => char.IsDigit(c) || c == '-' || c == '_'))
                return true;

            // Check if it's a URL
            if (text.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                text.StartsWith("https://", StringComparison.OrdinalIgnoreCase) ||
                text.StartsWith("www.", StringComparison.OrdinalIgnoreCase))
                return true;

            // Check if it's an email
            if (text.Contains('@') && text.Contains('.'))
                return true;

            // Check if it's already in target language (basic check)
            // This is a simplified check - in production, use language detection
            return false;
        }

        private static string BuildTranslationPrompt(string text, string targetLang, string? sourceLang)
        {
            var sb = new StringBuilder();
            
            if (!string.IsNullOrEmpty(sourceLang))
            {
                sb.AppendLine($"Translate from {sourceLang} to {targetLang}:");
            }
            else
            {
                sb.AppendLine($"Translate to {targetLang}:");
            }
            
            sb.AppendLine();
            sb.AppendLine(text);
            sb.AppendLine();
            sb.AppendLine("Rules:");
            sb.AppendLine("- Keep the original meaning and tone");
            sb.AppendLine("- Do not translate proper nouns (business names, place names)");
            sb.AppendLine("- Return ONLY the translated text");
            
            return sb.ToString();
        }

        private static string GetLanguageName(string code)
        {
            var languageNames = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["en"] = "English",
                ["hi"] = "Hindi",
                ["ta"] = "Tamil",
                ["te"] = "Telugu",
                ["bn"] = "Bengali",
                ["mr"] = "Marathi",
                ["gu"] = "Gujarati",
                ["kn"] = "Kannada",
                ["ml"] = "Malayalam",
                ["pa"] = "Punjabi",
                ["ur"] = "Urdu",
                ["ar"] = "Arabic",
                ["de"] = "German",
                ["es"] = "Spanish",
                ["fr"] = "French",
                ["it"] = "Italian",
                ["ja"] = "Japanese",
                ["ko"] = "Korean",
                ["pt"] = "Portuguese",
                ["ru"] = "Russian",
                ["zh"] = "Chinese",
                ["as"] = "Assamese",
                ["or"] = "Odia",
                ["ne"] = "Nepali",
                ["sa"] = "Sanskrit",
                ["sd"] = "Sindhi",
                ["sat"] = "Santali",
                ["kok"] = "Konkani",
                ["ks"] = "Kashmiri",
                ["mni"] = "Manipuri",
                ["mai"] = "Maithili",
                ["brx"] = "Bodo",
                ["doi"] = "Dogri"
            };

            return languageNames.TryGetValue(code, out var name) ? name : code.ToUpperInvariant();
        }

        private static IntentResult ParseIntentFallback(string text)
        {
            var lowerText = text.ToLowerInvariant().Trim();
            
            var result = new IntentResult
            {
                Success = true,
                Intent = "search",
                Query = text,
                OpenNow = false,
                RadiusKm = 5
            };

            // Parse "open now"
            var openNowKeywords = new[] { "open now", "open today", "currently open", "working now", "open right now" };
            result.OpenNow = openNowKeywords.Any(k => lowerText.Contains(k));

            // Parse radius
            var radiusMatch = System.Text.RegularExpressions.Regex.Match(lowerText, @"(\d+)\s*(km|kilometer|kilometers|mile|miles)");
            if (radiusMatch.Success)
            {
                var value = int.Parse(radiusMatch.Groups[1].Value);
                var unit = radiusMatch.Groups[2].Value;
                result.RadiusKm = unit.StartsWith("mile") ? (int)(value * 1.60934) : value;
            }

            // Parse category
            var categoryKeywords = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase)
            {
                ["restaurant"] = new[] { "restaurant", "restaurants", "food", "eat", "eating", "dining", "cafe", "cafeteria", "biryani", "dosa", "idly", "meals", "lunch", "dinner", "breakfast", "hotel" },
                ["hospital"] = new[] { "hospital", "hospitals", "clinic", "clinics", "medical", "doctor", "doctors", "physician", "surgeon", "dentist", "health", "pharmacy", "medicine", "drugstore", "healthcare" },
                ["school"] = new[] { "school", "schools", "college", "colleges", "education", "educational", "university", "institute", "academy", "coaching", "classes", "learning", "training" },
                ["shop"] = new[] { "shop", "shops", "store", "stores", "market", "markets", "mart", "retail", "supermarket", "mall", "shopping", "boutique", "outlet", "grocery", "kirana" },
                ["bank"] = new[] { "bank", "banks", "atm", "atms", "finance", "financial", "money", "cash", "credit", "loan", "insurance", "investment" },
                ["repair"] = new[] { "repair", "repairs", "service", "services", "fix", "fixing", "mechanic", "mechanics", "workshop", "garage", "plumber", "electrician", "carpenter", "technician" },
                ["beauty"] = new[] { "salon", "parlour", "parlor", "beauty", "spa", "haircut", "hairdresser", "barber", "makeup", "facial", "massage" },
                ["automotive"] = new[] { "car", "cars", "bike", "bikes", "automotive", "vehicle", "vehicles", "motorcycle", "scooter", "automobile", "petrol", "diesel", "fuel", "gas" },
                ["electronics"] = new[] { "electronics", "mobile", "phone", "computer", "laptop", "gadget", "appliances", "tv", "refrigerator", "ac", "air conditioner", "washing machine" },
                ["travel"] = new[] { "travel", "travels", "tour", "tours", "tourism", "hotel", "hotels", "lodging", "stay", "resort", "vacation", "booking" },
                ["fitness"] = new[] { "gym", "fitness", "yoga", "exercise", "workout", "sports", "game", "stadium", "pool", "swimming", "trainer" },
                ["home services"] = new[] { "cleaning", "maid", "servant", "cook", "chef", "catering", "security", "guard", "pest control", "painting", "renovation" }
            };

            foreach (var (cat, keywords) in categoryKeywords)
            {
                if (keywords.Any(k => lowerText.Contains(k)))
                {
                    result.Category = cat;
                    break;
                }
            }

            // Clean query
            var query = text;
            foreach (var keywords in categoryKeywords.Values)
            {
                foreach (var keyword in keywords)
                {
                    query = query.Replace(keyword, "", StringComparison.OrdinalIgnoreCase);
                }
            }
            query = System.Text.RegularExpressions.Regex.Replace(query, @"\d+\s*(km|kilometer|kilometers|mile|miles)", "", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            query = query.Replace("open now", "", StringComparison.OrdinalIgnoreCase)
                        .Replace("open today", "", StringComparison.OrdinalIgnoreCase)
                        .Replace("currently open", "", StringComparison.OrdinalIgnoreCase);
            query = System.Text.RegularExpressions.Regex.Replace(query, @"[.,?!;:]+$", ""); // Remove trailing punctuation
            
            result.Query = query.Trim();
            if (string.IsNullOrWhiteSpace(result.Query))
            {
                result.Query = text; // Fallback to original
            }

            return result;
        }

        #endregion

        #region DTOs

        private class WhisperResponse
        {
            [JsonPropertyName("text")]
            public string? Text { get; set; }
            
            [JsonPropertyName("language")]
            public string? Language { get; set; }
        }

        private class GroqChatResponse
        {
            [JsonPropertyName("choices")]
            public List<Choice>? Choices { get; set; }
        }

        private class Choice
        {
            [JsonPropertyName("message")]
            public Message? Message { get; set; }
        }

        private class Message
        {
            [JsonPropertyName("content")]
            public string? Content { get; set; }
        }

        private class ParsedIntent
        {
            [JsonPropertyName("intent")]
            public string? Intent { get; set; }
            
            [JsonPropertyName("category")]
            public string? Category { get; set; }
            
            [JsonPropertyName("query")]
            public string? Query { get; set; }
            
            [JsonPropertyName("openNow")]
            public bool OpenNow { get; set; }
            
            [JsonPropertyName("radiusKm")]
            public int? RadiusKm { get; set; }
        }

        #endregion
    }
}
