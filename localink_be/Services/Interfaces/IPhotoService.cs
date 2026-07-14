using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using localink_be.Models.Entities;

namespace localink_be.Services.Interfaces
{
    public interface IPhotoService
    {
        Task<BusinessPhoto?> UploadPhotoAsync(long businessId, IFormFile file);
        Task<List<BusinessPhoto>> GetPhotosAsync(long businessId);
        Task<bool> DeletePhotoAsync(long photoId);
        Task SavePhotoAsync(string photoBase64, long businessId);
        Task<string> SaveReviewPhotoAsync(string photoBase64);
    }
}
