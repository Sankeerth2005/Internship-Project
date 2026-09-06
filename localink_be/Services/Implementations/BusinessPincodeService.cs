using localink_be.Services.Implementations;
using localink_be.Validation;
using Microsoft.Extensions.Logging;

public class BusinessPincodeService : IBusinessPincodeService
{
    private readonly ICacheService _cache;
    private readonly HttpClient _http;
    private readonly ILogger<BusinessPincodeService> _logger;
    private readonly string _apiKey;

    private static readonly TimeSpan PincodeCacheExpiration = TimeSpan.FromHours(6);
    private const string PincodeCacheKeyPrefix = "pincode";

    public BusinessPincodeService(
        ICacheService cache,
        HttpClient http,
        IConfiguration config,
        ILogger<BusinessPincodeService> logger)
    {
        _cache = cache;
        _http = http;
        _logger = logger;
        _apiKey = config["Geoapify:ApiKey"]
                  ?? throw new Exception("Geoapify API Key missing");
    }

    public async Task<string> GetPincodeData(
        string postcode,
        string? countryIso2 = null,
        string? countryName = null)
    {
        if (string.IsNullOrWhiteSpace(postcode))
            throw new ArgumentException("Postcode is required", nameof(postcode));

        var iso = PostalCodeRules.ResolveIso2(countryIso2, countryName)?.ToLowerInvariant();
        var normalizedPostcode = postcode.Trim().ToLowerInvariant().Replace(" ", "");
        var cacheKey = string.IsNullOrEmpty(iso)
            ? $"{PincodeCacheKeyPrefix}_{normalizedPostcode}"
            : $"{PincodeCacheKeyPrefix}_{iso}_{normalizedPostcode}";

        try
        {
            return await _cache.GetOrCreateAsync(
                cacheKey,
                async () => await FetchFromApiAsync(postcode.Trim(), iso),
                PincodeCacheExpiration
            ) ?? "{}";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch pincode data for {Postcode} ({Country}). Attempting cached data.", postcode, iso ?? "any");

            var cached = await _cache.GetAsync<string>(cacheKey);
            if (!string.IsNullOrEmpty(cached))
            {
                _logger.LogWarning("Returning stale cached data for pincode {Postcode}", postcode);
                return cached;
            }

            throw new Exception($"Pincode API failed and no cached data available for {postcode}", ex);
        }
    }

    private async Task<string> FetchFromApiAsync(string postcode, string? countryIso2Lower)
    {
        var url = "https://api.geoapify.com/v1/geocode/search" +
                  $"?postcode={Uri.EscapeDataString(postcode)}" +
                  $"&apiKey={_apiKey}";

        if (!string.IsNullOrEmpty(countryIso2Lower))
            url += $"&filter=countrycode:{Uri.EscapeDataString(countryIso2Lower)}";

        _logger.LogInformation(
            "Fetching pincode {Postcode} from Geoapify (country={Country})",
            postcode,
            countryIso2Lower ?? "any");

        var response = await _http.GetAsync(url);

        if (!response.IsSuccessStatusCode)
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            _logger.LogError(
                "Geoapify API failed for pincode {Postcode}. Status: {StatusCode}, Response: {Response}",
                postcode, response.StatusCode, errorContent);
            throw new Exception($"Geoapify API failed with status {response.StatusCode}");
        }

        var result = await response.Content.ReadAsStringAsync();
        _logger.LogInformation("Successfully fetched pincode {Postcode} from Geoapify API", postcode);
        return result;
    }
}
