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
        Task<IEnumerable<Conversation>> GetBusinessConversationsAsync(long businessId);
        Task<IEnumerable<Message>> GetMessagesAsync(long conversationId);
        Task<Message> SendTextMessageAsync(long conversationId, string senderRole, string text);
        Task<Message> SendVoiceMessageAsync(long conversationId, string senderRole, IFormFile audioFile);
        Task MarkMessagesAsReadAsync(long conversationId, string readerRole);
    }
}
