using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace localink_be.Migrations
{
    /// <inheritdoc />
    public partial class AddTranslationCacheAndIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "translation_cache",
                columns: table => new
                {
                    id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    cache_key = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    original_text = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    translated_text = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    target_lang = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_translation_cache", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_business_reviews_business_id",
                table: "business_reviews",
                column: "business_id");

            migrationBuilder.CreateIndex(
                name: "IX_translation_cache_cache_key",
                table: "translation_cache",
                column: "cache_key",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "translation_cache");

            migrationBuilder.DropIndex(
                name: "IX_business_reviews_business_id",
                table: "business_reviews");
        }
    }
}
