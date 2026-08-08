using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.Processing;
using localink_be.Options;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class ImageOptimizationService : IImageOptimizationService
    {
        private readonly IUploadStorageService _storage;
        private readonly ImageOptimizationOptions _options;
        private readonly ILogger<ImageOptimizationService> _logger;

        private static readonly byte[] JpegMagic = { 0xFF, 0xD8, 0xFF };
        private static readonly byte[] PngMagic = { 0x89, 0x50, 0x4E, 0x47 };
        private static readonly byte[] GifMagic = { 0x47, 0x49, 0x46, 0x38 };
        private static readonly byte[] RiffMagic = { 0x52, 0x49, 0x46, 0x46 };
        private static readonly byte[] WebpMagic = { 0x57, 0x45, 0x42, 0x50 }; // at offset 8
        private static readonly byte[] HeicFtyp = { 0x66, 0x74, 0x79, 0x70 }; // 'ftyp' at offset 4

        public ImageOptimizationService(
            IUploadStorageService storage,
            IOptions<ImageOptimizationOptions> options,
            ILogger<ImageOptimizationService> logger)
        {
            _storage = storage;
            _options = options.Value;
            _logger = logger;
        }

        public async Task<OptimizedImageResult> OptimizeAndSaveAsync(
            byte[] input,
            string? originalFileName,
            ImageUploadCategory category,
            string? subFolder = null,
            CancellationToken cancellationToken = default)
        {
            await using var ms = new MemoryStream(input, writable: false);
            return await OptimizeAndSaveAsync(ms, originalFileName, category, subFolder, cancellationToken);
        }

        public async Task<OptimizedImageResult> OptimizeAndSaveAsync(
            Stream input,
            string? originalFileName,
            ImageUploadCategory category,
            string? subFolder = null,
            CancellationToken cancellationToken = default)
        {
            var sw = Stopwatch.StartNew();
            var folder = subFolder ?? CategoryFolder(category);
            var maxDimension = MaxDimensionFor(category);

            // Buffer to a temp file so we can rewind, validate magic, and release memory promptly.
            var tempPath = Path.Combine(Path.GetTempPath(), $"vfs-img-{Guid.NewGuid():N}.tmp");
            long originalBytes = 0;

            try
            {
                await using (var tempWrite = new FileStream(tempPath, FileMode.CreateNew, FileAccess.Write, FileShare.None, 81920, FileOptions.Asynchronous))
                {
                    await input.CopyToAsync(tempWrite, cancellationToken);
                    originalBytes = tempWrite.Length;
                }

                if (originalBytes == 0)
                    throw new ArgumentException("Empty image upload.");

                await using var tempRead = new FileStream(tempPath, FileMode.Open, FileAccess.Read, FileShare.Read, 81920, FileOptions.Asynchronous | FileOptions.SequentialScan);

                if (!await ValidateMagicBytesAsync(tempRead, cancellationToken))
                {
                    _logger.LogWarning(
                        "Image validation failed (magic bytes). File={FileName}, Size={Size}",
                        originalFileName, originalBytes);
                    throw new ArgumentException("Invalid or corrupted image file.");
                }

                tempRead.Position = 0;

                Image image;
                try
                {
                    image = await Image.LoadAsync(tempRead, cancellationToken);
                }
                catch (UnknownImageFormatException ex)
                {
                    _logger.LogWarning(ex, "Compression failed: unreadable image format. File={FileName}", originalFileName);
                    throw new ArgumentException("Unsupported or corrupted image format.");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Compression failed while loading image. File={FileName}, Size={Size}", originalFileName, originalBytes);
                    throw new ArgumentException("Unable to process image. The file may be corrupted.");
                }

                using (image)
                {
                    // Honor EXIF orientation then strip all metadata (privacy + size).
                    image.Mutate(ctx => ctx.AutoOrient());
                    StripMetadata(image);

                    if (image.Width > maxDimension || image.Height > maxDimension)
                    {
                        image.Mutate(ctx => ctx.Resize(new ResizeOptions
                        {
                            Mode = ResizeMode.Max,
                            Size = new Size(maxDimension, maxDimension),
                            Sampler = KnownResamplers.Lanczos3
                        }));
                    }

                    var preferWebp = _options.PreferWebp;
                    string fileName;
                    string contentType;
                    string absolutePath;
                    long optimizedBytes;

                    Directory.CreateDirectory(_storage.EnsureCategoryDirectory(folder));

                    try
                    {
                        if (preferWebp)
                        {
                            fileName = $"{Guid.NewGuid():N}.webp";
                            absolutePath = Path.Combine(_storage.EnsureCategoryDirectory(folder), fileName);
                            contentType = "image/webp";
                            var encoder = new WebpEncoder
                            {
                                Quality = ClampQuality(_options.WebpQuality),
                                FileFormat = WebpFileFormatType.Lossy
                            };
                            await image.SaveAsync(absolutePath, encoder, cancellationToken);
                        }
                        else
                        {
                            fileName = $"{Guid.NewGuid():N}.jpg";
                            absolutePath = Path.Combine(_storage.EnsureCategoryDirectory(folder), fileName);
                            contentType = "image/jpeg";
                            var encoder = new JpegEncoder { Quality = ClampQuality(_options.JpegQuality) };
                            await image.SaveAsync(absolutePath, encoder, cancellationToken);
                        }
                    }
                    catch (Exception encodeEx) when (preferWebp)
                    {
                        _logger.LogWarning(encodeEx, "WebP encode failed; falling back to JPEG. File={FileName}", originalFileName);
                        fileName = $"{Guid.NewGuid():N}.jpg";
                        absolutePath = Path.Combine(_storage.EnsureCategoryDirectory(folder), fileName);
                        contentType = "image/jpeg";
                        var encoder = new JpegEncoder { Quality = ClampQuality(_options.JpegQuality) };
                        await image.SaveAsync(absolutePath, encoder, cancellationToken);
                    }

                    optimizedBytes = new FileInfo(absolutePath).Length;
                    sw.Stop();

                    var relative = _storage.ToRelativeWebPath(folder, fileName);
                    var result = new OptimizedImageResult
                    {
                        RelativePath = relative,
                        AbsolutePath = absolutePath,
                        FileName = fileName,
                        ContentType = contentType,
                        OriginalBytes = originalBytes,
                        OptimizedBytes = optimizedBytes,
                        Width = image.Width,
                        Height = image.Height,
                        ProcessingMs = sw.ElapsedMilliseconds
                    };

                    _logger.LogInformation(
                        "Image optimized. Category={Category}, File={FileName}, OriginalBytes={OriginalBytes}, OptimizedBytes={OptimizedBytes}, CompressionRatio={CompressionRatio}%, Dimensions={Width}x{Height}, ProcessingMs={ProcessingMs}, RelativePath={RelativePath}",
                        category,
                        originalFileName,
                        result.OriginalBytes,
                        result.OptimizedBytes,
                        result.CompressionRatio,
                        result.Width,
                        result.Height,
                        result.ProcessingMs,
                        result.RelativePath);

                    return result;
                }
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Upload/compression pipeline failure. File={FileName}, OriginalBytes={OriginalBytes}, Category={Category}",
                    originalFileName, originalBytes, category);
                throw;
            }
            finally
            {
                TryDeleteTemp(tempPath);
            }
        }

        private int MaxDimensionFor(ImageUploadCategory category) => category switch
        {
            ImageUploadCategory.Business => _options.BusinessMaxDimension,
            ImageUploadCategory.Avatar => _options.AvatarMaxDimension,
            ImageUploadCategory.Catalog => _options.CatalogMaxDimension,
            ImageUploadCategory.Review => _options.ReviewMaxDimension,
            _ => _options.DefaultMaxDimension
        };

        private static string CategoryFolder(ImageUploadCategory category) => category switch
        {
            ImageUploadCategory.Business => "businesses",
            ImageUploadCategory.Avatar => "avatars",
            ImageUploadCategory.Catalog => "catalogs",
            ImageUploadCategory.Review => "reviews",
            _ => "misc"
        };

        private static int ClampQuality(int q) => Math.Clamp(q, 1, 100);

        private static void StripMetadata(Image image)
        {
            image.Metadata.ExifProfile = null;
            image.Metadata.IptcProfile = null;
            image.Metadata.XmpProfile = null;
            // Keep ICC only if present and needed for color — strip for size/privacy consistency
            image.Metadata.IccProfile = null;
        }

        private static async Task<bool> ValidateMagicBytesAsync(Stream stream, CancellationToken ct)
        {
            var header = new byte[12];
            var read = await stream.ReadAsync(header.AsMemory(0, 12), ct);
            stream.Position = 0;
            if (read < 4) return false;

            if (StartsWith(header, JpegMagic)) return true;
            if (StartsWith(header, PngMagic)) return true;
            if (StartsWith(header, GifMagic)) return true;

            // WEBP: RIFF....WEBP
            if (StartsWith(header, RiffMagic) && read >= 12 && header.AsSpan(8, 4).SequenceEqual(WebpMagic))
                return true;

            // HEIC/HEIF (common from iPhone) — ImageSharp may or may not decode depending on codecs;
            // accept magic so we attempt load and fail gracefully if unsupported.
            if (read >= 8 && header.AsSpan(4, 4).SequenceEqual(HeicFtyp))
                return true;

            // BMP
            if (header[0] == 0x42 && header[1] == 0x4D) return true;

            return false;
        }

        private static bool StartsWith(byte[] data, byte[] prefix)
        {
            if (data.Length < prefix.Length) return false;
            for (int i = 0; i < prefix.Length; i++)
                if (data[i] != prefix[i]) return false;
            return true;
        }

        private void TryDeleteTemp(string tempPath)
        {
            try
            {
                if (File.Exists(tempPath))
                    File.Delete(tempPath);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to delete temporary upload file {TempPath}", tempPath);
            }
        }
    }
}
