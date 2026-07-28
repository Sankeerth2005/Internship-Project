using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace localink_be.Migrations
{
    /// <inheritdoc />
    public partial class AddCurrencyToCatalogItems : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Currency",
                table: "CatalogItems",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Currency",
                table: "CatalogItems");
        }
    }
}
