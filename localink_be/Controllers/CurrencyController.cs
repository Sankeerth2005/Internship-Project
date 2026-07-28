using Microsoft.AspNetCore.Mvc;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class CurrencyController : ControllerBase
    {
        private readonly ICurrencyService _currencyService;

        public CurrencyController(ICurrencyService currencyService)
        {
            _currencyService = currencyService;
        }

        [HttpGet("convert")]
        public async Task<IActionResult> ConvertCurrency([FromQuery] decimal amount, [FromQuery] string from, [FromQuery] string to)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(from) || string.IsNullOrWhiteSpace(to))
                {
                    return BadRequest(new { success = false, message = "From and To currencies are required" });
                }

                var result = await _currencyService.ConvertCurrencyAsync(amount, from, to);
                return Ok(new { success = true, data = new { amount = result, from, to } });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        [HttpGet("rates")]
        public async Task<IActionResult> GetExchangeRates([FromQuery] string baseCurrency = "USD")
        {
            try
            {
                if (string.IsNullOrWhiteSpace(baseCurrency))
                {
                    baseCurrency = "USD";
                }

                var rates = await _currencyService.GetExchangeRatesAsync(baseCurrency);
                return Ok(new { success = true, data = new { baseCurrency, rates } });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }
    }
}
