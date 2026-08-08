using System.ComponentModel.DataAnnotations;

namespace localink_be.Models.DTOs
{
    public class GoogleAuthRequest
    {
        [Required(ErrorMessage = "Google ID token is required")]
        public string IdToken { get; set; } = string.Empty;
    }
}
