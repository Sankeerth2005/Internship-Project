using System.ComponentModel.DataAnnotations;

public class FeedbackDto
{
    [Required(ErrorMessage = "Category is required")]
    public string Category { get; set; }

    [Required(ErrorMessage = "Feedback is required")]
    [MinLength(3, ErrorMessage = "Feedback message must be at least 3 characters long")]
    public string Feedback { get; set; }

    public int? UserId { get; set; }
}