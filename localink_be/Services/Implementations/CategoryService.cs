using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using localink_be.Data;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class CategoryService : ICategoryService
    {
        private readonly AppDbContext _context;

        public CategoryService(AppDbContext context)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
        }

        public async Task<List<CategoryDto>> GetCategoriesAsync()
        {
            try
            {
                var categories = await _context.Categories
                    .Select(c => new CategoryDto
                    {
                        Id = c.CategoryId,
                        Name = c.CategoryName,
                        IconUrl = c.IconUrl
                    })
                    .OrderBy(c => c.Name)
                    .ToListAsync();

                return categories; // Return empty list if none found
            }
            catch (Exception ex)
            {
                throw new Exception("Error fetching categories from database", ex);
            }
        }
    }
}