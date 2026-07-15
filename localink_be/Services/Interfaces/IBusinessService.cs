using System.Collections.Generic;
using System.Threading.Tasks;
using localink_be.Models.Entities;
using localink_be.Models.DTOs;

namespace localink_be.Services.Interfaces
{
    public interface IBusinessService
    {

    Task<List<object>> GetAllBusinessesAsync();
    Task<object?> GetBusinessByIdAsync(long id);
    Task<bool> DeleteBusinessAsync(long id);
    Task<Business> CreateBusinessAsync(Business dto);
    Task<long> RegisterBusinessAsync(RegisterBusinessDto dto, long userId);
    Task<object?> GetBusinessPreviewAsync(long businessId);
    Task<List<BusinessDto>> SearchBusinessesAsync(string query, double? userLat = null, double? userLng = null, string? sortBy = "distance", string? userPincode = "", string? userCity = "");
    Task<List<BusinessDto>> GetBusinessesByUserAsync(long userId);
    Task<List<BusinessDto>> GetBySubcategoryAsync(int subcategoryId);
    Task<BusinessDto?> GetByIdAsync(long id);
    Task<bool> UpdateBusinessFullAsync(long id, UpdateBusinessDto dto);
    Task<VoiceSearchResponse> VoiceSearchAsync(VoiceSearchRequest request, double? userLat = null, double? userLng = null);
    }
}