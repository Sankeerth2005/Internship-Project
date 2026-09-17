using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace localink_be.Models.Entities
{
    [Table("business_share_items")]
    public class BusinessShareItem
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("share_id")]
        public long ShareId { get; set; }

        [Column("business_id")]
        public long BusinessId { get; set; }

        [Column("position")]
        public int Position { get; set; }

        public BusinessShare Share { get; set; } = null!;
        public Business Business { get; set; } = null!;
    }
}
