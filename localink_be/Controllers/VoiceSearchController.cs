using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Threading.Tasks;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/search")]
    public class VoiceSearchController : ControllerBase
    {
        private readonly IBusinessService _businessService;
        private readonly IAIGatewayService _aiGateway;

        public VoiceSearchController(IBusinessService businessService, IAIGatewayService aiGateway)
        {
            _businessService = businessService ?? throw new ArgumentNullException(nameof(businessService));
            _aiGateway = aiGateway ?? throw new ArgumentNullException(nameof(aiGateway));
        }

        /// <summary>
        /// Voice-enabled search endpoint with structured query parsing
        /// </summary>
        /// <param name="request">Voice search request with parsed parameters</param>
        /// <returns>Search results with applied filters</returns>
        [HttpPost("voice")]
        [AllowAnonymous]
        public async Task<IActionResult> VoiceSearch([FromBody] VoiceSearchRequest request)
        {
            // Validate request
            if (request == null)
            {
                return BadRequest(new VoiceSearchResponse
                {
                    Success = false,
                    Message = "Request body is required",
                    Results = new System.Collections.Generic.List<BusinessDto>(),
                    TotalCount = 0
                });
            }

            // Validate query length
            if (!string.IsNullOrEmpty(request.Query) && request.Query.Length > 200)
            {
                return BadRequest(new VoiceSearchResponse
                {
                    Success = false,
                    Message = "Query is too long. Maximum 200 characters allowed.",
                    Results = new System.Collections.Generic.List<BusinessDto>(),
                    TotalCount = 0
                });
            }

            // Validate radius
            if (request.Radius < 0 || request.Radius > 100)
            {
                return BadRequest(new VoiceSearchResponse
                {
                    Success = false,
                    Message = "Radius must be between 0 and 100 kilometers",
                    Results = new System.Collections.Generic.List<BusinessDto>(),
                    TotalCount = 0
                });
            }

            try
            {
                // Parse intent using AI Gateway to extract search query, category, openNow status
                if (!string.IsNullOrWhiteSpace(request.Query))
                {
                    try
                    {
                        var intentResult = await _aiGateway.ParseIntentAsync(request.Query);
                        if (intentResult.Success)
                        {
                            request.Query = intentResult.Query ?? request.Query;
                            request.Category = intentResult.Category ?? request.Category;
                            request.OpenNow = intentResult.OpenNow || request.OpenNow;
                            if (intentResult.RadiusKm.HasValue)
                            {
                                request.Radius = intentResult.RadiusKm.Value;
                            }
                        }
                    }
                    catch
                    {
                        // Fall back to original query if AI parsing fails
                    }
                }

                // Try to get user location from request headers if available
                double? userLat = null;
                double? userLng = null;

                if (Request.Headers.ContainsKey("X-User-Latitude") && 
                    Request.Headers.ContainsKey("X-User-Longitude"))
                {
                    if (double.TryParse(Request.Headers["X-User-Latitude"], out var lat) &&
                        double.TryParse(Request.Headers["X-User-Longitude"], out var lng))
                    {
                        userLat = lat;
                        userLng = lng;
                    }
                }

                var response = await _businessService.VoiceSearchAsync(request, userLat, userLng);

                if (response.Success)
                {
                    return Ok(response);
                }
                else
                {
                    return StatusCode(500, response);
                }
            }
            catch (Exception ex)
            {
                // Log the exception (in production, use proper logging)
                return StatusCode(500, new VoiceSearchResponse
                {
                    Success = false,
                    Message = "An unexpected error occurred while processing your voice search",
                    Results = new System.Collections.Generic.List<BusinessDto>(),
                    TotalCount = 0
                });
            }
        }

        /// <summary>
        /// Health check endpoint for voice search service
        /// </summary>
        [HttpGet("voice/health")]
        [AllowAnonymous]
        public IActionResult HealthCheck()
        {
            return Ok(new { status = "healthy", service = "voice-search", timestamp = DateTime.UtcNow });
        }
    }
}
