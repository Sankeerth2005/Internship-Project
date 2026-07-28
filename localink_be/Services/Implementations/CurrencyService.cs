using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class CurrencyService : ICurrencyService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _config;
        private readonly ILogger<CurrencyService> _logger;
        private readonly string _apiKey;
        private readonly string _baseUrl;
        
        // Fallback exchange rates (relative to USD) when API is unavailable
        private static readonly Dictionary<string, decimal> _fallbackRates = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase)
        {
            { "USD", 1.0m },
            { "INR", 83.12m },
            { "EUR", 0.92m },
            { "GBP", 0.79m },
            { "CAD", 1.36m },
            { "AUD", 1.52m },
            { "JPY", 149.50m },
            { "CNY", 7.24m },
            { "SGD", 1.34m },
            { "AED", 3.67m }
        };

        public CurrencyService(HttpClient httpClient, IConfiguration config, ILogger<CurrencyService> logger)
        {
            _httpClient = httpClient;
            _config = config;
            _logger = logger;
            _apiKey = _config["CurrencyConverter:ApiKey"] ?? string.Empty;
            _baseUrl = _config["CurrencyConverter:BaseUrl"] ?? "https://v6.exchangerate-api.com/v6";
        }
        
        private bool IsApilayerApi()
        {
            return !string.IsNullOrWhiteSpace(_apiKey) && _apiKey.StartsWith("apv_");
        }

        public async Task<decimal> ConvertCurrencyAsync(decimal amount, string fromCurrency, string toCurrency)
        {
            try
            {
                if (fromCurrency.Equals(toCurrency, StringComparison.OrdinalIgnoreCase))
                {
                    return amount;
                }

                // Try API if key is configured
                if (!string.IsNullOrWhiteSpace(_apiKey))
                {
                    try
                    {
                        if (IsApilayerApi())
                        {
                            return await ConvertUsingApilayerAsync(amount, fromCurrency, toCurrency);
                        }
                        else
                        {
                            return await ConvertUsingExchangerateApiAsync(amount, fromCurrency, toCurrency);
                        }
                    }
                    catch (Exception apiEx)
                    {
                        _logger.LogWarning(apiEx, "API call failed, using fallback rates for {From} to {To}", fromCurrency, toCurrency);
                    }
                }

                // Fallback to manual conversion using base rates
                return ConvertUsingFallbackRates(amount, fromCurrency, toCurrency);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error converting currency from {From} to {To}", fromCurrency, toCurrency);
                throw new InvalidOperationException($"Unable to convert currency from {fromCurrency} to {toCurrency}. Please try again later.", ex);
            }
        }
        
        private async Task<decimal> ConvertUsingApilayerAsync(decimal amount, string fromCurrency, string toCurrency)
        {
            var url = $"https://api.apilayer.com/exchangerates_data/convert?to={toCurrency.ToUpper()}&from={fromCurrency.ToUpper()}&amount={amount}";
            
            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.Add("apikey", _apiKey);
            
            var response = await _httpClient.SendAsync(request);
            response.EnsureSuccessStatusCode();
            
            var content = await response.Content.ReadAsStringAsync();
            var jsonDoc = JsonDocument.Parse(content);
            
            if (jsonDoc.RootElement.TryGetProperty("result", out var result))
            {
                return result.GetDecimal();
            }
            
            throw new InvalidOperationException("Invalid response from Apilayer currency API");
        }
        
        private async Task<decimal> ConvertUsingExchangerateApiAsync(decimal amount, string fromCurrency, string toCurrency)
        {
            var url = $"{_baseUrl}/{_apiKey}/pair/{fromCurrency.ToUpper()}/{toCurrency.ToUpper()}/{amount}";
            var response = await _httpClient.GetAsync(url);
            response.EnsureSuccessStatusCode();
            
            var content = await response.Content.ReadAsStringAsync();
            var jsonDoc = JsonDocument.Parse(content);
            
            if (jsonDoc.RootElement.TryGetProperty("conversion_result", out var result))
            {
                return result.GetDecimal();
            }
            
            throw new InvalidOperationException("Invalid response from exchangerate-api API");
        }

        public async Task<Dictionary<string, decimal>> GetExchangeRatesAsync(string baseCurrency)
        {
            try
            {
                // Try API if key is configured
                if (!string.IsNullOrWhiteSpace(_apiKey))
                {
                    try
                    {
                        if (IsApilayerApi())
                        {
                            return await GetRatesFromApilayerAsync(baseCurrency);
                        }
                        else
                        {
                            return await GetRatesFromExchangerateApiAsync(baseCurrency);
                        }
                    }
                    catch (Exception apiEx)
                    {
                        _logger.LogWarning(apiEx, "API call failed, using fallback rates for base currency {Base}", baseCurrency);
                    }
                }

                // Fallback to manual conversion
                return GetFallbackRates(baseCurrency);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting exchange rates for base currency {Base}", baseCurrency);
                throw new InvalidOperationException($"Unable to get exchange rates for {baseCurrency}. Please try again later.", ex);
            }
        }
        
        private async Task<Dictionary<string, decimal>> GetRatesFromApilayerAsync(string baseCurrency)
        {
            var url = $"https://api.apilayer.com/exchangerates_data/latest?base={baseCurrency.ToUpper()}";
            
            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.Add("apikey", _apiKey);
            
            var response = await _httpClient.SendAsync(request);
            response.EnsureSuccessStatusCode();
            
            var content = await response.Content.ReadAsStringAsync();
            var jsonDoc = JsonDocument.Parse(content);
            
            if (jsonDoc.RootElement.TryGetProperty("rates", out var rates))
            {
                var result = new Dictionary<string, decimal>();
                foreach (var rate in rates.EnumerateObject())
                {
                    result[rate.Name] = rate.Value.GetDecimal();
                }
                return result;
            }
            
            throw new InvalidOperationException("Invalid response from Apilayer currency API");
        }
        
        private async Task<Dictionary<string, decimal>> GetRatesFromExchangerateApiAsync(string baseCurrency)
        {
            var url = $"{_baseUrl}/{_apiKey}/latest/{baseCurrency.ToUpper()}";
            var response = await _httpClient.GetAsync(url);
            response.EnsureSuccessStatusCode();
            
            var content = await response.Content.ReadAsStringAsync();
            var jsonDoc = JsonDocument.Parse(content);
            
            if (jsonDoc.RootElement.TryGetProperty("conversion_rates", out var rates))
            {
                var result = new Dictionary<string, decimal>();
                foreach (var rate in rates.EnumerateObject())
                {
                    result[rate.Name] = rate.Value.GetDecimal();
                }
                return result;
            }
            
            throw new InvalidOperationException("Invalid response from exchangerate-api API");
        }
        
        private decimal ConvertUsingFallbackRates(decimal amount, string fromCurrency, string toCurrency)
        {
            fromCurrency = fromCurrency.ToUpper();
            toCurrency = toCurrency.ToUpper();
            
            // If either currency is not in our fallback list, throw an error
            if (!_fallbackRates.ContainsKey(fromCurrency) || !_fallbackRates.ContainsKey(toCurrency))
            {
                throw new InvalidOperationException($"Currency conversion not supported for {fromCurrency} to {toCurrency} in offline mode.");
            }
            
            // Convert to USD first, then to target currency
            var usdAmount = amount / _fallbackRates[fromCurrency];
            var result = usdAmount * _fallbackRates[toCurrency];
            
            // Round to 2 decimal places
            return Math.Round(result, 2);
        }
        
        private Dictionary<string, decimal> GetFallbackRates(string baseCurrency)
        {
            baseCurrency = baseCurrency.ToUpper();
            
            if (!_fallbackRates.ContainsKey(baseCurrency))
            {
                throw new InvalidOperationException($"Base currency {baseCurrency} not supported in offline mode.");
            }
            
            var result = new Dictionary<string, decimal>();
            var baseRate = _fallbackRates[baseCurrency];
            
            // Convert all rates relative to the base currency
            foreach (var rate in _fallbackRates)
            {
                result[rate.Key] = Math.Round(rate.Value / baseRate, 4);
            }
            
            return result;
        }
    }
}
