namespace localink_be.Models.DTOs
{
    public class BusinessShareCreatedDto
    {
        public string PublicToken { get; set; } = null!;
        public string ShareKind { get; set; } = null!;
        public string ShareUrl { get; set; } = null!;
        public int ItemCount { get; set; }
    }

    public class SharedBusinessItemDto
    {
        public long BusinessId { get; set; }
        public int Position { get; set; }
        public bool IsAvailable { get; set; }
        public string? UnavailableReason { get; set; }
        public BusinessDto? Business { get; set; }
    }

    public class BusinessShareViewDto
    {
        public string PublicToken { get; set; } = null!;
        public string ShareKind { get; set; } = null!;
        public string Title { get; set; } = null!;
        public string? Note { get; set; }
        public string? SharedByDisplayName { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<SharedBusinessItemDto> Items { get; set; } = new();
    }
}
