using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;
using System.Threading.Tasks;
using localink_be.Services.Interfaces;
using localink_be.Hubs;
using System.Linq;
using System;

namespace localink_be.Controllers
{
    [Route("api/v1/[controller]")]
    [ApiController]
    [Authorize]
    public class ChatController : ControllerBase
    {
        private readonly IChatService _chatService;
        private readonly IHubContext<ChatHub> _chatHubContext;

        public ChatController(IChatService chatService, IHubContext<ChatHub> chatHubContext)
        {
            _chatService = chatService;
            _chatHubContext = chatHubContext;
        }

        private long GetCurrentUserId()
        {
            var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (long.TryParse(idClaim, out long id)) return id;
            throw new UnauthorizedAccessException("Invalid token");
        }

        private bool IsAdmin() =>
            User.IsInRole("admin") ||
            string.Equals(User.FindFirst(ClaimTypes.Role)?.Value, "admin", StringComparison.OrdinalIgnoreCase);

        /// <summary>
        /// Starts (or resumes) a conversation between the current user and a business.
        /// Used by both clients to open a chat from a business detail page.
        /// </summary>
        [HttpPost("start/{businessId}")]
        public async Task<IActionResult> StartConversation(long businessId)
        {
            var conversation = await _chatService.GetOrCreateConversationAsync(GetCurrentUserId(), businessId);
            return Ok(new
            {
                conversation.Id,
                conversation.BusinessId,
                BusinessName = conversation.Business?.BusinessName,
                BusinessImage = (string?)null,
                conversation.LastMessageAt
            });
        }

        [HttpGet("user")]
        public async Task<IActionResult> GetUserConversations()
        {
            var userId = GetCurrentUserId();
            var conversations = await _chatService.GetUserConversationsAsync(userId);
            return Ok(conversations.Select(c => new
            {
                c.Id,
                c.BusinessId,
                BusinessName = c.Business?.BusinessName,
                BusinessImage = (string?)null,
                c.LastMessageAt
            }));
        }

        [HttpGet("business/{businessId}")]
        public async Task<IActionResult> GetBusinessConversations(long businessId)
        {
            try
            {
                var conversations = await _chatService.GetBusinessConversationsAsync(
                    businessId, GetCurrentUserId(), IsAdmin());
                return Ok(conversations.Select(c => new
                {
                    c.Id,
                    c.UserId,
                    UserName = c.User?.FullName,
                    c.LastMessageAt
                }));
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [HttpGet("messages/{conversationId}")]
        public async Task<IActionResult> GetMessages(
            long conversationId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50)
        {
            try
            {
                var messages = await _chatService.GetMessagesAsync(
                    conversationId, GetCurrentUserId(), IsAdmin(), page, pageSize);
                return Ok(messages);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [HttpPost("read/{conversationId}")]
        public async Task<IActionResult> MarkAsRead(long conversationId)
        {
            try
            {
                await _chatService.MarkMessagesAsReadAsync(conversationId, GetCurrentUserId(), IsAdmin());
                return Ok(new { success = true });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [HttpPost("voice/{conversationId}")]
        public async Task<IActionResult> UploadVoiceMessage(long conversationId, [FromForm] IFormFile file)
        {
            try
            {
                var message = await _chatService.SendVoiceMessageAsync(
                    conversationId, GetCurrentUserId(), IsAdmin(), file);

                await _chatHubContext.Clients.Group($"Conv_{conversationId}")
                    .SendAsync("ReceiveMessage", message);

                return Ok(message);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
