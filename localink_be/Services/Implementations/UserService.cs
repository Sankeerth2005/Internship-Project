using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;
using localink_be.Validation;

namespace localink_be.Services.Implementations
{
public class UserService : IUserService
{
    private readonly AppDbContext _db;
    private readonly IBusinessPincodeService _pincodeService;
    private readonly IBusinessLocationService _locationService;
    private readonly Microsoft.Extensions.Logging.ILogger<UserService> _logger;

    public UserService(
        AppDbContext db, 
        IBusinessPincodeService pincodeService, 
        IBusinessLocationService locationService,
        Microsoft.Extensions.Logging.ILogger<UserService> logger)
    {
        _db = db;
        _pincodeService = pincodeService;
        _locationService = locationService;
        _logger = logger;
    }

    public async Task<UserProfileDto?> GetUserProfileAsync(long userId)
    {
        var user = await _db.Users
            .Where(u => u.UserId == userId)
            .Select(u => new UserProfileDto
            {
                UserId = u.UserId,
                FullName = u.FullName,
                Email = u.Email,
                Phone = u.PhoneNumber ?? string.Empty,
                CountryCode = u.CountryCode,
                ProfilePicture = u.ProfilePicture,

                Address = _db.Addresses
                    .Where(a => a.UserId == u.UserId)
                    .Select(a => new AddressDto
                    {
                        Street = a.StreetAddress,
                        City = a.City,
                        State = a.State,
                        Country = a.Country,
                        Pincode = a.Pincode
                    })
                    .FirstOrDefault() ?? new AddressDto()
            })
            .FirstOrDefaultAsync();

        return user;
    }

    public async Task<bool> UpdateUserProfileAsync(long userId, UpdateUserProfileDto dto)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.UserId == userId);
        if (user == null)
            return false;

        // 1. Phone number uniqueness + country-aware format
        if (!string.IsNullOrWhiteSpace(dto.Phone))
        {
            PhoneNumberGuard.EnsureValid(dto.Phone, dto.CountryCode, dto.Address?.Country);
            var nationalPhone = PhoneNumberGuard.NationalNumber(dto.Phone, dto.CountryCode);

            var phoneExists = await _db.Users.AnyAsync(u => u.PhoneNumber == nationalPhone && u.UserId != userId);
            if (phoneExists)
            {
                throw new InvalidOperationException("Phone number is already associated with another account.");
            }

            user.PhoneNumber = nationalPhone;
        }

        if (!string.IsNullOrWhiteSpace(dto.CountryCode))
        {
            user.CountryCode = PhoneNumberGuard.FormatCallingCode(dto.CountryCode);
        }

        // 2. Validate Country, State, City, and Pincode are not empty
        if (dto.Address == null || 
            string.IsNullOrWhiteSpace(dto.Address.Country) || 
            string.IsNullOrWhiteSpace(dto.Address.State) || 
            string.IsNullOrWhiteSpace(dto.Address.City) || 
            string.IsNullOrWhiteSpace(dto.Address.Pincode))
        {
            throw new ArgumentException("Country, State, City, and Pincode are all required.");
        }

        // Cascading address validation (Country -> State -> City) using CSC API
        var isValidLocation = await _locationService.ValidateAddressAsync(
            dto.Address.Country.Trim(),
            dto.Address.State.Trim(),
            dto.Address.City.Trim()
        );

        if (!isValidLocation)
        {
            throw new ArgumentException("The specified Country, State, and City combination is invalid.");
        }

        PincodeGuard.EnsureValid(dto.Address.Pincode, dto.Address.Country, required: true);
        var cleanPincode = dto.Address.Pincode.Trim();

        // Validate pincode existence via Geoapify API
        try
        {
            var pincodeDataJson = await _pincodeService.GetPincodeData(cleanPincode);
            using var doc = System.Text.Json.JsonDocument.Parse(pincodeDataJson);
            if (doc.RootElement.TryGetProperty("features", out var features))
            {
                if (features.GetArrayLength() == 0)
                {
                    throw new ArgumentException("Pincode does not exist or is invalid.");
                }

                // Verify state matches
                var firstFeature = features[0];
                if (firstFeature.TryGetProperty("properties", out var props))
                {
                    string? geocodedState = null;
                    if (props.TryGetProperty("state", out var stateProp))
                        geocodedState = stateProp.GetString();

                    if (!string.IsNullOrEmpty(geocodedState) && 
                        !geocodedState.Contains(dto.Address.State.Trim(), StringComparison.OrdinalIgnoreCase) &&
                        !dto.Address.State.Trim().Contains(geocodedState, StringComparison.OrdinalIgnoreCase))
                    {
                        throw new ArgumentException($"The pincode {cleanPincode} belongs to state '{geocodedState}', not '{dto.Address.State}'.");
                    }
                }
            }
        }
        catch (Exception ex) when (!(ex is ArgumentException) && !(ex is InvalidOperationException))
        {
            _logger.LogWarning("Skipped deep pincode validation due to API error: {Message}", ex.Message);
        }

        user.FullName = dto.FullName;
        if (!string.IsNullOrEmpty(dto.Email))
        {
            user.Email = dto.Email;
        }
        if (dto.ProfilePicture != null)
        {
            user.ProfilePicture = dto.ProfilePicture;
        }

        var address = await _db.Addresses.FirstOrDefaultAsync(a => a.UserId == userId);

        if (address == null)
        {
            address = new Address
            {
                UserId = userId,
                StreetAddress = dto.Address.Street ?? string.Empty,
                City = dto.Address.City ?? string.Empty,
                State = dto.Address.State ?? string.Empty,
                Country = dto.Address.Country ?? string.Empty,
                Pincode = dto.Address.Pincode ?? string.Empty
            };

            _db.Addresses.Add(address);
        }
        else
        {
            address.StreetAddress = dto.Address.Street ?? string.Empty;
            address.City = dto.Address.City ?? string.Empty;
            address.State = dto.Address.State ?? string.Empty;
            address.Country = dto.Address.Country ?? string.Empty;
            address.Pincode = dto.Address.Pincode ?? string.Empty;
        }

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteUserAccountAsync(long userId)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.UserId == userId);
        if (user == null)
            return false;

        var ownedBusinessIds = await _db.Businesses
            .Where(b => b.UserId == userId)
            .Select(b => b.BusinessId)
            .ToListAsync();

        // --- Owned businesses: clear children before removing business rows ---
        if (ownedBusinessIds.Count > 0)
        {
            var ownerConversationIds = await _db.Conversations
                .Where(c => ownedBusinessIds.Contains(c.BusinessId))
                .Select(c => c.Id)
                .ToListAsync();

            if (ownerConversationIds.Count > 0)
            {
                await _db.Messages
                    .Where(m => ownerConversationIds.Contains(m.ConversationId))
                    .ExecuteDeleteAsync();
                await _db.Conversations
                    .Where(c => ownerConversationIds.Contains(c.Id))
                    .ExecuteDeleteAsync();
            }

            var catalogIds = await _db.Catalogs
                .Where(c => ownedBusinessIds.Contains(c.BusinessId))
                .Select(c => c.Id)
                .ToListAsync();

            if (catalogIds.Count > 0)
            {
                await _db.CatalogItems
                    .Where(i => catalogIds.Contains(i.CatalogId))
                    .ExecuteDeleteAsync();
                await _db.Catalogs
                    .Where(c => catalogIds.Contains(c.Id))
                    .ExecuteDeleteAsync();
            }

            await _db.Favorites
                .Where(f => ownedBusinessIds.Contains(f.BusinessId))
                .ExecuteDeleteAsync();

            await _db.BusinessReviews
                .Where(r => ownedBusinessIds.Contains(r.BusinessId))
                .ExecuteDeleteAsync();

            var hourIds = await _db.BusinessHours
                .Where(h => ownedBusinessIds.Contains(h.BusinessId))
                .Select(h => h.BusinessHourId)
                .ToListAsync();

            if (hourIds.Count > 0)
            {
                await _db.BusinessHourSlots
                    .Where(s => hourIds.Contains(s.BusinessHourId))
                    .ExecuteDeleteAsync();
                await _db.BusinessHours
                    .Where(h => hourIds.Contains(h.BusinessHourId))
                    .ExecuteDeleteAsync();
            }

            await _db.BusinessPhotos
                .Where(p => ownedBusinessIds.Contains(p.BusinessId))
                .ExecuteDeleteAsync();

            await _db.BusinessContacts
                .Where(c => ownedBusinessIds.Contains(c.BusinessId))
                .ExecuteDeleteAsync();

            await _db.BusinessMetrics
                .Where(m => ownedBusinessIds.Contains(m.BusinessId))
                .ExecuteDeleteAsync();

            await _db.AdminDashboards
                .Where(a => ownedBusinessIds.Contains(a.BusinessId))
                .ExecuteDeleteAsync();

            await _db.Businesses
                .Where(b => ownedBusinessIds.Contains(b.BusinessId))
                .ExecuteDeleteAsync();
        }

        // --- User-scoped rows (as customer / profile) ---
        var userConversationIds = await _db.Conversations
            .Where(c => c.UserId == userId)
            .Select(c => c.Id)
            .ToListAsync();

        if (userConversationIds.Count > 0)
        {
            await _db.Messages
                .Where(m => userConversationIds.Contains(m.ConversationId))
                .ExecuteDeleteAsync();
            await _db.Conversations
                .Where(c => userConversationIds.Contains(c.Id))
                .ExecuteDeleteAsync();
        }

        await _db.Favorites.Where(f => f.UserId == userId).ExecuteDeleteAsync();
        await _db.BusinessReviews.Where(r => r.UserId == userId).ExecuteDeleteAsync();
        await _db.Addresses.Where(a => a.UserId == userId).ExecuteDeleteAsync();
        await _db.RefreshTokens.Where(t => t.UserId == userId).ExecuteDeleteAsync();

        // Feedback.UserId is int? — clear matching rows defensively
        if (userId <= int.MaxValue)
        {
            var feedbackUserId = (int)userId;
            await _db.Feedbacks.Where(f => f.UserId == feedbackUserId).ExecuteDeleteAsync();
        }

        _db.Users.Remove(user);
        await _db.SaveChangesAsync();
        return true;
    }
}
}