using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace localink_be.Migrations
{
    /// <inheritdoc />
    public partial class AddAIModerationToReviews : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsFlagged",
                table: "business_reviews",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "ModerationReason",
                table: "business_reviews",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsFlagged",
                table: "business_reviews");

            migrationBuilder.DropColumn(
                name: "ModerationReason",
                table: "business_reviews");
        }
    }
}
