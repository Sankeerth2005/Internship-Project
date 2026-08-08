using localink_be.Models.DTOs;
using Microsoft.AspNetCore.Http;

namespace localink_be.Services.Interfaces
{
    public interface ICatalogService
    {
        Task EnsureOwnsBusinessAsync(long businessId, long userId, bool isAdmin);
        Task<List<CatalogDto>> GetBusinessCatalogsAsync(long businessId);
        Task<CatalogDto> CreateCatalogAsync(long businessId, CreateCatalogDto dto, long userId, bool isAdmin);
        Task<CatalogDto> UpdateCatalogAsync(int catalogId, CreateCatalogDto dto, long userId, bool isAdmin);
        Task DeleteCatalogAsync(int catalogId, long userId, bool isAdmin);

        Task<CatalogItemDto> AddCatalogItemAsync(int catalogId, CreateCatalogItemDto dto, IFormFile? image, long userId, bool isAdmin);
        Task<CatalogItemDto> UpdateCatalogItemAsync(int itemId, CreateCatalogItemDto dto, IFormFile? image, long userId, bool isAdmin);
        Task DeleteCatalogItemAsync(int itemId, long userId, bool isAdmin);
    }
}
