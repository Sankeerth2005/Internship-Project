using System.Data;
using System.Text;
using localink_be.Data;
using localink_be.Extensions;
using localink_be.Models.DTOs;
using localink_be.Models.Enums;
using localink_be.Models.Queries;
using localink_be.Repositories.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace localink_be.Repositories.Implementations
{
    /// <summary>
    /// Spatial discovery against SQL Server geography + supporting indexes.
    /// Filtering, ranking, and pagination all execute in the database.
    /// </summary>
    public class BusinessDiscoveryRepository : IBusinessDiscoveryRepository
    {
        private readonly AppDbContext _db;
        private readonly ILogger<BusinessDiscoveryRepository> _logger;

        // BusinessStatus.Approved = 2
        private const int ApprovedStatus = 2;

        public BusinessDiscoveryRepository(AppDbContext db, ILogger<BusinessDiscoveryRepository> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<PagedResultDto<BusinessDto>> DiscoverAsync(
            BusinessDiscoveryQuery query,
            double defaultRadiusKm,
            double maxRadiusKm,
            int maxPageSize,
            CancellationToken cancellationToken = default)
        {
            var page = query.Page < 1 ? 1 : query.Page;
            var pageSize = query.PageSize < 1 ? 10 : Math.Min(query.PageSize, maxPageSize);
            var offset = (page - 1) * pageSize;
            _ = (defaultRadiusKm, maxRadiusKm);

            _logger.LogDebug(
                "Business discovery: sort={Sort} page={Page} size={PageSize} lat={Lat} lng={Lng}",
                query.Sort, page, pageSize, query.Latitude, query.Longitude);

            var hasLocation = query.Latitude.HasValue
                              && query.Longitude.HasValue
                              && query.Latitude is >= -90 and <= 90
                              && query.Longitude is >= -180 and <= 180
                              && !(query.Latitude == 0 && query.Longitude == 0);

            // Radius is never a visibility cutoff. Location only ranks results by distance.
            double? appliedRadiusKm = null;
            if (!hasLocation && query.RequireLocation)
            {
                return EmptyPage(page, pageSize, query.Sort);
            }

            var search = string.IsNullOrWhiteSpace(query.Search) ? null : query.Search.Trim();
            var searchPattern = search == null ? null : $"%{EscapeLike(search)}%";
            var pincode = string.IsNullOrWhiteSpace(query.UserPincode) ? null : query.UserPincode.Trim();
            var city = string.IsNullOrWhiteSpace(query.UserCity) ? null : query.UserCity.Trim();

            var (countSql, dataSql) = BuildSql(query.Sort, hasLocation, searchPattern != null, query.CategoryId.HasValue, query.SubcategoryId.HasValue);

            var connection = _db.Database.GetDbConnection();
            if (connection.State != ConnectionState.Open)
                await connection.OpenAsync(cancellationToken);

            await using var countCmd = connection.CreateCommand();
            countCmd.CommandText = countSql;
            countCmd.CommandType = CommandType.Text;
            BindCommonParameters(countCmd, query, hasLocation, searchPattern, search, pincode, city);

            var totalCount = Convert.ToInt32(await countCmd.ExecuteScalarAsync(cancellationToken) ?? 0);

            var ranked = new List<(long BusinessId, double? DistanceKm)>(pageSize);
            if (totalCount > 0)
            {
                await using var dataCmd = connection.CreateCommand();
                dataCmd.CommandText = dataSql;
                dataCmd.CommandType = CommandType.Text;
                BindCommonParameters(dataCmd, query, hasLocation, searchPattern, search, pincode, city);
                AddParameter(dataCmd, "@Offset", offset);
                AddParameter(dataCmd, "@PageSize", pageSize);

                await using var reader = await dataCmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    var id = reader.GetInt64(0);
                    double? distanceKm = reader.IsDBNull(1) ? null : reader.GetDouble(1);
                    ranked.Add((id, distanceKm));
                }
            }

            if (ranked.Count == 0)
            {
                return new PagedResultDto<BusinessDto>
                {
                    Items = Array.Empty<BusinessDto>(),
                    Page = page,
                    PageSize = pageSize,
                    TotalCount = totalCount,
                    AppliedRadiusKm = appliedRadiusKm,
                    Sort = BusinessSortModeParser.ToApiValue(query.Sort)
                };
            }

            var ids = ranked.Select(r => r.BusinessId).ToList();
            var distanceMap = ranked.ToDictionary(r => r.BusinessId, r => r.DistanceKm);

            var items = await ProjectBusinessesAsync(ids, cancellationToken);

            // Preserve SQL ranking order
            var ordered = new List<BusinessDto>(items.Count);
            foreach (var id in ids)
            {
                var dto = items.FirstOrDefault(x => x.Id == id);
                if (dto == null) continue;
                if (distanceMap.TryGetValue(id, out var d))
                    dto.Distance = d;
                ordered.Add(dto);
            }

            return new PagedResultDto<BusinessDto>
            {
                Items = ordered,
                Page = page,
                PageSize = pageSize,
                TotalCount = totalCount,
                AppliedRadiusKm = appliedRadiusKm,
                Sort = BusinessSortModeParser.ToApiValue(query.Sort)
            };
        }

        private static PagedResultDto<BusinessDto> EmptyPage(int page, int pageSize, BusinessSortMode sort) =>
            new()
            {
                Items = Array.Empty<BusinessDto>(),
                Page = page,
                PageSize = pageSize,
                TotalCount = 0,
                Sort = BusinessSortModeParser.ToApiValue(sort)
            };

        private static string EscapeLike(string input) =>
            input.Replace("[", "[[]", StringComparison.Ordinal)
                 .Replace("%", "[%]", StringComparison.Ordinal)
                 .Replace("_", "[_]", StringComparison.Ordinal);

        private static (string CountSql, string DataSql) BuildSql(
            BusinessSortMode sort,
            bool hasLocation,
            bool hasSearch,
            bool hasCategory,
            bool hasSubcategory)
        {
            var filters = new StringBuilder();
            filters.AppendLine("WHERE ad.Status = @ApprovedStatus");
            filters.AppendLine(BusinessVisibilityExtensions.SqlAndNotActivelyTemporarilyClosed);

            if (hasCategory)
                filters.AppendLine("  AND b.category_id = @CategoryId");

            if (hasSubcategory)
                filters.AppendLine("  AND b.subcategory_id = @SubcategoryId");

            if (hasSearch)
            {
                filters.AppendLine("""
                  AND (
                        b.business_name LIKE @Search
                     OR (b.description IS NOT NULL AND b.description LIKE @Search)
                     OR (cat.category_name IS NOT NULL AND cat.category_name LIKE @Search)
                     OR (sub.subcategory_name IS NOT NULL AND sub.subcategory_name LIKE @Search)
                     OR (c.city IS NOT NULL AND c.city LIKE @Search)
                     OR (c.street_address IS NOT NULL AND c.street_address LIKE @Search)
                     OR (c.pincode IS NOT NULL AND c.pincode LIKE @Search)
                  )
                """);
            }

            var distanceExpr = hasLocation
                ? "CASE WHEN c.geo_location IS NOT NULL THEN (c.geo_location.STDistance(@UserPoint) / 1000.0) ELSE CAST(NULL AS float) END"
                : "CAST(NULL AS float)";

            // Chosen sort mode is primary; distance is only primary for Nearest.
            // Search uses relevance first so a weak nearby match cannot bury a true name/category hit.
            var orderBy = BuildOrderBy(sort, hasLocation, hasSearch, distanceExpr);

            var fromJoin = """
                FROM dbo.business b
                INNER JOIN dbo.admin_dashboard ad ON ad.business_id = b.business_id
                INNER JOIN dbo.business_contact c ON c.business_id = b.business_id
                LEFT JOIN dbo.category cat ON cat.category_id = b.category_id
                LEFT JOIN dbo.subcategory sub ON sub.subcategory_id = b.subcategory_id
                OUTER APPLY (
                    SELECT
                        AVG(CAST(r.rating AS float)) AS AverageRating,
                        COUNT_BIG(*) AS TotalReviews
                    FROM dbo.business_reviews r
                    WHERE r.business_id = b.business_id
                ) rev
                OUTER APPLY (
                    SELECT
                        ISNULL(m.views, 0) AS Views,
                        ISNULL(m.favorites_count, 0) AS FavoritesCount,
                        ISNULL(m.contact_clicks, 0) AS ContactClicks
                    FROM dbo.business_metric m
                    WHERE m.business_id = b.business_id
                ) met
                """;

            var countSql = $"""
                SELECT COUNT_BIG(1)
                {fromJoin}
                {filters}
                """;

            var dataSql = $"""
                SELECT
                    b.business_id,
                    {distanceExpr} AS DistanceKm
                {fromJoin}
                {filters}
                ORDER BY {orderBy}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY
                """;

            return (countSql, dataSql);
        }

        private static string BuildOrderBy(BusinessSortMode sort, bool hasLocation, bool hasSearch, string distanceExpr)
        {
            // Soft locality when GPS is absent (pincode/city boost only).
            var localityBoost = hasLocation
                ? string.Empty
                : """
                  CASE WHEN @UserPincode IS NOT NULL AND c.pincode = @UserPincode THEN 0 ELSE 1 END ASC,
                  CASE WHEN @UserCity IS NOT NULL AND LOWER(c.city) = LOWER(@UserCity) THEN 0 ELSE 1 END ASC,
                  """;

            var relevanceBoost = hasSearch
                ? """
                  CASE
                    WHEN LOWER(b.business_name) = LOWER(@SearchExact) THEN 0
                    WHEN b.business_name LIKE @Search THEN 1
                    WHEN (cat.category_name IS NOT NULL AND cat.category_name LIKE @Search)
                      OR (sub.subcategory_name IS NOT NULL AND sub.subcategory_name LIKE @Search) THEN 2
                    ELSE 3
                  END ASC,
                  """
                : string.Empty;

            // Missing coordinates are ranked after businesses with a real distance. Never invent coords.
            var missingGeoLast = hasLocation
                ? "CASE WHEN c.geo_location IS NULL THEN 1 ELSE 0 END ASC, "
                : string.Empty;

            var distanceTiebreak = hasLocation
                ? $", {distanceExpr} ASC"
                : string.Empty;

            return sort switch
            {
                BusinessSortMode.NameAsc =>
                    $"{relevanceBoost}{localityBoost}{missingGeoLast} b.business_name ASC{distanceTiebreak}, b.business_id ASC",

                BusinessSortMode.NameDesc =>
                    $"{relevanceBoost}{localityBoost}{missingGeoLast} b.business_name DESC{distanceTiebreak}, b.business_id ASC",

                BusinessSortMode.TopRated =>
                    $"{relevanceBoost}{localityBoost}{missingGeoLast} ISNULL(rev.AverageRating, 0) DESC, ISNULL(rev.TotalReviews, 0) DESC{distanceTiebreak}, b.business_name ASC",

                BusinessSortMode.MostReviewed =>
                    $"{relevanceBoost}{localityBoost}{missingGeoLast} ISNULL(rev.TotalReviews, 0) DESC, ISNULL(rev.AverageRating, 0) DESC{distanceTiebreak}, b.business_name ASC",

                BusinessSortMode.Newest =>
                    $"{relevanceBoost}{localityBoost}{missingGeoLast} b.created_at DESC{distanceTiebreak}, b.business_id DESC",

                BusinessSortMode.MostPopular =>
                    $"{relevanceBoost}{localityBoost}{missingGeoLast} (ISNULL(met.Views,0) + ISNULL(met.FavoritesCount,0) * 3 + ISNULL(met.ContactClicks,0) * 2) DESC, ISNULL(rev.TotalReviews, 0) DESC{distanceTiebreak}, b.business_name ASC",

                _ => // Nearest — relevance (when searching) then actual geographic distance
                    hasLocation
                        ? $"{relevanceBoost}{missingGeoLast}{distanceExpr} ASC, b.business_name ASC, b.business_id ASC"
                        : $"{relevanceBoost}{localityBoost} b.business_name ASC, b.business_id ASC"
            };
        }

        private static void BindCommonParameters(
            System.Data.Common.DbCommand cmd,
            BusinessDiscoveryQuery query,
            bool hasLocation,
            string? searchPattern,
            string? searchExact,
            string? pincode,
            string? city)
        {
            AddParameter(cmd, "@ApprovedStatus", ApprovedStatus);

            if (hasLocation)
            {
                AddParameter(cmd, "@UserLat", query.Latitude!.Value);
                AddParameter(cmd, "@UserLng", query.Longitude!.Value);

                cmd.CommandText = """
                    DECLARE @UserPoint geography = geography::Point(@UserLat, @UserLng, 4326);
                    """ + cmd.CommandText;
            }

            if (query.CategoryId.HasValue)
                AddParameter(cmd, "@CategoryId", query.CategoryId.Value);

            if (query.SubcategoryId.HasValue)
                AddParameter(cmd, "@SubcategoryId", query.SubcategoryId.Value);

            if (searchPattern != null)
            {
                AddParameter(cmd, "@Search", searchPattern);
                AddParameter(cmd, "@SearchExact", searchExact ?? string.Empty);
            }

            AddParameter(cmd, "@UserPincode", (object?)pincode ?? DBNull.Value);
            AddParameter(cmd, "@UserCity", (object?)city ?? DBNull.Value);
        }

        private static void AddParameter(System.Data.Common.DbCommand cmd, string name, object value)
        {
            var p = cmd.CreateParameter();
            p.ParameterName = name;
            p.Value = value ?? DBNull.Value;
            cmd.Parameters.Add(p);
        }

        private async Task<List<BusinessDto>> ProjectBusinessesAsync(List<long> ids, CancellationToken cancellationToken)
        {
            // Projection-only, AsNoTracking, no N+1: single query with correlated subselects batched by IN
            var list = await _db.Businesses
                .AsNoTracking()
                .Where(b => ids.Contains(b.BusinessId))
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
                    Status = _db.AdminDashboards.Where(a => a.BusinessId == b.BusinessId).Select(a => a.Status.ToString()).FirstOrDefault(),
                    PrimaryImage = _db.BusinessPhotos.Where(p => p.BusinessId == b.BusinessId).OrderByDescending(p => p.IsPrimary).Select(p => p.ImageUrl).FirstOrDefault(),
                    Photos = _db.BusinessPhotos.Where(p => p.BusinessId == b.BusinessId).OrderByDescending(p => p.IsPrimary).Select(p => p.ImageUrl).ToList(),
                    AverageRating = _db.BusinessReviews.Where(r => r.BusinessId == b.BusinessId).Select(r => (double?)r.Rating).Average() ?? 0.0,
                    TotalReviews = _db.BusinessReviews.Count(r => r.BusinessId == b.BusinessId),
                    IsTemporarilyClosed = b.TemporaryClosureStatus == "Approved" && b.TemporaryClosureReopenDate.HasValue && b.TemporaryClosureReopenDate.Value > DateTime.UtcNow,
                    TemporaryClosureReason = b.TemporaryClosureReason,
                    TemporaryClosureStatus = b.TemporaryClosureStatus,
                    TemporaryClosureDays = b.TemporaryClosureDays,
                    TemporaryClosureReopenDate = b.TemporaryClosureReopenDate
                })
                .ToListAsync(cancellationToken);

            return list;
        }
    }
}
