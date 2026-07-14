using Microsoft.EntityFrameworkCore;
using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;
using Microsoft.AspNetCore.SignalR;
using localink_be.Hubs;

namespace localink_be.Services.Implementations
{
public class AdminService : IAdminService
{
    private readonly AppDbContext _db;
    private readonly IEmailService _emailService;
    private readonly IHubContext<NotificationHub> _hubContext;

    public AdminService(AppDbContext db, IEmailService emailService, IHubContext<NotificationHub> hubContext)
    {
        _db = db;
        _emailService = emailService;
        _hubContext = hubContext;
    }

    public async Task<List<AdminBusinessDto>> GetAllAsync()
    {
        return await _db.AdminDashboards
            .Include(a => a.Business)
                .ThenInclude(b => b.Category)
            .Include(a => a.Business.Subcategory)
            .Select(a => new AdminBusinessDto
            {
                Id = a.BusinessId,
                Name = a.Business.BusinessName,
                Category = a.Business.Category.CategoryName,
                Description = a.Business.Description,
                Phone = _db.BusinessContacts
                    .Where(c => c.BusinessId == a.BusinessId)
                    .Select(c => c.PhoneCode+c.PhoneNumber)
                    .FirstOrDefault(),

                Email = _db.BusinessContacts
                    .Where(c => c.BusinessId == a.BusinessId)
                    .Select(c => c.Email)
                    .FirstOrDefault(),

                Address = _db.BusinessContacts
                    .Where(c => c.BusinessId == a.BusinessId)
                    .Select(c => c.City + ", " + c.State) 
                    .FirstOrDefault(),

                Status = a.Status.ToString(),
                RejectionComment = a.RejectionReason,
                IsTemporaryClosurePending = a.Business.TemporaryClosureStatus == "Pending",
                TemporaryClosureReason = a.Business.TemporaryClosureReason,
                TemporaryClosureDays = a.Business.TemporaryClosureDays,
                OwnerName = _db.Users
                    .Where(u => u.UserId == a.Business.UserId)
                    .Select(u => u.FullName)
                    .FirstOrDefault()
            })
            .OrderBy(b => b.Name)
            .ToListAsync();
    }
    public async Task UpdateStatusAsync(long businessId, UpdateStatusDto dto, long adminId)
    {
        var record = await _db.AdminDashboards
            .FirstOrDefaultAsync(a => a.BusinessId == businessId);

        if (record == null)
            throw new Exception("Business not found in admin dashboard");

        record.Status = dto.Status;
        record.RejectionReason = dto.RejectionReason;
        record.ActionBy = adminId;
        record.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        var business = await _db.Businesses
            .FirstOrDefaultAsync(b => b.BusinessId == businessId);

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.UserId == business.UserId);

        var categoryName = await _db.Categories
            .Where(c => c.CategoryId == business.CategoryId)
            .Select(c => c.CategoryName)
            .FirstOrDefaultAsync();

        await _emailService.SendBusinessStatusUpdateToUserAsync(
            user.Email,
            user.FullName,
            business.BusinessName,
            categoryName ?? "",
            record.Status.ToString(),
            record.RejectionReason
        );

        // Real-time status update notification to the business owner
        await _hubContext.Clients.Group($"client_{business.UserId}").SendAsync("ReceiveNotification", $"Your business '{business.BusinessName}' status has been updated to {record.Status}.");
    }

    public async Task<byte[]> ExportAsync(string status)
    {
        bool exportAll = status.Equals("All", StringComparison.OrdinalIgnoreCase);
        BusinessStatus? parsedStatus = null;

        if (!exportAll)
        {
            if (!Enum.TryParse<BusinessStatus>(status, true, out var result))
            {
                throw new Exception("Invalid status");
            }
            parsedStatus = result;
        }

        var isRejectedStatus = parsedStatus == BusinessStatus.Rejected;

        var query = _db.AdminDashboards
            .Include(a => a.Business)
                .ThenInclude(b => b.Category)
            .Include(a => a.Business.Subcategory)
            .AsQueryable();

        if (!exportAll && parsedStatus.HasValue)
        {
            query = query.Where(a => a.Status == parsedStatus.Value);
        }

        var data = await query
            .Select(a => new
            {
                BusinessName = a.Business.BusinessName,

                OwnerName = _db.Users
                    .Where(u => u.UserId == a.Business.UserId)
                    .Select(u => u.FullName)
                    .FirstOrDefault(),

                RegisteredDate = a.Business.CreatedAt,

                Category = a.Business.Category.CategoryName,
                Subcategory = a.Business.Subcategory.SubcategoryName,
                Description = a.Business.Description,

                Email = _db.BusinessContacts
                    .Where(c => c.BusinessId == a.BusinessId)
                    .Select(c => c.Email)
                    .FirstOrDefault(),

                Phone = _db.BusinessContacts
                    .Where(c => c.BusinessId == a.BusinessId)
                    .Select(c => c.PhoneCode+c.PhoneNumber)
                    .FirstOrDefault(),

                Address = _db.BusinessContacts
                    .Where(c => c.BusinessId == a.BusinessId)
                    .Select(c => c.StreetAddress)
                    .FirstOrDefault(),

                Status = a.Status.ToString(),

                RejectionReason = (exportAll || isRejectedStatus) ? a.RejectionReason : null
            })
            .ToListAsync();

        using var package = new OfficeOpenXml.ExcelPackage();
        var sheet = package.Workbook.Worksheets.Add("Businesses");

        // Remove RejectionReason column if not rejected status and not exporting all
        if (!exportAll && !isRejectedStatus && data.Count > 0)
        {
            var dataWithoutReason = data.Select(d => new
            {
                d.BusinessName,
                d.OwnerName,
                d.RegisteredDate,
                d.Category,
                d.Subcategory,
                d.Description,
                d.Email,
                d.Phone,
                d.Address,
                d.Status
            }).ToList();
            sheet.Cells.LoadFromCollection(dataWithoutReason, true);
        }
        else
        {
            sheet.Cells.LoadFromCollection(data, true);
        }

        int totalColumns = sheet.Dimension.Columns;
        int totalRows = sheet.Dimension.Rows;

        
        using (var header = sheet.Cells[1, 1, 1, totalColumns])
        {
            header.Style.Font.Bold = true;
            header.Style.Font.Color.SetColor(System.Drawing.Color.White);
            header.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
            header.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.FromArgb(44, 62, 80));
        }

        sheet.Column(3).Style.Numberformat.Format = "dd-MMM-yyyy";

        using (var range = sheet.Cells[1, 1, totalRows, totalColumns])
        {
            range.Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
            range.Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
            range.Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
            range.Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
        }

        sheet.Cells[1, 1, totalRows, totalColumns].AutoFilter = true;

        sheet.View.FreezePanes(2, 1);

        sheet.Cells[sheet.Dimension.Address].AutoFitColumns();

        return package.GetAsByteArray();
    }

    public async Task<List<AdminUserDto>> GetUsersAsync()
    {
        return await _db.Users
            .OrderBy(u => u.FullName)
            .Select(u => new AdminUserDto
            {
                UserId = u.UserId,
                FullName = u.FullName,
                Email = u.Email,
                AccountType = u.AccountType,
                PhoneNumber = u.PhoneNumber
            })
            .ToListAsync();
    }

    public async Task<AdminStatsDto> GetStatsAsync()
    {
        var totalUsers = await _db.Users.LongCountAsync();
        var totalBusinesses = await _db.Businesses.LongCountAsync();
        var approvedBusinesses = await _db.AdminDashboards.LongCountAsync(a => a.Status == BusinessStatus.Approved);
        var pendingBusinesses = await _db.AdminDashboards.LongCountAsync(a => a.Status == BusinessStatus.Pending);
        var totalViews = await _db.BusinessMetrics.SumAsync(m => (long?)m.Views) ?? 0;
        var totalClicks = await _db.BusinessMetrics.SumAsync(m => (long?)m.ContactClicks) ?? 0;
        var totalReviews = await _db.BusinessReviews.LongCountAsync();
        var averageRating = totalReviews > 0
            ? await _db.BusinessReviews.AverageAsync(r => (double?)r.Rating) ?? 0.0
            : 0.0;

        return new AdminStatsDto
        {
            TotalUsers = totalUsers,
            TotalBusinesses = totalBusinesses,
            ApprovedBusinesses = approvedBusinesses,
            PendingBusinesses = pendingBusinesses,
            TotalViews = totalViews,
            TotalClicks = totalClicks,
            TotalReviews = totalReviews,
            AverageRating = Math.Round(averageRating, 1)
        };
    }
}
}