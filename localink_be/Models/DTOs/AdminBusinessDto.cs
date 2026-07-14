public class AdminBusinessDto
{
    public long Id { get; set; }
    public string Name { get; set; }
    public string Category { get; set; }

    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? Address { get; set; }
    public string? Description { get; set; }
    public string Status { get; set; }
    public string? RejectionComment { get; set; }

    public bool IsTemporaryClosurePending { get; set; }
    public string? TemporaryClosureReason { get; set; }
    public int? TemporaryClosureDays { get; set; }
    public string? OwnerName { get; set; }
}