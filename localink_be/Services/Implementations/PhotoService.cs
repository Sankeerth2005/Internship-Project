using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class PhotoService : IPhotoService
    {
        private readonly AppDbContext _db;
        private readonly IWebHostEnvironment _env;
        private readonly Microsoft.Extensions.Logging.ILogger<PhotoService> _logger;

        public PhotoService(AppDbContext db, IWebHostEnvironment env, Microsoft.Extensions.Logging.ILogger<PhotoService> logger)
        {
            _db = db;
            _env = env;
            _logger = logger;
        }

        private string GetUploadsRootPath()
        {
            var baseDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "localink_uploads");
            return Path.GetFullPath(baseDir);
        }

        private readonly List<string> _allowedExtensions = new() { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
        private readonly List<string> _allowedMimeTypes = new() { "image/jpeg", "image/png", "image/gif", "image/webp" };

        private bool ValidateImageMagicBytes(Stream stream)
        {
            byte[] header = new byte[8];
            int bytesRead = stream.Read(header, 0, 8);
            stream.Position = 0; // Reset position

            if (bytesRead < 4) return false;

            // PNG
            if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47)
                return true;

            // JPEG
            if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
                return true;

            // GIF
            if (header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x38)
                return true;

            // WEBP
            if (header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46)
                return true;

            return false;
        }

        private bool ValidateImageMagicBytes(byte[] bytes)
        {
            if (bytes == null || bytes.Length < 4) return false;

            // PNG
            if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47)
                return true;

            // JPEG
            if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
                return true;

            // GIF
            if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38)
                return true;

            // WEBP
            if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46)
                return true;

            return false;
        }

        public async Task<BusinessPhoto?> UploadPhotoAsync(long businessId, IFormFile file, long currentUserId, bool isAdmin)
        {
            if (file == null || file.Length == 0) return null;

            // 1. Verify Ownership
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

            // 2. Size Validation (Max 5MB)
            if (file.Length > 5 * 1024 * 1024)
            {
                _logger.LogWarning("Upload photo rejected: File size {Length} exceeds limit", file.Length);
                throw new ArgumentException("File size exceeds 5MB limit.");
            }

            // 3. Extension Validation
            var ext = Path.GetExtension(file.FileName)?.ToLower();
            if (string.IsNullOrEmpty(ext) || !_allowedExtensions.Contains(ext))
            {
                _logger.LogWarning("Upload photo rejected: Invalid file extension {Extension}", ext);
                throw new ArgumentException("Invalid file extension.");
            }

            // 4. MIME Type Validation
            var contentType = file.ContentType?.ToLower();
            if (string.IsNullOrEmpty(contentType) || !_allowedMimeTypes.Contains(contentType))
            {
                _logger.LogWarning("Upload photo rejected: Invalid MIME type {MimeType}", contentType);
                throw new ArgumentException("Invalid MIME type.");
            }

            // 5. Magic Bytes Check
            using (var checkStream = file.OpenReadStream())
            {
                if (!ValidateImageMagicBytes(checkStream))
                {
                    _logger.LogWarning("Upload photo rejected: Magic bytes validation failed for business {BusinessId}", businessId);
                    throw new ArgumentException("Invalid image file format (magic bytes check failed).");
                }
            }

            var uploadsPath = GetUploadsRootPath();
            if (!Directory.Exists(uploadsPath)) Directory.CreateDirectory(uploadsPath);
            var fileName = $"{Guid.NewGuid()}{ext}";
            var filePath = Path.Combine(uploadsPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create)) 
            { 
                await file.CopyToAsync(stream); 
            }

            var photo = new BusinessPhoto 
            { 
                BusinessId = businessId, 
                ImageUrl = $"/uploads/{fileName}", 
                IsPrimary = false, 
                CreatedAt = DateTime.UtcNow 
            };

            _db.BusinessPhotos.Add(photo);
            await _db.SaveChangesAsync();

            _logger.LogInformation("Successfully uploaded photo for BusinessId={BusinessId}, PhotoId={PhotoId}", businessId, photo.PhotoId);
            return photo;
        }

        public async Task<List<BusinessPhoto>> GetPhotosAsync(long businessId)
        {
            return await _db.BusinessPhotos
                .Where(p => p.BusinessId == businessId)
                .OrderByDescending(p => p.IsPrimary)
                .ToListAsync();
        }

        public async Task<bool> DeletePhotoAsync(long photoId, long currentUserId, bool isAdmin)
        {
            var photo = await _db.BusinessPhotos.FindAsync(photoId);
            if (photo == null) return false;

            // Verify Ownership
            var business = await _db.Businesses.FindAsync(photo.BusinessId);
            if (business != null && !isAdmin && business.UserId != currentUserId)
            {
                _logger.LogWarning("Unauthorized delete photo attempt by user {UserId} for business {BusinessId}, PhotoId {PhotoId}", 
                    currentUserId, photo.BusinessId, photoId);
                throw new UnauthorizedAccessException("You do not own the business associated with this photo.");
            }

            var relativePath = photo.ImageUrl.Replace("/uploads/", "").Replace("/", Path.DirectorySeparatorChar.ToString());
            var filePath = Path.Combine(GetUploadsRootPath(), relativePath);
            if (File.Exists(filePath))
            {
                try
                {
                    File.Delete(filePath);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to delete file from disk: {Path}", filePath);
                }
            }

            _db.BusinessPhotos.Remove(photo);
            await _db.SaveChangesAsync();

            _logger.LogInformation("Successfully deleted photo with PhotoId={PhotoId} for BusinessId={BusinessId}", photoId, photo.BusinessId);
            return true;
        }

        public async Task SavePhotoAsync(string photoBase64, long businessId)
        {
            if (string.IsNullOrWhiteSpace(photoBase64)) return;

            byte[] bytes;
            try
            {
                bytes = Convert.FromBase64String(photoBase64);
            }
            catch (FormatException)
            {
                _logger.LogWarning("Failed to decode base64 string for photo upload");
                throw new ArgumentException("Invalid base64 string");
            }

            // Size check (5MB)
            if (bytes.Length > 5 * 1024 * 1024)
            {
                throw new ArgumentException("Base64 image size exceeds 5MB");
            }

            // Magic bytes check
            if (!ValidateImageMagicBytes(bytes))
            {
                throw new ArgumentException("Invalid image magic bytes in base64");
            }

            var uploadsPath = GetUploadsRootPath();
            if (!Directory.Exists(uploadsPath))
                Directory.CreateDirectory(uploadsPath);

            var fileName = $"{Guid.NewGuid()}.jpg";
            var filePath = Path.Combine(uploadsPath, fileName);

            await File.WriteAllBytesAsync(filePath, bytes);

            var imageUrl = $"/uploads/{fileName}";

            // Set all existing photos to not primary
            var existingPhotos = await _db.BusinessPhotos
                .Where(p => p.BusinessId == businessId)
                .ToListAsync();
            foreach (var p in existingPhotos)
            {
                p.IsPrimary = false;
            }

            var photo = new BusinessPhoto
            {
                BusinessId = businessId,
                ImageUrl = imageUrl,
                IsPrimary = true,
                CreatedAt = DateTime.UtcNow
            };

            _db.BusinessPhotos.Add(photo);
            await _db.SaveChangesAsync();

            _logger.LogInformation("Saved base64 photo for BusinessId={BusinessId}", businessId);
        }

        public async Task<string?> SaveReviewPhotoAsync(string photoBase64)
        {
            if (string.IsNullOrWhiteSpace(photoBase64)) return null;

            byte[] bytes;
            try
            {
                bytes = Convert.FromBase64String(photoBase64);
            }
            catch (FormatException)
            {
                _logger.LogWarning("Failed to decode base64 string for review photo");
                throw new ArgumentException("Invalid base64 string");
            }

            // Size check (5MB)
            if (bytes.Length > 5 * 1024 * 1024)
            {
                throw new ArgumentException("Base64 image size exceeds 5MB");
            }

            // Magic bytes check
            if (!ValidateImageMagicBytes(bytes))
            {
                throw new ArgumentException("Invalid image magic bytes in base64");
            }

            var uploadsPath = Path.Combine(GetUploadsRootPath(), "reviews");
            if (!Directory.Exists(uploadsPath))
                Directory.CreateDirectory(uploadsPath);

            var fileName = $"{Guid.NewGuid()}.jpg";
            var filePath = Path.Combine(uploadsPath, fileName);

            await File.WriteAllBytesAsync(filePath, bytes);

            _logger.LogInformation("Saved base64 review photo to {Path}", filePath);
            return $"/uploads/reviews/{fileName}";
        }
    }
}
