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

Env.Load();

var builder = WebApplication.CreateBuilder(args);

// Map standard .env variables to ASP.NET Core hierarchical configuration
var envMappings = new Dictionary<string, string>
{
    { "DB_CONNECTION_STRING", "ConnectionStrings:DefaultConnection" },
    { "JWT_SECRET_KEY", "Jwt:Key" },
    { "JWT_ISSUER", "Jwt:Issuer" },
    { "JWT_AUDIENCE", "Jwt:Audience" },
    { "JWT_EXPIRY_MINUTES", "Jwt:ExpiryMinutes" },
    { "CAPTCHA_SECRET_KEY", "Captcha:SecretKey" },
    { "COUNTRY_CSC_API_KEY", "CountryApi:ApiKey" },
    { "GEOAPIFY_API_KEY", "Geoapify:ApiKey" },
    { "GROQ_API_KEY", "Groq:ApiKey" },
    { "EMAIL_HOST", "Email:Host" },
    { "EMAIL_PORT", "Email:Port" },
    { "EMAIL_USERNAME", "Email:Username" },
    { "EMAIL_PASSWORD", "Email:Password" },
    { "EMAIL_FROM", "Email:From" },
    { "EMAIL_APP_NAME", "Email:AppName" }
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

builder.Services.AddHttpClient();
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sql => sql.EnableRetryOnFailure()
    )
);

builder.Logging.ClearProviders();
builder.Logging.AddConsole();

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IAddressService, AddressService>();
builder.Services.AddScoped<ISubcategoryService, SubcategoryService>();
builder.Services.AddScoped<IBusinessService, BusinessService>();
builder.Services.AddScoped<IContactService, ContactService>();
builder.Services.AddScoped<IHoursService, HoursService>();
builder.Services.AddScoped<IPhotoService, PhotoService>();

// CACHING SERVICES
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<ICacheService, CacheService>();

// HTTP CLIENTS WITH CACHE
builder.Services.AddHttpClient<BusinessLocationService>();
builder.Services.AddScoped<IBusinessLocationService, BusinessLocationService>();
builder.Services.AddScoped<IBusinessPincodeService, BusinessPincodeService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<ICaptchaService, CaptchaService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IFavoritesService, FavoritesService>();
builder.Services.AddScoped<IAIService, AIService>();

// AI GATEWAY SERVICE - Unified AI operations
builder.Services.AddHttpClient("GroqAI");
builder.Services.AddScoped<IAIGatewayService, AIGatewayService>();

// GLOBAL RATE LIMITER CONFIGURATION (100 requests per minute per IP address)
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? httpContext.Request.Headers.Host.ToString(),
            factory: partition => new FixedWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 100,
                QueueLimit = 0,
                Window = TimeSpan.FromMinutes(1)
            }));
});

var jwtKey = builder.Configuration["Jwt:Key"];

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;

    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,

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
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && 
                (path.StartsWithSegments("/api/v1/admin/export") || path.StartsWithSegments("/notifications")))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

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
    options.AddPolicy("AllowFrontend",
        policy => policy
            .SetIsOriginAllowed(origin => true)
            .AllowCredentials()
            .AllowAnyMethod()
            .AllowAnyHeader());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// GLOBAL ERROR HANDLER
app.UseMiddleware<ExceptionMiddleware>();

// TRANSLATION MIDDLEWARE - Global response translation
app.UseResponseTranslation();

app.UseHttpsRedirection();

// Serve default wwwroot static files & ensure wwwroot/uploads directory
var webRootPath = builder.Environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
var uploadsPath = Path.Combine(webRootPath, "uploads");
if (!Directory.Exists(uploadsPath)) Directory.CreateDirectory(uploadsPath);

app.UseStaticFiles();

// CORS FIRST
app.UseCors("AllowFrontend");

// RATE LIMITER MIDDLEWARE
app.UseRateLimiter();

// AUTH PIPELINE (IMPORTANT)
app.UseAuthentication();
app.UseAuthorization();

// ROUTES
app.MapGet("/", () => "Vocal For Sanatan API is running");
app.MapControllers();
app.MapHub<NotificationHub>("/notifications");

// SEED ADMIN PASSWORD RESET & EMAIL UPDATE
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<localink_be.Data.AppDbContext>();
    var admin = db.Users.FirstOrDefault(u => u.Email == "admin@vocalforsanatan.com")
                ?? db.Users.FirstOrDefault(u => u.Email == "admin@localink.com")
                ?? db.Users.FirstOrDefault(u => u.AccountType.ToLower() == "admin");
    if (admin != null)
    {
        admin.Email = "admin@vocalforsanatan.com";
        admin.PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123", 12);
        db.SaveChanges();
    }
}

app.Run();

// Required for WebApplicationFactory<Program> in integration tests
public partial class Program { }
