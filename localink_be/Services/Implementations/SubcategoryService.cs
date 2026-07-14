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
    public class SubcategoryService : ISubcategoryService
    {
        private readonly AppDbContext _context;

        public SubcategoryService(AppDbContext context)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
        }

        public async Task<List<SubcategoryDto>> GetByCategoryIdAsync(int categoryId)
        {
            if (categoryId <= 0)
                throw new ArgumentException("CategoryId must be greater than 0");

            try
            {
                var subcategories = await _context.Subcategories
                    .Where(s => s.CategoryId == categoryId)
                    .Select(s => new SubcategoryDto
                    {
                        Id = s.SubcategoryId,
                        Name = s.SubcategoryName,
                        IconUrl = s.IconUrl,
                        Count = _context.Businesses.Count(b => b.SubcategoryId == s.SubcategoryId)
                    })
                    .OrderBy(s => s.Name)
                    .ToListAsync();

                return subcategories; // Return empty list if none found
            }
            catch (Exception ex)
            {
                throw new Exception($"Error fetching subcategories for categoryId {categoryId}", ex);
            }
        }
    }
}