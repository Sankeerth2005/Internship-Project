using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

[Authorize(Roles = "admin")]
[ApiController]
[Route("api/v1/admin")]
public class AdminController : ControllerBase
{
    private readonly IAdminService _service;

    public AdminController(IAdminService service)
    {
        _service = service;
    }

    [HttpGet("businesses")]
    public async Task<IActionResult> GetAll()
    {
        var data = await _service.GetAllAsync();
        return Ok(data);
    }

    [HttpPut("business/{id}/status")]
    public async Task<IActionResult> UpdateStatus(long id, UpdateStatusDto dto)
    {
        var adminId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(adminId)) return Unauthorized();
        await _service.UpdateStatusAsync(id, dto, long.Parse(adminId));
        return Ok(new { message = "Status updated" });
    }

    [HttpGet("export")]
    public async Task<IActionResult> Export([FromQuery] string status)
    {
        var file = await _service.ExportAsync(status);
        return File(file, 
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"{status}-businesses.xlsx");
    }
}