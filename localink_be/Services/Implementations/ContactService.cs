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
    public class ContactService : IContactService
    {
        private readonly AppDbContext _db;
        private readonly Microsoft.Extensions.Logging.ILogger<ContactService> _logger;

        public ContactService(AppDbContext db, Microsoft.Extensions.Logging.ILogger<ContactService> logger)
        {
            _db = db ?? throw new ArgumentNullException(nameof(db));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        // ADD CONTACT (used during registration)
        public async Task AddContactAsync(RegisterBusinessDto dto, long businessId)
        {
            if (string.IsNullOrWhiteSpace(dto.PhoneCode) || string.IsNullOrWhiteSpace(dto.PhoneNumber))
                throw new ArgumentException("Phone code and number required");

            if (dto.Latitude.HasValue || dto.Longitude.HasValue)
            {
                var lat = dto.Latitude;
                var lng = dto.Longitude;
                if (!lat.HasValue || !lng.HasValue)
                {
                    _logger.LogWarning("Coordinates validation failed for business registration BusinessId={BusinessId}: both latitude and longitude must be provided together.", businessId);
                    throw new ArgumentException("Both latitude and longitude must be provided together.");
                }
                if (lat < -90.0 || lat > 90.0 || double.IsNaN(lat.Value) || double.IsInfinity(lat.Value))
                {
                    _logger.LogWarning("Coordinates validation failed for business registration BusinessId={BusinessId}: latitude {Latitude} out of bounds.", businessId, lat);
                    throw new ArgumentException("Latitude must be a valid number between -90 and 90.");
                }
                if (lng < -180.0 || lng > 180.0 || double.IsNaN(lng.Value) || double.IsInfinity(lng.Value))
                {
                    _logger.LogWarning("Coordinates validation failed for business registration BusinessId={BusinessId}: longitude {Longitude} out of bounds.", businessId, lng);
                    throw new ArgumentException("Longitude must be a valid number between -180 and 180.");
                }
                if (lat == 0.0 && lng == 0.0)
                {
                    _logger.LogWarning("Coordinates validation failed for business registration BusinessId={BusinessId}: coordinates cannot be (0,0).", businessId);
                    throw new ArgumentException("Coordinates (0,0) are invalid.");
                }
            }

            _logger.LogInformation("Saving new contact for BusinessId {BusinessId} with coordinates Lat={Latitude}, Lng={Longitude}", 
                businessId, dto.Latitude, dto.Longitude);

            var contact = new BusinessContact
            {
                BusinessId = businessId,
                PhoneCode = dto.PhoneCode,
                PhoneNumber = dto.PhoneNumber,
                Email = dto.Email,
                Website = dto.Website,
                StreetAddress = dto.Address,
                City = dto.City,
                State = dto.State,
                Country = dto.Country,
                Pincode = dto.Pincode,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.BusinessContacts.Add(contact);
            await _db.SaveChangesAsync();
        }

        public async Task<BusinessContact?> UpdateContactAsync(long businessId, BusinessContact updated)
        {
            var existing = await _db.BusinessContacts
                .FirstOrDefaultAsync(c => c.BusinessId == businessId);

            if (existing == null) return null;

            if (updated.Latitude.HasValue || updated.Longitude.HasValue)
            {
                var lat = updated.Latitude;
                var lng = updated.Longitude;
                if (!lat.HasValue || !lng.HasValue)
                {
                    _logger.LogWarning("Coordinates validation failed for business update BusinessId={BusinessId}: both latitude and longitude must be provided together.", businessId);
                    throw new ArgumentException("Both latitude and longitude must be provided together.");
                }
                if (lat < -90.0 || lat > 90.0 || double.IsNaN(lat.Value) || double.IsInfinity(lat.Value))
                {
                    _logger.LogWarning("Coordinates validation failed for business update BusinessId={BusinessId}: latitude {Latitude} out of bounds.", businessId, lat);
                    throw new ArgumentException("Latitude must be a valid number between -90 and 90.");
                }
                if (lng < -180.0 || lng > 180.0 || double.IsNaN(lng.Value) || double.IsInfinity(lng.Value))
                {
                    _logger.LogWarning("Coordinates validation failed for business update BusinessId={BusinessId}: longitude {Longitude} out of bounds.", businessId, lng);
                    throw new ArgumentException("Longitude must be a valid number between -180 and 180.");
                }
                if (lat == 0.0 && lng == 0.0)
                {
                    _logger.LogWarning("Coordinates validation failed for business update BusinessId={BusinessId}: coordinates cannot be (0,0).", businessId);
                    throw new ArgumentException("Coordinates (0,0) are invalid.");
                }
            }

            _logger.LogInformation("Updating contact for BusinessId {BusinessId} with coordinates Lat={Latitude}, Lng={Longitude}", 
                businessId, updated.Latitude, updated.Longitude);

            existing.PhoneCode = updated.PhoneCode;
            existing.PhoneNumber = updated.PhoneNumber;
            existing.Email = updated.Email;
            existing.Website = updated.Website;
            existing.StreetAddress = updated.StreetAddress;
            existing.City = updated.City;
            existing.State = updated.State;
            existing.Country = updated.Country;
            existing.Pincode = updated.Pincode;
            existing.Latitude = updated.Latitude;
            existing.Longitude = updated.Longitude;
            existing.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            return existing;
        }

        public async Task<bool> DeleteContactAsync(long contactId)
        {
            var contact = await _db.BusinessContacts.FindAsync(contactId);
            if (contact == null) return false;

            _db.BusinessContacts.Remove(contact);
            await _db.SaveChangesAsync();
            return true;
        }

        public async Task<object?> GetContactByBusinessIdAsync(long businessId)
        {
            var contact = await _db.BusinessContacts
                .Where(c => c.BusinessId == businessId)
                .Select(c => new
                {
                    c.ContactId,
                    c.BusinessId,
                    c.PhoneCode,
                    c.PhoneNumber,
                    c.Email,
                    c.Website,
                    c.StreetAddress,
                    c.City,
                    c.State,
                    c.Country,
                    c.Pincode,
                    c.Latitude,
                    c.Longitude,
                    c.CreatedAt,
                    c.UpdatedAt
                }).FirstOrDefaultAsync();

            return contact; 
        }
    }
}
