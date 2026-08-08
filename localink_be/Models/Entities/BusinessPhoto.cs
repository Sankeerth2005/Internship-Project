using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace localink_be.Models.Entities
{
    [Table("business_photos")]
    public class BusinessPhoto
    {
        [Key]
        [Column("photo_id")]
        public long PhotoId { get; set; }

        [Column("business_id")]
        public long BusinessId { get; set; }

        /// <summary>
        /// Relative web path only (e.g. /uploads/businesses/{guid}.webp). Never stores binary or absolute disk paths.
        /// Kept as ImageUrl for API/backward compatibility; this is the RelativePath in the storage model.
        /// </summary>
        [Column("image_url")]
        public string ImageUrl { get; set; } = default!;

        /// <summary>Alias for ImageUrl — relative path stored in SQL.</summary>
        [NotMapped]
        public string RelativePath
        {
            get => ImageUrl;
            set => ImageUrl = value;
        }

        [Column("is_primary")]
        public bool IsPrimary { get; set; }

        /// <summary>Lower values display first. Primary photos are typically DisplayOrder = 0.</summary>
        [Column("display_order")]
        public int DisplayOrder { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; }

        public Business Business { get; set; } = null!;
    }
}
