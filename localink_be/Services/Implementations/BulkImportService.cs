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
        private const int BatchSize = 75;
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

                // Accumulate graphs in memory; attach + SaveChanges only at batch boundaries.
                var pending = new List<(CsvBusinessRecord Record, Business Business, BusinessContact Contact)>(BatchSize);

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

                        if (string.IsNullOrWhiteSpace(record.Phone) ||
                            record.Phone.Trim('0').Length == 0 ||
                            record.Phone.Length < 7)
                        {
                            result.FailureCount++;
                            result.Errors.Add($"Skipped '{record.Name}': valid phone required (placeholder phones rejected).");
                            continue;
                        }

                        if (record.Latitude.HasValue || record.Longitude.HasValue)
                        {
                            if (!record.Latitude.HasValue || !record.Longitude.HasValue ||
                                record.Latitude is < -90 or > 90 ||
                                record.Longitude is < -180 or > 180 ||
                                (record.Latitude == 0 && record.Longitude == 0))
                            {
                                result.FailureCount++;
                                result.Errors.Add($"Skipped '{record.Name}': invalid coordinates (bounds/(0,0)).");
                                continue;
                            }
                        }

                        long ownerId = fallbackUserId;
                        if (!string.IsNullOrWhiteSpace(record.Email))
                        {
                            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == record.Email);
                            if (user != null)
                                ownerId = user.UserId;
                        }

                        var cat = await _context.Categories.FirstOrDefaultAsync(c => c.CategoryName == record.Category);
                        int catId = cat?.CategoryId ?? 1;

                        var subcat = await _context.Subcategories.FirstOrDefaultAsync(s => s.SubcategoryName == record.Subcategory);
                        int subcatId = subcat?.SubcategoryId ?? 1;

                        var (business, contact) = BuildBusinessGraph(record, ownerId, catId, subcatId, adminUser?.UserId);
                        pending.Add((record, business, contact));

                        if (pending.Count >= BatchSize)
                        {
                            await FlushBatchAsync(result, pending);
                            pending.Clear();
                        }
                    }
                    catch (Exception ex)
                    {
                        result.FailureCount++;
                        result.Errors.Add($"Error importing {record.Name}: {ex.Message}");
                    }
                }

                if (pending.Count > 0)
                {
                    await FlushBatchAsync(result, pending);
                    pending.Clear();
                }
            }
            catch (Exception ex)
            {
                result.Errors.Add($"Failed to parse CSV file: {ex.Message}");
            }

            return result;
        }

        private static (Business Business, BusinessContact Contact) BuildBusinessGraph(
            CsvBusinessRecord record,
            long ownerId,
            int catId,
            int subcatId,
            long? adminUserId)
        {
            var business = new Business
            {
                UserId = ownerId,
                BusinessName = record.Name!,
                CategoryId = catId,
                SubcategoryId = subcatId,
                Description = record.Description ?? "Imported Business",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            business.AdminDashboard = new AdminDashboard
            {
                Business = business,
                Status = BusinessStatus.Approved,
                ActionBy = adminUserId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            // Contact linked via Business navigation so one SaveChanges persists the graph.
            var contact = new BusinessContact
            {
                Business = business,
                Email = record.Email ?? throw new ArgumentException("Email is required for import"),
                PhoneNumber = record.Phone!,
                PhoneCode = string.IsNullOrWhiteSpace(record.PhoneCode) ? "+1" : record.PhoneCode.Trim(),
                Website = record.Website ?? string.Empty,
                StreetAddress = record.Address ?? throw new ArgumentException("Address is required for import"),
                City = record.City ?? throw new ArgumentException("City is required for import"),
                State = record.State ?? throw new ArgumentException("State is required for import"),
                Country = record.Country ?? throw new ArgumentException("Country is required for import"),
                Pincode = record.Pincode ?? throw new ArgumentException("Pincode is required for import"),
                Latitude = record.Latitude,
                Longitude = record.Longitude,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            return (business, contact);
        }

        private async Task FlushBatchAsync(
            BulkImportResultDto result,
            List<(CsvBusinessRecord Record, Business Business, BusinessContact Contact)> pending)
        {
            foreach (var item in pending)
            {
                _context.Businesses.Add(item.Business);
                _context.BusinessContacts.Add(item.Contact);
            }

            try
            {
                await _context.SaveChangesAsync();
                result.SuccessCount += pending.Count;
                _context.ChangeTracker.Clear();
            }
            catch (Exception batchEx)
            {
                _context.ChangeTracker.Clear();
                result.Errors.Add($"Batch save failed, retrying row-by-row: {batchEx.Message}");

                foreach (var item in pending)
                {
                    try
                    {
                        var (business, contact) = BuildBusinessGraph(
                            item.Record,
                            item.Business.UserId,
                            item.Business.CategoryId,
                            item.Business.SubcategoryId,
                            item.Business.AdminDashboard?.ActionBy);

                        _context.Businesses.Add(business);
                        _context.BusinessContacts.Add(contact);
                        await _context.SaveChangesAsync();
                        _context.ChangeTracker.Clear();
                        result.SuccessCount++;
                    }
                    catch (Exception rowEx)
                    {
                        _context.ChangeTracker.Clear();
                        result.FailureCount++;
                        result.Errors.Add($"Error importing {item.Record.Name}: {rowEx.Message}");
                    }
                }
            }
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
        public string? PhoneCode { get; set; }
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
