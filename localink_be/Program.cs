using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using localink_be.Hubs;
using System.Text;
using DotNetEnv;
using localink_be.Data;
using localink_be.Services.Interfaces;
using localink_be.Services.Implementations;
using localink_be.Middleware;
using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.HttpOverrides;
using localink_be.Options;

// Single .env source of truth:
// 1) ENV_FILE override  2) beside DLL (prod)  3) repo root  4) first parent .env
static string? ResolveEnvFilePath()
{
    var explicitPath = Environment.GetEnvironmentVariable("ENV_FILE");
    if (!string.IsNullOrWhiteSpace(explicitPath) && File.Exists(explicitPath))
        return Path.GetFullPath(explicitPath);

    var baseDir = new DirectoryInfo(AppContext.BaseDirectory);
    var besideDll = Path.Combine(baseDir.FullName, ".env");
    if (File.Exists(besideDll))
        return besideDll;

    for (var dir = baseDir; dir != null; dir = dir.Parent)
    {
        var looksLikeRepoRoot =
            Directory.Exists(Path.Combine(dir.FullName, "localink_be")) &&
            Directory.Exists(Path.Combine(dir.FullName, "localink_mobile"));
        var candidate = Path.Combine(dir.FullName, ".env");
        if (looksLikeRepoRoot && File.Exists(candidate))
            return candidate;
    }

    for (var dir = baseDir; dir != null; dir = dir.Parent)
    {
        var candidate = Path.Combine(dir.FullName, ".env");
        if (File.Exists(candidate))
            return candidate;
    }

    return null;
}

var envFilePath = ResolveEnvFilePath();
if (envFilePath != null)
{
    Env.Load(envFilePath);
    Console.WriteLine($"Loaded configuration from: {envFilePath}");
}
else
{
    Console.WriteLine("WARNING: No .env file found. Relying on process environment / appsettings only.");
}

var builder = WebApplication.CreateBuilder(args);

// Map standard .env variables to ASP.NET Core hierarchical configuration
var envMappings = new Dictionary<string, string>
{
    { "DB_CONNECTION_STRING", "ConnectionStrings:DefaultConnection" },
    { "JWT_SECRET_KEY", "Jwt:Key" },
    { "JWT_ISSUER", "Jwt:Issuer" },
    { "JWT_AUDIENCE", "Jwt:Audience" },
    { "JWT_EXPIRY_MINUTES", "Jwt:ExpiryMinutes" },
    { "JWT_EXPIRY_DAYS", "Jwt:ExpiryDays" },
    { "JWT_REFRESH_TOKEN_DAYS", "Jwt:RefreshTokenDays" },
    { "CORS_ALLOWED_ORIGINS", "Cors:AllowedOrigins" },
    { "COUNTRY_CSC_API_KEY", "CountryApi:ApiKey" },
    { "GEOAPIFY_API_KEY", "Geoapify:ApiKey" },
    { "GROQ_API_KEY", "Groq:ApiKey" },
    { "CURRENCY_CONVERTER_API_KEY", "CurrencyConverter:ApiKey" },
    { "ADMIN_EMAIL", "AdminEmail" },
    { "EMAIL_HOST", "Email:Host" },
    { "EMAIL_PORT", "Email:Port" },
    { "EMAIL_USERNAME", "Email:Username" },
    { "EMAIL_PASSWORD", "Email:Password" },
    { "EMAIL_FROM", "Email:From" },
    { "EMAIL_APP_NAME", "Email:AppName" },
    { "UPLOADS_PATH", "UploadSettings:UploadsPath" },
    { "GOOGLE_CLIENT_ID", "Google:ClientId" },
    { "GOOGLE_CLIENT_SECRET", "Google:ClientSecret" },
    { "GOOGLE_ANDROID_CLIENT_ID", "Google:AndroidClientId" },
    { "GOOGLE_WEB_CLIENT_ID", "Google:WebClientId" }
};

foreach (var mapping in envMappings)
{
    var val = Environment.GetEnvironmentVariable(mapping.Key);
    if (!string.IsNullOrEmpty(val))
    {
        builder.Configuration[mapping.Value] = val;
    }
}

builder.Configuration.AddEnvironmentVariables();

// Validate critical configuration elements on startup (Fail-Fast pattern)
var dbConn = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(dbConn))
{
    throw new InvalidOperationException("Startup Error: ConnectionStrings:DefaultConnection is empty or missing. Please set it in appsettings.json or via DB_CONNECTION_STRING environment variable.");
}

// Manager-server SQL Express commonly uses localhost — allow it.
// Log a warning in Production so it is reviewed before public launch.
if (!builder.Environment.IsDevelopment() &&
    dbConn.Contains("localhost", StringComparison.OrdinalIgnoreCase))
{
    Console.WriteLine(
        "WARNING: Production is using a localhost SQL connection. Ensure this is intentional on the manager server.");
}

var jwtKeySetting = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKeySetting) ||
    jwtKeySetting.Length < 32 ||
    jwtKeySetting.Contains("REPLACE_", StringComparison.OrdinalIgnoreCase) ||
    jwtKeySetting.Contains("YOUR_", StringComparison.OrdinalIgnoreCase))
{
    throw new InvalidOperationException("Startup Error: Jwt:Key must be set via JWT_SECRET_KEY / Jwt:Key to a strong secret (min 32 chars). Do not use placeholders.");
}

builder.Services.AddHttpClient();
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sql =>
        {
            sql.EnableRetryOnFailure();
            sql.UseNetTopologySuite();
        })
    .ConfigureWarnings(warnings => warnings.Ignore(RelationalEventId.MultipleCollectionIncludeWarning))
);

builder.Logging.ClearProviders();
builder.Logging.AddConsole();

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IAddressService, AddressService>();
builder.Services.AddScoped<ISubcategoryService, SubcategoryService>();
builder.Services.AddScoped<IBusinessService, BusinessService>();
builder.Services.Configure<localink_be.Services.Implementations.BusinessDiscoveryOptions>(
    builder.Configuration.GetSection(localink_be.Services.Implementations.BusinessDiscoveryOptions.SectionName));
builder.Services.AddScoped<localink_be.Repositories.Interfaces.IBusinessDiscoveryRepository,
    localink_be.Repositories.Implementations.BusinessDiscoveryRepository>();
builder.Services.AddScoped<IBusinessDiscoveryService, BusinessDiscoveryService>();
builder.Services.AddScoped<IContactService, ContactService>();
builder.Services.AddScoped<IHoursService, HoursService>();
builder.Services.Configure<UploadSettings>(builder.Configuration.GetSection(UploadSettings.SectionName));
builder.Services.Configure<ImageOptimizationOptions>(builder.Configuration.GetSection(ImageOptimizationOptions.SectionName));
builder.Services.AddSingleton<IUploadStorageService, UploadStorageService>();
builder.Services.AddScoped<IImageOptimizationService, ImageOptimizationService>();
builder.Services.AddScoped<IPhotoService, PhotoService>();

// Allow phone-camera sized uploads; backend always optimizes before disk write.
var maxUploadBytes = builder.Configuration.GetValue<long?>("UploadSettings:MaxUploadBytes") ?? (25L * 1024 * 1024);
builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = maxUploadBytes;
    options.ValueLengthLimit = (int)Math.Min(maxUploadBytes, int.MaxValue);
});
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = maxUploadBytes;
});

// CACHING SERVICES
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<ICacheService, CacheService>();

// HTTP CLIENTS WITH CACHE
builder.Services.AddHttpClient<BusinessLocationService>();
builder.Services.AddScoped<IBusinessLocationService, BusinessLocationService>();
builder.Services.AddScoped<IBusinessPincodeService, BusinessPincodeService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IBulkImportService, BulkImportService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IFavoritesService, FavoritesService>();
builder.Services.AddScoped<IAIService, AIService>();
builder.Services.AddScoped<IPersonalizationService, PersonalizationService>();
builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddScoped<ICatalogService, CatalogService>();
builder.Services.AddScoped<ICurrencyService, CurrencyService>();
builder.Services.AddHttpClient<ICurrencyService, CurrencyService>();

// AI GATEWAY SERVICE - Unified AI operations
builder.Services.AddHttpClient("GroqAI");
builder.Services.AddScoped<IAIGatewayService, AIGatewayService>();

// GLOBAL RATE LIMITER CONFIGURATION (100 requests per minute per IP address)
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
        RateLimitPartition.GetSlidingWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? httpContext.Request.Headers.Host.ToString(),
            factory: partition => new SlidingWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 100,
                QueueLimit = 0,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 4
            }));
    
    // Stricter rate limiting for authentication endpoints
    options.AddPolicy("AuthPolicy", context =>
        RateLimitPartition.GetSlidingWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? context.Request.Headers.Host.ToString(),
            factory: _ => new SlidingWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 10,
                QueueLimit = 0,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 2
            }));

    options.AddPolicy("AiPolicy", context =>
        RateLimitPartition.GetSlidingWindowLimiter(
            partitionKey: context.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                ?? context.Connection.RemoteIpAddress?.ToString()
                ?? context.Request.Headers.Host.ToString(),
            factory: _ => new SlidingWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 20,
                QueueLimit = 0,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 4
            }));
});

builder.Services.AddHealthChecks();

var jwtKey = builder.Configuration["Jwt:Key"];

var authBuilder = builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
    options.SaveToken = true;

    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ClockSkew = TimeSpan.FromMinutes(1),

        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],

        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtKey!)
        )
    };

    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            // SignalR cannot always set Authorization headers — allow query token only for hubs.
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) &&
                (path.StartsWithSegments("/notifications") || path.StartsWithSegments("/chat")))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

var clientId = builder.Configuration["Google:ClientId"];
var clientSecret = builder.Configuration["Google:ClientSecret"];
if (!string.IsNullOrEmpty(clientId) && !string.IsNullOrEmpty(clientSecret))
{
    authBuilder.AddGoogle(options =>
    {
        options.ClientId = clientId;
        options.ClientSecret = clientSecret;
    });
}

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter()
        );
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Enter 'Bearer' [space] and then your valid token in the text input below.\n\nExample: \"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\""
    });
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});
builder.Services.AddSignalR();

builder.Services.AddCors(options =>
{
    var configured = builder.Configuration["Cors:AllowedOrigins"]
        ?? "https://www.vocalforsanatan.com;https://vocalforsanatan.com;https://app.vocalforsanatan.com";
    var origins = configured
        .Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

    if (builder.Environment.IsDevelopment())
    {
        origins = origins
            .Concat(new[]
            {
                "http://localhost:3000",
                "http://localhost:8080",
                "http://127.0.0.1:3000",
                "http://127.0.0.1:8080"
            })
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }
    else
    {
        origins = origins
            .Where(o => !o.Contains("localhost", StringComparison.OrdinalIgnoreCase)
                     && !o.Contains("127.0.0.1", StringComparison.OrdinalIgnoreCase))
            .ToArray();
    }

    options.AddPolicy("AllowFrontend",
        policy => policy
            .WithOrigins(origins)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials());
});

builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    // Clear defaults so reverse-proxy headers are honored in production deployments.
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

var app = builder.Build();

app.UseForwardedHeaders();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// GLOBAL ERROR HANDLER
app.UseMiddleware<ExceptionMiddleware>();

// TRANSLATION MIDDLEWARE - Global response translation
app.UseResponseTranslation();

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
    app.UseHttpsRedirection();
}

// Persistent uploads OUTSIDE the deploy folder (e.g. C:\VocalForSanatan\uploads).
// Register BEFORE default wwwroot static files so /uploads never resolves to a
// wiped wwwroot\uploads leftover from older deploys.
var uploadStorage = app.Services.GetRequiredService<IUploadStorageService>();
var uploadsRoot = uploadStorage.UploadsRootPath;
Directory.CreateDirectory(uploadsRoot);
foreach (var sub in new[] { "businesses", "avatars", "catalogs", "reviews", "audio", "misc" })
    Directory.CreateDirectory(Path.Combine(uploadsRoot, sub));

var startupLogger = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger("Startup");
startupLogger.LogInformation(
    "Serving /uploads from persistent disk root {UploadsRoot}. Set UPLOADS_PATH to override.",
    uploadsRoot);

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadsRoot),
    RequestPath = "/uploads",
    OnPrepareResponse = ctx =>
    {
        // Aggressive client/CDN cache for immutable GUID filenames
        ctx.Context.Response.Headers.CacheControl = "public,max-age=31536000,immutable";
    }
});

// Default wwwroot static files (non-upload assets only)
var webRootPath = builder.Environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
if (!Directory.Exists(webRootPath)) Directory.CreateDirectory(webRootPath);
app.UseStaticFiles();

// Ensure refresh_tokens table exists (production-safe idempotent DDL)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("Startup");
    try
    {
        await db.Database.ExecuteSqlRawAsync(@"
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'refresh_tokens')
BEGIN
    CREATE TABLE refresh_tokens (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_refresh_tokens PRIMARY KEY,
        user_id BIGINT NOT NULL,
        token_hash NVARCHAR(128) NOT NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_refresh_tokens_created_at DEFAULT (SYSUTCDATETIME()),
        expires_at DATETIME2 NOT NULL,
        revoked_at DATETIME2 NULL,
        replaced_by_token_hash NVARCHAR(128) NULL,
        device_info NVARCHAR(64) NULL,
        CONSTRAINT FK_refresh_tokens_users FOREIGN KEY (user_id) REFERENCES users(user_id)
    );
    CREATE UNIQUE INDEX IX_refresh_tokens_token_hash ON refresh_tokens(token_hash);
    CREATE INDEX IX_refresh_tokens_user_id ON refresh_tokens(user_id);
END");
    }
    catch (Exception ex)
    {
        logger.LogWarning(ex, "Could not ensure refresh_tokens table exists. Run Scripts/EnsureRefreshTokensTable.sql if needed.");
    }
}

// CORS FIRST
app.UseCors("AllowFrontend");

// RATE LIMITER MIDDLEWARE
app.UseRateLimiter();

// AUTH PIPELINE (IMPORTANT)
app.UseAuthentication();
app.UseAuthorization();

// ROUTES
app.MapGet("/", () => "Vocal For Sanatan API is running");
app.MapHealthChecks("/health");
app.MapGet("/health/ready", async (AppDbContext db) =>
{
    try
    {
        var ok = await db.Database.CanConnectAsync();
        return ok
            ? Results.Ok(new { status = "ready" })
            : Results.Json(new { status = "not_ready" }, statusCode: 503);
    }
    catch
    {
        return Results.Json(new { status = "not_ready" }, statusCode: 503);
    }
});

app.MapControllers();
app.MapHub<NotificationHub>("/notifications");
app.MapHub<ChatHub>("/chat");

app.Run();

// Required for WebApplicationFactory<Program> in integration tests
public partial class Program { }
