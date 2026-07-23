using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace localink_be.Models.Entities
{
    [Table("translation_cache")]
    public class TranslationCache
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Required]
        [Column("cache_key")]
        [MaxLength(128)]
        public string CacheKey { get; set; } = string.Empty;

        [Required]
        [Column("original_text")]
        public string OriginalText { get; set; } = string.Empty;

        [Required]
        [Column("translated_text")]
        public string TranslatedText { get; set; } = string.Empty;

        [Required]
        [Column("target_lang")]
        [MaxLength(10)]
        public string TargetLang { get; set; } = string.Empty;

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
