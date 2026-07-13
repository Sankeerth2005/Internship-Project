using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace localink_be.Models.Entities
{
    [Table("business_metric")]
    public class BusinessMetric
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("business_id")]
        [Required]
        public long BusinessId { get; set; }

        [Column("views")]
        public int Views { get; set; } = 0;

        [Column("favorites_count")]
        public int FavoritesCount { get; set; } = 0;

        [Column("contact_clicks")]
        public int ContactClicks { get; set; } = 0;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("BusinessId")]
        public Business Business { get; set; } = null!;
    }
}
