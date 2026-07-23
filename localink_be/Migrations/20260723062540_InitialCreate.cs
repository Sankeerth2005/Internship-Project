using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace localink_be.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "addresses",
                columns: table => new
                {
                    address_id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    user_id = table.Column<long>(type: "bigint", nullable: false),
                    country = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    state = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    city = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    street_address = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    pincode = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_addresses", x => x.address_id);
                });

            migrationBuilder.CreateTable(
                name: "business_hours",
                columns: table => new
                {
                    business_hour_id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    business_id = table.Column<long>(type: "bigint", nullable: false),
                    day_of_week = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    mode = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_business_hours", x => x.business_hour_id);
                });

            migrationBuilder.CreateTable(
                name: "category",
                columns: table => new
                {
                    category_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    category_name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    icon_url = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_category", x => x.category_id);
                });

            migrationBuilder.CreateTable(
                name: "Feedbacks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Message = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Feedbacks", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "search_query_log",
                columns: table => new
                {
                    id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    query = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    latitude = table.Column<double>(type: "float", nullable: false),
                    longitude = table.Column<double>(type: "float", nullable: false),
                    timestamp = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_search_query_log", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    user_id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    account_type = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    full_name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    email = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    phone_number = table.Column<string>(type: "nvarchar(450)", nullable: true),
                    country_code = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    password_hash = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    otp_attempts = table.Column<int>(type: "int", nullable: true),
                    password_reset_otp = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    otp_expiry = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.user_id);
                });

            migrationBuilder.CreateTable(
                name: "business_hour_slots",
                columns: table => new
                {
                    slot_id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    business_hour_id = table.Column<long>(type: "bigint", nullable: false),
                    open_time = table.Column<TimeSpan>(type: "time", nullable: false),
                    close_time = table.Column<TimeSpan>(type: "time", nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_business_hour_slots", x => x.slot_id);
                    table.ForeignKey(
                        name: "FK_business_hour_slots_business_hours_business_hour_id",
                        column: x => x.business_hour_id,
                        principalTable: "business_hours",
                        principalColumn: "business_hour_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "subcategory",
                columns: table => new
                {
                    subcategory_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    subcategory_name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    icon_url = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    category_id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_subcategory", x => x.subcategory_id);
                    table.ForeignKey(
                        name: "FK_subcategory_category_category_id",
                        column: x => x.category_id,
                        principalTable: "category",
                        principalColumn: "category_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "business_reviews",
                columns: table => new
                {
                    review_id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    business_id = table.Column<long>(type: "bigint", nullable: false),
                    user_id = table.Column<long>(type: "bigint", nullable: false),
                    rating = table.Column<int>(type: "int", nullable: false),
                    comment = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: true),
                    image_url = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_business_reviews", x => x.review_id);
                    table.ForeignKey(
                        name: "FK_business_reviews_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "business",
                columns: table => new
                {
                    business_id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    business_name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    user_id = table.Column<long>(type: "bigint", nullable: false),
                    category_id = table.Column<int>(type: "int", nullable: false),
                    subcategory_id = table.Column<int>(type: "int", nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: false),
                    temporary_closure_reason = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    temporary_closure_days = table.Column<int>(type: "int", nullable: true),
                    temporary_closure_status = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    temporary_closure_reopen_date = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_business", x => x.business_id);
                    table.ForeignKey(
                        name: "FK_business_category_category_id",
                        column: x => x.category_id,
                        principalTable: "category",
                        principalColumn: "category_id");
                    table.ForeignKey(
                        name: "FK_business_subcategory_subcategory_id",
                        column: x => x.subcategory_id,
                        principalTable: "subcategory",
                        principalColumn: "subcategory_id");
                    table.ForeignKey(
                        name: "FK_business_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "admin_dashboard",
                columns: table => new
                {
                    id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    business_id = table.Column<long>(type: "bigint", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    rejection_reason = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    action_by = table.Column<long>(type: "bigint", nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_admin_dashboard", x => x.id);
                    table.ForeignKey(
                        name: "FK_admin_dashboard_business_business_id",
                        column: x => x.business_id,
                        principalTable: "business",
                        principalColumn: "business_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "business_contact",
                columns: table => new
                {
                    contact_id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    business_id = table.Column<long>(type: "bigint", nullable: false),
                    phone_code = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    phone_number = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    email = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    website = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    street_address = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    city = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    state = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    country = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    pincode = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: false),
                    latitude = table.Column<double>(type: "float", nullable: true),
                    longitude = table.Column<double>(type: "float", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_business_contact", x => x.contact_id);
                    table.ForeignKey(
                        name: "FK_business_contact_business_business_id",
                        column: x => x.business_id,
                        principalTable: "business",
                        principalColumn: "business_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "business_metric",
                columns: table => new
                {
                    id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    business_id = table.Column<long>(type: "bigint", nullable: false),
                    views = table.Column<int>(type: "int", nullable: false),
                    favorites_count = table.Column<int>(type: "int", nullable: false),
                    contact_clicks = table.Column<int>(type: "int", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_business_metric", x => x.id);
                    table.ForeignKey(
                        name: "FK_business_metric_business_business_id",
                        column: x => x.business_id,
                        principalTable: "business",
                        principalColumn: "business_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "business_photos",
                columns: table => new
                {
                    photo_id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    business_id = table.Column<long>(type: "bigint", nullable: false),
                    image_url = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    is_primary = table.Column<bool>(type: "bit", nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_business_photos", x => x.photo_id);
                    table.ForeignKey(
                        name: "FK_business_photos_business_business_id",
                        column: x => x.business_id,
                        principalTable: "business",
                        principalColumn: "business_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Favorites",
                columns: table => new
                {
                    id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    user_id = table.Column<long>(type: "bigint", nullable: false),
                    business_id = table.Column<long>(type: "bigint", nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Favorites", x => x.id);
                    table.ForeignKey(
                        name: "FK_Favorites_business_business_id",
                        column: x => x.business_id,
                        principalTable: "business",
                        principalColumn: "business_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Favorites_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_admin_dashboard_business_id",
                table: "admin_dashboard",
                column: "business_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_business_category_id",
                table: "business",
                column: "category_id");

            migrationBuilder.CreateIndex(
                name: "IX_business_subcategory_id",
                table: "business",
                column: "subcategory_id");

            migrationBuilder.CreateIndex(
                name: "IX_business_user_id",
                table: "business",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_business_contact_business_id",
                table: "business_contact",
                column: "business_id");

            migrationBuilder.CreateIndex(
                name: "IX_business_hour_slots_business_hour_id",
                table: "business_hour_slots",
                column: "business_hour_id");

            migrationBuilder.CreateIndex(
                name: "IX_business_metric_business_id",
                table: "business_metric",
                column: "business_id");

            migrationBuilder.CreateIndex(
                name: "IX_business_photos_business_id",
                table: "business_photos",
                column: "business_id");

            migrationBuilder.CreateIndex(
                name: "IX_business_reviews_user_id",
                table: "business_reviews",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_business_id",
                table: "Favorites",
                column: "business_id");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_user_id_business_id",
                table: "Favorites",
                columns: new[] { "user_id", "business_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_subcategory_category_id",
                table: "subcategory",
                column: "category_id");

            migrationBuilder.CreateIndex(
                name: "IX_users_phone_number",
                table: "users",
                column: "phone_number",
                unique: true,
                filter: "[phone_number] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "addresses");

            migrationBuilder.DropTable(
                name: "admin_dashboard");

            migrationBuilder.DropTable(
                name: "business_contact");

            migrationBuilder.DropTable(
                name: "business_hour_slots");

            migrationBuilder.DropTable(
                name: "business_metric");

            migrationBuilder.DropTable(
                name: "business_photos");

            migrationBuilder.DropTable(
                name: "business_reviews");

            migrationBuilder.DropTable(
                name: "Favorites");

            migrationBuilder.DropTable(
                name: "Feedbacks");

            migrationBuilder.DropTable(
                name: "search_query_log");

            migrationBuilder.DropTable(
                name: "business_hours");

            migrationBuilder.DropTable(
                name: "business");

            migrationBuilder.DropTable(
                name: "subcategory");

            migrationBuilder.DropTable(
                name: "users");

            migrationBuilder.DropTable(
                name: "category");
        }
    }
}
