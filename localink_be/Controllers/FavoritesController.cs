using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [Route("api/v1/favorites")]
    [ApiController]
    [Authorize]
    public class FavoritesController : ControllerBase
    {
        private readonly IFavoritesService _favoritesService;

        public FavoritesController(IFavoritesService favoritesService)
        {
            _favoritesService = favoritesService;
        }

        [HttpPost("add")]
        [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(object), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> AddFavorite([FromBody] FavoriteDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Validation failed",
                    errors = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                });
            }

            var currentUserIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(currentUserIdStr)) return Unauthorized();
            long currentUserId = long.Parse(currentUserIdStr);
            if (dto.UserId != currentUserId && !User.IsInRole("admin"))
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = "Forbidden" });
            }

            var result = await _favoritesService.AddFavoriteAsync(dto);

            if (result == "Already added" || result == "User not found" || result == "Business not found")
                return BadRequest(new { success = false, message = result });

            return Ok(new { success = true, message = result });
        }

        [HttpDelete("remove")]
        [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(object), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(object), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> RemoveFavorite(
            [FromQuery][Required][Range(1, long.MaxValue)] long userId,
            [FromQuery][Required][Range(1, long.MaxValue)] long businessId)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Validation failed",
                    errors = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                });
            }

            var currentUserIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(currentUserIdStr)) return Unauthorized();
            long currentUserId = long.Parse(currentUserIdStr);
            if (userId != currentUserId && !User.IsInRole("admin"))
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = "Forbidden" });
            }

            var result = await _favoritesService.RemoveFavoriteAsync(userId, businessId);

            if (result == "Not found")
                return NotFound(new { success = false, message = result });

            return Ok(new { success = true, message = result });
        }

        [HttpGet("user/{userId}")]
        [ProducesResponseType(typeof(List<long>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(object), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> GetFavorites(
            [FromRoute][Range(1, long.MaxValue)] long userId)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Invalid User ID"
                });
            }

            var currentUserIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(currentUserIdStr)) return Unauthorized();
            long currentUserId = long.Parse(currentUserIdStr);
            if (userId != currentUserId && !User.IsInRole("admin"))
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = "Forbidden" });
            }

            var favorites = await _favoritesService.GetUserFavoritesAsync(userId);
            return Ok(favorites);
        }
    }
}
