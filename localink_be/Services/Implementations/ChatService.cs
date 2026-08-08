using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class ChatService : IChatService
    {
        private const long MaxVoiceBytes = 5 * 1024 * 1024;
        private readonly AppDbContext _db;
        private readonly IUploadStorageService _storage;

        public ChatService(AppDbContext db, IUploadStorageService storage)
        {
            _db = db;
            _storage = storage;
        }

        public async Task EnsureBusinessOwnerAsync(long businessId, long userId, bool isAdmin)
        {
            if (isAdmin) return;
            var owns = await _db.Businesses.AnyAsync(b => b.BusinessId == businessId && b.UserId == userId);
            if (!owns)
                throw new UnauthorizedAccessException("You do not own this business");
        }

        public async Task<bool> UserCanAccessConversationAsync(long conversationId, long userId, bool isAdmin)
        {
            if (isAdmin) return true;

            return await _db.Conversations
                .AnyAsync(c => c.Id == conversationId &&
                    (c.UserId == userId || (c.Business != null && c.Business.UserId == userId)));
        }

        private async Task<(Conversation conversation, string senderRole)> ResolveParticipantAsync(
            long conversationId, long userId, bool isAdmin)
        {
            var conversation = await _db.Conversations
                .Include(c => c.Business)
                .FirstOrDefaultAsync(c => c.Id == conversationId)
                ?? throw new KeyNotFoundException("Conversation not found");

            if (isAdmin)
                return (conversation, "User");

            if (conversation.UserId == userId)
                return (conversation, "User");

            if (conversation.Business != null && conversation.Business.UserId == userId)
                return (conversation, "Owner");

            throw new UnauthorizedAccessException("You are not a participant in this conversation");
        }

        public async Task<Conversation> GetOrCreateConversationAsync(long userId, long businessId)
        {
            var conversation = await _db.Conversations
                .Include(c => c.User)
                .Include(c => c.Business)
                .FirstOrDefaultAsync(c => c.UserId == userId && c.BusinessId == businessId);

            if (conversation == null)
            {
                var businessExists = await _db.Businesses.AnyAsync(b => b.BusinessId == businessId);
                if (!businessExists)
                    throw new KeyNotFoundException("Business not found");

                conversation = new Conversation
                {
                    UserId = userId,
                    BusinessId = businessId,
                    CreatedAt = DateTime.UtcNow,
                    LastMessageAt = DateTime.UtcNow
                };
                _db.Conversations.Add(conversation);
                await _db.SaveChangesAsync();

                await _db.Entry(conversation).Reference(c => c.User).LoadAsync();
                await _db.Entry(conversation).Reference(c => c.Business).LoadAsync();
            }

            return conversation;
        }

        public async Task<IEnumerable<Conversation>> GetUserConversationsAsync(long userId)
        {
            return await _db.Conversations
                .Include(c => c.Business)
                .Where(c => c.UserId == userId)
                .OrderByDescending(c => c.LastMessageAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<Conversation>> GetBusinessConversationsAsync(
            long businessId, long requesterUserId, bool isAdmin)
        {
            await EnsureBusinessOwnerAsync(businessId, requesterUserId, isAdmin);

            return await _db.Conversations
                .Include(c => c.User)
                .Where(c => c.BusinessId == businessId)
                .OrderByDescending(c => c.LastMessageAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<Message>> GetMessagesAsync(
            long conversationId, long requesterUserId, bool isAdmin, int page = 1, int pageSize = 50)
        {
            if (!await UserCanAccessConversationAsync(conversationId, requesterUserId, isAdmin))
                throw new UnauthorizedAccessException("You are not a participant in this conversation");

            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var batch = await _db.Messages
                .Where(m => m.ConversationId == conversationId)
                .OrderByDescending(m => m.Timestamp)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return batch.OrderBy(m => m.Timestamp).ToList();
        }

        public async Task<Message> SendTextMessageAsync(
            long conversationId, long senderUserId, bool isAdmin, string text)
        {
            if (string.IsNullOrWhiteSpace(text) || text.Length > 4000)
                throw new ArgumentException("Message text is invalid");

            var (conversation, senderRole) = await ResolveParticipantAsync(conversationId, senderUserId, isAdmin);

            var message = new Message
            {
                ConversationId = conversationId,
                SenderRole = senderRole,
                Text = text.Trim(),
                Timestamp = DateTime.UtcNow,
                IsRead = false
            };

            _db.Messages.Add(message);
            conversation.LastMessageAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return message;
        }

        public async Task<Message> SendVoiceMessageAsync(
            long conversationId, long senderUserId, bool isAdmin, IFormFile audioFile)
        {
            var (conversation, senderRole) = await ResolveParticipantAsync(conversationId, senderUserId, isAdmin);

            if (audioFile == null || audioFile.Length == 0)
                throw new ArgumentException("Audio file is empty.");
            if (audioFile.Length > MaxVoiceBytes)
                throw new ArgumentException("Audio file exceeds 5 MB limit.");

            var ext = Path.GetExtension(audioFile.FileName).ToLowerInvariant();
            if (ext is not (".m4a" or ".mp3" or ".wav" or ".aac"))
                throw new ArgumentException("Invalid audio format.");

            var audioDir = _storage.EnsureCategoryDirectory("audio");
            var fileName = $"voice_{Guid.NewGuid():N}{ext}";
            var filePath = Path.Combine(audioDir, fileName);

            await using (var stream = new FileStream(filePath, FileMode.CreateNew, FileAccess.Write, FileShare.None))
            {
                await audioFile.CopyToAsync(stream);
            }

            var audioUrl = _storage.ToRelativeWebPath("audio", fileName);

            var message = new Message
            {
                ConversationId = conversationId,
                SenderRole = senderRole,
                AudioUrl = audioUrl,
                Timestamp = DateTime.UtcNow,
                IsRead = false
            };

            _db.Messages.Add(message);
            conversation.LastMessageAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return message;
        }

        public async Task MarkMessagesAsReadAsync(long conversationId, long requesterUserId, bool isAdmin)
        {
            var (_, readerRole) = await ResolveParticipantAsync(conversationId, requesterUserId, isAdmin);
            var targetSenderRole = readerRole == "User" ? "Owner" : "User";

            var unreadMessages = await _db.Messages
                .Where(m => m.ConversationId == conversationId && m.SenderRole == targetSenderRole && !m.IsRead)
                .ToListAsync();

            if (unreadMessages.Count == 0) return;

            foreach (var msg in unreadMessages)
                msg.IsRead = true;

            await _db.SaveChangesAsync();
        }
    }
}
