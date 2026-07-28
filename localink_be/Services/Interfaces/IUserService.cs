using localink_be.Models.DTOs;

public interface IUserService
{
    Task<UserProfileDto?> GetUserProfileAsync(long userId);
    Task<bool> UpdateUserProfileAsync(long userId, UpdateUserProfileDto dto);
}