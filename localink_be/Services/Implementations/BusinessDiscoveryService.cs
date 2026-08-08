using localink_be.Models.DTOs;
using localink_be.Models.Queries;
using localink_be.Repositories.Interfaces;
using localink_be.Services.Interfaces;
using Microsoft.Extensions.Options;

namespace localink_be.Services.Implementations
{
    public class BusinessDiscoveryOptions
    {
        public const string SectionName = "BusinessDiscovery";

        public double DefaultRadiusKm { get; set; } = 25;
        public double MaxRadiusKm { get; set; } = 100;
        public int DefaultPageSize { get; set; } = 20;
        public int MaxPageSize { get; set; } = 50;
    }

    public class BusinessDiscoveryService : IBusinessDiscoveryService
    {
        private readonly IBusinessDiscoveryRepository _repository;
        private readonly BusinessDiscoveryOptions _options;

        public BusinessDiscoveryService(
            IBusinessDiscoveryRepository repository,
            IOptions<BusinessDiscoveryOptions> options)
        {
            _repository = repository;
            _options = options.Value;
        }

        public Task<PagedResultDto<BusinessDto>> DiscoverAsync(
            BusinessDiscoveryQuery query,
            CancellationToken cancellationToken = default)
        {
            if (query.Page < 1) query.Page = 1;
            if (query.PageSize < 1) query.PageSize = _options.DefaultPageSize;
            if (query.PageSize > _options.MaxPageSize) query.PageSize = _options.MaxPageSize;

            if (query.RadiusKm.HasValue)
            {
                if (query.RadiusKm <= 0)
                    query.RadiusKm = _options.DefaultRadiusKm;
                else if (query.RadiusKm > _options.MaxRadiusKm)
                    query.RadiusKm = _options.MaxRadiusKm;
            }

            // Reject clearly invalid coordinates so we fall back to non-spatial ranking
            if (query.Latitude.HasValue && (query.Latitude < -90 || query.Latitude > 90))
                query.Latitude = null;
            if (query.Longitude.HasValue && (query.Longitude < -180 || query.Longitude > 180))
                query.Longitude = null;
            if (query.Latitude == 0 && query.Longitude == 0)
            {
                query.Latitude = null;
                query.Longitude = null;
            }

            return _repository.DiscoverAsync(
                query,
                _options.DefaultRadiusKm,
                _options.MaxRadiusKm,
                _options.MaxPageSize,
                cancellationToken);
        }
    }
}
