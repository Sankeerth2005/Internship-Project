using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;
using System.Linq;
using localink_be.Data;
using localink_be.Models.Entities;

namespace localink_be.Controllers
{
    [ApiController]
    [Route("api/v1/business/{businessId}/preview")]
    public class BusinessPreviewController : ControllerBase
    {
        private readonly AppDbContext _db;
        
        public BusinessPreviewController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> GetBusinessPreview(long businessId)
        {
            var business = await _db.Businesses
                .FirstOrDefaultAsync(b => b.BusinessId == businessId);

            if (business == null)
                return NotFound("Business not found");

            // Anonymous preview must not leak Pending/Rejected contact PII.
            var status = await _db.AdminDashboards
                .Where(a => a.BusinessId == businessId)
                .Select(a => (BusinessStatus?)a.Status)
                .FirstOrDefaultAsync();
            if (status != BusinessStatus.Approved && status != BusinessStatus.Active)
                return NotFound("Business not found");

            var category = await _db.Categories
                .Where(c => c.CategoryId == business.CategoryId)
                .Select(c => c.CategoryName)
                .FirstOrDefaultAsync();

            var subcategory = await _db.Subcategories
                .Where(s => s.SubcategoryId == business.SubcategoryId)
                .Select(s => s.SubcategoryName)
                .FirstOrDefaultAsync();

            var contact = await _db.BusinessContacts
                .FirstOrDefaultAsync(c => c.BusinessId == businessId);

            var hours = await _db.BusinessHours
                .Where(h => h.BusinessId == businessId)
                .Select(h => new
                {
                    h.DayOfWeek,
                    h.Mode,
                    Slots = _db.BusinessHourSlots
                        .Where(s => s.BusinessHourId == h.BusinessHourId)
                        .Select(s => new { s.OpenTime, s.CloseTime })
                        .ToList()
                }).ToListAsync();

            var photos = await _db.BusinessPhotos
                .Where(p => p.BusinessId == businessId)
                .OrderByDescending(p => p.IsPrimary)
                .Select(p => new { p.PhotoId, p.ImageUrl, p.IsPrimary })
                .ToListAsync();

            var result = new
            {
                BusinessInformation = new
                {
                    business.BusinessName,
                    business.Description,
                    Category = category,
                    Subcategory = subcategory
                },
                ContactDetails = contact == null ? null : new
                {
                    contact.PhoneCode,
                    contact.PhoneNumber,
                    contact.Email,
                    contact.Website,
                    contact.StreetAddress,
                    contact.City,
                    contact.State,
                    contact.Country,
                    contact.Pincode
                },
                BusinessHours = hours,
                BusinessPhotos = photos
            };

            return Ok(result);
        }
    }
}
