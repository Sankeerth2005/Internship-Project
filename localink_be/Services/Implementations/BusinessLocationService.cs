using System.Net.Http.Headers;
using localink_be.Services.Implementations;

public class BusinessLocationService : IBusinessLocationService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _config;
    private readonly ICacheService _cache;
    private readonly ILogger<BusinessLocationService> _logger;

    // Cache expiration times
    private static readonly TimeSpan CountriesCacheExpiration = TimeSpan.FromHours(24);
    private static readonly TimeSpan StatesCacheExpiration = TimeSpan.FromHours(24);
    private static readonly TimeSpan CitiesCacheExpiration = TimeSpan.FromHours(12);

    // Cache key prefixes
    private const string CountriesCacheKey = "countries_all";
    private const string StatesCacheKeyPrefix = "states";
    private const string CitiesCacheKeyPrefix = "cities";

    public BusinessLocationService(
        HttpClient httpClient, 
        IConfiguration config,
        ICacheService cache,
        ILogger<BusinessLocationService> logger)
    {
        _httpClient = httpClient;
        _config = config;
        _cache = cache;
        _logger = logger;
    }

    private void SetHeaders()
    {
        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Add(
            "X-CSCAPI-KEY",
            _config["CountryApi:ApiKey"]
        );
    }

    /// <summary>
    /// Gets all countries with caching.
    /// Cache duration: 24 hours
    /// </summary>
    public async Task<string> GetCountries()
    {
        return await _cache.GetOrCreateAsync(
            CountriesCacheKey,
            async () =>
            {
                _logger.LogInformation("Fetching countries from external API");
                SetHeaders();
                var url = $"{_config["CountryApi:BaseUrl"]}/countries";
                var response = await _httpClient.GetStringAsync(url);
                _logger.LogInformation("Successfully fetched countries from external API");
                return response;
            },
            CountriesCacheExpiration
        ) ?? "[]"; // Return empty JSON array if null
    }

    /// <summary>
    /// Gets states for a country with caching.
    /// Cache key: states_{countryCode}
    /// Cache duration: 24 hours
    /// </summary>
    public async Task<string> GetStates(string countryCode)
    {
        if (string.IsNullOrWhiteSpace(countryCode))
            throw new ArgumentException("Country code is required", nameof(countryCode));

        var cacheKey = $"{StatesCacheKeyPrefix}_{countryCode.ToLowerInvariant()}";

        return await _cache.GetOrCreateAsync(
            cacheKey,
            async () =>
            {
                _logger.LogInformation("Fetching states for country {CountryCode} from external API", countryCode);
                SetHeaders();
                var url = $"{_config["CountryApi:BaseUrl"]}/countries/{countryCode}/states";
                var response = await _httpClient.GetStringAsync(url);
                _logger.LogInformation("Successfully fetched states for country {CountryCode}", countryCode);
                return response;
            },
            StatesCacheExpiration
        ) ?? "[]"; // Return empty JSON array if null
    }

    /// <summary>
    /// Gets cities for a state with caching.
    /// Cache key: cities_{countryCode}_{stateCode}
    /// Cache duration: 12 hours
    /// </summary>
    public async Task<string> GetCities(string countryCode, string stateCode)
    {
        if (string.IsNullOrWhiteSpace(countryCode))
            throw new ArgumentException("Country code is required", nameof(countryCode));
        if (string.IsNullOrWhiteSpace(stateCode))
            throw new ArgumentException("State code is required", nameof(stateCode));

        var cacheKey = $"{CitiesCacheKeyPrefix}_{countryCode.ToLowerInvariant()}_{stateCode.ToLowerInvariant()}";

        return await _cache.GetOrCreateAsync(
            cacheKey,
            async () =>
            {
                _logger.LogInformation("Fetching cities for country {CountryCode}, state {StateCode} from external API", 
                    countryCode, stateCode);
                SetHeaders();
                var url = $"{_config["CountryApi:BaseUrl"]}/countries/{countryCode}/states/{stateCode}/cities";
                var response = await _httpClient.GetStringAsync(url);
                _logger.LogInformation("Successfully fetched cities for country {CountryCode}, state {StateCode}", 
                    countryCode, stateCode);
                return response;
            },
            CitiesCacheExpiration
        ) ?? "[]"; // Return empty JSON array if null
    }

    public async Task<bool> ValidateAddressAsync(string countryName, string stateName, string cityName)
    {
        if (string.IsNullOrWhiteSpace(countryName) || string.IsNullOrWhiteSpace(stateName) || string.IsNullOrWhiteSpace(cityName))
            return false;

        try
        {
            // 1. Get countries and find country matching countryName
            var countriesJson = await GetCountries();
            using var countriesDoc = System.Text.Json.JsonDocument.Parse(countriesJson);
            string? countryCode = null;
            foreach (var country in countriesDoc.RootElement.EnumerateArray())
            {
                if (country.TryGetProperty("name", out var nameProp) && 
                    nameProp.GetString()?.Equals(countryName, StringComparison.OrdinalIgnoreCase) == true)
                {
                    if (country.TryGetProperty("iso2", out var iso2Prop))
                    {
                        countryCode = iso2Prop.GetString();
                        break;
                    }
                }
            }

            if (string.IsNullOrEmpty(countryCode))
                return false;

            // 2. Get states and find state matching stateName
            var statesJson = await GetStates(countryCode);
            using var statesDoc = System.Text.Json.JsonDocument.Parse(statesJson);
            string? stateCode = null;
            foreach (var state in statesDoc.RootElement.EnumerateArray())
            {
                if (state.TryGetProperty("name", out var nameProp) && 
                    nameProp.GetString()?.Equals(stateName, StringComparison.OrdinalIgnoreCase) == true)
                {
                    if (state.TryGetProperty("iso2", out var iso2Prop))
                    {
                        stateCode = iso2Prop.GetString();
                        break;
                    }
                }
            }

            if (string.IsNullOrEmpty(stateCode))
                return false;

            // 3. Get cities and find city matching cityName
            var citiesJson = await GetCities(countryCode, stateCode);
            using var citiesDoc = System.Text.Json.JsonDocument.Parse(citiesJson);
            bool cityFound = false;
            foreach (var city in citiesDoc.RootElement.EnumerateArray())
            {
                if (city.TryGetProperty("name", out var nameProp) && 
                    nameProp.GetString()?.Equals(cityName, StringComparison.OrdinalIgnoreCase) == true)
                {
                    cityFound = true;
                    break;
                }
            }

            return cityFound;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating address for country={Country}, state={State}, city={City}", countryName, stateName, cityName);
            // In case of CSC API failure/rate limiting, we fall back to returning true to avoid blocking user profile updates
            return true;
        }
    }
}
