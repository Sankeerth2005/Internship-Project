using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace localink_be.Models.Entities
{
    /// <summary>
    /// Verified referral attribution: one row per successfully registered referred user.
    /// Inserted only by backend registration logic — never by client increment APIs.
    /// </summary>
    public class ReferralHistory
    {
        [Key]
        public long Id { get; set; }

        public long ReferrerUserId { get; set; }

        public long ReferredUserId { get; set; }

        [MaxLength(16)]
        public string ReferralCode { get; set; } = null!;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey(nameof(ReferrerUserId))]
        public User ReferrerUser { get; set; } = null!;

        [ForeignKey(nameof(ReferredUserId))]
        public User ReferredUser { get; set; } = null!;
    }
}
