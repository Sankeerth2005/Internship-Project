using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using System;
using System.Security.Claims;
using System.Threading.Tasks;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/business/{businessId}/photos")]
    public class PhotoController : ControllerBase
    {
        private readonly IPhotoService _photoService;

        public PhotoController(IPhotoService photoService)
        {
            _photoService = photoService;
        }

        // POST: api/v1/business/{businessId}/photos
        [Authorize(Roles = "client,businessowner")]
        [HttpPost]
        public async Task<IActionResult> UploadPhoto(long businessId, IFormFile file)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();
            long currentUserId = long.Parse(userIdStr);
            bool isAdmin = User.IsInRole("admin");

            try
            {
                var result = await _photoService.UploadPhotoAsync(businessId, file, currentUserId, isAdmin);
                if (result == null)
                    return BadRequest(new { success = false, message = "Upload failed" });

                return Ok(new { success = true, data = result });
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = ex.Message });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new { success = false, message = ex.Message });
            }
        }

        // DELETE: api/v1/photos/{photoId}
        [Authorize(Roles = "client,businessowner")]
        [HttpDelete("~/api/v1/photos/{photoId}")]
        public async Task<IActionResult> DeletePhoto(long photoId)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();
            long currentUserId = long.Parse(userIdStr);
            bool isAdmin = User.IsInRole("admin");

            try
            {
                var deleted = await _photoService.DeletePhotoAsync(photoId, currentUserId, isAdmin);
                if (!deleted)
                    return NotFound(new { success = false, message = "Photo not found" });

                return NoContent();
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new { success = false, message = ex.Message });
            }
        }
    }
}
