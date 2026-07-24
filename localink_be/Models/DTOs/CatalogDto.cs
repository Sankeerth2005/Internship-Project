using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class CatalogDto
    {
        public int Id { get; set; }
        public long BusinessId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public List<CatalogItemDto> Items { get; set; } = new List<CatalogItemDto>();
    }

    public class CatalogItemDto
    {
        public int Id { get; set; }
        public int CatalogId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsAvailable { get; set; }
    }

    public class CreateCatalogDto
    {
        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(250)]
        public string? Description { get; set; }
    }

    public class CreateCatalogItemDto
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Description { get; set; }

        public decimal Price { get; set; }

        public bool IsAvailable { get; set; } = true;
    }
}
