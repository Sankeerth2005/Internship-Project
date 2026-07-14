public class AdminUserDto
{
    public long UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string AccountType { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
}

public class AdminStatsDto
{
    public long TotalUsers { get; set; }
    public long TotalBusinesses { get; set; }
    public long ApprovedBusinesses { get; set; }
    public long PendingBusinesses { get; set; }
    public long TotalViews { get; set; }
    public long TotalClicks { get; set; }
    public long TotalReviews { get; set; }
    public double AverageRating { get; set; }
}
