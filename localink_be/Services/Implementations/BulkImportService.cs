using System.Globalization;
using CsvHelper;
using CsvHelper.Configuration;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class BulkImportService : IBulkImportService
    {
        private readonly AppDbContext _context;

        public BulkImportService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<BulkImportResultDto> ProcessBulkImportAsync(IFormFile csvFile)
        {
            var result = new BulkImportResultDto();

            if (csvFile == null || csvFile.Length == 0)
            {
                result.Errors.Add("No file uploaded or file is empty.");
                return result;
            }

            try
            {
                using var stream = csvFile.OpenReadStream();
                using var reader = new StreamReader(stream);
                using var csv = new CsvReader(reader, new CsvConfiguration(CultureInfo.InvariantCulture)
                {
                    HasHeaderRecord = true,
                    HeaderValidated = null,
                    MissingFieldFound = null,
                    IgnoreBlankLines = true,
                    TrimOptions = TrimOptions.Trim
                });

                var records = csv.GetRecords<CsvBusinessRecord>().ToList();

                var adminUser = await _context.Users.FirstOrDefaultAsync(u => u.AccountType == "admin");
                long fallbackUserId = adminUser?.UserId ?? 1;

                foreach (var record in records)
                {
                    try
                    {
                        if (string.IsNullOrWhiteSpace(record.Name) || string.IsNullOrWhiteSpace(record.Category))
                        {
                            result.FailureCount++;
                            result.Errors.Add($"Skipped record due to missing Name or Category: {record.Name}");
                            continue;
                        }

                        // Try find existing owner by email if provided
                        long ownerId = fallbackUserId;
                        if (!string.IsNullOrWhiteSpace(record.Email))
                        {
                            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == record.Email);
                            if (user != null)
                            {
                                ownerId = user.UserId;
                            }
                        }

                        // Try finding Category ID
                        var cat = await _context.Categories.FirstOrDefaultAsync(c => c.CategoryName == record.Category);
                        int catId = cat?.CategoryId ?? 1;

                        var subcat = await _context.Subcategories.FirstOrDefaultAsync(s => s.SubcategoryName == record.Subcategory);
                        int subcatId = subcat?.SubcategoryId ?? 1;

                        var business = new Business
                        {
                            UserId = ownerId,
                            BusinessName = record.Name,
                            CategoryId = catId,
                            SubcategoryId = subcatId,
                            Description = record.Description ?? "Imported Business",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };

                        _context.Businesses.Add(business);
                        await _context.SaveChangesAsync(); 

                        var contact = new BusinessContact
                        {
                            BusinessId = business.BusinessId,
                            Email = record.Email ?? "no-email@example.com",
                            PhoneNumber = record.Phone ?? "0000000000",
                            PhoneCode = "+1", // Default if omitted
                            Website = record.Website ?? string.Empty,
                            StreetAddress = record.Address ?? "Unknown Address",
                            City = record.City ?? "Unknown City",
                            State = record.State ?? "Unknown State",
                            Country = record.Country ?? "Unknown Country",
                            Pincode = record.Pincode ?? "000000",
                            Latitude = record.Latitude,
                            Longitude = record.Longitude,
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };
                        _context.BusinessContacts.Add(contact);
                        
                        var dashboard = new AdminDashboard
                        {
                            BusinessId = business.BusinessId,
                            Status = BusinessStatus.Approved,
                            ActionBy = adminUser?.UserId,
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };
                        _context.AdminDashboards.Add(dashboard);

                        await _context.SaveChangesAsync();
                        result.SuccessCount++;
                    }
                    catch (Exception ex)
                    {
                        result.FailureCount++;
                        result.Errors.Add($"Error importing {record.Name}: {ex.Message}");
                    }
                }
            }
            catch (Exception ex)
            {
                result.Errors.Add($"Failed to parse CSV file: {ex.Message}");
            }

            return result;
        }
    }

    public class CsvBusinessRecord
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public string? Category { get; set; }
        public string? Subcategory { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string? Website { get; set; }
        public string? Address { get; set; }
        public string? City { get; set; }
        public string? State { get; set; }
        public string? Country { get; set; }
        public string? Pincode { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
    }
}
