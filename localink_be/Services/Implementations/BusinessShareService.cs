using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using localink_be.Data;
using localink_be.Extensions;
using localink_be.Models.DTOs;
using localink_be.Models.Entities;
using localink_be.Models.Enums;
using localink_be.Options;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class BusinessShareService : IBusinessShareService
    {
        private static readonly char[] TokenAlphabet =
            "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray();

        private readonly AppDbContext _db;
        private readonly BusinessShareOptions _options;

        public BusinessShareService(AppDbContext db, IOptions<BusinessShareOptions> options)
        {
            _db = db;
            _options = options.Value;
        }

        public async Task<(bool Success, string Message, BusinessShareCreatedDto? Data)> CreateSingleBusinessShareAsync(
            long userId,
            long businessId,
            CancellationToken cancellationToken = default)
        {
            if (!await IsBusinessShareableAsync(businessId, cancellationToken))
                return (false, "This business cannot be shared right now.", null);

            var token = await GenerateUniqueTokenAsync(cancellationToken);
            var share = new BusinessShare
            {
                PublicToken = token,
                ShareKind = "business",
                CreatedByUserId = userId,
                Title = null,
                Note = null,
                CreatedAt = DateTime.UtcNow,
                Items = new List<BusinessShareItem>
                {
                    new() { BusinessId = businessId, Position = 0 }
                }
            };

            _db.BusinessShares.Add(share);
            await _db.SaveChangesAsync(cancellationToken);

            return (true, "Share created", BuildCreatedDto(share));
        }

        public async Task<(bool Success, string Message, BusinessShareCreatedDto? Data)> CreateFavoritesShareAsync(
            long userId,
            CreateFavoritesShareRequest request,
            CancellationToken cancellationToken = default)
        {
            List<long> orderedIds;

            if (request.ShareAllFavorites)
            {
                orderedIds = await _db.Favorites
                    .AsNoTracking()
                    .Where(f => f.UserId == userId)
                    .OrderBy(f => f.CreatedAt)
                    .ThenBy(f => f.Id)
                    .Select(f => f.BusinessId)
                    .ToListAsync(cancellationToken);
            }
            else
            {
                orderedIds = (request.BusinessIds ?? new List<long>())
                    .Where(id => id > 0)
                    .Distinct()
                    .ToList();
            }

            if (orderedIds.Count == 0)
                return (false, "Select at least one favorite business to share.", null);

            var maxItems = Math.Clamp(_options.MaxItemsPerShare, 1, 500);
            if (orderedIds.Count > maxItems)
                return (false, $"You can share up to {maxItems} businesses at once.", null);

            var favoriteIds = await _db.Favorites
                .AsNoTracking()
                .Where(f => f.UserId == userId)
                .Select(f => f.BusinessId)
                .ToListAsync(cancellationToken);
            var favoriteSet = favoriteIds.ToHashSet();

            if (!request.ShareAllFavorites)
            {
                if (orderedIds.Any(id => !favoriteSet.Contains(id)))
                    return (false, "You can only share businesses from your favorites.", null);
            }
            else
            {
                orderedIds = orderedIds.Where(favoriteSet.Contains).ToList();
                if (orderedIds.Count == 0)
                    return (false, "You don't have any favorite businesses to share.", null);
            }

            var shareableIds = new List<long>();
            foreach (var id in orderedIds)
            {
                if (await IsBusinessShareableAsync(id, cancellationToken))
                    shareableIds.Add(id);
            }

            if (shareableIds.Count == 0)
                return (false, "None of the selected businesses can be shared right now.", null);

            var title = string.IsNullOrWhiteSpace(request.Title)
                ? null
                : request.Title.Trim();
            var note = string.IsNullOrWhiteSpace(request.Note)
                ? null
                : request.Note.Trim();

            var token = await GenerateUniqueTokenAsync(cancellationToken);
            var share = new BusinessShare
            {
                PublicToken = token,
                ShareKind = "collection",
                CreatedByUserId = userId,
                Title = title,
                Note = note,
                CreatedAt = DateTime.UtcNow,
                Items = shareableIds.Select((id, index) => new BusinessShareItem
                {
                    BusinessId = id,
                    Position = index
                }).ToList()
            };

            _db.BusinessShares.Add(share);
            await _db.SaveChangesAsync(cancellationToken);

            return (true, "Share created", BuildCreatedDto(share));
        }

        public async Task<BusinessShareViewDto?> GetShareByPublicTokenAsync(
            string publicToken,
            CancellationToken cancellationToken = default)
        {
            var normalized = NormalizeToken(publicToken);
            if (normalized == null) return null;

            var share = await _db.BusinessShares
                .AsNoTracking()
                .Include(s => s.CreatedByUser)
                .Include(s => s.Items)
                .FirstOrDefaultAsync(s => s.PublicToken == normalized, cancellationToken);

            if (share == null) return null;

            var orderedItems = share.Items.OrderBy(i => i.Position).ToList();
            var businessIds = orderedItems.Select(i => i.BusinessId).ToList();

            var businesses = await LoadBusinessDtosAsync(businessIds, cancellationToken);
            var businessMap = businesses.ToDictionary(b => b.Id);

            var items = new List<SharedBusinessItemDto>();
            foreach (var item in orderedItems)
            {
                if (businessMap.TryGetValue(item.BusinessId, out var dto))
                {
                    items.Add(new SharedBusinessItemDto
                    {
                        BusinessId = item.BusinessId,
                        Position = item.Position,
                        IsAvailable = true,
                        Business = dto
                    });
                }
                else
                {
                    items.Add(new SharedBusinessItemDto
                    {
                        BusinessId = item.BusinessId,
                        Position = item.Position,
                        IsAvailable = false,
                        UnavailableReason = "This business is no longer available."
                    });
                }
            }

            var displayTitle = !string.IsNullOrWhiteSpace(share.Title)
                ? share.Title!.Trim()
                : "Businesses shared with you";

            return new BusinessShareViewDto
            {
                PublicToken = share.PublicToken,
                ShareKind = share.ShareKind,
                Title = displayTitle,
                Note = share.Note,
                SharedByDisplayName = share.CreatedByUser?.FullName,
                CreatedAt = share.CreatedAt,
                Items = items
            };
        }

        private BusinessShareCreatedDto BuildCreatedDto(BusinessShare share)
        {
            var baseUrl = (_options.ShareBaseUrl ?? "https://vocalforsanatan.com/share")
                .Trim()
                .TrimEnd('/');
            var pathSegment = share.ShareKind == "business" ? "business" : "collection";
            return new BusinessShareCreatedDto
            {
                PublicToken = share.PublicToken,
                ShareKind = share.ShareKind,
                ShareUrl = $"{baseUrl}/{pathSegment}/{share.PublicToken}",
                ItemCount = share.Items?.Count ?? 0
            };
        }

        private async Task<bool> IsBusinessShareableAsync(long businessId, CancellationToken cancellationToken)
        {
            var exists = await _db.Businesses.AsNoTracking()
                .AnyAsync(b => b.BusinessId == businessId, cancellationToken);
            if (!exists) return false;

            var status = await _db.AdminDashboards.AsNoTracking()
                .Where(a => a.BusinessId == businessId)
                .Select(a => (BusinessStatus?)a.Status)
                .FirstOrDefaultAsync(cancellationToken);

            if (status != BusinessStatus.Approved && status != BusinessStatus.Active)
                return false;

            var business = await _db.Businesses.AsNoTracking()
                .FirstAsync(b => b.BusinessId == businessId, cancellationToken);

            return !business.IsActivelyTemporarilyClosed();
        }

        private async Task<List<BusinessDto>> LoadBusinessDtosAsync(
            List<long> businessIds,
            CancellationToken cancellationToken)
        {
            if (businessIds.Count == 0) return new List<BusinessDto>();

            return await _db.Businesses
                .AsNoTracking()
                .Where(b => businessIds.Contains(b.BusinessId))
                .Where(b => _db.AdminDashboards.Any(a =>
                    a.BusinessId == b.BusinessId &&
                    (a.Status == BusinessStatus.Approved || a.Status == BusinessStatus.Active)))
                .WhereVisibleToConsumers()
                .Select(b => new BusinessDto
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
                    Website = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Website).FirstOrDefault(),
                    City = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.City).FirstOrDefault(),
                    State = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.State).FirstOrDefault(),
                    Country = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Country).FirstOrDefault(),
                    StreetAddress = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.StreetAddress).FirstOrDefault(),
                    Pincode = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Pincode).FirstOrDefault(),
                    Latitude = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Latitude).FirstOrDefault(),
                    Longitude = _db.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Longitude).FirstOrDefault(),
                    PrimaryImage = _db.BusinessPhotos.Where(p => p.BusinessId == b.BusinessId).OrderByDescending(p => p.IsPrimary).Select(p => p.ImageUrl).FirstOrDefault(),
                    Photos = _db.BusinessPhotos.Where(p => p.BusinessId == b.BusinessId).OrderByDescending(p => p.IsPrimary).Select(p => p.ImageUrl).ToList(),
                    AverageRating = _db.BusinessReviews.Where(r => r.BusinessId == b.BusinessId && !r.IsFlagged).Select(r => (double?)r.Rating).Average() ?? 0.0,
                    TotalReviews = _db.BusinessReviews.Count(r => r.BusinessId == b.BusinessId && !r.IsFlagged),
                    IsTemporarilyClosed = b.TemporaryClosureStatus == "Approved" && b.TemporaryClosureReopenDate.HasValue && b.TemporaryClosureReopenDate.Value > DateTime.UtcNow,
                    TemporaryClosureReason = b.TemporaryClosureReason,
                    TemporaryClosureStatus = b.TemporaryClosureStatus,
                    TemporaryClosureDays = b.TemporaryClosureDays,
                    TemporaryClosureReopenDate = b.TemporaryClosureReopenDate
                })
                .ToListAsync(cancellationToken);
        }

        private async Task<string> GenerateUniqueTokenAsync(CancellationToken cancellationToken)
        {
            var length = Math.Clamp(_options.TokenLength, 8, 32);
            var maxAttempts = Math.Clamp(_options.TokenGenerationMaxAttempts, 3, 32);

            for (var attempt = 0; attempt < maxAttempts; attempt++)
            {
                var candidate = CreateCandidateToken(length);
                var taken = await _db.BusinessShares.AsNoTracking()
                    .AnyAsync(s => s.PublicToken == candidate, cancellationToken);
                if (!taken) return candidate;
            }

            throw new InvalidOperationException("Unable to allocate a unique share token.");
        }

        private static string CreateCandidateToken(int length)
        {
            Span<byte> bytes = stackalloc byte[length];
            RandomNumberGenerator.Fill(bytes);
            var chars = new char[length];
            for (var i = 0; i < length; i++)
                chars[i] = TokenAlphabet[bytes[i] % TokenAlphabet.Length];
            return new string(chars);
        }

        public static string? NormalizeToken(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;
            var s = raw.Trim().ToUpperInvariant();
            if (s.Length is < 8 or > 32) return null;
            return s.All(c => TokenAlphabet.Contains(c)) ? s : null;
        }
    }
}
