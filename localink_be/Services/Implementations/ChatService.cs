using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using localink_be.Data;
using localink_be.Models.Entities;
using localink_be.Services.Interfaces;

namespace localink_be.Services.Implementations
{
    public class ChatService : IChatService
    {
        private readonly AppDbContext _db;
        private readonly IWebHostEnvironment _env;

        public ChatService(AppDbContext db, IWebHostEnvironment env)
        {
            _db = db;
            _env = env;
        }

        public async Task<Conversation> GetOrCreateConversationAsync(long userId, long businessId)
        {
            var conversation = await _db.Conversations
                .Include(c => c.User)
                .Include(c => c.Business)
                .FirstOrDefaultAsync(c => c.UserId == userId && c.BusinessId == businessId);

            if (conversation == null)
            {
                conversation = new Conversation
                {
                    UserId = userId,
                    BusinessId = businessId,
                    CreatedAt = DateTime.UtcNow,
                    LastMessageAt = DateTime.UtcNow
                };
                _db.Conversations.Add(conversation);
                await _db.SaveChangesAsync();

                // Load navigation properties for response
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

        public async Task<IEnumerable<Conversation>> GetBusinessConversationsAsync(long businessId)
        {
            return await _db.Conversations
                .Include(c => c.User)
                .Where(c => c.BusinessId == businessId)
                .OrderByDescending(c => c.LastMessageAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<Message>> GetMessagesAsync(long conversationId)
        {
            return await _db.Messages
                .Where(m => m.ConversationId == conversationId)
                .OrderBy(m => m.Timestamp)
                .ToListAsync();
        }

        public async Task<Message> SendTextMessageAsync(long conversationId, string senderRole, string text)
        {
            var message = new Message
            {
                ConversationId = conversationId,
                SenderRole = senderRole,
                Text = text,
                Timestamp = DateTime.UtcNow,
                IsRead = false
            };

            _db.Messages.Add(message);
            
            var conversation = await _db.Conversations.FindAsync(conversationId);
            if (conversation != null)
            {
                conversation.LastMessageAt = DateTime.UtcNow;
            }

            await _db.SaveChangesAsync();
            return message;
        }

        public async Task<Message> SendVoiceMessageAsync(long conversationId, string senderRole, IFormFile audioFile)
        {
            if (audioFile == null || audioFile.Length == 0)
                throw new ArgumentException("Audio file is empty.");

            var webRoot = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var audioDir = Path.Combine(webRoot, "uploads", "audio");
            if (!Directory.Exists(audioDir))
                Directory.CreateDirectory(audioDir);

            var ext = Path.GetExtension(audioFile.FileName).ToLower();
            if (ext != ".m4a" && ext != ".mp3" && ext != ".wav" && ext != ".aac")
                throw new ArgumentException("Invalid audio format.");

            var fileName = $"voice_{Guid.NewGuid()}{ext}";
            var filePath = Path.Combine(audioDir, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await audioFile.CopyToAsync(stream);
            }

            var audioUrl = $"/uploads/audio/{fileName}";

            var message = new Message
            {
                ConversationId = conversationId,
                SenderRole = senderRole,
                AudioUrl = audioUrl,
                Timestamp = DateTime.UtcNow,
                IsRead = false
            };

            _db.Messages.Add(message);
            
            var conversation = await _db.Conversations.FindAsync(conversationId);
            if (conversation != null)
            {
                conversation.LastMessageAt = DateTime.UtcNow;
            }

            await _db.SaveChangesAsync();
            return message;
        }

        public async Task MarkMessagesAsReadAsync(long conversationId, string readerRole)
        {
            // If reader is "User", mark all messages from "Owner" as read
            var targetSenderRole = readerRole == "User" ? "Owner" : "User";
            
            var unreadMessages = await _db.Messages
                .Where(m => m.ConversationId == conversationId && m.SenderRole == targetSenderRole && !m.IsRead)
                .ToListAsync();

            if (unreadMessages.Any())
            {
                foreach (var msg in unreadMessages)
                {
                    msg.IsRead = true;
                }
                await _db.SaveChangesAsync();
            }
        }
    }
}
