public class ReviewResponseDto
{
    public long ReviewId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public string UserName { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? ImageUrl { get; set; }
}