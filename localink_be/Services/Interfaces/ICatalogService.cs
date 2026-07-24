using localink_be.Models.DTOs;
using Microsoft.AspNetCore.Http;

namespace localink_be.Services.Interfaces
{
    public interface ICatalogService
    {
        Task<List<CatalogDto>> GetBusinessCatalogsAsync(long businessId);
        Task<CatalogDto> CreateCatalogAsync(long businessId, CreateCatalogDto dto);
        Task<CatalogDto> UpdateCatalogAsync(int catalogId, CreateCatalogDto dto);
        Task DeleteCatalogAsync(int catalogId);

        Task<CatalogItemDto> AddCatalogItemAsync(int catalogId, CreateCatalogItemDto dto, IFormFile? image);
        Task<CatalogItemDto> UpdateCatalogItemAsync(int itemId, CreateCatalogItemDto dto, IFormFile? image);
        Task DeleteCatalogItemAsync(int itemId);
    }
}
