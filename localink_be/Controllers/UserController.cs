using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Threading.Tasks;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
[ApiController]
[Route("api/v1/user")]
[Authorize]
public class UserController : ControllerBase
{
    private readonly IUserService _service;
    private readonly IPhotoService _photoService;

    public UserController(IUserService service, IPhotoService photoService)
    {
        _service = service;
        _photoService = photoService;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var result = await _service.GetUserProfileAsync(long.Parse(userId));

        if (result == null)
            return NotFound();

        return Ok(result);
    }
    
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserProfileDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { success = false, errors = ModelState });

        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        if (userId == null)
            return Unauthorized();

        var result = await _service.UpdateUserProfileAsync(long.Parse(userId), request);

        if (!result)
            return NotFound(new { success = false, message = "User not found" });

        return Ok(new { success = true, message = "Profile updated successfully" });
    }

    [HttpPost("avatar")]
    public async Task<IActionResult> UploadAvatar(IFormFile file)
    {
        var userIdStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();

        if (file == null || file.Length == 0)
            return BadRequest(new { success = false, message = "No image file uploaded" });

        var imageUrl = await _photoService.UploadImageAsync(file, "avatars");
        if (imageUrl == null)
            return BadRequest(new { success = false, message = "Failed to upload image" });

        var userId = long.Parse(userIdStr);
        var user = await _service.GetUserProfileAsync(userId);
        if (user == null) return NotFound(new { success = false, message = "User not found" });

        await _service.UpdateUserProfileAsync(userId, new UpdateUserProfileDto
        {
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            CountryCode = user.CountryCode,
            ProfilePicture = imageUrl,
            Address = user.Address
        });

        return Ok(new { success = true, imageUrl });
    }

    [HttpDelete("account")]
    public async Task<IActionResult> DeleteAccount()
    {
        var userIdStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();

        var userId = long.Parse(userIdStr);
        var result = await _service.DeleteUserAccountAsync(userId);

        if (!result)
            return NotFound(new { success = false, message = "User not found" });

        return Ok(new { success = true, message = "Account deleted successfully" });
    }
}
}