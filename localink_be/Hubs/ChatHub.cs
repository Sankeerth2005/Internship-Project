using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using localink_be.Services.Interfaces;

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

        private long GetUserId()
        {
            var id = Context.UserIdentifier
                ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!long.TryParse(id, out var userId))
                throw new HubException("Unauthorized");
            return userId;
        }

        private bool IsAdmin()
        {
            var role = Context.User?.FindFirst(ClaimTypes.Role)?.Value
                ?? Context.User?.FindFirst("role")?.Value;
            return string.Equals(role, "admin", StringComparison.OrdinalIgnoreCase);
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Context.UserIdentifier;
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"User_{userId}");
                _logger.LogInformation("Client connected: {ConnectionId} for User: {UserId}", Context.ConnectionId, userId);
            }
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.UserIdentifier;
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"User_{userId}");
            }
            await base.OnDisconnectedAsync(exception);
        }

        public async Task SendMessage(long conversationId, string senderRole, string text)
        {
            try
            {
                var userId = GetUserId();
                var message = await _chatService.SendTextMessageAsync(conversationId, userId, IsAdmin(), text);
                await Clients.Group($"Conv_{conversationId}").SendAsync("ReceiveMessage", message);
            }
            catch (UnauthorizedAccessException)
            {
                throw new HubException("Forbidden");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message");
                throw new HubException("Failed to send message");
            }
        }

        public async Task JoinConversation(long conversationId)
        {
            var userId = GetUserId();
            var allowed = await _chatService.UserCanAccessConversationAsync(conversationId, userId, IsAdmin());
            if (!allowed)
                throw new HubException("Forbidden");

            await Groups.AddToGroupAsync(Context.ConnectionId, $"Conv_{conversationId}");
        }

        public async Task LeaveConversation(long conversationId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Conv_{conversationId}");
        }
    }
}
