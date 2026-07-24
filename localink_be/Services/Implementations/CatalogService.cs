using localink_be.Data;
using localink_be.Data.Models;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace localink_be.Services.Implementations
{
    public class CatalogService : ICatalogService
    {
        private readonly AppDbContext _context;
        private readonly IPhotoService _photoService;

        public CatalogService(AppDbContext context, IPhotoService photoService)
        {
            _context = context;
            _photoService = photoService;
        }

        public async Task<List<CatalogDto>> GetBusinessCatalogsAsync(long businessId)
        {
            var catalogs = await _context.Catalogs
                .Include(c => c.Items)
                .Where(c => c.BusinessId == businessId)
                .ToListAsync();

            return catalogs.Select(MapToDto).ToList();
        }

        public async Task<CatalogDto> CreateCatalogAsync(long businessId, CreateCatalogDto dto)
        {
            var catalog = new Catalog
            {
                BusinessId = businessId,
                Title = dto.Title,
                Description = dto.Description
            };

            _context.Catalogs.Add(catalog);
            await _context.SaveChangesAsync();

            return MapToDto(catalog);
        }

        public async Task<CatalogDto> UpdateCatalogAsync(int catalogId, CreateCatalogDto dto)
        {
            var catalog = await _context.Catalogs.Include(c => c.Items).FirstOrDefaultAsync(c => c.Id == catalogId);
            if (catalog == null) throw new KeyNotFoundException("Catalog not found");

            catalog.Title = dto.Title;
            catalog.Description = dto.Description;

            await _context.SaveChangesAsync();
            return MapToDto(catalog);
        }

        public async Task DeleteCatalogAsync(int catalogId)
        {
            var catalog = await _context.Catalogs.FindAsync(catalogId);
            if (catalog == null) return;

            _context.Catalogs.Remove(catalog);
            await _context.SaveChangesAsync();
        }

        public async Task<CatalogItemDto> AddCatalogItemAsync(int catalogId, CreateCatalogItemDto dto, IFormFile? image)
        {
            string? imageUrl = null;
            if (image != null)
            {
                var resultUrl = await _photoService.UploadImageAsync(image, "catalogs");
                imageUrl = resultUrl;
            }

            var item = new CatalogItem
            {
                CatalogId = catalogId,
                Name = dto.Name,
                Description = dto.Description,
                Price = dto.Price,
                IsAvailable = dto.IsAvailable,
                ImageUrl = imageUrl
            };

            _context.CatalogItems.Add(item);
            await _context.SaveChangesAsync();

            return MapItemToDto(item);
        }

        public async Task<CatalogItemDto> UpdateCatalogItemAsync(int itemId, CreateCatalogItemDto dto, IFormFile? image)
        {
            var item = await _context.CatalogItems.FindAsync(itemId);
            if (item == null) throw new KeyNotFoundException("Item not found");

            if (image != null)
            {
                var resultUrl = await _photoService.UploadImageAsync(image, "catalogs");
                item.ImageUrl = resultUrl;
            }

            item.Name = dto.Name;
            item.Description = dto.Description;
            item.Price = dto.Price;
            item.IsAvailable = dto.IsAvailable;

            await _context.SaveChangesAsync();
            return MapItemToDto(item);
        }

        public async Task DeleteCatalogItemAsync(int itemId)
        {
            var item = await _context.CatalogItems.FindAsync(itemId);
            if (item == null) return;

            _context.CatalogItems.Remove(item);
            await _context.SaveChangesAsync();
        }

        private CatalogDto MapToDto(Catalog catalog)
        {
            return new CatalogDto
            {
                Id = catalog.Id,
                BusinessId = catalog.BusinessId,
                Title = catalog.Title,
                Description = catalog.Description,
                Items = catalog.Items.Select(MapItemToDto).ToList()
            };
        }

        private CatalogItemDto MapItemToDto(CatalogItem item)
        {
            return new CatalogItemDto
            {
                Id = item.Id,
                CatalogId = item.CatalogId,
                Name = item.Name,
                Description = item.Description,
                Price = item.Price,
                ImageUrl = item.ImageUrl,
                IsAvailable = item.IsAvailable
            };
        }
    }
}
