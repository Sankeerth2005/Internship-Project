using Microsoft.EntityFrameworkCore;
using localink_be.Data;
using localink_be.Extensions;
using localink_be.Models.DTOs;
using localink_be.Models.Entities;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class FavoritesService : IFavoritesService
    {
        private readonly AppDbContext _context;

        public FavoritesService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<string> AddFavoriteAsync(FavoriteDto dto)
        {
            // Validate that the user exists
            var userExists = await _context.Users.AnyAsync(u => u.UserId == dto.UserId);
            if (!userExists)
                return "User not found";

            // Validate that the business exists
            var businessExists = await _context.Businesses.AnyAsync(b => b.BusinessId == dto.BusinessId);
            if (!businessExists)
                return "Business not found";

            var exists = await _context.Favorites
                .AnyAsync(f => f.UserId == dto.UserId && f.BusinessId == dto.BusinessId);

            if (exists)
                return "Already added";

            var favorite = new Favorite
            {
                UserId = dto.UserId,
                BusinessId = dto.BusinessId,
                CreatedAt = DateTime.Now
            };

            _context.Favorites.Add(favorite);
            await _context.SaveChangesAsync();

            return "Added to favorites";
        }

        public async Task<string> RemoveFavoriteAsync(long userId, long businessId)
        {
            var fav = await _context.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.BusinessId == businessId);

            if (fav == null)
                return "Not found";

            _context.Favorites.Remove(fav);
            await _context.SaveChangesAsync();

            return "Removed from favorites";
        }

        public async Task<List<long>> GetUserFavoritesAsync(long userId)
        {
            return await _context.Favorites
                .Where(f => f.UserId == userId)
                .Select(f => f.BusinessId)
                .ToListAsync();
        }

        public async Task<List<BusinessDto>> GetUserFavoriteBusinessesAsync(long userId)
        {
            var ids = await GetUserFavoritesAsync(userId);
            if (ids.Count == 0) return new List<BusinessDto>();

            return await _context.Businesses
                .AsNoTracking()
                .Where(b => ids.Contains(b.BusinessId))
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
                    PhoneNumber = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.PhoneNumber).FirstOrDefault(),
                    PhoneCode = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.PhoneCode).FirstOrDefault(),
                    Email = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Email).FirstOrDefault(),
                    Website = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Website).FirstOrDefault(),
                    City = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.City).FirstOrDefault(),
                    State = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.State).FirstOrDefault(),
                    Country = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Country).FirstOrDefault(),
                    StreetAddress = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.StreetAddress).FirstOrDefault(),
                    Pincode = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Pincode).FirstOrDefault(),
                    Latitude = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Latitude).FirstOrDefault(),
                    Longitude = _context.BusinessContacts.Where(c => c.BusinessId == b.BusinessId).Select(c => c.Longitude).FirstOrDefault(),
                    PrimaryImage = _context.BusinessPhotos.Where(p => p.BusinessId == b.BusinessId).OrderByDescending(p => p.IsPrimary).Select(p => p.ImageUrl).FirstOrDefault(),
                    Photos = _context.BusinessPhotos.Where(p => p.BusinessId == b.BusinessId).OrderByDescending(p => p.IsPrimary).Select(p => p.ImageUrl).ToList(),
                    AverageRating = _context.BusinessReviews.Where(r => r.BusinessId == b.BusinessId).Select(r => (double?)r.Rating).Average() ?? 0.0,
                    TotalReviews = _context.BusinessReviews.Count(r => r.BusinessId == b.BusinessId),
                    IsTemporarilyClosed = b.TemporaryClosureStatus == "Approved" && b.TemporaryClosureReopenDate.HasValue && b.TemporaryClosureReopenDate.Value > DateTime.UtcNow,
                    TemporaryClosureReason = b.TemporaryClosureReason,
                    TemporaryClosureStatus = b.TemporaryClosureStatus,
                    TemporaryClosureDays = b.TemporaryClosureDays,
                    TemporaryClosureReopenDate = b.TemporaryClosureReopenDate
                })
                .ToListAsync();
        }
    }
}
