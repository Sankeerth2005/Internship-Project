using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class FeedbackDto
    {
        [Required(ErrorMessage = "Category is required")]
        [RegularExpression(@"^(Feedback|Complaint|Request|Inquiry)$", ErrorMessage = "Category must be Feedback, Complaint, Request, or Inquiry")]
        public string Category { get; set; } = string.Empty;

        [Required(ErrorMessage = "Feedback is required")]
        [StringLength(5000, MinimumLength = 10, ErrorMessage = "Feedback must be between 10 and 5000 characters")]
        public string Feedback { get; set; } = string.Empty;

        public int? UserId { get; set; }
    }
}