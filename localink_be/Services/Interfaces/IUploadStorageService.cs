namespace localink_be.Services.Interfaces
{
    public interface IUploadStorageService
    {
        /// <summary>Absolute path to the persistent uploads root (e.g. C:\VocalForSanatan\uploads).</summary>
        string UploadsRootPath { get; }

        /// <summary>Ensures a category subfolder exists and returns its absolute path.</summary>
        string EnsureCategoryDirectory(string categoryFolder);

        /// <summary>Maps a stored relative web path (/uploads/...) to an absolute disk path.</summary>
        string ResolveAbsolutePath(string relativeWebPath);

        /// <summary>Builds the public relative path stored in SQL (never a binary, never an absolute disk path).</summary>
        string ToRelativeWebPath(string categoryFolder, string fileName);

        bool TryDeleteRelativePath(string relativeWebPath);
    }
}
