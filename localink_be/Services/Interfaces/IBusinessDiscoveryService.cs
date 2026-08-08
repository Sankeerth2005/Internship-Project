using localink_be.Models.DTOs;
using localink_be.Models.Queries;

namespace localink_be.Services.Interfaces
{
    public interface IBusinessDiscoveryService
    {
        Task<PagedResultDto<BusinessDto>> DiscoverAsync(
            BusinessDiscoveryQuery query,
            CancellationToken cancellationToken = default);
    }
}
