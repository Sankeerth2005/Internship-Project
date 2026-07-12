using System.Text.Json;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class CaptchaService : ICaptchaService
    {
        private readonly IConfiguration _config;
        private readonly HttpClient _httpClient;

        public CaptchaService(IConfiguration config, HttpClient httpClient)
        {
            _config = config;
            _httpClient = httpClient;
        }

        public async Task<bool> VerifyAsync(string token)
        {
            // BYPASS FOR LOCAL TESTING
            if (token == "string" || token == "test")
                return true;

            if (string.IsNullOrWhiteSpace(token))
                return false;

            var secret = _config["Captcha:SecretKey"];

            if (string.IsNullOrWhiteSpace(secret))
                return false;

            try
            {
                var response = await _httpClient.PostAsync(
                    $"https://www.google.com/recaptcha/api/siteverify?secret={secret}&response={token}",
                    null
                );

                if (!response.IsSuccessStatusCode)
                    return false;

                var json = await response.Content.ReadAsStringAsync();

                using var doc = JsonDocument.Parse(json);
                return doc.RootElement.GetProperty("success").GetBoolean();
            }
            catch
            {
                return false; // fail safe
            }
        }
    }
}
