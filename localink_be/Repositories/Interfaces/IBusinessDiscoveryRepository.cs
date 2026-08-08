using localink_be.Models.DTOs;
using localink_be.Models.Queries;

namespace localink_be.Repositories.Interfaces
{
    public interface IBusinessDiscoveryRepository
    {
        Task<PagedResultDto<BusinessDto>> DiscoverAsync(
            BusinessDiscoveryQuery query,
            double defaultRadiusKm,
            double maxRadiusKm,
            int maxPageSize,
            CancellationToken cancellationToken = default);
    }
}
