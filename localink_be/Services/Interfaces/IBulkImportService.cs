using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;

namespace localink_be.Services.Interfaces
{
    public interface IBulkImportService
    {
        Task<BulkImportResultDto> ProcessBulkImportAsync(IFormFile csvFile);
    }

    public class BulkImportResultDto
    {
        public int SuccessCount { get; set; }
        public int FailureCount { get; set; }
        public System.Collections.Generic.List<string> Errors { get; set; } = new();
    }
}
