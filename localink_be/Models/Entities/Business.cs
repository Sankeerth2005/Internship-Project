using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace localink_be.Models.Entities
{
    [Table("business")]
    public class Business
    {
        [Key]
        [Column("business_id")]
        public long BusinessId { get; set; }

        [Column("business_name")]
        [Required(ErrorMessage = "Business name is required")]
        [RegularExpression(@"^[A-Za-z\s&'-]+$", ErrorMessage = "Business name can only contain letters, spaces, &, ', -")]
        public string BusinessName { get; set; }

        [Column("description")]
        [Required(ErrorMessage = "Description is required")]
        [MinLength(10, ErrorMessage = "Description must be at least 10 characters long")]
        [RegularExpression(@"^[A-Za-z][A-Za-z\s.,'()%!]*$", ErrorMessage = "Description must start with a letter and can contain letters, spaces, and punctuation")]
        public string Description { get; set; }

        public long UserId { get; set; } 
        
        [Column("category_id")]
        [Required(ErrorMessage = "Category is required")]
        public int CategoryId { get; set; }

        [Column("subcategory_id")]
        [Required(ErrorMessage = "Sub category is required")]
        public int SubcategoryId { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; }

        [Column("temporary_closure_reason")]
        public string? TemporaryClosureReason { get; set; }

        [Column("temporary_closure_days")]
        public int? TemporaryClosureDays { get; set; }

        [Column("temporary_closure_status")]
        public string? TemporaryClosureStatus { get; set; }

        [Column("temporary_closure_reopen_date")]
        public DateTime? TemporaryClosureReopenDate { get; set; }

        public AdminDashboard? AdminDashboard { get; set; }
        public User User { get; set; } = null!;
        public Category Category { get; set; } = null!;
        public Subcategory Subcategory { get; set; } = null!;
    }
}