using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace localink_be.Models.Entities
{
    public class Message
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public long Id { get; set; }

        public long ConversationId { get; set; }
        [JsonIgnore]
        [ForeignKey("ConversationId")]
        public Conversation? Conversation { get; set; }

        // Role of the sender: "User" or "Owner"
        [Required]
        [MaxLength(20)]
        public string SenderRole { get; set; } = string.Empty;

        // Either Text or AudioUrl should be provided
        public string? Text { get; set; }
        
        public string? AudioUrl { get; set; }

        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        
        public bool IsRead { get; set; } = false;
    }
}
