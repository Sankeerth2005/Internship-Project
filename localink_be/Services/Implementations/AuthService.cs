using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;
using Google.Apis.Auth;

namespace localink_be.Services.Implementations
{
    public class AuthService : IAuthService
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;
        private readonly IEmailService _emailService;
        private readonly ILogger<AuthService> _logger;

        public AuthService(
            AppDbContext context,
            IConfiguration config,
            IEmailService emailService,
            ILogger<AuthService> logger)
        {
            _context = context;
            _config = config;
            _emailService = emailService;
            _logger = logger;
        }

        public async Task<string> RegisterAsync(RegisterRequest request)
        {
            var email = request.Email?.Trim().ToLower();

            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("Email is required");

            if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 8)
                throw new ArgumentException("Password must be at least 8 characters");

            User user = null!;

            var strategy = _context.Database.CreateExecutionStrategy();
            await strategy.ExecuteAsync(async () =>
            {
                using var transaction = await _context.Database.BeginTransactionAsync();
                try
                {
                    var emailExists = await _context.Users.AnyAsync(u => u.Email == email);
                    if (emailExists)
                        throw new InvalidOperationException("Email already exists");

                    var phoneExists = await _context.Users.AnyAsync(u => u.PhoneNumber == request.Phone);
                    if (phoneExists)
                        throw new InvalidOperationException("Phone number already exists");

                    var accountType = (request.UserType ?? "user").Trim().ToLowerInvariant();
                    if (accountType is not ("client" or "businessowner" or "user"))
                        throw new ArgumentException("Invalid user type");
                    // Never allow self-registration as admin
                    if (accountType == "admin")
                        throw new UnauthorizedAccessException("Admin accounts cannot be self-registered");

                    user = new User
                    {
                        AccountType = accountType,
                        FullName = request.Name,
                        Email = email,
                        PhoneNumber = request.Phone,
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password, 12),
                        CountryCode = request.CountryCode
                    };

                    _context.Users.Add(user);
                    await _context.SaveChangesAsync();

                    var address = new Address
                    {
                        UserId = user.UserId,
                        Country = request.Country,
                        State = request.State,
                        City = request.City,
                        StreetAddress = request.Street,
                        Pincode = request.Pincode
                    };

                    _context.Addresses.Add(address);
                    await _context.SaveChangesAsync();

                    await transaction.CommitAsync();
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            });

            try
            {
                await _emailService.SendWelcomeEmailAsync(user.Email, user.FullName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Email sending failed during registration for {Email}", email);
            }

            return "User registered successfully";
        }

        public async Task<string> VerifyEmailAsync(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("Email is required");

            var exists = await _context.Users
                .AnyAsync(u => u.Email == email.Trim().ToLower());

            return exists ? "Email exists" : "Email available";
        }

        public Task<string> ResetPasswordAsync(ForgotPasswordRequest request)
        {
            // Password reset without OTP is intentionally disabled.
            return Task.FromException<string>(new InvalidOperationException(
                "Password reset requires OTP verification. Use the forgot-password + OTP flow."));
        }

        public async Task<object> LoginAsync(LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.UsernameOrEmail) ||
                string.IsNullOrWhiteSpace(request.Password))
                throw new UnauthorizedAccessException("Invalid credentials");

            var email = request.UsernameOrEmail.Trim().ToLower();

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == email);

            if (user == null ||
                string.IsNullOrEmpty(user.PasswordHash) ||
                !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                throw new UnauthorizedAccessException("Invalid credentials");

            return await IssueSessionAsync(user);
        }

        public async Task<object> GoogleSignInAsync(string idToken)
        {
            try
            {
                var clientId = _config["Google:ClientId"];
                if (string.IsNullOrEmpty(clientId))
                {
                    throw new InvalidOperationException("Google authentication is not configured");
                }

                // Accept Web client (primary), optional explicit web id, and Android client audiences.
                var audiences = new List<string> { clientId };
                var webClientId = _config["Google:WebClientId"];
                if (!string.IsNullOrWhiteSpace(webClientId) &&
                    !audiences.Contains(webClientId, StringComparer.Ordinal))
                {
                    audiences.Add(webClientId);
                }
                var androidClientId = _config["Google:AndroidClientId"];
                if (!string.IsNullOrWhiteSpace(androidClientId) &&
                    !audiences.Contains(androidClientId, StringComparer.Ordinal))
                {
                    audiences.Add(androidClientId);
                }

                var settings = new GoogleJsonWebSignature.ValidationSettings()
                {
                    Audience = audiences
                };

                var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, settings);

                var email = payload.Email.ToLower();
                var name = payload.Name;
                var picture = payload.Picture;

                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == email);

                if (user != null)
                {
                    return await IssueSessionAsync(user, isNewUser: false);
                }

                var strategy = _context.Database.CreateExecutionStrategy();
                return await strategy.ExecuteAsync(async () =>
                {
                    using var transaction = await _context.Database.BeginTransactionAsync();
                    try
                    {
                        user = new User
                        {
                            AccountType = "user",
                            FullName = name ?? "Google User",
                            Email = email,
                            ProfilePicture = picture,
                            CountryCode = string.Empty,
                            AuthProvider = "google",
                            ProviderId = payload.Subject,
                            CreatedAt = DateTime.UtcNow
                        };

                        _context.Users.Add(user);
                        await _context.SaveChangesAsync();

                        await transaction.CommitAsync();

                        return await IssueSessionAsync(user, isNewUser: true);
                    }
                    catch
                    {
                        await transaction.RollbackAsync();
                        throw;
                    }
                });
            }
            catch (UnauthorizedAccessException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Google sign-in failed");
                throw new UnauthorizedAccessException("Google authentication failed");
            }
        }

        public async Task<object> RefreshSessionAsync(string refreshToken)
        {
            if (string.IsNullOrWhiteSpace(refreshToken))
                throw new UnauthorizedAccessException("Invalid refresh token");

            var tokenHash = HashToken(refreshToken);
            var stored = await _context.RefreshTokens
                .Include(t => t.User)
                .FirstOrDefaultAsync(t => t.TokenHash == tokenHash);

            if (stored == null || stored.User == null)
                throw new UnauthorizedAccessException("Invalid refresh token");

            if (stored.RevokedAt != null)
            {
                // Possible token reuse after rotation — revoke all sessions for this user
                await RevokeAllUserTokensAsync(stored.UserId);
                throw new UnauthorizedAccessException("Refresh token revoked");
            }

            if (stored.ExpiresAt <= DateTime.UtcNow)
                throw new UnauthorizedAccessException("Refresh token expired");

            var user = stored.User;
            var accessToken = GenerateAccessToken(user);
            var (newRefreshToken, newEntity) = CreateRefreshTokenEntity(user.UserId);

            stored.RevokedAt = DateTime.UtcNow;
            stored.ReplacedByTokenHash = newEntity.TokenHash;
            _context.RefreshTokens.Add(newEntity);
            await _context.SaveChangesAsync();

            return BuildAuthResponse(user, accessToken, newRefreshToken);
        }

        public async Task LogoutAsync(string refreshToken)
        {
            if (string.IsNullOrWhiteSpace(refreshToken))
                return;

            var tokenHash = HashToken(refreshToken);
            var stored = await _context.RefreshTokens
                .FirstOrDefaultAsync(t => t.TokenHash == tokenHash);

            if (stored == null || stored.RevokedAt != null)
                return;

            stored.RevokedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        public async Task<string> SendResetOtpAsync(string email)
        {
            var normalizedEmail = email.Trim().ToLower();

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == normalizedEmail);

            if (user == null)
                return "If the email exists, an OTP has been sent";

            if (user.OtpExpiry != null && user.OtpExpiry > DateTime.UtcNow.AddMinutes(-1))
                throw new InvalidOperationException("Please wait before requesting another OTP");

            var otp = GenerateOtp();

            // Store hashed OTP only — never plaintext, never log the code
            user.PasswordResetOtp = BCrypt.Net.BCrypt.HashPassword(otp, workFactor: 10);
            user.OtpExpiry = DateTime.UtcNow.AddMinutes(15);
            user.OtpAttempts = 0;

            await _context.SaveChangesAsync();

            try
            {
                await _emailService.SendOtpEmailAsync(user.Email, otp);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Email sending failed during OTP generation for {Email}", normalizedEmail);
            }

            return "If the email exists, an OTP has been sent";
        }

        public async Task<string> VerifyOtpAndResetPasswordAsync(string email, string otp, string newPassword)
        {
            var normalizedEmail = email.Trim().ToLower();

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == normalizedEmail);

            if (user == null)
                throw new UnauthorizedAccessException("Invalid request");

            if (user.OtpAttempts >= 5)
                throw new UnauthorizedAccessException("Too many attempts. Request new OTP");

            if (string.IsNullOrEmpty(user.PasswordResetOtp) ||
                !BCrypt.Net.BCrypt.Verify(otp, user.PasswordResetOtp))
            {
                user.OtpAttempts += 1;
                await _context.SaveChangesAsync();
                throw new UnauthorizedAccessException("Invalid OTP");
            }

            if (user.OtpExpiry < DateTime.UtcNow)
                throw new UnauthorizedAccessException("OTP expired");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword, 12);
            user.OtpAttempts = 0;
            user.PasswordResetOtp = null;
            user.OtpExpiry = null;

            await RevokeAllUserTokensAsync(user.UserId);
            await _context.SaveChangesAsync();

            return "Password reset successful";
        }

        public async Task<string> ChangePasswordAsync(long userId, ChangePasswordRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId)
                ?? throw new UnauthorizedAccessException("User not found");

            if (string.IsNullOrEmpty(user.PasswordHash))
                throw new InvalidOperationException("This account uses social login. Set a password via forgot-password first.");

            if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
                throw new UnauthorizedAccessException("Current password is incorrect");

            if (BCrypt.Net.BCrypt.Verify(request.NewPassword, user.PasswordHash))
                throw new ArgumentException("New password must be different from the current password");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword, 12);
            user.UpdatedAt = DateTime.UtcNow;
            await RevokeAllUserTokensAsync(user.UserId);
            await _context.SaveChangesAsync();

            return "Password changed successfully. Please sign in again.";
        }

        public async Task<AuthorizedExperiencesDto> GetAuthorizedExperiencesAsync(long userId)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId)
                ?? throw new UnauthorizedAccessException("User not found");

            var accountType = NormalizeAccountType(user.AccountType);
            var ownsBusiness = await _context.Businesses.AnyAsync(b => b.UserId == userId);
            var canOwner = accountType == "businessowner" || accountType == "admin" || ownsBusiness;
            var canUser = accountType != "admin";

            var experiences = new List<string>();
            if (canUser) experiences.Add("user");
            if (canOwner) experiences.Add("businessowner");
            if (accountType == "admin") experiences.Add("admin");

            return new AuthorizedExperiencesDto
            {
                AccountType = accountType,
                AuthorizedExperiences = experiences,
                CanContinueAsUser = canUser,
                CanContinueAsBusinessOwner = canOwner,
                CanRegisterBusiness = accountType is "user" or "client" or "businessowner"
            };
        }

        public async Task<SelectExperienceResultDto> SelectExperienceAsync(long userId, string experience)
        {
            var requested = (experience ?? string.Empty).Trim().ToLowerInvariant();
            if (requested is not ("user" or "businessowner"))
                throw new ArgumentException("Experience must be user or businessowner");

            var caps = await GetAuthorizedExperiencesAsync(userId);

            if (requested == "user")
            {
                if (!caps.CanContinueAsUser)
                {
                    return new SelectExperienceResultDto
                    {
                        Allowed = false,
                        Experience = requested,
                        Destination = "admin",
                        Message = "This account uses the admin experience."
                    };
                }

                return new SelectExperienceResultDto
                {
                    Allowed = true,
                    Experience = "user",
                    Destination = "user",
                    Message = null
                };
            }

            // businessowner
            if (caps.CanContinueAsBusinessOwner)
            {
                return new SelectExperienceResultDto
                {
                    Allowed = true,
                    Experience = "businessowner",
                    Destination = "businessowner",
                    Message = null
                };
            }

            // Not authorized for Owner dashboard — reuse existing business registration flow.
            return new SelectExperienceResultDto
            {
                Allowed = false,
                Experience = "businessowner",
                Destination = "register-business",
                Message = "Your account is not authorized for the Business Owner portal yet. Register your business to continue."
            };
        }

        private static string NormalizeAccountType(string? accountType) =>
            (accountType ?? "user").Trim().ToLowerInvariant();

        private async Task<object> IssueSessionAsync(User user, bool? isNewUser = null)
        {
            var accessToken = GenerateAccessToken(user);
            var (refreshToken, entity) = CreateRefreshTokenEntity(user.UserId);
            _context.RefreshTokens.Add(entity);
            await _context.SaveChangesAsync();

            return BuildAuthResponse(user, accessToken, refreshToken, isNewUser);
        }

        private object BuildAuthResponse(User user, string accessToken, string refreshToken, bool? isNewUser = null)
        {
            if (isNewUser.HasValue)
            {
                return new
                {
                    token = accessToken,
                    refreshToken,
                    expiresIn = GetAccessTokenLifetimeSeconds(),
                    user = new
                    {
                        id = user.UserId.ToString(),
                        name = user.FullName,
                        email = user.Email,
                        userType = user.AccountType,
                        isNewUser = isNewUser.Value
                    }
                };
            }

            return new
            {
                token = accessToken,
                refreshToken,
                expiresIn = GetAccessTokenLifetimeSeconds(),
                user = new
                {
                    id = user.UserId.ToString(),
                    name = user.FullName,
                    email = user.Email,
                    userType = user.AccountType
                }
            };
        }

        private (string PlainToken, RefreshToken Entity) CreateRefreshTokenEntity(long userId)
        {
            var plain = GenerateSecureToken();
            var entity = new RefreshToken
            {
                UserId = userId,
                TokenHash = HashToken(plain),
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(GetRefreshTokenLifetimeDays())
            };
            return (plain, entity);
        }

        private async Task RevokeAllUserTokensAsync(long userId)
        {
            var active = await _context.RefreshTokens
                .Where(t => t.UserId == userId && t.RevokedAt == null)
                .ToListAsync();

            var now = DateTime.UtcNow;
            foreach (var token in active)
                token.RevokedAt = now;
        }

        private string GenerateOtp()
        {
            var bytes = new byte[4];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(bytes);
            int number = BitConverter.ToInt32(bytes, 0) & 0x7fffffff;
            return (number % 900000 + 100000).ToString();
        }

        private string GenerateAccessToken(User user)
        {
            var jwtKey = _config["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key is not configured");
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.AccountType ?? "user"),
                new Claim(ClaimTypes.Name, user.FullName ?? "")
            };

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(GetAccessTokenLifetimeMinutes()),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private int GetAccessTokenLifetimeMinutes()
        {
            var minutesStr = _config["Jwt:ExpiryMinutes"];
            if (int.TryParse(minutesStr, out var minutes) && minutes > 0)
                return minutes;

            // Fallback for older deployments that only set ExpiryDays
            var daysStr = _config["Jwt:ExpiryDays"];
            if (int.TryParse(daysStr, out var days) && days > 0)
                return days * 24 * 60;

            return 60;
        }

        private int GetAccessTokenLifetimeSeconds() => GetAccessTokenLifetimeMinutes() * 60;

        /// <summary>
        /// Long-lived refresh so mobile users stay signed in until logout or app uninstall.
        /// Tokens are hashed + rotated on each refresh; logout/password-reset revokes them.
        /// Default ~10 years (3650 days).
        /// </summary>
        private int GetRefreshTokenLifetimeDays()
        {
            var daysStr = _config["Jwt:RefreshTokenDays"];
            if (int.TryParse(daysStr, out var days) && days > 0)
                return days;
            return 3650;
        }

        private static string GenerateSecureToken()
        {
            var bytes = new byte[64];
            RandomNumberGenerator.Fill(bytes);
            return Convert.ToBase64String(bytes)
                .TrimEnd('=')
                .Replace('+', '-')
                .Replace('/', '_');
        }

        private static string HashToken(string token)
        {
            var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token));
            return Convert.ToHexString(hash);
        }
    }
}
