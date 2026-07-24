using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using localink_be.Models.Entities;

namespace localink_be.Data.Models
{
    public class Catalog
    {
        [Key]
        public int Id { get; set; }

        public long BusinessId { get; set; }

        [ForeignKey("BusinessId")]
        [JsonIgnore]
        public Business? Business { get; set; }

        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(250)]
        public string? Description { get; set; }

        public ICollection<CatalogItem> Items { get; set; } = new List<CatalogItem>();
    }

    public class CatalogItem
    {
        [Key]
        public int Id { get; set; }

        public int CatalogId { get; set; }

        [ForeignKey("CatalogId")]
        [JsonIgnore]
        public Catalog? Catalog { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Description { get; set; }

        public decimal Price { get; set; }

        [MaxLength(250)]
        public string? ImageUrl { get; set; }

        public bool IsAvailable { get; set; } = true;
    }
}
