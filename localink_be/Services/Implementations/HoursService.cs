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
    public class HoursService : IHoursService
    {
        private readonly AppDbContext _db;

        public HoursService(AppDbContext db)
        {
            _db = db;
        }

        public async Task<bool> CreateOrReplaceBusinessHoursAsync(long businessId, BusinessHoursDto dto)
        {
            var businessExists = await _db.Businesses.AnyAsync(b => b.BusinessId == businessId);
            if (!businessExists) return false;

            // Remove existing hours
            var existingHours = _db.BusinessHours.Where(b => b.BusinessId == businessId);
            _db.BusinessHours.RemoveRange(existingHours);
            await _db.SaveChangesAsync();

            // Add new hours
            foreach (var day in dto.Days)
            {
                var businessHour = new BusinessHour
                {
                    BusinessId = businessId,
                    DayOfWeek = day.DayOfWeek,
                    Mode = day.Mode,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _db.BusinessHours.Add(businessHour);
                await _db.SaveChangesAsync();

                var modeLower = day.Mode?.ToLower() ?? "";
                if (modeLower == "custom" || modeLower == "open" || modeLower == "regular")
                {
                    if (modeLower == "custom" && (day.Slots == null || !day.Slots.Any()))
                        throw new ArgumentException($"Slots required for {day.DayOfWeek}");

                    if (day.Slots != null && day.Slots.Any())
                    {
                        var sortedSlots = day.Slots.OrderBy(s => s.OpenTime).ToList();

                        for (int i = 0; i < sortedSlots.Count - 1; i++)
                        {
                            if (sortedSlots[i].CloseTime > sortedSlots[i + 1].OpenTime)
                                throw new ArgumentException($"Overlapping slots on {day.DayOfWeek}");
                        }

                        foreach (var slot in sortedSlots)
                        {
                            _db.BusinessHourSlots.Add(new BusinessHourSlot
                            {
                                BusinessHourId = businessHour.BusinessHourId,
                                OpenTime = slot.OpenTime,
                                CloseTime = slot.CloseTime,
                                CreatedAt = DateTime.UtcNow
                            });
                        }
                    }
                }
            }

            await _db.SaveChangesAsync();
            return true;
        }

        public async Task<List<object>> GetBusinessHoursAsync(long businessId)
        {
            var result = await _db.BusinessHours
                .Where(b => b.BusinessId == businessId)
                .Select(b => new
                {
                    b.DayOfWeek,
                    b.Mode,
                    Slots = _db.BusinessHourSlots
                        .Where(s => s.BusinessHourId == b.BusinessHourId)
                        .Select(s => new { s.OpenTime, s.CloseTime })
                        .ToList()
                })
                .ToListAsync<object>();

            return result;
        }

        public async Task AddHoursAsync(List<DayHoursDto> hours, long businessId)
        {
            foreach (var day in hours)
            {
                var businessHour = new BusinessHour
                {
                    BusinessId = businessId,
                    DayOfWeek = day.DayOfWeek,
                    Mode = day.Mode,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _db.BusinessHours.Add(businessHour);
                await _db.SaveChangesAsync();

                var modeLower = day.Mode?.ToLower() ?? "";
                if ((modeLower == "custom" || modeLower == "open" || modeLower == "regular") && day.Slots != null)
                {
                    foreach (var slot in day.Slots)
                    {
                        _db.BusinessHourSlots.Add(new BusinessHourSlot
                        {
                            BusinessHourId = businessHour.BusinessHourId,
                            OpenTime = slot.OpenTime,
                            CloseTime = slot.CloseTime,
                            CreatedAt = DateTime.UtcNow
                        });
                    }
                }
            }

            await _db.SaveChangesAsync();
        }
    }
}
