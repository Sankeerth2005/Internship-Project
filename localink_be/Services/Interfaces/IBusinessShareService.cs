using localink_be.Models.DTOs;

namespace localink_be.Services.Interfaces
{
    public interface IBusinessShareService
    {
        Task<(bool Success, string Message, BusinessShareCreatedDto? Data)> CreateSingleBusinessShareAsync(
            long userId,
            long businessId,
            CancellationToken cancellationToken = default);

        Task<(bool Success, string Message, BusinessShareCreatedDto? Data)> CreateFavoritesShareAsync(
            long userId,
            CreateFavoritesShareRequest request,
            CancellationToken cancellationToken = default);

        Task<BusinessShareViewDto?> GetShareByPublicTokenAsync(
            string publicToken,
            CancellationToken cancellationToken = default);
    }
}
