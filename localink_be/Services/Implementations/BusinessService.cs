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
    public BusinessService(AppDbContext db,
                           IContactService contactService,
                           IHoursService hoursService,
                           IPhotoService photoService,
                           IEmailService emailService,
                           IHubContext<NotificationHub> hubContext)
    {
        _db = db ?? throw new ArgumentNullException(nameof(db));
        _contactService = contactService;
        _hoursService = hoursService;
        _photoService = photoService;
        _emailService = emailService;
        _hubContext = hubContext;
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


    public async Task<bool> UpdateBusinessFullAsync(long id, UpdateBusinessDto dto)
    {
        var business = await _db.Businesses.FindAsync(id);
        if (business == null) return false;

        business.BusinessName = dto.BusinessName;
        business.Description = dto.Description;
        business.CategoryId = dto.CategoryId;
        business.SubcategoryId = dto.SubcategoryId;

        var contact = await _db.BusinessContacts
            .FirstOrDefaultAsync(c => c.BusinessId == id);

        if (contact != null)
        {
            contact.PhoneCode = dto.PhoneCode;
            contact.PhoneNumber = dto.PhoneNumber;
            contact.Email = dto.Email;
            contact.City = dto.City;
            contact.State = dto.State;
            contact.Country = dto.Country;
            contact.Pincode = dto.Pincode;
            contact.StreetAddress = dto.StreetAddress;
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
        return true;
    }
    public async Task<bool> DeleteBusinessAsync(long id)
    {
        var business = await _db.Businesses.FindAsync(id);
        if (business == null) return false;

        _db.Businesses.Remove(business);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<long> RegisterBusinessAsync(RegisterBusinessDto dto, long userId)
    {
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
                // GET BUSINESS DETAILS FOR EMAIL
                var contact = await _db.BusinessContacts
                    .Where(c => c.BusinessId == business.BusinessId)
                    .FirstOrDefaultAsync();

                var categoryName = await _db.Categories
                    .Where(c => c.CategoryId == business.CategoryId)
                    .Select(c => c.CategoryName)
                    .FirstOrDefaultAsync();

                // ADMIN EMAIL FROM CONFIG
                var adminEmail = "aadarshreddydepa@gmail.com"; // move to config later

                await _emailService.SendNewBusinessNotificationToAdminAsync(
                    adminEmail,
                    business.BusinessName,
                    categoryName ?? "",
                    business.Description ?? "",
                    contact?.City + ", " + contact?.State,
                    contact?.PhoneCode + contact?.PhoneNumber,
                    contact?.Email
                );

                // Send welcome/pending email to business owner
                var user = await _db.Users.FindAsync(userId);
                if (user != null)
                {
                    await _emailService.SendBusinessRegistrationEmailToOwnerAsync(
                        user.Email,
                        user.FullName,
                        business.BusinessName,
                        categoryName ?? ""
                    );
                }

                // Notify all active Admins of new pending business listing
                await _hubContext.Clients.Group("admin").SendAsync("ReceiveNotification", $"New Business Alert: '{business.BusinessName}' has been registered and is pending approval.");
 
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
                        .Where(p => p.BusinessId == b.BusinessId && p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .FirstOrDefault()
                })
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
                        .Where(p => p.BusinessId == b.BusinessId && p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .FirstOrDefault(),
                    StreetAddress = _db.BusinessContacts
                        .Where(c => c.BusinessId == b.BusinessId)
                        .Select(c => c.StreetAddress)
                        .FirstOrDefault()
                })
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
                    SubcategoryName = b.Subcategory != null ? b.Subcategory.SubcategoryName : ""
                })
                .FirstOrDefaultAsync();
        }

        public async Task<List<BusinessDto>> SearchBusinessesAsync(string query, double? userLat = null, double? userLng = null)
        {
            if (string.IsNullOrWhiteSpace(query))
                return new List<BusinessDto>();

            query = query.Trim();

            var businessesQuery = _db.Businesses
                .AsNoTracking()
                .Where(b =>
                    _db.AdminDashboards.Any(a => a.BusinessId == b.BusinessId && a.Status == BusinessStatus.Approved) &&
                    (
                         EF.Functions.Like(b.BusinessName, $"%{query}%") ||
                        (b.Description != null && EF.Functions.Like(b.Description, $"%{query}%")) ||
                        (b.Category != null && EF.Functions.Like(b.Category.CategoryName, $"%{query}%")) ||
                        (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, $"%{query}%"))
                    )
                );

            // Project to DTO with distance calculation
            var projectedQuery = businessesQuery.Select(b => new BusinessDto
            {
                Id = b.BusinessId,
                Name = b.BusinessName,
                Description = b.Description,
                CategoryName = b.Category != null ? b.Category.CategoryName : "",
                SubcategoryName = b.Subcategory != null ? b.Subcategory.SubcategoryName : "",
                SubcategoryId = b.SubcategoryId,
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
                .Take(10)
                .ToListAsync();

            return results;
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

                // Start with base query
                var businessesQuery = _db.Businesses
                    .AsNoTracking()
                    .AsQueryable();

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
                    var categoryLower = request.Category.ToLower();
                    businessesQuery = businessesQuery.Where(b =>
                        (b.Category != null && EF.Functions.Like(b.Category.CategoryName, $"%{categoryLower}%")) ||
                        (b.Subcategory != null && EF.Functions.Like(b.Subcategory.SubcategoryName, $"%{categoryLower}%"))
                    );
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
                    // Note: This is a simplified distance calculation
                    // For production, consider using SQL Server geography types
                    var radiusDegrees = request.Radius / 111.0; // Rough conversion km to degrees

                    businessesQuery = businessesQuery.Where(b =>
                        _db.BusinessContacts.Any(c =>
                            c.BusinessId == b.BusinessId &&
                            c.Latitude.HasValue &&
                            c.Longitude.HasValue &&
                            Math.Abs(c.Latitude.Value - userLat.Value) <= radiusDegrees &&
                            Math.Abs(c.Longitude.Value - userLng.Value) <= radiusDegrees
                        )
                    );
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
                        .Where(p => p.BusinessId == b.BusinessId && p.IsPrimary)
                        .Select(p => p.ImageUrl)
                        .FirstOrDefault(),
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