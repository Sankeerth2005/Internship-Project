using System;
using System.IO;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using localink_be.Options;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class UploadStorageService : IUploadStorageService
    {
        private readonly IWebHostEnvironment _env;
        private readonly ILogger<UploadStorageService> _logger;
        private readonly string _uploadsRoot;

        public UploadStorageService(
            IWebHostEnvironment env,
            IOptions<UploadSettings> uploadOptions,
            ILogger<UploadStorageService> logger)
        {
            _env = env;
            _logger = logger;
            _uploadsRoot = ResolveUploadsRoot(uploadOptions.Value.UploadsPath);
            Directory.CreateDirectory(_uploadsRoot);
            _logger.LogInformation(
                "Persistent uploads root resolved to {UploadsRoot} (configured={Configured})",
                _uploadsRoot,
                uploadOptions.Value.UploadsPath ?? "(null)");
        }

        public string UploadsRootPath => _uploadsRoot;

        public string EnsureCategoryDirectory(string categoryFolder)
        {
            var safe = SanitizeFolder(categoryFolder);
            var dir = Path.Combine(_uploadsRoot, safe);
            Directory.CreateDirectory(dir);
            return dir;
        }

        public string ResolveAbsolutePath(string relativeWebPath)
        {
            if (string.IsNullOrWhiteSpace(relativeWebPath))
                throw new ArgumentException("Relative path is required.", nameof(relativeWebPath));

            var normalized = relativeWebPath
                .Replace('\\', '/')
                .TrimStart('/');

            // Strip the public URL prefix so disk layout is root-relative:
            // /uploads/businesses/x.webp -> businesses/x.webp under UploadsRootPath
            if (normalized.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase))
                normalized = normalized["uploads/".Length..];
            else if (string.Equals(normalized, "uploads", StringComparison.OrdinalIgnoreCase))
                normalized = string.Empty;

            var combined = Path.GetFullPath(Path.Combine(
                _uploadsRoot,
                normalized.Replace('/', Path.DirectorySeparatorChar)));

            // Prevent path traversal outside the uploads root
            var rootFull = Path.GetFullPath(_uploadsRoot)
                .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                + Path.DirectorySeparatorChar;
            if (!combined.StartsWith(rootFull, StringComparison.OrdinalIgnoreCase)
                && !string.Equals(
                    combined.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar),
                    rootFull.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar),
                    StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Invalid image path.");
            }

            return combined;
        }

        public string ToRelativeWebPath(string categoryFolder, string fileName)
        {
            var safeFolder = SanitizeFolder(categoryFolder);
            return $"/uploads/{safeFolder}/{fileName}";
        }

        public bool TryDeleteRelativePath(string relativeWebPath)
        {
            try
            {
                var absolute = ResolveAbsolutePath(relativeWebPath);
                if (!File.Exists(absolute)) return false;
                File.Delete(absolute);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to delete upload file for relative path {RelativePath}", relativeWebPath);
                return false;
            }
        }

        private string ResolveUploadsRoot(string? configured)
        {
            if (!string.IsNullOrWhiteSpace(configured))
            {
                var full = Path.GetFullPath(configured.Trim());
                var trimmed = full.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);

                // Accept either C:\VocalForSanatan or C:\VocalForSanatan\uploads
                // Use last segment equality (not EndsWith) so paths like ...\myuploads are not misread.
                var lastSegment = Path.GetFileName(trimmed);
                if (!string.Equals(lastSegment, "uploads", StringComparison.OrdinalIgnoreCase))
                    trimmed = Path.Combine(trimmed, "uploads");

                // Collapse accidental ...\uploads\uploads from mis-set env vars
                lastSegment = Path.GetFileName(trimmed);
                var parent = Path.GetDirectoryName(trimmed);
                if (!string.IsNullOrEmpty(parent)
                    && string.Equals(lastSegment, "uploads", StringComparison.OrdinalIgnoreCase)
                    && string.Equals(Path.GetFileName(parent), "uploads", StringComparison.OrdinalIgnoreCase))
                {
                    trimmed = parent;
                    _logger.LogWarning(
                        "UPLOADS_PATH had nested uploads segments; normalized to {UploadsRoot}",
                        trimmed);
                }

                return Path.GetFullPath(trimmed);
            }

            // Fallback only when config is missing — prefer persistent path over wwwroot
            // so a blank env var does not silently land files inside the deploy folder.
            var preferred = @"C:\VocalForSanatan\uploads";
            try
            {
                Directory.CreateDirectory(preferred);
                return Path.GetFullPath(preferred);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Could not use default persistent uploads path {Preferred}; falling back to wwwroot/uploads",
                    preferred);
            }

            var webRoot = _env.WebRootPath;
            if (string.IsNullOrEmpty(webRoot))
                webRoot = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

            return Path.GetFullPath(Path.Combine(webRoot, "uploads"));
        }

        private static string SanitizeFolder(string folder)
        {
            if (string.IsNullOrWhiteSpace(folder))
                return "misc";

            var cleaned = folder.Trim().Replace('\\', '/').Trim('/');

            // Callers sometimes pass "uploads/businesses" — strip leading uploads/
            if (cleaned.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase))
                cleaned = cleaned["uploads/".Length..];

            foreach (var segment in cleaned.Split('/', StringSplitOptions.RemoveEmptyEntries))
            {
                if (segment is "." or ".." || segment.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
                    throw new ArgumentException($"Invalid upload folder: {folder}");
            }

            return string.IsNullOrEmpty(cleaned) ? "misc" : cleaned.ToLowerInvariant();
        }
    }
}
