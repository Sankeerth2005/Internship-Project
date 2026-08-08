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
            if (string.IsNullOrWhiteSpace(from) || string.IsNullOrWhiteSpace(to))
            {
                return BadRequest(new { success = false, message = "From and To currencies are required" });
            }

            try
            {
                var result = await _currencyService.ConvertCurrencyAsync(amount, from, to);
                return Ok(new { success = true, data = new { amount = result, from, to } });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        [HttpGet("rates")]
        public async Task<IActionResult> GetExchangeRates([FromQuery] string baseCurrency = "USD")
        {
            if (string.IsNullOrWhiteSpace(baseCurrency))
            {
                baseCurrency = "USD";
            }

            try
            {
                var rates = await _currencyService.GetExchangeRatesAsync(baseCurrency);
                return Ok(new { success = true, data = new { baseCurrency, rates } });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }
    }
}
