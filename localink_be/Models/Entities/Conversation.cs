using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace localink_be.Models.Entities
{
    public class Conversation
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public long Id { get; set; }

        public long UserId { get; set; }
        [ForeignKey("UserId")]
        public User? User { get; set; }

        public long BusinessId { get; set; }
        [ForeignKey("BusinessId")]
        public Business? Business { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;

        [JsonIgnore]
        public ICollection<Message> Messages { get; set; } = new List<Message>();
    }
}
