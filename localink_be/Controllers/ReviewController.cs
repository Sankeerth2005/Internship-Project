using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using localink_be.Models.DTOs;

[ApiController]
[Route("api/v1/reviews")]
public class ReviewController : ControllerBase
{
    private readonly IReviewService _reviewService;

    public ReviewController(IReviewService reviewService)
    {
        _reviewService = reviewService;
    }

    [HttpPost]
    [Authorize] 
    public async Task<IActionResult> AddOrUpdateReview([FromBody] ReviewRequestDto dto)
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

        try
        {
            var userId = GetUserId();

            if (userId == 0)
                return Unauthorized(new { success = false, message = "Invalid user" });

            await _reviewService.AddOrUpdateReview(userId, dto);

            return Ok(new
            {
                success = true,
                message = "Review submitted successfully"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message
            });
        }
    }

    [HttpGet("business/{businessId}")]
    public async Task<IActionResult> GetReviews(long businessId)
    {
        try
        {
            var reviews = await _reviewService.GetReviewsByBusiness(businessId);

            return Ok(reviews);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                error = ex.Message
            });
        }
    }

    [HttpGet("summary/{businessId}")]
    public async Task<IActionResult> GetSummary(long businessId)
    {
        try
        {
            var summary = await _reviewService.GetSummary(businessId);

            return Ok(summary);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                error = ex.Message
            });
        }
    }
    private long GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return 0;

        return long.TryParse(userIdClaim.Value, out var userId)
            ? userId
            : 0;
    }
}