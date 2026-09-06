using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

[ApiController]
[Route("api/v1/BusinessPincode")]
public class BusinessPincodeController : ControllerBase
{
    private readonly IBusinessPincodeService _service;

    public BusinessPincodeController(IBusinessPincodeService service)
    {
        _service = service;
    }

    [HttpGet("validate")]
    public async Task<IActionResult> Validate(
        [FromQuery] string postcode,
        [FromQuery] string? country = null,
        [FromQuery] string? countryIso2 = null)
    {
        if (string.IsNullOrWhiteSpace(postcode))
            return BadRequest("Invalid pincode");

        try
        {
            var result = await _service.GetPincodeData(postcode, countryIso2, country);

            var jsonDoc = JsonDocument.Parse(result);
            if (!jsonDoc.RootElement.TryGetProperty("features", out var features) ||
                features.GetArrayLength() == 0)
            {
                return NotFound(new
                {
                    message = "Invalid pincode"
                });
            }

            var firstResult = features[0].GetProperty("properties");

            return Ok(new
            {
                country = firstResult.TryGetProperty("country", out var countryProp)
                    ? countryProp.GetString()
                    : null,
                state = firstResult.TryGetProperty("state", out var stateProp)
                    ? stateProp.GetString()
                    : null,
                city = firstResult.TryGetProperty("city", out var cityProp)
                    ? cityProp.GetString()
                    : null
            });
        }
        catch (JsonException)
        {
            return StatusCode(500, new { message = "Business pincode validation failed" });
        }
        catch (InvalidOperationException)
        {
            return StatusCode(502, new { message = "Business pincode validation failed" });
        }
        catch (Exception)
        {
            return StatusCode(502, new { message = "Business pincode validation failed" });
        }
    }
}
