using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace localink_be.Models.Entities
{
    /// <summary>
    /// Snapshot share created by a user (single business or curated favorites collection).
    /// </summary>
    [Table("business_shares")]
    public class BusinessShare
    {
        [Key]
        [Column("share_id")]
        public long ShareId { get; set; }

        [Column("public_token")]
        [MaxLength(32)]
        public string PublicToken { get; set; } = null!;

        /// <summary>business = single-item share; collection = multi-item.</summary>
        [Column("share_kind")]
        [MaxLength(16)]
        public string ShareKind { get; set; } = "collection";

        [Column("created_by_user_id")]
        public long CreatedByUserId { get; set; }

        [Column("title")]
        [MaxLength(120)]
        public string? Title { get; set; }

        [Column("note")]
        [MaxLength(500)]
        public string? Note { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        public User CreatedByUser { get; set; } = null!;
        public ICollection<BusinessShareItem> Items { get; set; } = new List<BusinessShareItem>();
    }
}
