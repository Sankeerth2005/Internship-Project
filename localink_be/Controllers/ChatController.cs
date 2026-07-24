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
            var conversations = await _chatService.GetBusinessConversationsAsync(businessId);
            return Ok(conversations.Select(c => new
            {
                c.Id,
                c.UserId,
                UserName = c.User?.FullName,
                c.LastMessageAt
            }));
        }

        [HttpGet("messages/{conversationId}")]
        public async Task<IActionResult> GetMessages(long conversationId)
        {
            var messages = await _chatService.GetMessagesAsync(conversationId);
            return Ok(messages);
        }

        [HttpPost("read/{conversationId}")]
        public async Task<IActionResult> MarkAsRead(long conversationId, [FromQuery] string role)
        {
            if (role != "User" && role != "Owner") return BadRequest("Invalid role");
            await _chatService.MarkMessagesAsReadAsync(conversationId, role);
            return Ok(new { success = true });
        }

        [HttpPost("voice/{conversationId}")]
        public async Task<IActionResult> UploadVoiceMessage(long conversationId, [FromForm] IFormFile file, [FromForm] string role)
        {
            try
            {
                if (role != "User" && role != "Owner") return BadRequest("Invalid role");
                
                var message = await _chatService.SendVoiceMessageAsync(conversationId, role, file);
                
                // Broadcast the newly created voice message to the SignalR group
                await _chatHubContext.Clients.Group($"Conv_{conversationId}").SendAsync("ReceiveMessage", message);
                
                return Ok(message);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
