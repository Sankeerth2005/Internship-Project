using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
public class UserService : IUserService
{
    private readonly AppDbContext _db;
    private readonly IBusinessPincodeService _pincodeService;
    private readonly Microsoft.Extensions.Logging.ILogger<UserService> _logger;

    public UserService(
        AppDbContext db, 
        IBusinessPincodeService pincodeService, 
        Microsoft.Extensions.Logging.ILogger<UserService> logger)
    {
        _db = db;
        _pincodeService = pincodeService;
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
                Phone = u.PhoneNumber,

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

        // 1. Phone number uniqueness validation
        if (!string.IsNullOrWhiteSpace(dto.Phone))
        {
            var phoneExists = await _db.Users.AnyAsync(u => u.PhoneNumber == dto.Phone && u.UserId != userId);
            if (phoneExists)
            {
                throw new InvalidOperationException("Phone number is already associated with another account.");
            }
            user.PhoneNumber = dto.Phone;
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

        // 3. Indian pincode validation (exactly 6 digits and numeric)
        var cleanPincode = dto.Address.Pincode.Trim();
        if (dto.Address.Country.ToLower().Contains("india") && (cleanPincode.Length != 6 || !int.TryParse(cleanPincode, out _)))
        {
            throw new ArgumentException("Invalid Pincode. Indian pincodes must be exactly 6 digits.");
        }

        // 4. Validate pincode existence via Geoapify API
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

        var address = await _db.Addresses.FirstOrDefaultAsync(a => a.UserId == userId);

        if (address == null)
        {
            address = new Address
            {
                UserId = userId,
                StreetAddress = dto.Address.Street,
                City = dto.Address.City,
                State = dto.Address.State,
                Country = dto.Address.Country,
                Pincode = dto.Address.Pincode
            };

            _db.Addresses.Add(address);
        }
        else
        {
            address.StreetAddress = dto.Address.Street;
            address.City = dto.Address.City;
            address.State = dto.Address.State;
            address.Country = dto.Address.Country;
            address.Pincode = dto.Address.Pincode;
        }

        await _db.SaveChangesAsync();
        return true;
    }
}
}