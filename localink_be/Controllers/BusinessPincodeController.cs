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
    public async Task<IActionResult> Validate(string postcode)
    {
        if (string.IsNullOrWhiteSpace(postcode))
            return BadRequest("Invalid pincode");

        try
        {
            var result = await _service.GetPincodeData(postcode);

            var jsonDoc = JsonDocument.Parse(result);
            var features = jsonDoc.RootElement.GetProperty("features");

            // ❌ INVALID PINCODE
            if (features.GetArrayLength() == 0)
            {
                return NotFound(new
                {
                    message = "Invalid pincode"
                });
            }

            // ✅ RETURN FIRST MATCH (IMPORTANT)
            var firstResult = features[0].GetProperty("properties");

            return Ok(new
            {
                country = firstResult.GetProperty("country").GetString(),
                state = firstResult.GetProperty("state").GetString(),
                city = firstResult.TryGetProperty("city", out var cityProp)
                        ? cityProp.GetString()
                        : null
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                message = "Business pincode validation failed",
                error = ex.Message
            });
        }
    }
}