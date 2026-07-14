using System;

namespace localink_be.Models.Entities
{
    public class BusinessReview
    {
        public long ReviewId { get; set; }
        public long BusinessId { get; set; }
        public long UserId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public string? ImageUrl { get; set; }

        public User User { get; set; }  
    }
}