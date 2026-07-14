using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System;

namespace localink_be.Models.Entities
{
    public class User 
    {
        [Key]
        public long UserId { get; set; }
        public string AccountType { get; set; } = null!;
        public string FullName { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string? PhoneNumber { get; set; }
        public string CountryCode { get; set; } = string.Empty;
        public string? PasswordHash { get; set; }
        public string? GoogleId { get; set; }

        public int? OtpAttempts { get; set; }
        public string? PasswordResetOtp { get; set; }
        public DateTime? OtpExpiry { get; set; }
        public ICollection<Business> Businesses { get; set; } = new List<Business>();
    }
}