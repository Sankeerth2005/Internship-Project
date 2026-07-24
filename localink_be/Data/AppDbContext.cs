using Microsoft.EntityFrameworkCore;
using localink_be.Models.Entities;

namespace localink_be.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Subcategory> Subcategories { get; set; }

        public DbSet<Business> Businesses { get; set; }
        public DbSet<BusinessContact> BusinessContacts { get; set; }
        public DbSet<BusinessPhoto> BusinessPhotos { get; set; }

        public DbSet<BusinessHour> BusinessHours { get; set; }
        public DbSet<BusinessHourSlot> BusinessHourSlots { get; set; }

        public DbSet<Address> Addresses { get; set; }
        public DbSet<AdminDashboard> AdminDashboards { get; set; }
        public DbSet<BusinessReview> BusinessReviews { get; set; }
        public DbSet<Feedback> Feedbacks { get; set; }
        public DbSet<Favorite> Favorites { get; set; }
        public DbSet<BusinessMetric> BusinessMetrics { get; set; }
        public DbSet<SearchQueryLog> SearchQueryLogs { get; set; }
        public DbSet<TranslationCache> TranslationCaches { get; set; }
        
        // Phase 2: Chat & Messaging
        public DbSet<Conversation> Conversations { get; set; }
        public DbSet<Message> Messages { get; set; }
        
        // Phase 2: Catalogs
        public DbSet<localink_be.Data.Models.Catalog> Catalogs { get; set; }
        public DbSet<localink_be.Data.Models.CatalogItem> CatalogItems { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            ConfigureCategory(modelBuilder);
            ConfigureSubcategory(modelBuilder);
            ConfigureBusiness(modelBuilder);
            ConfigureBusinessContact(modelBuilder);
            ConfigureBusinessPhoto(modelBuilder);
            ConfigureBusinessHours(modelBuilder);
            ConfigureUser(modelBuilder);
            ConfigureBusinessReview(modelBuilder);
            ConfigureFavorite(modelBuilder);
            ConfigureTranslationCache(modelBuilder);
            ConfigureMessaging(modelBuilder);
        }

        private void ConfigureCategory(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Category>(entity =>
            {
                entity.ToTable("category");

                entity.Property(c => c.CategoryId).HasColumnName("category_id");
                entity.Property(c => c.CategoryName).HasColumnName("category_name");
                entity.Property(c => c.IconUrl).HasColumnName("icon_url");
            });
        }

        private void ConfigureSubcategory(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Subcategory>(entity =>
            {
                entity.ToTable("subcategory");

                entity.Property(s => s.SubcategoryId).HasColumnName("subcategory_id");
                entity.Property(s => s.SubcategoryName).HasColumnName("subcategory_name");
                entity.Property(s => s.CategoryId).HasColumnName("category_id");
                entity.Property(s => s.IconUrl).HasColumnName("icon_url");
            });
        }

        private void ConfigureBusiness(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Business>(entity =>
            {
                entity.ToTable("business");

                entity.Property(b => b.BusinessId).HasColumnName("business_id");
                entity.Property(b => b.BusinessName).HasColumnName("business_name");
                entity.Property(b => b.Description).HasColumnName("description");
                entity.Property(b => b.CategoryId).HasColumnName("category_id");
                entity.Property(b => b.SubcategoryId).HasColumnName("subcategory_id");
                entity.Property(b => b.UserId).HasColumnName("user_id");

                entity.HasIndex(b => b.CategoryId);
                entity.HasIndex(b => b.SubcategoryId);
                entity.HasIndex(b => b.UserId);

                entity.HasOne(b => b.Category)
                    .WithMany()
                    .HasForeignKey(b => b.CategoryId)
                    .OnDelete(DeleteBehavior.NoAction);

                entity.HasOne(b => b.Subcategory)
                    .WithMany()
                    .HasForeignKey(b => b.SubcategoryId)
                    .OnDelete(DeleteBehavior.NoAction);
            });
        }

        private void ConfigureBusinessContact(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<BusinessContact>(entity =>
            {
                entity.ToTable("business_contact");

                entity.Property(c => c.ContactId).HasColumnName("contact_id");
                entity.Property(c => c.BusinessId).HasColumnName("business_id");
                entity.Property(c => c.PhoneNumber).HasColumnName("phone_number");
                entity.Property(c => c.PhoneCode).HasColumnName("phone_code");
                entity.Property(c => c.Email).HasColumnName("email");
                entity.Property(c => c.Website).HasColumnName("website");
                entity.Property(c => c.StreetAddress).HasColumnName("street_address");
                entity.Property(c => c.City).HasColumnName("city");
                entity.Property(c => c.State).HasColumnName("state");
                entity.Property(c => c.Country).HasColumnName("country");
                entity.Property(c => c.Pincode).HasColumnName("pincode");
                entity.Property(c => c.CreatedAt).HasColumnName("created_at");
                entity.Property(c => c.UpdatedAt).HasColumnName("updated_at");
                entity.Property(c => c.Latitude).HasColumnName("latitude");
                entity.Property(c => c.Longitude).HasColumnName("longitude");

                entity.HasIndex(c => c.BusinessId);
            });
        }

        private void ConfigureBusinessPhoto(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<BusinessPhoto>(entity =>
            {
                entity.ToTable("business_photos");

                entity.Property(p => p.PhotoId).HasColumnName("photo_id");
                entity.Property(p => p.BusinessId).HasColumnName("business_id");
                entity.Property(p => p.ImageUrl).HasColumnName("image_url");
                entity.Property(p => p.IsPrimary).HasColumnName("is_primary");

                entity.HasIndex(p => p.BusinessId);
            });
        }

        private void ConfigureBusinessHours(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<BusinessHour>()
                .HasMany(b => b.Slots)
                .WithOne()
                .HasForeignKey(s => s.BusinessHourId)
                .OnDelete(DeleteBehavior.Cascade);
        }

        private void ConfigureUser(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>(entity =>
            {
                entity.ToTable("users");

                entity.HasKey(u => u.UserId);

                entity.Property(u => u.UserId).HasColumnName("user_id");
                entity.Property(u => u.AccountType).HasColumnName("account_type");
                entity.Property(u => u.FullName).HasColumnName("full_name");
                entity.Property(u => u.Email).HasColumnName("email");
                entity.Property(u => u.PhoneNumber).HasColumnName("phone_number");
                entity.Property(u => u.PasswordHash).HasColumnName("password_hash").IsRequired(false);
                entity.Property(u => u.CountryCode).HasColumnName("country_code");

                entity.Property(u => u.PasswordResetOtp).HasColumnName("password_reset_otp");
                entity.Property(u => u.OtpExpiry).HasColumnName("otp_expiry");
                entity.Property(u => u.OtpAttempts).HasColumnName("otp_attempts");

                entity.HasIndex(u => u.PhoneNumber).IsUnique();
            });
        }

        private void ConfigureBusinessReview(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<BusinessReview>(entity =>
            {
                entity.ToTable("business_reviews");
                entity.HasKey(r => r.ReviewId);
                entity.Property(r => r.ReviewId).HasColumnName("review_id");
                entity.Property(r => r.BusinessId).HasColumnName("business_id");
                entity.Property(r => r.UserId).HasColumnName("user_id");
                entity.Property(r => r.Rating).HasColumnName("rating");
                entity.Property(r => r.Comment).HasColumnName("comment");
                entity.Property(r => r.CreatedAt).HasColumnName("created_at");
                entity.Property(r => r.UpdatedAt).HasColumnName("updated_at");
                entity.Property(r => r.ImageUrl).HasColumnName("image_url");

                entity.HasIndex(r => r.BusinessId);
                entity.HasIndex(r => r.UserId);

                entity.HasOne(r => r.User)
                    .WithMany()
                    .HasForeignKey(r => r.UserId)
                    .OnDelete(DeleteBehavior.NoAction);
            });
        }

        private void ConfigureFavorite(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Favorite>(entity =>
            {
                entity.ToTable("Favorites");
                entity.HasKey(f => f.Id);
                entity.Property(f => f.Id)
                    .HasColumnName("id")
                    .ValueGeneratedOnAdd();
                entity.Property(f => f.UserId).HasColumnName("user_id");
                entity.Property(f => f.BusinessId).HasColumnName("business_id");
                entity.Property(f => f.CreatedAt).HasColumnName("created_at");

                entity.HasOne(f => f.User)
                    .WithMany()
                    .HasForeignKey(f => f.UserId)
                    .OnDelete(DeleteBehavior.NoAction);

                entity.HasOne(f => f.Business)
                    .WithMany()
                    .HasForeignKey(f => f.BusinessId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(f => new { f.UserId, f.BusinessId })
                    .IsUnique();
            });
        }

        private void ConfigureTranslationCache(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<TranslationCache>(entity =>
            {
                entity.ToTable("translation_cache");
                entity.HasIndex(t => t.CacheKey).IsUnique();
            });
        }

        private void ConfigureMessaging(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Conversation>(entity =>
            {
                entity.ToTable("conversations");
                
                entity.HasOne(c => c.User)
                    .WithMany()
                    .HasForeignKey(c => c.UserId)
                    .OnDelete(DeleteBehavior.NoAction); // Prevent cycle
                    
                entity.HasOne(c => c.Business)
                    .WithMany()
                    .HasForeignKey(c => c.BusinessId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Message>(entity =>
            {
                entity.ToTable("messages");
                
                entity.HasOne(m => m.Conversation)
                    .WithMany(c => c.Messages)
                    .HasForeignKey(m => m.ConversationId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
