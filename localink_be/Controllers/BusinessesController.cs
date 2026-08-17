using Microsoft.AspNetCore.Mvc;
using localink_be.Data;
using localink_be.Models.DTOs;
using localink_be.Models.Entities;
using localink_be.Models.Queries;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    /// <summary>
    /// Enterprise business discovery API.
    /// All search, sort, distance ranking, and pagination run in SQL Server.
    /// </summary>
    [ApiController]
    [Route("api/v1/businesses")]
    public class BusinessesController : ControllerBase
    {
        private readonly IBusinessDiscoveryService _discoveryService;
        private readonly AppDbContext _db;

        public BusinessesController(IBusinessDiscoveryService discoveryService, AppDbContext db)
        {
            _discoveryService = discoveryService;
            _db = db;
        }

        /// <summary>
        /// GET /api/v1/businesses?latitude=&amp;longitude=&amp;radius=&amp;categoryId=&amp;search=&amp;sort=&amp;page=&amp;pageSize=
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(PagedResultDto<BusinessDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetBusinesses(
            [FromQuery] double? latitude = null,
            [FromQuery] double? longitude = null,
            [FromQuery] double? radius = null,
            [FromQuery] int? categoryId = null,
            [FromQuery] int? subcategoryId = null,
            [FromQuery] string? search = null,
            [FromQuery] string? query = null,
            [FromQuery] string? sort = null,
            [FromQuery] string? sortBy = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? userPincode = null,
            CancellationToken cancellationToken = default)
        {
            ResolveLocationFromHeaders(ref latitude, ref longitude, out var userCity);

            var searchText = !string.IsNullOrWhiteSpace(search) ? search : query;
            var sortKey = !string.IsNullOrWhiteSpace(sort) ? sort : sortBy;

            if (!string.IsNullOrWhiteSpace(searchText))
                await TryLogSearchAsync(searchText, latitude, longitude);

            var result = await _discoveryService.DiscoverAsync(new BusinessDiscoveryQuery
            {
                Latitude = latitude,
                Longitude = longitude,
                RadiusKm = radius,
                CategoryId = categoryId,
                SubcategoryId = subcategoryId,
                Search = searchText,
                Sort = BusinessSortModeParser.Parse(sortKey),
                Page = page,
                PageSize = pageSize,
                UserPincode = userPincode,
                UserCity = userCity
            }, cancellationToken);

            return Ok(result);
        }

        private void ResolveLocationFromHeaders(ref double? latitude, ref double? longitude, out string? userCity)
        {
            userCity = null;

            if ((!latitude.HasValue || !longitude.HasValue)
                && Request.Headers.ContainsKey("X-User-Latitude")
                && Request.Headers.ContainsKey("X-User-Longitude")
                && double.TryParse(Request.Headers["X-User-Latitude"], out var lat)
                && double.TryParse(Request.Headers["X-User-Longitude"], out var lng))
            {
                latitude ??= lat;
                longitude ??= lng;
            }

            if (Request.Headers.ContainsKey("X-User-City"))
                userCity = Request.Headers["X-User-City"].ToString();
        }

        private async Task TryLogSearchAsync(string searchText, double? lat, double? lng)
        {
            try
            {
                var log = new SearchQueryLog
                {
                    Query = searchText,
                    Timestamp = DateTime.UtcNow
                };
                if (lat.HasValue && lng.HasValue)
                {
                    log.Latitude = lat.Value;
                    log.Longitude = lng.Value;
                }
                _db.SearchQueryLogs.Add(log);
                await _db.SaveChangesAsync();
            }
            catch
            {
                /* never fail discovery because of analytics */
            }
        }
    }
}
