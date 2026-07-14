using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class AuthService : IAuthService
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;
        private readonly IEmailService _emailService;
        private readonly ICaptchaService _captchaService;

        public AuthService(
            AppDbContext context,
            IConfiguration config,
            IEmailService emailService,
            ICaptchaService captchaService)
        {
            _context = context;
            _config = config;
            _emailService = emailService;
            _captchaService = captchaService;
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

                    user = new User
                    {
                        AccountType = request.UserType?.Trim().ToLower() ?? "user",
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
                Console.WriteLine($"Email failed: {ex.Message}");
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

        public async Task<string> ResetPasswordAsync(ForgotPasswordRequest request)
        {
            var email = request.Email.Trim().ToLower();

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
                throw new UnauthorizedAccessException("Invalid request");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword, 12);

            await _context.SaveChangesAsync();

            return "Password updated successfully";
        }

        public async Task<object> LoginAsync(LoginRequest request)
        {
            var isCaptchaValid = await _captchaService.VerifyAsync(request.CaptchaToken);
            if (!isCaptchaValid)
                throw new UnauthorizedAccessException("Captcha validation failed");

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

            var token = GenerateJwtToken(user);

            return new
            {
                token,
                user = new
                {
                    id = user.UserId.ToString(),
                    name = user.FullName,
                    email = user.Email,
                    userType = user.AccountType
                }
            };
        }

        public async Task<string> SendResetOtpAsync(string email, string captchaToken)
        {
            var isCaptchaValid = await _captchaService.VerifyAsync(captchaToken);
            if (!isCaptchaValid)
                throw new UnauthorizedAccessException("Captcha validation failed");

            var normalizedEmail = email.Trim().ToLower();

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == normalizedEmail);

            if (user == null)
                return "If the email exists, an OTP has been sent";

            if (user.OtpExpiry != null && user.OtpExpiry > DateTime.UtcNow.AddMinutes(-1))
                throw new InvalidOperationException("Please wait before requesting another OTP");

            var otp = GenerateOtp();

            user.PasswordResetOtp = otp;
            user.OtpExpiry = DateTime.UtcNow.AddMinutes(15);
            user.OtpAttempts = 0;

            await _context.SaveChangesAsync();

            // DEVELOPMENT ONLY: Log the OTP to the console so it can be retrieved without email configuration
            Console.WriteLine($"[DEVELOPMENT OTP] OTP for {email} is: {otp}");

            try
            {
                await _emailService.SendOtpEmailAsync(user.Email, otp);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Email failed: " + ex.Message);
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

            if (user.PasswordResetOtp != otp)
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

            await _context.SaveChangesAsync();

            return "Password reset successful";
        }

        private string GenerateOtp()
        {
            var bytes = new byte[4];
            using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
            rng.GetBytes(bytes);
            int number = BitConverter.ToInt32(bytes, 0) & 0x7fffffff;
            return (number % 900000 + 100000).ToString();
        }

        public async Task<object> GoogleSignInAsync(string idToken)
        {
            if (string.IsNullOrWhiteSpace(idToken))
                throw new ArgumentException("ID token is required");

            try
            {
                // Validate Google ID token
                var payload = await Google.Apis.Auth.GoogleJsonWebSignature.ValidateAsync(idToken);
                if (payload == null)
                    throw new UnauthorizedAccessException("Google token validation failed");

                var email = payload.Email.Trim().ToLower();
                var googleId = payload.Subject;

                // 1. Check if user already has this google_id linked
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.GoogleId == googleId);

                if (user == null)
                {
                    // 2. If not, check if user exists with the same email
                    user = await _context.Users
                        .FirstOrDefaultAsync(u => u.Email == email);

                    if (user != null)
                      {
                        // Link Google account to existing user
                        user.GoogleId = googleId;
                        await _context.SaveChangesAsync();
                    }
                    else
                    {
                        // 3. Register a new user
                        user = new User
                        {
                            FullName = payload.Name ?? "Google User",
                            Email = email,
                            GoogleId = googleId,
                            AccountType = "client", // Default type is client
                            PasswordHash = null,
                            CountryCode = "" // Default empty
                        };

                        await _context.Users.AddAsync(user);
                        await _context.SaveChangesAsync();

                        try
                        {
                            await _emailService.SendWelcomeEmailAsync(user.Email, user.FullName);
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine($"Welcome email failed: {ex.Message}");
                        }
                    }
                }

                var token = GenerateJwtToken(user);

                return new
                {
                    token,
                    user = new
                    {
                        id = user.UserId.ToString(),
                        name = user.FullName,
                        email = user.Email,
                        userType = user.AccountType
                    }
                };
            }
            catch (Exception ex)
            {
                throw new UnauthorizedAccessException($"Google authentication failed: {ex.Message}");
            }
        }

        private string GenerateJwtToken(User user)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));
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
                expires: DateTime.UtcNow.AddMinutes(Convert.ToDouble(_config["Jwt:ExpiryMinutes"])),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}