using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using localink_be.Services.Interfaces;
using localink_be.Models.Entities;

namespace localink_be.Hubs
{
    [Authorize]
    public class ChatHub : Hub
    {
        private readonly IChatService _chatService;
        private readonly Microsoft.Extensions.Logging.ILogger<ChatHub> _logger;

        public ChatHub(IChatService chatService, Microsoft.Extensions.Logging.ILogger<ChatHub> logger)
        {
            _chatService = chatService;
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Context.UserIdentifier;
            if (!string.IsNullOrEmpty(userId))
            {
                // Join a group dedicated to this specific user ID so we can route messages to them
                await Groups.AddToGroupAsync(Context.ConnectionId, $"User_{userId}");
                _logger.LogInformation($"Client connected: {Context.ConnectionId} for User: {userId}");
            }
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.UserIdentifier;
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"User_{userId}");
                _logger.LogInformation($"Client disconnected: {Context.ConnectionId} for User: {userId}");
            }
            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Sends a text message from one user/owner to another.
        /// </summary>
        public async Task SendMessage(long conversationId, string senderRole, string text)
        {
            try
            {
                // 1. Save to database
                var message = await _chatService.SendTextMessageAsync(conversationId, senderRole, text);
                
                // 2. We need to notify the OTHER party in the conversation.
                // In a real production app, we would look up the Conversation to find the UserID and BusinessID,
                // then find the specific Owner's UserId to route the message.
                
                // For simplicity in this hub, we broadcast to the specific Conversation group.
                // Clients must join their Conversation groups when they open a chat.
                await Clients.Group($"Conv_{conversationId}").SendAsync("ReceiveMessage", message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message");
                throw new HubException("Failed to send message", ex);
            }
        }

        /// <summary>
        /// Called by a client when they open a specific chat screen
        /// </summary>
        public async Task JoinConversation(long conversationId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"Conv_{conversationId}");
            _logger.LogInformation($"Connection {Context.ConnectionId} joined conversation {conversationId}");
        }

        /// <summary>
        /// Called by a client when they leave a specific chat screen
        /// </summary>
        public async Task LeaveConversation(long conversationId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Conv_{conversationId}");
            _logger.LogInformation($"Connection {Context.ConnectionId} left conversation {conversationId}");
        }
    }
}
