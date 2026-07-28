using localink_be.Models.DTOs;

public interface IReviewService
{
    Task AddOrUpdateReview(long userId, ReviewRequestDto dto);
    Task<List<ReviewResponseDto>> GetReviewsByBusiness(long businessId);
    Task<ReviewSummaryDto> GetSummary(long businessId);
}