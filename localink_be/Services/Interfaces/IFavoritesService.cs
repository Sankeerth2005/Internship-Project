using localink_be.Models.DTOs;

namespace localink_be.Services.Interfaces
{
    public interface IFavoritesService
    {
        Task<string> AddFavoriteAsync(FavoriteDto dto);
        Task<string> RemoveFavoriteAsync(long userId, long businessId);
        Task<List<long>> GetUserFavoritesAsync(long userId);
        Task<List<BusinessDto>> GetUserFavoriteBusinessesAsync(long userId);
    }
}
