using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Options;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class PhotoService : IPhotoService
    {
        private readonly AppDbContext _db;
        private readonly ILogger<PhotoService> _logger;
        private readonly IImageOptimizationService _optimizer;
        private readonly IUploadStorageService _storage;
        private readonly UploadSettings _uploadSettings;

        private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
        {
            ".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic", ".heif", ".bmp"
        };

        private static readonly HashSet<string> AllowedMimeTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "image/jpeg", "image/png", "image/gif", "image/webp",
            "image/heic", "image/heif", "image/bmp", "application/octet-stream"
        };

        public PhotoService(
            AppDbContext db,
            ILogger<PhotoService> logger,
            IImageOptimizationService optimizer,
            IUploadStorageService storage,
            IOptions<UploadSettings> uploadSettings)
        {
            _db = db;
            _logger = logger;
            _optimizer = optimizer;
            _storage = storage;
            _uploadSettings = uploadSettings.Value;
        }

        public async Task<BusinessPhoto?> UploadPhotoAsync(long businessId, IFormFile file, long currentUserId, bool isAdmin)
        {
            if (file == null || file.Length == 0) return null;

            var business = await _db.Businesses.FindAsync(businessId);
            if (business == null)
            {
                _logger.LogWarning("Upload photo failed: Business with ID {BusinessId} not found", businessId);
                return null;
            }

            if (!isAdmin && business.UserId != currentUserId)
            {
                _logger.LogWarning("Unauthorized photo upload attempt by user {UserId} for business {BusinessId}", currentUserId, businessId);
                throw new UnauthorizedAccessException("You do not own this business.");
            }

            ValidateUploadHeaders(file);

            try
            {
                await using var stream = file.OpenReadStream();
                var optimized = await _optimizer.OptimizeAndSaveAsync(
                    stream,
                    file.FileName,
                    ImageUploadCategory.Business);

                var maxOrder = await _db.BusinessPhotos
                    .Where(p => p.BusinessId == businessId)
                    .Select(p => (int?)p.DisplayOrder)
                    .MaxAsync() ?? -1;

                var now = DateTime.UtcNow;
                var photo = new BusinessPhoto
                {
                    BusinessId = businessId,
                    ImageUrl = optimized.RelativePath,
                    IsPrimary = maxOrder < 0,
                    DisplayOrder = maxOrder + 1,
                    CreatedAt = now,
                    UpdatedAt = now
                };

                _db.BusinessPhotos.Add(photo);
                await _db.SaveChangesAsync();

                _logger.LogInformation(
                    "Successfully uploaded optimized photo for BusinessId={BusinessId}, PhotoId={PhotoId}, Path={Path}, Ratio={Ratio}%",
                    businessId, photo.PhotoId, optimized.RelativePath, optimized.CompressionRatio);

                return photo;
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Upload failure for BusinessId={BusinessId}, File={FileName}", businessId, file.FileName);
                throw;
            }
        }

        public async Task<List<BusinessPhoto>> GetPhotosAsync(long businessId)
        {
            return await _db.BusinessPhotos
                .Where(p => p.BusinessId == businessId)
                .OrderByDescending(p => p.IsPrimary)
                .ThenBy(p => p.DisplayOrder)
                .ThenBy(p => p.CreatedAt)
                .ToListAsync();
        }

        public async Task<bool> DeletePhotoAsync(long photoId, long currentUserId, bool isAdmin)
        {
            var photo = await _db.BusinessPhotos.FindAsync(photoId);
            if (photo == null) return false;

            var business = await _db.Businesses.FindAsync(photo.BusinessId);
            if (business != null && !isAdmin && business.UserId != currentUserId)
            {
                _logger.LogWarning(
                    "Unauthorized delete photo attempt by user {UserId} for business {BusinessId}, PhotoId {PhotoId}",
                    currentUserId, photo.BusinessId, photoId);
                throw new UnauthorizedAccessException("You do not own the business associated with this photo.");
            }

            _storage.TryDeleteRelativePath(photo.ImageUrl);

            _db.BusinessPhotos.Remove(photo);
            await _db.SaveChangesAsync();

            _logger.LogInformation("Successfully deleted photo with PhotoId={PhotoId} for BusinessId={BusinessId}", photoId, photo.BusinessId);
            return true;
        }

        public async Task<string?> UploadImageAsync(IFormFile file, string folderName)
        {
            if (file == null || file.Length == 0) return null;

            ValidateUploadHeaders(file);

            var category = MapFolderToCategory(folderName);
            try
            {
                await using var stream = file.OpenReadStream();
                var optimized = await _optimizer.OptimizeAndSaveAsync(
                    stream,
                    file.FileName,
                    category,
                    SanitizeFolder(folderName));

                return optimized.RelativePath;
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "UploadImageAsync failure. Folder={Folder}, File={FileName}", folderName, file.FileName);
                throw;
            }
        }

        public async Task SavePhotoAsync(string photoBase64, long businessId)
        {
            if (string.IsNullOrWhiteSpace(photoBase64)) return;

            byte[] bytes;
            try
            {
                // Support data-URI prefixes from Flutter / web clients
                var payload = photoBase64;
                var comma = photoBase64.IndexOf(',');
                if (photoBase64.StartsWith("data:", StringComparison.OrdinalIgnoreCase) && comma > 0)
                    payload = photoBase64[(comma + 1)..];

                bytes = Convert.FromBase64String(payload);
            }
            catch (FormatException)
            {
                _logger.LogWarning("Failed to decode base64 string for photo upload");
                throw new ArgumentException("Invalid base64 string");
            }

            if (bytes.Length > _uploadSettings.MaxUploadBytes)
            {
                _logger.LogWarning("Base64 image rejected: size {Length} exceeds limit {Limit}", bytes.Length, _uploadSettings.MaxUploadBytes);
                throw new ArgumentException($"Image size exceeds {_uploadSettings.MaxUploadBytes / (1024 * 1024)}MB limit.");
            }

            try
            {
                var optimized = await _optimizer.OptimizeAndSaveAsync(
                    bytes,
                    "business-photo.jpg",
                    ImageUploadCategory.Business);

                var existingPhotos = await _db.BusinessPhotos
                    .Where(p => p.BusinessId == businessId)
                    .ToListAsync();

                foreach (var p in existingPhotos)
                {
                    p.IsPrimary = false;
                    p.UpdatedAt = DateTime.UtcNow;
                }

                var now = DateTime.UtcNow;
                var photo = new BusinessPhoto
                {
                    BusinessId = businessId,
                    ImageUrl = optimized.RelativePath,
                    IsPrimary = true,
                    DisplayOrder = 0,
                    CreatedAt = now,
                    UpdatedAt = now
                };

                _db.BusinessPhotos.Add(photo);
                await _db.SaveChangesAsync();

                _logger.LogInformation(
                    "Saved optimized base64 photo for BusinessId={BusinessId}, Ratio={Ratio}%",
                    businessId, optimized.CompressionRatio);
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "SavePhotoAsync failure for BusinessId={BusinessId}", businessId);
                throw;
            }
        }

        public async Task<string?> SaveReviewPhotoAsync(string photoBase64)
        {
            if (string.IsNullOrWhiteSpace(photoBase64)) return null;

            byte[] bytes;
            try
            {
                var payload = photoBase64;
                var comma = photoBase64.IndexOf(',');
                if (photoBase64.StartsWith("data:", StringComparison.OrdinalIgnoreCase) && comma > 0)
                    payload = photoBase64[(comma + 1)..];

                bytes = Convert.FromBase64String(payload);
            }
            catch (FormatException)
            {
                _logger.LogWarning("Failed to decode base64 string for review photo");
                throw new ArgumentException("Invalid base64 string");
            }

            if (bytes.Length > _uploadSettings.MaxUploadBytes)
                throw new ArgumentException($"Image size exceeds {_uploadSettings.MaxUploadBytes / (1024 * 1024)}MB limit.");

            try
            {
                var optimized = await _optimizer.OptimizeAndSaveAsync(
                    bytes,
                    "review-photo.jpg",
                    ImageUploadCategory.Review);

                return optimized.RelativePath;
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "SaveReviewPhotoAsync failure");
                throw;
            }
        }

        private void ValidateUploadHeaders(IFormFile file)
        {
            if (file.Length > _uploadSettings.MaxUploadBytes)
            {
                _logger.LogWarning("Upload rejected: File size {Length} exceeds limit {Limit}", file.Length, _uploadSettings.MaxUploadBytes);
                throw new ArgumentException($"File size exceeds {_uploadSettings.MaxUploadBytes / (1024 * 1024)}MB limit.");
            }

            var ext = Path.GetExtension(file.FileName)?.ToLowerInvariant();
            // Allow missing extension — magic-byte + ImageSharp validation is authoritative.
            if (!string.IsNullOrEmpty(ext) && !AllowedExtensions.Contains(ext))
            {
                _logger.LogWarning("Upload rejected: Invalid file extension {Extension}", ext);
                throw new ArgumentException("Invalid file extension.");
            }

            var contentType = file.ContentType?.ToLowerInvariant();
            if (!string.IsNullOrEmpty(contentType) && !AllowedMimeTypes.Contains(contentType))
            {
                // Some phones send odd MIME types; still attempt if extension looks fine.
                if (string.IsNullOrEmpty(ext) || !AllowedExtensions.Contains(ext))
                {
                    _logger.LogWarning("Upload rejected: Invalid MIME type {MimeType}", contentType);
                    throw new ArgumentException("Invalid MIME type.");
                }

                _logger.LogInformation("Accepting upload with atypical MIME {MimeType} based on extension {Ext}", contentType, ext);
            }
        }

        private static ImageUploadCategory MapFolderToCategory(string folderName)
        {
            var f = (folderName ?? string.Empty).Trim().ToLowerInvariant();
            if (f.Contains("avatar")) return ImageUploadCategory.Avatar;
            if (f.Contains("catalog")) return ImageUploadCategory.Catalog;
            if (f.Contains("review")) return ImageUploadCategory.Review;
            if (f.Contains("business")) return ImageUploadCategory.Business;
            return ImageUploadCategory.Generic;
        }

        private static string SanitizeFolder(string folderName)
        {
            var cleaned = (folderName ?? "misc").Trim().Replace('\\', '/').Trim('/');
            return string.IsNullOrEmpty(cleaned) ? "misc" : cleaned.ToLowerInvariant();
        }
    }
}
