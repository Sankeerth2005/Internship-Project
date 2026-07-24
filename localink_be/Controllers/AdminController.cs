using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using localink_be.Models.Entities;

[Authorize(Roles = "admin")]
[ApiController]
[Route("api/v1/admin")]
public class AdminController : ControllerBase
{
    private readonly IAdminService _service;

    public AdminController(IAdminService service)
    {
        _service = service;
    }

    [HttpGet("businesses")]
    public async Task<IActionResult> GetAll()
    {
        var data = await _service.GetAllAsync();
        return Ok(data);
    }

    [HttpPut("business/{id}/status")]
    public async Task<IActionResult> UpdateStatus(long id, UpdateStatusDto dto)
    {
        var adminId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(adminId)) return Unauthorized();
        await _service.UpdateStatusAsync(id, dto, long.Parse(adminId));
        return Ok(new { message = "Status updated" });
    }

    [HttpGet("export")]
    public async Task<IActionResult> Export([FromQuery] string status)
    {
        var file = await _service.ExportAsync(status);
        return File(file, 
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"{status}-businesses.xlsx");
    }

    [HttpPut("business/{id}/temporary-closure/approve")]
    public async Task<IActionResult> ApproveTemporaryClosure(
        long id,
        [FromServices] localink_be.Data.AppDbContext db,
        [FromServices] Microsoft.AspNetCore.SignalR.IHubContext<localink_be.Hubs.NotificationHub> hubContext)
    {
        var business = await db.Businesses.FindAsync(id);
        if (business == null) return NotFound(new { message = "Business not found" });

        if (business.TemporaryClosureStatus != "Pending")
            return BadRequest(new { message = "No pending closure request found" });

        business.TemporaryClosureStatus = "Approved";
        business.TemporaryClosureReopenDate = DateTime.UtcNow.AddDays(business.TemporaryClosureDays ?? 1);

        await db.SaveChangesAsync();

        // Notify owner
        await hubContext.Clients.Group($"client_{business.UserId}").SendAsync("ReceiveNotification", $"Your business '{business.BusinessName}' temporary closure request has been APPROVED by the admin.");

        return Ok(new { success = true, message = "Temporary closure approved" });
    }

    [HttpPut("business/{id}/temporary-closure/reject")]
    public async Task<IActionResult> RejectTemporaryClosure(
        long id,
        [FromServices] localink_be.Data.AppDbContext db,
        [FromServices] Microsoft.AspNetCore.SignalR.IHubContext<localink_be.Hubs.NotificationHub> hubContext)
    {
        var business = await db.Businesses.FindAsync(id);
        if (business == null) return NotFound(new { message = "Business not found" });

        if (business.TemporaryClosureStatus != "Pending")
            return BadRequest(new { message = "No pending closure request found" });

        business.TemporaryClosureReason = null;
        business.TemporaryClosureDays = null;
        business.TemporaryClosureStatus = "Rejected";

        await db.SaveChangesAsync();

        // Notify owner
        await hubContext.Clients.Group($"client_{business.UserId}").SendAsync("ReceiveNotification", $"Your business '{business.BusinessName}' temporary closure request has been REJECTED by the admin.");

        return Ok(new { success = true, message = "Temporary closure rejected" });
    }

    [HttpDelete("business/{id}/delete")]
    public async Task<IActionResult> ApprovePermanentDeletion(
        long id,
        [FromServices] localink_be.Data.AppDbContext db,
        [FromServices] Microsoft.AspNetCore.SignalR.IHubContext<localink_be.Hubs.NotificationHub> hubContext)
    {
        var adminId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(adminId)) return Unauthorized();

        var business = await db.Businesses.FindAsync(id);
        if (business == null) return NotFound(new { message = "Business not found" });

        var adminDash = await db.AdminDashboards.FirstOrDefaultAsync(a => a.BusinessId == id);
        if (adminDash == null || adminDash.Status != BusinessStatus.DeletionRequested)
            return BadRequest(new { message = "No pending deletion request found for this business" });

        try
        {
            await hubContext.Clients.Group($"client_{business.UserId}").SendAsync("ReceiveNotification", $"Your business '{business.BusinessName}' has been permanently deleted by the admin.");
        }
        catch { /* Suppress notifications errors */ }

        db.Businesses.Remove(business);
        await db.SaveChangesAsync();

        return Ok(new { success = true, message = "Business permanently deleted from database" });
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetAllUsers()
    {
        var data = await _service.GetUsersAsync();
        return Ok(data);
    }

    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var data = await _service.GetStatsAsync();
        return Ok(data);
    }

    [HttpGet("flagged-reviews")]
    public async Task<IActionResult> GetFlaggedReviews([FromServices] localink_be.Data.AppDbContext db)
    {
        var reviews = await db.BusinessReviews
            .Include(r => r.User)
            .Where(r => r.IsFlagged)
            .Select(r => new
            {
                r.ReviewId,
                r.BusinessId,
                r.Rating,
                r.Comment,
                r.CreatedAt,
                r.ModerationReason,
                UserName = r.User.FullName
            })
            .ToListAsync();
        return Ok(new { success = true, data = reviews });
    }

    [HttpDelete("reviews/{reviewId}")]
    public async Task<IActionResult> DeleteReview(long reviewId, [FromServices] localink_be.Data.AppDbContext db)
    {
        var review = await db.BusinessReviews.FindAsync(reviewId);
        if (review == null) return NotFound(new { message = "Review not found" });

        db.BusinessReviews.Remove(review);
        await db.SaveChangesAsync();

        return Ok(new { success = true, message = "Review deleted" });
    }

    [HttpPut("reviews/{reviewId}/unflag")]
    public async Task<IActionResult> UnflagReview(long reviewId, [FromServices] localink_be.Data.AppDbContext db)
    {
        var review = await db.BusinessReviews.FindAsync(reviewId);
        if (review == null) return NotFound(new { message = "Review not found" });

        review.IsFlagged = false;
        review.ModerationReason = null;
        await db.SaveChangesAsync();

        return Ok(new { success = true, message = "Review unflagged" });
    }

    [HttpPost("bulk-import")]
    public async Task<IActionResult> BulkImport(
        IFormFile file,
        [FromServices] localink_be.Services.Interfaces.IBulkImportService bulkImportService)
    {
        var result = await bulkImportService.ProcessBulkImportAsync(file);
        return Ok(new { success = true, data = result });
    }
}