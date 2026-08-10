using System.Collections.Generic;

namespace localink_be.Models.DTOs
{
    public class AuthorizedExperiencesDto
    {
        public string AccountType { get; set; } = string.Empty;
        public IReadOnlyList<string> AuthorizedExperiences { get; set; } = [];
        public bool CanContinueAsUser { get; set; }
        public bool CanContinueAsBusinessOwner { get; set; }
        public bool CanRegisterBusiness { get; set; }
    }

    public class SelectExperienceResultDto
    {
        public bool Allowed { get; set; }
        public string Experience { get; set; } = string.Empty;
        /// <summary>
        /// App route key: "user", "businessowner", or "register-business".
        /// </summary>
        public string Destination { get; set; } = string.Empty;
        public string? Message { get; set; }
    }
}
