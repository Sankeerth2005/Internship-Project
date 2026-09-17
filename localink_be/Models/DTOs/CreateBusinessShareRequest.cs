using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class CreateSingleBusinessShareRequest
    {
        [Required]
        [Range(1, long.MaxValue)]
        public long BusinessId { get; set; }
    }

    public class CreateFavoritesShareRequest
    {
        /// <summary>When true, server snapshots all current favorites (ignores BusinessIds).</summary>
        public bool ShareAllFavorites { get; set; }

        /// <summary>Selected favorites when ShareAllFavorites is false.</summary>
        public List<long>? BusinessIds { get; set; }

        [MaxLength(120)]
        public string? Title { get; set; }

        [MaxLength(500)]
        public string? Note { get; set; }
    }
}
