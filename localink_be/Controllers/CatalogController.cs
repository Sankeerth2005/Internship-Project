using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class CatalogController : ControllerBase
    {
        private readonly ICatalogService _catalogService;

        public CatalogController(ICatalogService catalogService)
        {
            _catalogService = catalogService;
        }

        private long GetCurrentUserId()
        {
            var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (long.TryParse(idClaim, out long id)) return id;
            throw new UnauthorizedAccessException("Invalid token");
        }

        private bool IsAdmin() =>
            User.IsInRole("admin") ||
            string.Equals(User.FindFirst(ClaimTypes.Role)?.Value, "admin", StringComparison.OrdinalIgnoreCase);

        [HttpGet("{businessId}")]
        public async Task<IActionResult> GetBusinessCatalogs(long businessId)
        {
            var catalogs = await _catalogService.GetBusinessCatalogsAsync(businessId);
            return Ok(new { success = true, data = catalogs });
        }

        [Authorize(Roles = "client,businessowner,admin")]
        [HttpPost("{businessId}")]
        public async Task<IActionResult> CreateCatalog(long businessId, [FromBody] CreateCatalogDto dto)
        {
            try
            {
                var catalog = await _catalogService.CreateCatalogAsync(businessId, dto, GetCurrentUserId(), IsAdmin());
                return Ok(new { success = true, data = catalog });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [Authorize(Roles = "client,businessowner,admin")]
        [HttpPut("{catalogId}")]
        public async Task<IActionResult> UpdateCatalog(int catalogId, [FromBody] CreateCatalogDto dto)
        {
            try
            {
                var catalog = await _catalogService.UpdateCatalogAsync(catalogId, dto, GetCurrentUserId(), IsAdmin());
                return Ok(new { success = true, data = catalog });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (KeyNotFoundException)
            {
                return NotFound(new { success = false, message = "Catalog not found" });
            }
        }

        [Authorize(Roles = "client,businessowner,admin")]
        [HttpDelete("{catalogId}")]
        public async Task<IActionResult> DeleteCatalog(int catalogId)
        {
            try
            {
                await _catalogService.DeleteCatalogAsync(catalogId, GetCurrentUserId(), IsAdmin());
                return Ok(new { success = true });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [Authorize(Roles = "client,businessowner,admin")]
        [HttpPost("{catalogId}/items")]
        public async Task<IActionResult> AddCatalogItem(int catalogId, [FromForm] CreateCatalogItemDto dto, IFormFile? image)
        {
            try
            {
                var item = await _catalogService.AddCatalogItemAsync(catalogId, dto, image, GetCurrentUserId(), IsAdmin());
                return Ok(new { success = true, data = item });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [Authorize(Roles = "client,businessowner,admin")]
        [HttpPut("items/{itemId}")]
        public async Task<IActionResult> UpdateCatalogItem(int itemId, [FromForm] CreateCatalogItemDto dto, IFormFile? image)
        {
            try
            {
                var item = await _catalogService.UpdateCatalogItemAsync(itemId, dto, image, GetCurrentUserId(), IsAdmin());
                return Ok(new { success = true, data = item });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (KeyNotFoundException)
            {
                return NotFound(new { success = false, message = "Item not found" });
            }
        }

        [Authorize(Roles = "client,businessowner,admin")]
        [HttpDelete("items/{itemId}")]
        public async Task<IActionResult> DeleteCatalogItem(int itemId)
        {
            try
            {
                await _catalogService.DeleteCatalogItemAsync(itemId, GetCurrentUserId(), IsAdmin());
                return Ok(new { success = true });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }
    }
}
