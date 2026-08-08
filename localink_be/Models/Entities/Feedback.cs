public class Feedback
{
    public int Id { get; set; }
    public string Message { get; set; } = string.Empty;
    public int? UserId { get; set; }
    public DateTime CreatedAt { get; set; }
}