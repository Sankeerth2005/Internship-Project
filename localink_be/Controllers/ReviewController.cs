using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Security.Claims;
using localink_be.Models.DTOs;

[ApiController]
[Route("api/v1/reviews")]
public class ReviewController : ControllerBase
{
    private readonly IReviewService _reviewService;
    private readonly ILogger<ReviewController> _logger;

    public ReviewController(IReviewService reviewService, ILogger<ReviewController> logger)
    {
        _reviewService = reviewService;
        _logger = logger;
    }

    [HttpPost]
    [Authorize]
    [LogInvalidReviewModelState]
    public async Task<IActionResult> AddOrUpdateReview([FromBody] ReviewRequestDto dto)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .Where(m => !string.IsNullOrWhiteSpace(m))
                    .ToList();

            _logger.LogWarning("Review validation failed: {Errors}", string.Join("; ", errors));

            return BadRequest(new
            {
                success = false,
                message = errors.Count == 1 ? errors[0] : "Validation failed",
                errors
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
        catch (ArgumentException ex)
        {
            return BadRequest(new { success = false, error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, error = ex.Message });
        }
        // Unexpected errors bubble to ExceptionMiddleware
    }

    [HttpGet("business/{businessId}")]
    public async Task<IActionResult> GetReviews(long businessId)
    {
        var reviews = await _reviewService.GetReviewsByBusiness(businessId);
        return Ok(reviews);
    }

    [HttpGet("summary/{businessId}")]
    public async Task<IActionResult> GetSummary(long businessId)
    {
        var summary = await _reviewService.GetSummary(businessId);
        return Ok(summary);
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

/// Logs the exact failing review fields before [ApiController] automatic 400.
internal sealed class LogInvalidReviewModelStateAttribute : ActionFilterAttribute
{
    public LogInvalidReviewModelStateAttribute()
    {
        Order = -3000;
    }

    public override void OnActionExecuting(ActionExecutingContext context)
    {
        if (context.ModelState.IsValid) return;

        var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<ReviewController>>();
        var errors = context.ModelState
            .Where(kvp => kvp.Value is { Errors.Count: > 0 })
            .SelectMany(kvp => kvp.Value!.Errors.Select(e =>
            {
                var detail = string.IsNullOrWhiteSpace(e.ErrorMessage)
                    ? e.Exception?.Message ?? "invalid"
                    : e.ErrorMessage;
                return $"{kvp.Key}: {detail}";
            }));

        logger.LogWarning("Review request rejected by model validation: {Errors}", string.Join("; ", errors));
    }
}
