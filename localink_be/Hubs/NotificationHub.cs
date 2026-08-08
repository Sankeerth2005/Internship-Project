using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;
using System.Threading.Tasks;

namespace localink_be.Hubs
{
    [Authorize]
    public class NotificationHub : Hub
    {
        public async Task JoinGroup(string groupName)
        {
            if (string.IsNullOrWhiteSpace(groupName))
                throw new HubException("Invalid group");

            var userId = Context.UserIdentifier
                ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var role = Context.User?.FindFirst(ClaimTypes.Role)?.Value
                ?? Context.User?.FindFirst("role")?.Value;

            if (string.IsNullOrEmpty(userId))
                throw new HubException("Unauthorized");

            var isAdmin = string.Equals(role, "admin", StringComparison.OrdinalIgnoreCase);
            var allowed =
                groupName.Equals($"client_{userId}", StringComparison.Ordinal) ||
                groupName.Equals($"user_{userId}", StringComparison.Ordinal) ||
                groupName.Equals($"User_{userId}", StringComparison.Ordinal) ||
                (isAdmin && groupName.Equals("admin", StringComparison.OrdinalIgnoreCase));

            if (!allowed)
                throw new HubException("Forbidden");

            await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
        }

        public async Task LeaveGroup(string groupName)
        {
            if (string.IsNullOrWhiteSpace(groupName))
                return;

            var userId = Context.UserIdentifier
                ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var role = Context.User?.FindFirst(ClaimTypes.Role)?.Value
                ?? Context.User?.FindFirst("role")?.Value;
            var isAdmin = string.Equals(role, "admin", StringComparison.OrdinalIgnoreCase);

            var allowed =
                !string.IsNullOrEmpty(userId) && (
                    groupName.Equals($"client_{userId}", StringComparison.Ordinal) ||
                    groupName.Equals($"user_{userId}", StringComparison.Ordinal) ||
                    groupName.Equals($"User_{userId}", StringComparison.Ordinal) ||
                    (isAdmin && groupName.Equals("admin", StringComparison.OrdinalIgnoreCase)));

            if (!allowed)
                throw new HubException("Forbidden");

            await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
        }
    }
}
