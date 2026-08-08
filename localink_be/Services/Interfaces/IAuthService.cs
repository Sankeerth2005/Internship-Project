using System.Threading.Tasks;
using localink_be.Models.DTOs;

namespace localink_be.Services.Interfaces
{
    public interface IAuthService
    {
        Task<string> RegisterAsync(RegisterRequest request);
        Task<object> LoginAsync(LoginRequest request);
        Task<object> GoogleSignInAsync(string idToken);
        Task<object> RefreshSessionAsync(string refreshToken);
        Task LogoutAsync(string refreshToken);
        Task<string> VerifyEmailAsync(string email);
        Task<string> ResetPasswordAsync(ForgotPasswordRequest request);
        Task<string> SendResetOtpAsync(string email);
        Task<string> VerifyOtpAndResetPasswordAsync(string email, string otp, string newPassword);
        Task<string> ChangePasswordAsync(long userId, ChangePasswordRequest request);
    }
}
