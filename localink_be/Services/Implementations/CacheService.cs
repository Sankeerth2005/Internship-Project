using System.Collections.Concurrent;
using Microsoft.Extensions.Caching.Memory;

namespace localink_be.Services.Implementations
{
    /// <summary>
    /// Generic caching service with thread-safe operations and fallback support.
    /// Implements cache-aside pattern with proper expiration policies.
    /// </summary>
    public interface ICacheService
    {
        /// <summary>
        /// Gets data from cache or creates it using the factory function.
        /// Thread-safe implementation prevents duplicate API calls.
        /// </summary>
        Task<T?> GetOrCreateAsync<T>(string key, Func<Task<T>> factory, TimeSpan expiration);

        /// <summary>
        /// Gets data from cache if exists, returns default otherwise.
        /// </summary>
        Task<T?> GetAsync<T>(string key);

        /// <summary>
        /// Sets data in cache with specified expiration.
        /// </summary>
        Task SetAsync<T>(string key, T value, TimeSpan expiration);

        /// <summary>
        /// Removes data from cache.
        /// </summary>
        Task RemoveAsync(string key);
    }

    public class CacheService : ICacheService
    {
        private readonly IMemoryCache _memoryCache;
        private readonly ILogger<CacheService> _logger;

        // Per-key locks to prevent concurrent factory calls; pruned so the map cannot grow forever.
        private static readonly ConcurrentDictionary<string, LockEntry> _locks = new();
        private const int MaxLockEntries = 512;
        private const int PruneTargetEntries = 256;
        private static readonly long LockIdlePruneMs = (long)TimeSpan.FromMinutes(10).TotalMilliseconds;
        private static int _pruneGate;

        private sealed class LockEntry
        {
            public SemaphoreSlim Semaphore { get; } = new(1, 1);
            public long LastUsedTicks;
        }

        public CacheService(IMemoryCache memoryCache, ILogger<CacheService> logger)
        {
            _memoryCache = memoryCache;
            _logger = logger;
        }

        /// <inheritdoc />
        public async Task<T?> GetOrCreateAsync<T>(string key, Func<Task<T>> factory, TimeSpan expiration)
        {
            // Try to get from cache first
            if (_memoryCache.TryGetValue(key, out T? cachedValue))
            {
                _logger.LogDebug("Cache HIT for key: {CacheKey}", key);
                return cachedValue;
            }

            // Get or create semaphore for this key to prevent concurrent API calls
            var semaphore = GetOrCreateSemaphore(key);

            try
            {
                // Wait to enter the semaphore (only one thread can call API for this key)
                await semaphore.WaitAsync();

                // Double-check after acquiring lock (another thread might have cached it)
                if (_memoryCache.TryGetValue(key, out cachedValue))
                {
                    _logger.LogDebug("Cache HIT after lock for key: {CacheKey}", key);
                    return cachedValue;
                }

                _logger.LogInformation("Cache MISS for key: {CacheKey}. Calling external API...", key);

                // Call factory function (external API)
                T? result;
                try
                {
                    result = await factory();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "External API call failed for key: {CacheKey}", key);
                    throw;
                }

                // Store in cache if result is not null
                if (result != null)
                {
                    var cacheOptions = new MemoryCacheEntryOptions()
                        .SetAbsoluteExpiration(expiration)
                        .SetPriority(CacheItemPriority.Normal);

                    _memoryCache.Set(key, result, cacheOptions);
                    _logger.LogInformation("Cached data for key: {CacheKey} with expiration: {Expiration}",
                        key, expiration);
                }

                return result;
            }
            finally
            {
                semaphore.Release();
            }
        }

        /// <inheritdoc />
        public Task<T?> GetAsync<T>(string key)
        {
            if (_memoryCache.TryGetValue(key, out T? cachedValue))
            {
                _logger.LogDebug("Cache HIT for key: {CacheKey}", key);
                return Task.FromResult(cachedValue);
            }

            _logger.LogDebug("Cache MISS for key: {CacheKey}", key);
            return Task.FromResult(default(T?));
        }

        /// <inheritdoc />
        public Task SetAsync<T>(string key, T value, TimeSpan expiration)
        {
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(expiration)
                .SetPriority(CacheItemPriority.Normal);

            _memoryCache.Set(key, value, cacheOptions);
            _logger.LogInformation("Manually cached data for key: {CacheKey} with expiration: {Expiration}",
                key, expiration);

            return Task.CompletedTask;
        }

        /// <inheritdoc />
        public Task RemoveAsync(string key)
        {
            _memoryCache.Remove(key);
            _logger.LogInformation("Removed cache for key: {CacheKey}", key);
            return Task.CompletedTask;
        }

        /// <summary>
        /// Gets or creates a SemaphoreSlim for the specified key.
        /// Ensures thread-safe access to prevent duplicate API calls.
        /// </summary>
        private static SemaphoreSlim GetOrCreateSemaphore(string key)
        {
            var entry = _locks.GetOrAdd(key, static _ => new LockEntry());
            Interlocked.Exchange(ref entry.LastUsedTicks, Environment.TickCount64);

            if (_locks.Count > MaxLockEntries)
                TryPruneUnusedLocks();

            return entry.Semaphore;
        }

        /// <summary>
        /// Removes idle, unlocked semaphore entries so the static map stays bounded.
        /// Semaphores are not disposed after removal to avoid racing with in-flight WaitAsync holders.
        /// </summary>
        private static void TryPruneUnusedLocks()
        {
            if (Interlocked.CompareExchange(ref _pruneGate, 1, 0) != 0)
                return;

            try
            {
                if (_locks.Count <= MaxLockEntries)
                    return;

                var now = Environment.TickCount64;
                foreach (var kvp in _locks)
                {
                    if (_locks.Count <= PruneTargetEntries)
                        break;

                    var entry = kvp.Value;
                    var idleMs = now - Volatile.Read(ref entry.LastUsedTicks);
                    // Only prune unlocked keys that have been idle long enough.
                    if (idleMs < LockIdlePruneMs || entry.Semaphore.CurrentCount != 1)
                        continue;

                    _locks.TryRemove(kvp.Key, out _);
                }
            }
            finally
            {
                Interlocked.Exchange(ref _pruneGate, 0);
            }
        }
    }
}
