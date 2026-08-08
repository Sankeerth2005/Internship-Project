using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using localink_be.Models.Entities;

namespace localink_be.Services.Interfaces
{
    public interface IChatService
    {
        Task<Conversation> GetOrCreateConversationAsync(long userId, long businessId);
        Task<IEnumerable<Conversation>> GetUserConversationsAsync(long userId);
        Task<IEnumerable<Conversation>> GetBusinessConversationsAsync(long businessId, long requesterUserId, bool isAdmin);
        Task<IEnumerable<Message>> GetMessagesAsync(long conversationId, long requesterUserId, bool isAdmin, int page = 1, int pageSize = 50);
        Task<Message> SendTextMessageAsync(long conversationId, long senderUserId, bool isAdmin, string text);
        Task<Message> SendVoiceMessageAsync(long conversationId, long senderUserId, bool isAdmin, IFormFile audioFile);
        Task MarkMessagesAsReadAsync(long conversationId, long requesterUserId, bool isAdmin);
        Task<bool> UserCanAccessConversationAsync(long conversationId, long userId, bool isAdmin);
        Task EnsureBusinessOwnerAsync(long businessId, long userId, bool isAdmin);
    }
}
