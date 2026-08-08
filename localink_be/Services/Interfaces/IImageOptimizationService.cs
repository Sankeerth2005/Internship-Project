using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace localink_be.Services.Interfaces
{
    public enum ImageUploadCategory
    {
        Business,
        Avatar,
        Catalog,
        Review,
        Generic
    }

    public sealed class OptimizedImageResult
    {
        public required string RelativePath { get; init; }
        public required string AbsolutePath { get; init; }
        public required string FileName { get; init; }
        public required string ContentType { get; init; }
        public long OriginalBytes { get; init; }
        public long OptimizedBytes { get; init; }
        public int Width { get; init; }
        public int Height { get; init; }
        public double CompressionRatio => OriginalBytes <= 0
            ? 0
            : Math.Round(100.0 * (1.0 - (double)OptimizedBytes / OriginalBytes), 2);
        public long ProcessingMs { get; init; }
    }

    public interface IImageOptimizationService
    {
        /// <summary>
        /// Validates, resizes (aspect preserved), compresses, strips metadata,
        /// writes a uniquely named file under the persistent uploads root, and returns a relative web path.
        /// </summary>
        Task<OptimizedImageResult> OptimizeAndSaveAsync(
            Stream input,
            string? originalFileName,
            ImageUploadCategory category,
            string? subFolder = null,
            CancellationToken cancellationToken = default);

        Task<OptimizedImageResult> OptimizeAndSaveAsync(
            byte[] input,
            string? originalFileName,
            ImageUploadCategory category,
            string? subFolder = null,
            CancellationToken cancellationToken = default);
    }
}
