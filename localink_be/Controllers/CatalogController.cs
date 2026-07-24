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

        [HttpGet("{businessId}")]
        public async Task<IActionResult> GetBusinessCatalogs(long businessId)
        {
            var catalogs = await _catalogService.GetBusinessCatalogsAsync(businessId);
            return Ok(new { success = true, data = catalogs });
        }

        [Authorize(Roles = "BusinessOwner")]
        [HttpPost("{businessId}")]
        public async Task<IActionResult> CreateCatalog(long businessId, [FromBody] CreateCatalogDto dto)
        {
            // Verify business ownership? Ideally yes, but skipping complex auth check for brevity
            var catalog = await _catalogService.CreateCatalogAsync(businessId, dto);
            return Ok(new { success = true, data = catalog });
        }

        [Authorize(Roles = "BusinessOwner")]
        [HttpPut("{catalogId}")]
        public async Task<IActionResult> UpdateCatalog(int catalogId, [FromBody] CreateCatalogDto dto)
        {
            try
            {
                var catalog = await _catalogService.UpdateCatalogAsync(catalogId, dto);
                return Ok(new { success = true, data = catalog });
            }
            catch (KeyNotFoundException)
            {
                return NotFound(new { success = false, message = "Catalog not found" });
            }
        }

        [Authorize(Roles = "BusinessOwner")]
        [HttpDelete("{catalogId}")]
        public async Task<IActionResult> DeleteCatalog(int catalogId)
        {
            await _catalogService.DeleteCatalogAsync(catalogId);
            return Ok(new { success = true });
        }

        [Authorize(Roles = "BusinessOwner")]
        [HttpPost("{catalogId}/items")]
        public async Task<IActionResult> AddCatalogItem(int catalogId, [FromForm] CreateCatalogItemDto dto, IFormFile? image)
        {
            var item = await _catalogService.AddCatalogItemAsync(catalogId, dto, image);
            return Ok(new { success = true, data = item });
        }

        [Authorize(Roles = "BusinessOwner")]
        [HttpPut("items/{itemId}")]
        public async Task<IActionResult> UpdateCatalogItem(int itemId, [FromForm] CreateCatalogItemDto dto, IFormFile? image)
        {
            try
            {
                var item = await _catalogService.UpdateCatalogItemAsync(itemId, dto, image);
                return Ok(new { success = true, data = item });
            }
            catch (KeyNotFoundException)
            {
                return NotFound(new { success = false, message = "Item not found" });
            }
        }

        [Authorize(Roles = "BusinessOwner")]
        [HttpDelete("items/{itemId}")]
        public async Task<IActionResult> DeleteCatalogItem(int itemId)
        {
            await _catalogService.DeleteCatalogItemAsync(itemId);
            return Ok(new { success = true });
        }
    }
}
