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

    private string GetFallbackCountries()
    {
        return "[{\"name\": \"India\", \"iso2\": \"IN\", \"phonecode\": \"91\", \"emoji\": \"🇮🇳\"}, {\"name\": \"United States\", \"iso2\": \"US\", \"phonecode\": \"1\", \"emoji\": \"🇺🇸\"}, {\"name\": \"United Kingdom\", \"iso2\": \"GB\", \"phonecode\": \"44\", \"emoji\": \"🇬🇧\"}]";
    }

    private string GetFallbackStates(string countryCode)
    {
        countryCode = countryCode.ToUpperInvariant();
        if (countryCode == "IN")
        {
            return "[{\"name\": \"Maharashtra\", \"iso2\": \"MH\"}, {\"name\": \"Delhi\", \"iso2\": \"DL\"}, {\"name\": \"Karnataka\", \"iso2\": \"KA\"}, {\"name\": \"Telangana\", \"iso2\": \"TG\"}, {\"name\": \"Tamil Nadu\", \"iso2\": \"TN\"}, {\"name\": \"Gujarat\", \"iso2\": \"GJ\"}, {\"name\": \"Uttar Pradesh\", \"iso2\": \"UP\"}]";
        }
        if (countryCode == "US")
        {
            return "[{\"name\": \"California\", \"iso2\": \"CA\"}, {\"name\": \"New York\", \"iso2\": \"NY\"}, {\"name\": \"Texas\", \"iso2\": \"TX\"}]";
        }
        return "[]";
    }

    private string GetFallbackCities(string countryCode, string stateCode)
    {
        countryCode = countryCode.ToUpperInvariant();
        stateCode = stateCode.ToUpperInvariant();
        if (countryCode == "IN")
        {
            switch (stateCode)
            {
                case "MH": return "[{\"name\": \"Mumbai\"}, {\"name\": \"Pune\"}, {\"name\": \"Nagpur\"}]";
                case "DL": return "[{\"name\": \"New Delhi\"}]";
                case "KA": return "[{\"name\": \"Bengaluru\"}, {\"name\": \"Mysore\"}]";
                case "TG": return "[{\"name\": \"Hyderabad\"}, {\"name\": \"Warangal\"}]";
                case "TN": return "[{\"name\": \"Chennai\"}, {\"name\": \"Coimbatore\"}]";
                case "GJ": return "[{\"name\": \"Ahmedabad\"}, {\"name\": \"Surat\"}]";
                case "UP": return "[{\"name\": \"Noida\"}, {\"name\": \"Lucknow\"}, {\"name\": \"Varanasi\"}]";
            }
        }
        if (countryCode == "US")
        {
            switch (stateCode)
            {
                case "CA": return "[{\"name\": \"Los Angeles\"}, {\"name\": \"San Francisco\"}]";
                case "NY": return "[{\"name\": \"New York City\"}]";
                case "TX": return "[{\"name\": \"Houston\"}, {\"name\": \"Austin\"}]";
            }
        }
        return "[]";
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
                var url = $"{_config["CountryApi:BaseUrl"]}/countries";
                _logger.LogInformation("Fetching countries from external API: {Url}", url);
                try
                {
                    SetHeaders();
                    var response = await _httpClient.GetAsync(url);
                    if (!response.IsSuccessStatusCode)
                    {
                        var errBody = await response.Content.ReadAsStringAsync();
                        _logger.LogError("External API Failure: Endpoint={Url}, Status={Status}, Message={Message}", 
                            url, (int)response.StatusCode, errBody);
                        return GetFallbackCountries();
                    }
                    var content = await response.Content.ReadAsStringAsync();
                    _logger.LogInformation("Successfully fetched countries from external API");
                    return content;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "External API Exception: Endpoint={Url}, Message={Message}", url, ex.Message);
                    return GetFallbackCountries();
                }
            },
            CountriesCacheExpiration
        ) ?? "[]";
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
                var url = $"{_config["CountryApi:BaseUrl"]}/countries/{countryCode}/states";
                _logger.LogInformation("Fetching states for country {CountryCode} from external API: {Url}", countryCode, url);
                try
                {
                    SetHeaders();
                    var response = await _httpClient.GetAsync(url);
                    if (!response.IsSuccessStatusCode)
                    {
                        var errBody = await response.Content.ReadAsStringAsync();
                        _logger.LogError("External API Failure: Endpoint={Url}, Status={Status}, Message={Message}", 
                            url, (int)response.StatusCode, errBody);
                        return GetFallbackStates(countryCode);
                    }
                    var content = await response.Content.ReadAsStringAsync();
                    _logger.LogInformation("Successfully fetched states for country {CountryCode}", countryCode);
                    return content;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "External API Exception: Endpoint={Url}, Message={Message}", url, ex.Message);
                    return GetFallbackStates(countryCode);
                }
            },
            StatesCacheExpiration
        ) ?? "[]";
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
                var url = $"{_config["CountryApi:BaseUrl"]}/countries/{countryCode}/states/{stateCode}/cities";
                _logger.LogInformation("Fetching cities for country {CountryCode}, state {StateCode} from external API: {Url}", countryCode, stateCode, url);
                try
                {
                    SetHeaders();
                    var response = await _httpClient.GetAsync(url);
                    if (!response.IsSuccessStatusCode)
                    {
                        var errBody = await response.Content.ReadAsStringAsync();
                        _logger.LogError("External API Failure: Endpoint={Url}, Status={Status}, Message={Message}", 
                            url, (int)response.StatusCode, errBody);
                        return GetFallbackCities(countryCode, stateCode);
                    }
                    var content = await response.Content.ReadAsStringAsync();
                    _logger.LogInformation("Successfully fetched cities for country {CountryCode}, state {StateCode}", countryCode, stateCode);
                    return content;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "External API Exception: Endpoint={Url}, Message={Message}", url, ex.Message);
                    return GetFallbackCities(countryCode, stateCode);
                }
            },
            CitiesCacheExpiration
        ) ?? "[]";
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
