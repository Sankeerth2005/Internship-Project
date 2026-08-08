namespace localink_be.Options
{
    public class UploadSettings
    {
        public const string SectionName = "UploadSettings";

        /// <summary>
        /// Persistent root for uploads. Must be <c>C:\VocalForSanatan\uploads</c>
        /// (outside the deploy folder so redeploys never wipe images).
        /// Override with env <c>UPLOADS_PATH</c> on the manager server.
        /// </summary>
        public string UploadsPath { get; set; } = @"C:\VocalForSanatan\uploads";

        /// <summary>
        /// Absolute max upload bytes (DoS guard). Typical phone camera shots are well under this.
        /// Images are always optimized before storage — callers should not need to pre-compress.
        /// </summary>
        public long MaxUploadBytes { get; set; } = 25 * 1024 * 1024;
    }

    public class ImageOptimizationOptions
    {
        public const string SectionName = "ImageOptimization";

        public int BusinessMaxDimension { get; set; } = 1920;
        public int AvatarMaxDimension { get; set; } = 512;
        public int CatalogMaxDimension { get; set; } = 1200;
        public int ReviewMaxDimension { get; set; } = 1600;
        public int DefaultMaxDimension { get; set; } = 1920;

        /// <summary>JPEG quality 1–100. ~82 preserves visual quality while cutting size sharply.</summary>
        public int JpegQuality { get; set; } = 82;

        /// <summary>WebP quality 1–100.</summary>
        public int WebpQuality { get; set; } = 80;

        /// <summary>Prefer WebP output; fall back to JPEG on encode failure.</summary>
        public bool PreferWebp { get; set; } = true;
    }
}
