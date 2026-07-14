public interface IAdminService
{
    Task<List<AdminBusinessDto>> GetAllAsync();
    Task UpdateStatusAsync(long businessId, UpdateStatusDto dto, long adminId);
    Task<byte[]> ExportAsync(string status);
    Task<List<AdminUserDto>> GetUsersAsync();
    Task<AdminStatsDto> GetStatsAsync();
}