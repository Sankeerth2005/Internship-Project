using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using localink_be.Hubs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Models.DTOs;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class ReviewService : IReviewService
    {
        private readonly AppDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly IPhotoService _photoService;

        private readonly IAIService _aiService;

        public ReviewService(AppDbContext context, IHubContext<NotificationHub> hubContext, IPhotoService photoService, IAIService aiService)
        {
            _context = context;
            _hubContext = hubContext;
            _photoService = photoService;
            _aiService = aiService;
        }

        public async Task AddOrUpdateReview(long userId, ReviewRequestDto dto)
        {
            if (dto.Rating < 1 || dto.Rating > 5)
                throw new Exception("Rating must be between 1 and 5");

            string? reviewImageUrl = null;
            if (!string.IsNullOrWhiteSpace(dto.Image))
            {
                reviewImageUrl = await _photoService.SaveReviewPhotoAsync(dto.Image);
            }

            bool isFlagged = false;
            string? moderationReason = null;
            if (!string.IsNullOrWhiteSpace(dto.Comment))
            {
                var modResult = await _aiService.ModerateContentAsync(dto.Comment);
                isFlagged = modResult.isFlagged;
                moderationReason = modResult.reason;
            }

            var existingReview = await _context.BusinessReviews
                .FirstOrDefaultAsync(r => r.BusinessId == dto.BusinessId && r.UserId == userId);

            if (existingReview != null)
            {
                existingReview.Rating = dto.Rating;
                existingReview.Comment = dto.Comment;
                if (reviewImageUrl != null)
                {
                    existingReview.ImageUrl = reviewImageUrl;
                }
                existingReview.UpdatedAt = DateTime.UtcNow;
                existingReview.IsFlagged = isFlagged;
                existingReview.ModerationReason = moderationReason;
            }
            else
            {
                var newReview = new BusinessReview
                {
                    BusinessId = dto.BusinessId,
                    UserId = userId,
                    Rating = dto.Rating,
                    Comment = dto.Comment,
                    ImageUrl = reviewImageUrl,
                    CreatedAt = DateTime.UtcNow,
                    IsFlagged = isFlagged,
                    ModerationReason = moderationReason
                };

                await _context.BusinessReviews.AddAsync(newReview);
            }

            await _context.SaveChangesAsync();

            var business = await _context.Businesses.FirstOrDefaultAsync(b => b.BusinessId == dto.BusinessId);
            if (business != null)
            {
                await _hubContext.Clients.Group($"client_{business.UserId}").SendAsync("ReceiveNotification", $"You received a new {dto.Rating}-star review for {business.BusinessName}!");
            }
        }

        public async Task<List<ReviewResponseDto>> GetReviewsByBusiness(long businessId)
        {
            return await _context.BusinessReviews
                .AsNoTracking() 
                .Where(r => r.BusinessId == businessId)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new ReviewResponseDto
                {
                    ReviewId = r.ReviewId,
                    Rating = r.Rating,
                    Comment = r.Comment,
                    CreatedAt = r.CreatedAt,
                    UserName = r.User.FullName,
                    ImageUrl = r.ImageUrl
                })
                .ToListAsync();
        }


        public async Task<ReviewSummaryDto> GetSummary(long businessId)
        {
            var query = _context.BusinessReviews
                .Where(r => r.BusinessId == businessId);

            var avg = await query
                .AverageAsync(r => (double?)r.Rating) ?? 0;

            var count = await query.CountAsync();

            return new ReviewSummaryDto
            {
                AverageRating = Math.Round(avg, 1),
                TotalReviews = count
            };
        }
    }
}