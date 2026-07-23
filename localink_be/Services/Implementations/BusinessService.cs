using Microsoft.EntityFrameworkCore;
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
    public class BusinessService : IBusinessService
    {
        private readonly AppDbContext _db;
        private readonly IContactService _contactService;
        private readonly IHoursService _hoursService;
        private readonly IPhotoService _photoService;
        private readonly IEmailService _emailService;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly IServiceProvider _serviceProvider;
    public BusinessService(AppDbContext db,
                           IContactService contactService,
                           IHoursService hoursService,
                           IPhotoService photoService,
                           IEmailService emailService,
                           IHubContext<NotificationHub> hubContext,
                           IServiceProvider serviceProvider)
    {
        _db = db ?? throw new ArgumentNullException(nameof(db));
        _contactService = contactService;
        _hoursService = hoursService;
        _photoService = photoService;
        _emailService = emailService;
        _hubContext = hubContext;
        _serviceProvider = serviceProvider;
    }

 
    public async Task<List<object>> GetAllBusinessesAsync()
    {
        return await _db.Businesses
            .Where(b => _db.AdminDashboards.Any(a => a.BusinessId == b.BusinessId && a.Status == BusinessStatus.Approved))
            .Select(b => new
            {
                b.BusinessId,
                b.BusinessName,
                b.Description,
                b.CategoryId,
                b.SubcategoryId,
                CategoryName = b.Category.CategoryName,
                SubcategoryName = b.Subcategory.SubcategoryName,
                PrimaryImage = _db.BusinessPhotos
                    .Where(p => p.BusinessId == b.BusinessId && p.IsPrimary)
                    .Select(p => p.ImageUrl)
                    .FirstOrDefault(),
                AverageRating = _db.BusinessReviews
                    .Where(r => r.BusinessId == b.BusinessId)
                    .Select(r => (double?)r.Rating)
                    .Average() ?? 0,
                TotalReviews = _db.BusinessReviews
                    .Count(r => r.BusinessId == b.BusinessId),
                StreetAddress = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.StreetAddress)
                    .FirstOrDefault(),
                City = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.City)
                    .FirstOrDefault(),
                State = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.State)
                    .FirstOrDefault(),
                Country = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.Country)
                    .FirstOrDefault(),
                Pincode = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.Pincode)
                    .FirstOrDefault(),
                Latitude = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.Latitude)
                    .FirstOrDefault(),
                Longitude = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.Longitude)
                    .FirstOrDefault(),
                b.CreatedAt
            })
            .ToListAsync<object>();
    }

    public async Task<Business> CreateBusinessAsync(Business dto)
    {
        _db.Businesses.Add(dto);
        await _db.SaveChangesAsync();
        return dto;
    }

    public async Task<object?> GetBusinessByIdAsync(long id)
    {
        var business = await _db.Businesses
            .Where(b => b.BusinessId == id)
            .Select(b => new
            {
                b.BusinessId,
                b.BusinessName,
                b.Description,
                b.CategoryId,
                b.SubcategoryId,
                Contact = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => new
                    {
                        c.PhoneCode,
                        c.PhoneNumber,
                        c.Email,
                        c.Website,
                        c.StreetAddress,
                        c.City,
                        c.State,
                        c.Country,
                        c.Pincode,
                        c.Latitude,
                        c.Longitude
                    })
                    .FirstOrDefault(),
                Hours = _db.BusinessHours
                    .Where(h => h.BusinessId == b.BusinessId)
                    .Select(h => new
                    {
                        h.DayOfWeek,
                        h.Mode,
                        Slots = _db.BusinessHourSlots
                            .Where(s => s.BusinessHourId == h.BusinessHourId)
                            .Select(s => new { s.OpenTime, s.CloseTime })
                            .ToList()
                    })
                    .ToList(),
                Photos = _db.BusinessPhotos
                    .Where(p => p.BusinessId == b.BusinessId)
                    .Select(p => new
                    {
                        p.ImageUrl,
                        p.IsPrimary
                    })
                    .ToList()
            })
            .FirstOrDefaultAsync();

        return business;
    }


    public async Task<bool> UpdateBusinessFullAsync(long id, UpdateBusinessDto dto, long currentUserId, bool isAdmin)
    {
        var business = await _db.Businesses.FindAsync(id);
        if (business == null) return false;

        if (!isAdmin && business.UserId != currentUserId)
        {
            throw new UnauthorizedAccessException("You do not own this business.");
        }

        business.BusinessName = dto.BusinessName;
        business.Description = dto.Description;
        business.CategoryId = dto.CategoryId;
        business.SubcategoryId = dto.SubcategoryId;

        var contact = await _db.BusinessContacts
            .FirstOrDefaultAsync(c => c.BusinessId == id);

        if (contact != null)
        {
            var normalizedPhone = dto.PhoneNumber?.Trim();
            var normalizedPhoneCode = dto.PhoneCode?.Trim();

            if (dto.Latitude.HasValue || dto.Longitude.HasValue)
            {
                var lat = dto.Latitude;
                var lng = dto.Longitude;
                if (!lat.HasValue || !lng.HasValue)
                {
                    throw new ArgumentException("Both latitude and longitude must be provided together.");
                }
                if (lat < -90.0 || lat > 90.0 || double.IsNaN(lat.Value) || double.IsInfinity(lat.Value))
                {
                    throw new ArgumentException("Latitude must be a valid number between -90 and 90.");
                }
                if (lng < -180.0 || lng > 180.0 || double.IsNaN(lng.Value) || double.IsInfinity(lng.Value))
                {
                    throw new ArgumentException("Longitude must be a valid number between -180 and 180.");
                }
                if (lat == 0.0 && lng == 0.0)
                {
                    throw new ArgumentException("Coordinates (0,0) are invalid.");
                }
            }

            contact.PhoneCode = dto.PhoneCode;
            contact.PhoneNumber = dto.PhoneNumber;
            contact.Email = dto.Email;
            contact.City = dto.City;
            contact.State = dto.State;
            contact.Country = dto.Country;
            contact.Pincode = dto.Pincode;
            contact.StreetAddress = dto.StreetAddress;
            contact.Latitude = dto.Latitude;
            contact.Longitude = dto.Longitude;
        }

        // Save new photo if provided
        if (!string.IsNullOrWhiteSpace(dto.Photo))
        {
            if (dto.Photo.Length > 5_000_000)
                throw new Exception("Image too large");

            await _photoService.SavePhotoAsync(dto.Photo, id);
        }

        // Update hours
        if (dto.Hours != null && dto.Hours.Any())
        {
            await _hoursService.CreateOrReplaceBusinessHoursAsync(id, new BusinessHoursDto { Days = dto.Hours });
        }

        await _db.SaveChangesAsync();
        try
        {
            await _hubContext.Clients.All.SendAsync("ReceiveNotification", $"BusinessUpdated:{id}");
        }
        catch { /* fail silently */ }
        return true;
    }
    public async Task<bool> DeleteBusinessAsync(long id, long currentUserId, bool isAdmin)
    {
        var business = await _db.Businesses.FindAsync(id);
        if (business == null) return false;

        if (!isAdmin && business.UserId != currentUserId)
        {
            throw new UnauthorizedAccessException("You do not own this business.");
        }

        _db.Businesses.Remove(business);
        await _db.SaveChangesAsync();
        try
        {
            await _hubContext.Clients.All.SendAsync("ReceiveNotification", $"BusinessDeleted:{id}");
        }
        catch { /* fail silently */ }
        return true;
    }

    public async Task<long> RegisterBusinessAsync(RegisterBusinessDto dto, long userId)
    {
        // 1. Duplication Prevention: Check if business name is already registered by this user
        var normalizedName = dto.BusinessName?.Trim().ToLower();
        var exists = await _db.Businesses.AnyAsync(b => b.UserId == userId && b.BusinessName.ToLower() == normalizedName);
        if (exists)
        {
            throw new ArgumentException("A business with this name has already been registered under your account.");
        }

        var normalizedPhone = dto.PhoneNumber?.Trim();
        var normalizedPhoneCode = dto.PhoneCode?.Trim();

        var strategy = _db.Database.CreateExecutionStrategy();
        
        return await strategy.ExecuteAsync(async () =>
        {
            using var transaction = await _db.Database.BeginTransactionAsync();

            try
            {
                var category = await _db.Categories.FindAsync(dto.CategoryId);
                if (category == null)
                    throw new Exception("Invalid category");

                var subcategory = await _db.Subcategories
                    .FirstOrDefaultAsync(s => s.SubcategoryId == dto.SubcategoryId &&
                                            s.CategoryId == dto.CategoryId);

                if (subcategory == null)
                    throw new Exception("Invalid subcategory");
                var business = new Business
                {
                    BusinessName = dto.BusinessName,
                    Description = dto.Description,
                    CategoryId = dto.CategoryId,
                    SubcategoryId = dto.SubcategoryId,
                    UserId = userId, 
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _db.Businesses.Add(business);
                await _db.SaveChangesAsync();

                // CONTACT
                await _contactService.AddContactAsync(dto, business.BusinessId);

                // HOURS
                await _hoursService.AddHoursAsync(dto.Hours, business.BusinessId);

                // PHOTO
                if (!string.IsNullOrWhiteSpace(dto.Photo))
                {
                    if (dto.Photo.Length > 5_000_000)
                        throw new Exception("Image too large");

                    await _photoService.SavePhotoAsync(dto.Photo, business.BusinessId);
                }

                // ADMIN DASHBOARD ENTRY
                await _db.AdminDashboards.AddAsync(new AdminDashboard
                {
                    BusinessId = business.BusinessId,
                    Status = BusinessStatus.Pending,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                });

                await _db.SaveChangesAsync();

                await transaction.CommitAsync();

                // 2. Heavy operations (SMTP Emails & SignalR broadcasts) are executed on a background thread
                // to prevent client-side HTTP timeouts (like DioTimeoutException).
                _ = Task.Run(async () =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var scopedDb = scope.ServiceProvider.GetRequiredService<localink_be.Data.AppDbContext>();
                        var scopedEmail = scope.ServiceProvider.GetRequiredService<IEmailService>();

                        var contact = await scopedDb.BusinessContacts
                            .Where(c => c.BusinessId == business.BusinessId)
                            .FirstOrDefaultAsync();

                        var categoryName = await scopedDb.Categories
                            .Where(c => c.CategoryId == business.CategoryId)
                            .Select(c => c.CategoryName)
                            .FirstOrDefaultAsync();

                        var adminEmail = "sankeerth559@gmail.com";

                        await scopedEmail.SendNewBusinessNotificationToAdminAsync(
                            adminEmail,
                            business.BusinessName,
                            categoryName ?? "",
                            business.Description ?? "",
                            (contact?.City ?? "") + ", " + (contact?.State ?? ""),
                            (contact?.PhoneCode ?? "") + (contact?.PhoneNumber ?? ""),
                            contact?.Email ?? ""
                        );

                        var user = await scopedDb.Users.FindAsync(userId);
                        if (user != null)
                        {
                            await scopedEmail.SendBusinessRegistrationEmailToOwnerAsync(
                                user.Email,
                                user.FullName,
                                business.BusinessName,
                                categoryName ?? ""
                            );
                        }

                        await _hubContext.Clients.Group("admin").SendAsync("ReceiveNotification", $"New Business Alert: '{business.BusinessName}' has been registered and is pending approval.");
                    }
                    catch (Exception ex)
                    {
                        // Fail silently to prevent crashing the response
                    }
                });

                return business.BusinessId;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        });
    }
        // GET PREVIEW
        public async Task<object?> GetBusinessPreviewAsync(long businessId)
        {
            var business = await _db.Businesses.FirstOrDefaultAsync(b => b.BusinessId == businessId);
            if (business == null) return null;

            var category = await _db.Categories
                .Where(c => c.CategoryId == business.CategoryId)
                .Select(c => c.CategoryName)
                .FirstOrDefaultAsync();

            var subcategory = await _db.Subcategories
                .Where(s => s.SubcategoryId == business.SubcategoryId)
                .Select(s => s.SubcategoryName)
                .FirstOrDefaultAsync();

            var contact = await _db.BusinessContacts
                .Where(c => c.BusinessId == businessId)
                .FirstOrDefaultAsync();

            var hours = await _db.BusinessHours
                .Where(h => h.BusinessId == businessId)
                .Select(h => new
                {
                    h.DayOfWeek,
                    h.Mode,
                    Slots = _db.BusinessHourSlots
                        .Where(s => s.BusinessHourId == h.BusinessHourId)
                        .Select(s => new { s.OpenTime, s.CloseTime })
                        .ToList()
                }).ToListAsync();

            var photos = await _db.BusinessPhotos
                .Where(p => p.BusinessId == businessId)
                .OrderByDescending(p => p.IsPrimary)
                .Select(p => new { p.PhotoId, p.ImageUrl, p.IsPrimary })
                .ToListAsync();

            return new
            {
                business.BusinessName,
                business.Description,
                Category = category,
                Subcategory = subcategory,
                Contact = contact,
                Hours = hours,
                Photos = photos
            };
        }

        public async Task<Business?> UpdateBusinessAsync(long id, Business updated)
        {
            var existing = await _db.Businesses.FindAsync(id);
            if (existing == null) return null;

            existing.BusinessName = updated.BusinessName;
            existing.Description = updated.Description;
            existing.CategoryId = updated.CategoryId;
            existing.SubcategoryId = updated.SubcategoryId;
            existing.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            return existing;
        }

        public async Task<List<BusinessDto>> GetBusinessesByUserAsync(long userId)
        {
            if (userId <= 0)
                throw new ArgumentException("UserId must be greater than 0");

            return await _db.Businesses
                .Where(b => b.UserId == userId)
                .Include(b => b.Category)
                .Include(b => b.Subcategory)
                .Select(b => new BusinessDto
                {
                    Id = b.BusinessId,
                    Name = b.BusinessName,
                    Description = b.Description,
                    CategoryName = b.Category != null ? b.Category.CategoryName : "",
                    SubcategoryName = b.Subcategory != null ? b.Subcategory.SubcategoryName : "",
                    SubcategoryId = b.SubcategoryId,
                    CategoryId = b.CategoryId,
                    PhoneCode = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.PhoneCode)
                        .FirstOrDefault(),

                    PhoneNumber = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.PhoneNumber)
                        .FirstOrDefault(),

                    Email = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Email)
                        .FirstOrDefault(),

                    City = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.City)
                        .FirstOrDefault(),

                    State = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.State)
                        .FirstOrDefault(),

                    Country = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Country)
                        .FirstOrDefault(),

                    Pincode = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Pincode)
                        .FirstOrDefault(),

                    StreetAddress = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.StreetAddress)
                        .FirstOrDefault(),

                    Latitude = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Latitude)
                        .FirstOrDefault(),
                    Longitude = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Longitude)
                        .FirstOrDefault(),
                    Status = _db.AdminDashboards
                        .Where(a => a.BusinessId == b.BusinessId)
                        .Select(a => a.Status.ToString())
                        .FirstOrDefault(),
                    PrimaryImage = _db.BusinessPhotos
                        .Where(p => p.BusinessId == b.BusinessId)
                        .OrderByDescending(p => p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .FirstOrDefault(),
                    Photos = _db.BusinessPhotos
                        .Where(p => p.BusinessId == b.BusinessId)
                        .OrderByDescending(p => p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .ToList(),
                    IsTemporarilyClosed = b.TemporaryClosureStatus == "Approved" && b.TemporaryClosureReopenDate.HasValue && b.TemporaryClosureReopenDate.Value > DateTime.UtcNow,
                    TemporaryClosureReason = b.TemporaryClosureReason,
                    TemporaryClosureStatus = b.TemporaryClosureStatus,
                    TemporaryClosureDays = b.TemporaryClosureDays,
                    TemporaryClosureReopenDate = b.TemporaryClosureReopenDate
                })
                .OrderBy(b => b.Name)
                .ToListAsync();
        }

        public async Task<List<BusinessDto>> GetBySubcategoryAsync(int subcategoryId)
        {
            return await _db.Businesses
                .Where(b => b.SubcategoryId == subcategoryId && _db.AdminDashboards.Any(a => a.BusinessId == b.BusinessId && a.Status == BusinessStatus.Approved))
                .Select(b => new BusinessDto
                {
                    Id = b.BusinessId,
                    Name = b.BusinessName,
                    Description = b.Description,
                    CategoryName = b.Category != null ? b.Category.CategoryName : "",
                    SubcategoryName = b.Subcategory != null ? b.Subcategory.SubcategoryName : "",
                    SubcategoryId = b.SubcategoryId,
                    CategoryId = b.CategoryId,
                    PhoneNumber = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => (c.PhoneCode ?? "") + " " + (c.PhoneNumber ?? ""))
                        .FirstOrDefault(),
                    Email = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Email)
                        .FirstOrDefault(),
                    City = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.City)
                        .FirstOrDefault(),
                    State = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.State)
                        .FirstOrDefault(),
                    Country = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Country)
                        .FirstOrDefault(),
                    PrimaryImage = _db.BusinessPhotos
                        .Where(p => p.BusinessId == b.BusinessId)
                        .OrderByDescending(p => p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .FirstOrDefault(),
                    Photos = _db.BusinessPhotos
                        .Where(p => p.BusinessId == b.BusinessId)
                        .OrderByDescending(p => p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .ToList(),
                    StreetAddress = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.StreetAddress)
                        .FirstOrDefault()
                })
                .OrderBy(b => b.Name)
                .ToListAsync();
        }

        public async Task<BusinessDto?> GetByIdAsync(long id)
        {
            return await _db.Businesses
                .Where(b => b.BusinessId == id)
                .Select(b => new BusinessDto
                {
                    Id = b.BusinessId,
                    Name = b.BusinessName,
                    Description = b.Description,
                    CategoryName = b.Category != null ? b.Category.CategoryName : "",
                    SubcategoryName = b.Subcategory != null ? b.Subcategory.SubcategoryName : "",
                    CategoryId = b.CategoryId,
                    SubcategoryId = b.SubcategoryId,
                    PhoneNumber = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.PhoneNumber)
                        .FirstOrDefault(),
                    PhoneCode = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.PhoneCode)
                        .FirstOrDefault(),
                    Email = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Email)
                        .FirstOrDefault(),
                    City = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.City)
                        .FirstOrDefault(),
                    State = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.State)
                        .FirstOrDefault(),
                    Country = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Country)
                        .FirstOrDefault(),
                    Pincode = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Pincode)
                        .FirstOrDefault(),
                    StreetAddress = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.StreetAddress)
                        .FirstOrDefault(),
                    Latitude = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Latitude)
                        .FirstOrDefault(),
                    Longitude = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Longitude)
                        .FirstOrDefault(),
                    Status = _db.AdminDashboards
                        .Where(a => a.BusinessId == b.BusinessId)
                        .Select(a => a.Status.ToString())
                        .FirstOrDefault(),
                    PrimaryImage = _db.BusinessPhotos
                        .Where(p => p.BusinessId == b.BusinessId && p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .FirstOrDefault(),
                    Photos = _db.BusinessPhotos
                        .Where(p => p.BusinessId == b.BusinessId)
                        .OrderByDescending(p => p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .ToList(),
                    Hours = _db.BusinessHours
                        .Where(h => h.BusinessId == b.BusinessId)
                        .Select(h => new DayHoursDto
                        {
                            DayOfWeek = h.DayOfWeek,
                            Mode = h.Mode,
                            Slots = _db.BusinessHourSlots
                                .Where(s => s.BusinessHourId == h.BusinessHourId)
                                .Select(s => new TimeSlotDto
                                {
                                    OpenTime = s.OpenTime,
                                    CloseTime = s.CloseTime
                                })
                                .ToList()
                        })
                        .ToList(),
                    IsTemporarilyClosed = b.TemporaryClosureStatus == "Approved" && b.TemporaryClosureReopenDate.HasValue && b.TemporaryClosureReopenDate.Value > DateTime.UtcNow,
                    TemporaryClosureReason = b.TemporaryClosureReason,
                    TemporaryClosureStatus = b.TemporaryClosureStatus,
                    TemporaryClosureDays = b.TemporaryClosureDays,
                    TemporaryClosureReopenDate = b.TemporaryClosureReopenDate
                })
                .FirstOrDefaultAsync();
        }

        public async Task<List<BusinessDto>> SearchBusinessesAsync(string query, double? userLat = null, double? userLng = null, string? sortBy = "distance", string? userPincode = "", string? userCity = "")
        {
            var businessesQuery = _db.Businesses
                .AsNoTracking()
                .Where(b => _db.AdminDashboards.Any(a => a.BusinessId == b.BusinessId && a.Status == BusinessStatus.Approved));

            if (!string.IsNullOrWhiteSpace(query))
            {
                query = query.Trim().ToLower();
                businessesQuery = businessesQuery.Where(b =>
                     EF.Functions.Like(b.BusinessName, $"%{query}%") ||
                    (b.Description != null && EF.Functions.Like(b.Description, $"%{query}%")) ||
                    (b.Category != null && EF.Functions.Like(b.Category.CategoryName, $"%{query}%")) ||
                    (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, $"%{query}%"))
                );
            }

            // Project to DTO
            var projectedQuery = businessesQuery.Select(b => new BusinessDto
            {
                Id = b.BusinessId,
                Name = b.BusinessName,
                Description = b.Description,
                CategoryName = b.Category != null ? b.Category.CategoryName : "",
                SubcategoryName = b.Subcategory != null ? b.Subcategory.SubcategoryName : "",
                SubcategoryId = b.SubcategoryId,
                CategoryId = b.CategoryId,
                PhoneNumber = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.PhoneNumber)
                    .FirstOrDefault(),
                PhoneCode = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.PhoneCode)
                    .FirstOrDefault(),
                Email = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.Email)
                    .FirstOrDefault(),
                City = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.City)
                    .FirstOrDefault(),
                State = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.State)
                    .FirstOrDefault(),
                Country = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.Country)
                    .FirstOrDefault(),
                StreetAddress = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.StreetAddress)
                    .FirstOrDefault(),
                Pincode = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.Pincode)
                    .FirstOrDefault(),
                Latitude = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.Latitude)
                    .FirstOrDefault(),
                Longitude = _db.BusinessContacts
                    .Where(c => c.BusinessId == b.BusinessId)
                    .Select(c => c.Longitude)
                    .FirstOrDefault(),
                Status = _db.AdminDashboards
                    .Where(a => a.BusinessId == b.BusinessId)
                    .Select(a => a.Status.ToString())
                    .FirstOrDefault(),
                PrimaryImage = _db.BusinessPhotos
                    .Where(p => p.BusinessId == b.BusinessId)
                    .OrderByDescending(p => p.IsPrimary)
                    .Select(p => p.ImageUrl)
                    .FirstOrDefault(),
                Photos = _db.BusinessPhotos
                    .Where(p => p.BusinessId == b.BusinessId)
                    .OrderByDescending(p => p.IsPrimary)
                    .Select(p => p.ImageUrl)
                    .ToList(),
                AverageRating = _db.BusinessReviews
                    .Where(r => r.BusinessId == b.BusinessId)
                    .Select(r => (double?)r.Rating)
                    .Average() ?? 0.0,
                TotalReviews = _db.BusinessReviews
                    .Count(r => r.BusinessId == b.BusinessId),
                IsTemporarilyClosed = b.TemporaryClosureStatus == "Approved" && b.TemporaryClosureReopenDate.HasValue && b.TemporaryClosureReopenDate.Value > DateTime.UtcNow,
                TemporaryClosureReason = b.TemporaryClosureReason,
                TemporaryClosureStatus = b.TemporaryClosureStatus,
                TemporaryClosureDays = b.TemporaryClosureDays,
                TemporaryClosureReopenDate = b.TemporaryClosureReopenDate,
                // Calculate distance using Haversine formula approximation with Cosine squared fix
                Distance = userLat.HasValue && userLng.HasValue
                    ? _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId && c.Latitude.HasValue && c.Longitude.HasValue)
                        .Select(c => (double?)(111.0 * Math.Sqrt(
                            Math.Pow(c.Latitude.Value - userLat.Value, 2) +
                            Math.Pow(c.Longitude.Value - userLng.Value, 2) * Math.Pow(Math.Cos(userLat.Value * Math.PI / 180.0), 2)
                        )))
                        .FirstOrDefault()
                    : null
            });

            var allMatches = await projectedQuery.ToListAsync();

            // Perform sorting on the matched results list in memory
            var normalizedSort = sortBy?.ToLower().Trim() ?? "distance";
            IEnumerable<BusinessDto> sortedResults;

            if (normalizedSort == "alphabetical")
            {
                sortedResults = allMatches.OrderBy(b => b.Name);
            }
            else if (normalizedSort == "reviews")
            {
                // Descending order of review ratings
                sortedResults = allMatches.OrderByDescending(b => b.AverageRating)
                                          .ThenByDescending(b => b.TotalReviews)
                                          .ThenBy(b => b.Name);
            }
            else // Default: Sort by distance
            {
                var cleanPincode = userPincode?.Trim();
                var cleanCity = userCity?.Trim().ToLower();

                if (userLat.HasValue && userLng.HasValue)
                {
                    // Sort purely by distance (closest first). If distance is null, fall back to pincode/city match, then name
                    sortedResults = allMatches.OrderBy(b => b.Distance ?? double.MaxValue)
                                              .ThenBy(b => (!string.IsNullOrEmpty(cleanPincode) && b.Pincode != null && b.Pincode.Trim() == cleanPincode) ? 0 : 1)
                                              .ThenBy(b => (!string.IsNullOrEmpty(cleanCity) && b.City != null && b.City.Trim().ToLower() == cleanCity) ? 0 : 1)
                                              .ThenBy(b => b.Name);
                }
                else
                {
                    // Fallback to pincode match first, then city match, then name
                    if (!string.IsNullOrEmpty(cleanPincode) || !string.IsNullOrEmpty(cleanCity))
                    {
                        sortedResults = allMatches.OrderBy(b => (!string.IsNullOrEmpty(cleanPincode) && b.Pincode != null && b.Pincode.Trim() == cleanPincode) ? 0 : 1)
                                                  .ThenBy(b => (!string.IsNullOrEmpty(cleanCity) && b.City != null && b.City.Trim().ToLower() == cleanCity) ? 0 : 1)
                                                  .ThenBy(b => b.Name);
                    }
                    else
                    {
                        sortedResults = allMatches.OrderBy(b => b.Name);
                    }
                }
            }

            return sortedResults.Take(25).ToList();
        }

        public async Task<VoiceSearchResponse> VoiceSearchAsync(VoiceSearchRequest request, double? userLat = null, double? userLng = null)
        {
            try
            {
                // Validate request
                if (request == null)
                {
                    return new VoiceSearchResponse
                    {
                        Success = false,
                        Message = "Invalid request",
                        Results = new List<BusinessDto>()
                    };
                }

                var query = request.Query?.Trim() ?? string.Empty;

                // Start with base query of APPROVED businesses
                var businessesQuery = _db.Businesses
                    .AsNoTracking()
                    .Where(b => _db.AdminDashboards.Any(a => a.BusinessId == b.BusinessId && a.Status == BusinessStatus.Approved));

                // Apply text search if query provided
                if (!string.IsNullOrWhiteSpace(query))
                {
                    businessesQuery = businessesQuery.Where(b =>
                        EF.Functions.Like(b.BusinessName, $"%{query}%") ||
                        (b.Description != null && EF.Functions.Like(b.Description, $"%{query}%")) ||
                        (b.Category != null && EF.Functions.Like(b.Category.CategoryName, $"%{query}%")) ||
                        (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, $"%{query}%"))
                    );
                }

                // Apply category filter if provided
                if (!string.IsNullOrWhiteSpace(request.Category))
                {
                    var categoryLower = request.Category.ToLower().Trim();
                    if (categoryLower == "restaurant")
                    {
                        businessesQuery = businessesQuery.Where(b => (b.Category != null && EF.Functions.Like(b.Category.CategoryName, "%Restaurants & Cafes%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%restaurant%")));
                    }
                    else if (categoryLower == "hospital" || categoryLower == "fitness")
                    {
                        businessesQuery = businessesQuery.Where(b => (b.Category != null && EF.Functions.Like(b.Category.CategoryName, "%Health & Wellness%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%hospital%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%fitness%")));
                    }
                    else if (categoryLower == "school")
                    {
                        businessesQuery = businessesQuery.Where(b => (b.Category != null && EF.Functions.Like(b.Category.CategoryName, "%Education%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%school%")));
                    }
                    else if (categoryLower == "shop" || categoryLower == "electronics")
                    {
                        businessesQuery = businessesQuery.Where(b => (b.Category != null && EF.Functions.Like(b.Category.CategoryName, "%Shopping & Retail%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%shop%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%electronics%")));
                    }
                    else if (categoryLower == "bank")
                    {
                        businessesQuery = businessesQuery.Where(b => (b.Category != null && EF.Functions.Like(b.Category.CategoryName, "%Finance%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%bank%")));
                    }
                    else if (categoryLower == "repair" || categoryLower == "home services")
                    {
                        businessesQuery = businessesQuery.Where(b => (b.Category != null && EF.Functions.Like(b.Category.CategoryName, "%Services%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%repair%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%service%")));
                    }
                    else if (categoryLower == "beauty")
                    {
                        businessesQuery = businessesQuery.Where(b => (b.Category != null && EF.Functions.Like(b.Category.CategoryName, "%Beauty & Wellness%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%beauty%")));
                    }
                    else if (categoryLower == "automotive")
                    {
                        businessesQuery = businessesQuery.Where(b => (b.Category != null && EF.Functions.Like(b.Category.CategoryName, "%Automotive%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%automotive%")));
                    }
                    else if (categoryLower == "travel")
                    {
                        businessesQuery = businessesQuery.Where(b => (b.Category != null && EF.Functions.Like(b.Category.CategoryName, "%Travel%")) || (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, "%travel%")));
                    }
                    else
                    {
                        businessesQuery = businessesQuery.Where(b =>
                            (b.Category != null && EF.Functions.Like(b.Category.CategoryName, $"%{categoryLower}%")) ||
                            (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, $"%{categoryLower}%"))
                        );
                    }
                }

                // Apply "open now" filter if requested
                if (request.OpenNow)
                {
                    var currentDay = (int)DateTime.UtcNow.DayOfWeek;
                    var currentTime = DateTime.UtcNow.TimeOfDay;

                    businessesQuery = businessesQuery.Where(b =>
                        _db.BusinessHours.Any(h =>
                            h.BusinessId == b.BusinessId &&
                            h.DayOfWeek == currentDay.ToString() &&
                            h.Mode == "open" &&
                            _db.BusinessHourSlots.Any(s =>
                                s.BusinessHourId == h.BusinessHourId &&
                                s.OpenTime <= currentTime &&
                                s.CloseTime >= currentTime
                            )
                        )
                    );
                }
                // Apply radius filter if user location provided
                if (userLat.HasValue && userLng.HasValue && request.Radius > 0)
                {
                    // If the radius is 5 (which is the default client-side value),
                    // expand it to 100km to prevent filtering out businesses in the same city.
                    var searchRadius = request.Radius == 5 ? 100 : request.Radius;
                    var radiusDegrees = searchRadius / 111.0; // Rough conversion km to degrees

                    var localQuery = businessesQuery.Where(b =>
                        _db.BusinessContacts.Any(c =>
                            c.BusinessId == b.BusinessId &&
                            c.Latitude.HasValue &&
                            c.Longitude.HasValue &&
                            Math.Abs(c.Latitude.Value - userLat.Value) <= radiusDegrees &&
                            Math.Abs(c.Longitude.Value - userLng.Value) <= radiusDegrees
                        )
                    );

                    if (await localQuery.AnyAsync())
                    {
                        businessesQuery = localQuery;
                    }
                }

                // Project to DTO with distance calculation
                var projectedQuery = businessesQuery.Select(b => new BusinessDto
                {
                    Id = b.BusinessId,
                    Name = b.BusinessName,
                    Description = b.Description,
                    CategoryName = b.Category != null ? b.Category.CategoryName : "",
                    SubcategoryName = b.Subcategory != null ? b.Subcategory.SubcategoryName : "",
                    SubcategoryId = b.SubcategoryId,
                    CategoryId = b.CategoryId,
                    PhoneNumber = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.PhoneNumber)
                        .FirstOrDefault(),
                    Email = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Email)
                        .FirstOrDefault(),
                    City = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.City)
                        .FirstOrDefault(),
                    State = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.State)
                        .FirstOrDefault(),
                    Latitude = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Latitude)
                        .FirstOrDefault(),
                    Longitude = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.Longitude)
                        .FirstOrDefault(),
                    Status = _db.AdminDashboards
                        .Where(a => a.BusinessId == b.BusinessId)
                        .Select(a => a.Status.ToString())
                        .FirstOrDefault(),
                    PrimaryImage = _db.BusinessPhotos
                        .Where(p => p.BusinessId == b.BusinessId)
                        .OrderByDescending(p => p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .FirstOrDefault(),
                    Photos = _db.BusinessPhotos
                        .Where(p => p.BusinessId == b.BusinessId)
                        .OrderByDescending(p => p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .ToList(),
                    // Calculate distance using Haversine formula approximation
                    Distance = userLat.HasValue && userLng.HasValue
                        ? _db.BusinessContacts
                            .Where(c => c.BusinessId == b.BusinessId && c.Latitude.HasValue && c.Longitude.HasValue)
                            .Select(c => (double?)(111.0 * Math.Sqrt(
                                Math.Pow(c.Latitude.Value - userLat.Value, 2) +
                                Math.Pow(c.Longitude.Value - userLng.Value, 2) * Math.Cos(userLat.Value * Math.PI / 180.0)
                            )))
                            .FirstOrDefault()
                        : null
                });

                // Sort by distance if location provided, otherwise by name
                var results = await (userLat.HasValue && userLng.HasValue
                    ? projectedQuery.OrderBy(b => b.Distance ?? double.MaxValue)
                    : projectedQuery.OrderBy(b => b.Name))
                    .Take(20)
                    .ToListAsync();

                // FALLBACK: If 0 results found, and we had filters, relax them
                if (results.Count == 0 && (!string.IsNullOrEmpty(query) || !string.IsNullOrEmpty(request.Category)))
                {
                    var fallbackQuery = _db.Businesses
                        .AsNoTracking()
                        .Where(b => _db.AdminDashboards.Any(a => a.BusinessId == b.BusinessId && a.Status == BusinessStatus.Approved));

                    var keywords = new List<string>();
                    if (!string.IsNullOrWhiteSpace(query)) keywords.Add(query.ToLower().Trim());
                    if (!string.IsNullOrWhiteSpace(request.Category)) keywords.Add(request.Category.ToLower().Trim());

                    if (keywords.Count > 0)
                    {
                        var kw1 = keywords[0];
                        if (keywords.Count == 1)
                        {
                            fallbackQuery = fallbackQuery.Where(b =>
                                EF.Functions.Like(b.BusinessName.ToLower(), $"%{kw1}%") ||
                                (b.Description != null && EF.Functions.Like(b.Description.ToLower(), $"%{kw1}%")) ||
                                (b.Category != null && EF.Functions.Like(b.Category.CategoryName.ToLower(), $"%{kw1}%")) ||
                                (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName.ToLower(), $"%{kw1}%"))
                            );
                        }
                        else
                        {
                            var kw2 = keywords[1];
                            fallbackQuery = fallbackQuery.Where(b =>
                                EF.Functions.Like(b.BusinessName.ToLower(), $"%{kw1}%") ||
                                (b.Description != null && EF.Functions.Like(b.Description.ToLower(), $"%{kw1}%")) ||
                                (b.Category != null && EF.Functions.Like(b.Category.CategoryName.ToLower(), $"%{kw1}%")) ||
                                (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName.ToLower(), $"%{kw1}%")) ||
                                EF.Functions.Like(b.BusinessName.ToLower(), $"%{kw2}%") ||
                                (b.Description != null && EF.Functions.Like(b.Description.ToLower(), $"%{kw2}%")) ||
                                (b.Category != null && EF.Functions.Like(b.Category.CategoryName.ToLower(), $"%{kw2}%")) ||
                                (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName.ToLower(), $"%{kw2}%"))
                            );
                        }
                    }

                    var projectedFallback = fallbackQuery.Select(b => new BusinessDto
                    {
                        Id = b.BusinessId,
                        Name = b.BusinessName,
                        Description = b.Description,
                        CategoryName = b.Category != null ? b.Category.CategoryName : "",
                        SubcategoryName = b.Subcategory != null ? b.Subcategory.SubcategoryName : "",
                        SubcategoryId = b.SubcategoryId,
                        CategoryId = b.CategoryId,
                        PhoneNumber = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.PhoneNumber).FirstOrDefault(),
                        PhoneCode = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.PhoneCode).FirstOrDefault(),
                        Email = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Email).FirstOrDefault(),
                        City = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.City).FirstOrDefault(),
                        State = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.State).FirstOrDefault(),
                        Latitude = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Latitude).FirstOrDefault(),
                        Longitude = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Longitude).FirstOrDefault(),
                        Status = _db.AdminDashboards.Where(a => a.BusinessId == b.BusinessId).Select(a => a.Status.ToString()).FirstOrDefault(),
                        PrimaryImage = _db.BusinessPhotos.Where(p => p.BusinessId == b.BusinessId).OrderByDescending(p => p.IsPrimary).Select(p => p.ImageUrl).FirstOrDefault(),
                        Photos = _db.BusinessPhotos.Where(p => p.BusinessId == b.BusinessId).OrderByDescending(p => p.IsPrimary).Select(p => p.ImageUrl).ToList(),
                        Distance = userLat.HasValue && userLng.HasValue
                            ? _db.BusinessContacts
                                .Where(c => c.BusinessId == b.BusinessId && c.Latitude.HasValue && c.Longitude.HasValue)
                                .Select(c => (double?)(111.0 * Math.Sqrt(
                                    Math.Pow(c.Latitude.Value - userLat.Value, 2) +
                                    Math.Pow(c.Longitude.Value - userLng.Value, 2) * Math.Cos(userLat.Value * Math.PI / 180.0)
                                )))
                                .FirstOrDefault()
                            : null
                    });

                    results = await (userLat.HasValue && userLng.HasValue
                        ? projectedFallback.OrderBy(b => b.Distance ?? double.MaxValue)
                        : projectedFallback.OrderBy(b => b.Name))
                        .Take(20)
                        .ToListAsync();
                }

                return new VoiceSearchResponse
                {
                    Success = true,
                    Message = $"Found {results.Count} businesses",
                    Results = results,
                    TotalCount = results.Count,
                    AppliedFilters = new VoiceSearchFilters
                    {
                        Query = query,
                        OpenNow = request.OpenNow,
                        RadiusKm = request.Radius,
                        Category = request.Category
                    }
                };
            }
            catch (Exception ex)
            {
                // Log the error
                return new VoiceSearchResponse
                {
                    Success = false,
                    Message = "An error occurred while processing your voice search",
                    Results = new List<BusinessDto>(),
                    TotalCount = 0
                };
            }
        }
    }
}