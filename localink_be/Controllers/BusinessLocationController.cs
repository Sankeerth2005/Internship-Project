using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/v1/location")]
public class BusinessLocationController : ControllerBase
{
    private readonly BusinessLocationService _service;

    public BusinessLocationController(BusinessLocationService service)
    {
        _service = service;
    }

    [HttpGet("countries")]
    public async Task<IActionResult> GetCountries()
    {
        var data = await _service.GetCountries();
        return Content(data, "application/json");
    }

    [HttpGet("states/{countryCode}")]
    public async Task<IActionResult> GetStates(string countryCode)
    {
        var data = await _service.GetStates(countryCode);
        return Content(data, "application/json");
    }

    [HttpGet("cities/{countryCode}/{stateCode}")]
    public async Task<IActionResult> GetCities(string countryCode, string stateCode)
    {
        var data = await _service.GetCities(countryCode, stateCode);
        return Content(data, "application/json");
    }
}