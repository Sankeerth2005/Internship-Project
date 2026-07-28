using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class ReviewRequestDto
    {
        [Required(ErrorMessage = "Business ID is required")]
        [Range(1, long.MaxValue, ErrorMessage = "Invalid Business ID")]
        public long BusinessId { get; set; }

        [Required(ErrorMessage = "Rating is required")]
        [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5")]
        public int Rating { get; set; }

        [StringLength(1000, MinimumLength = 5, ErrorMessage = "Comment must be between 5 and 1000 characters")]
        public string? Comment { get; set; }

        [StringLength(500000, ErrorMessage = "Image data too large")]
        public string? Image { get; set; }
    }
}