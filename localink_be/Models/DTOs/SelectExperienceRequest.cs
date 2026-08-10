using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class SelectExperienceRequest
    {
        /// <summary>
        /// Requested post-auth experience: "user" or "businessowner".
        /// </summary>
        [Required]
        [RegularExpression(@"^(user|businessowner)$", ErrorMessage = "Experience must be user or businessowner")]
        public string Experience { get; set; } = null!;
    }
}
