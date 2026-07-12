using localink_be.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/ai")]
    public class AIController : ControllerBase
    {
        private readonly IAIService _aiService;

        public AIController(IAIService aiService)
        {
            _aiService = aiService;
        }

        [HttpPost("review-suggestions")]
        public async Task<IActionResult> GetReviewSuggestions([FromBody] ReviewSuggestionRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.DraftText) || request.DraftText.Length < 3)
            {
                return BadRequest(new { success = false, message = "Please provide at least a few words" });
            }

            if (request.Rating < 1 || request.Rating > 5)
            {
                return BadRequest(new { success = false, message = "Invalid rating" });
            }

            var suggestions = await _aiService.GetReviewSuggestionsAsync(
                request.DraftText, 
                request.Rating, 
                request.BusinessName ?? "this business");

            return Ok(new { success = true, data = suggestions });
        }

        [HttpPost("review-summary")]
        public async Task<IActionResult> GetReviewSummary([FromBody] ReviewSummaryRequest request)
        {
            if (request.Reviews == null || request.Reviews.Length == 0)
            {
                return BadRequest(new { success = false, message = "No reviews provided" });
            }

            if (string.IsNullOrWhiteSpace(request.BusinessName))
            {
                return BadRequest(new { success = false, message = "Business name is required" });
            }

            var summary = await _aiService.GetReviewSummaryAsync(
                request.Reviews,
                request.AverageRating,
                request.TotalReviews,
                request.BusinessName);

            return Ok(new { success = true, data = summary });
        }

        [HttpPost("generate-description")]
        public async Task<IActionResult> GenerateDescription([FromBody] GenerateDescriptionRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.BusinessName))
                return BadRequest(new { success = false, message = "Business name is required" });

            var keywords = request.Keywords ?? Array.Empty<string>();
            var description = await _aiService.GenerateDescriptionAsync(
                request.BusinessName,
                request.Category ?? "general",
                keywords);

            return Ok(new { success = true, data = description });
        }

        [HttpPost("chat-search")]
        public async Task<IActionResult> ChatSearch([FromBody] ChatSearchRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Message))
                return BadRequest(new { success = false, message = "Message is required" });

            var reply = await _aiService.ChatSearchAsync(request.Message, request.ChatHistoryJson ?? "");
            return Ok(new { success = true, data = reply });
        }
    }

    public class GenerateDescriptionRequest
    {
        public string BusinessName { get; set; } = string.Empty;
        public string? Category { get; set; }
        public string[]? Keywords { get; set; }
    }

    public class ChatSearchRequest
    {
        public string Message { get; set; } = string.Empty;
        public string? ChatHistoryJson { get; set; }
    }

    public class ReviewSuggestionRequest
    {
        public string DraftText { get; set; } = string.Empty;
        public int Rating { get; set; }
        public string? BusinessName { get; set; }
    }

    public class ReviewSummaryRequest
    {
        public string[] Reviews { get; set; } = Array.Empty<string>();
        public double AverageRating { get; set; }
        public int TotalReviews { get; set; }
        public string BusinessName { get; set; } = string.Empty;
    }
}
