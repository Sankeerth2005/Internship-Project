using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace localink_be.Models.Entities
{
    public class RefreshToken
    {
        [Key]
        public long Id { get; set; }

        public long UserId { get; set; }

        /// <summary>SHA-256 hash of the opaque refresh token. Never store plaintext.</summary>
        [Required]
        [MaxLength(128)]
        public string TokenHash { get; set; } = null!;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime ExpiresAt { get; set; }

        public DateTime? RevokedAt { get; set; }

        [MaxLength(128)]
        public string? ReplacedByTokenHash { get; set; }

        [MaxLength(64)]
        public string? DeviceInfo { get; set; }

        [ForeignKey(nameof(UserId))]
        public User? User { get; set; }

        [NotMapped]
        public bool IsActive => RevokedAt == null && ExpiresAt > DateTime.UtcNow;
    }
}
