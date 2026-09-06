using localink_be.Services.Interfaces;

namespace localink_be.Middleware
{
    /// <summary>
    /// Translation Middleware - Intercepts all API responses and translates string fields
    /// Reads target language from x-lang header
    /// Uses batch JSON translation via AI Gateway for efficiency
    /// Opt-in via Translation:EnableResponseMiddleware (default false).
    /// </summary>
    public class TranslationMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<TranslationMiddleware> _logger;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly bool _enabled;

        // Language codes that don't need translation (already English or default)
        private static readonly HashSet<string> DefaultLanguages = new(StringComparer.OrdinalIgnoreCase)
        {
            "en", "en-us", "en-gb"
        };

        public TranslationMiddleware(
            RequestDelegate next,
            ILogger<TranslationMiddleware> logger,
            IServiceScopeFactory scopeFactory,
            IConfiguration configuration)
        {
            _next = next;
            _logger = logger;
            _scopeFactory = scopeFactory;
            _enabled = configuration.GetValue("Translation:EnableResponseMiddleware", false);
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Opt-in only — default disabled means zero Groq/translation work.
            if (!_enabled)
            {
                await _next(context);
                return;
            }

            // Get target language from header
            var targetLang = GetTargetLanguage(context);

            // If no language header or English, skip translation
            if (string.IsNullOrEmpty(targetLang) || DefaultLanguages.Contains(targetLang))
            {
                await _next(context);
                return;
            }

            _logger.LogDebug("Translation middleware active for language: {Language}", targetLang);

            // Capture the original response
            var originalBody = context.Response.Body;
            
            try
            {
                using var memoryStream = new MemoryStream();
                context.Response.Body = memoryStream;

                // Execute the next middleware
                await _next(context);

                // Only process successful JSON responses
                if (context.Response.StatusCode == StatusCodes.Status200OK &&
                    IsJsonContentType(context.Response.ContentType))
                {
                    // Reset position and read the response
                    memoryStream.Position = 0;
                    var responseBody = await new StreamReader(memoryStream).ReadToEndAsync();

                    if (!string.IsNullOrEmpty(responseBody))
                    {
                        try
                        {
                            // Parse and translate
                            var translated = await TranslateResponseAsync(responseBody, targetLang);
                            
                            // Write translated response
                            var translatedBytes = System.Text.Encoding.UTF8.GetBytes(translated);
                            context.Response.Body = originalBody;
                            context.Response.ContentLength = translatedBytes.Length;
                            await context.Response.Body.WriteAsync(translatedBytes);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Translation failed for language: {Language}. Returning original response.", 
                                targetLang);
                            
                            // Return original on error
                            memoryStream.Position = 0;
                            context.Response.Body = originalBody;
                            await memoryStream.CopyToAsync(originalBody);
                        }
                    }
                    else
                    {
                        memoryStream.Position = 0;
                        context.Response.Body = originalBody;
                        await memoryStream.CopyToAsync(originalBody);
                    }
                }
                else
                {
                    // Non-JSON response, pass through unchanged
                    memoryStream.Position = 0;
                    context.Response.Body = originalBody;
                    await memoryStream.CopyToAsync(originalBody);
                }
            }
            finally
            {
                context.Response.Body = originalBody;
            }
        }

        private async Task<string> TranslateResponseAsync(string json, string targetLang)
        {
            // Create a scope to resolve scoped services
            using var scope = _scopeFactory.CreateScope();
            var aiGateway = scope.ServiceProvider.GetRequiredService<IAIGatewayService>();
            
            // Use batch JSON translation for efficiency
            var result = await aiGateway.TranslateJsonAsync(json, targetLang);
            
            if (result.Success && !string.IsNullOrEmpty(result.TranslatedJson))
            {
                return result.TranslatedJson;
            }
            
            // Return original if translation failed
            _logger.LogWarning("JSON translation failed or returned empty. Returning original response.");
            return json;
        }

        private static string? GetTargetLanguage(HttpContext context)
        {
            // Check x-lang header first
            if (context.Request.Headers.TryGetValue("x-lang", out var langHeader) &&
                !string.IsNullOrWhiteSpace(langHeader.ToString()))
            {
                return langHeader.ToString().Trim().ToLowerInvariant();
            }

            // Fallback to Accept-Language header
            if (context.Request.Headers.TryGetValue("Accept-Language", out var acceptLang))
            {
                var languages = acceptLang.ToString().Split(',');
                if (languages.Length > 0)
                {
                    // Get primary language code (remove quality value)
                    var primary = languages[0].Split(';')[0].Trim().ToLowerInvariant();
                    return primary.Length > 2 ? primary[..2] : primary;
                }
            }

            return null;
        }

        private static bool IsJsonContentType(string? contentType)
        {
            if (string.IsNullOrEmpty(contentType))
                return false;

            // Handle content types like "application/json; charset=utf-8"
            var normalized = contentType.ToLowerInvariant().Split(';')[0].Trim();
            
            return normalized == "application/json" || 
                   normalized == "text/json" ||
                   normalized == "application/json;";
        }
    }

    /// <summary>
    /// Extension methods for TranslationMiddleware
    /// </summary>
    public static class TranslationMiddlewareExtensions
    {
        /// <summary>
        /// Adds TranslationMiddleware when Translation:EnableResponseMiddleware is true.
        /// Defaults to disabled so the pipeline skips translation and Groq calls.
        /// </summary>
        public static IApplicationBuilder UseResponseTranslation(
            this IApplicationBuilder app)
        {
            var enabled = app.ApplicationServices
                .GetRequiredService<IConfiguration>()
                .GetValue("Translation:EnableResponseMiddleware", false);

            if (!enabled)
                return app;

            return app.UseMiddleware<TranslationMiddleware>();
        }
    }
}
