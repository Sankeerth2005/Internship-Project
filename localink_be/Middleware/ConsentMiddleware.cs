using System.Security.Claims;

namespace localink_be.Middleware;

/// <summary>
/// Blocks authenticated non-admin API access until User Agreement consent is accepted.
/// Consent state is carried in the JWT <c>consent_accepted</c> claim (account source of truth).
/// </summary>
public class ConsentMiddleware
{
    private readonly RequestDelegate _next;

    public ConsentMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.User?.Identity?.IsAuthenticated == true)
        {
            var role = context.User.FindFirst(ClaimTypes.Role)?.Value;
            if (!string.Equals(role, "admin", StringComparison.OrdinalIgnoreCase))
            {
                var path = context.Request.Path.Value ?? string.Empty;
                if (!IsConsentExemptPath(path))
                {
                    var consent = context.User.FindFirst("consent_accepted")?.Value;
                    if (!string.Equals(consent, "true", StringComparison.OrdinalIgnoreCase))
                    {
                        context.Response.StatusCode = StatusCodes.Status403Forbidden;
                        await context.Response.WriteAsJsonAsync(new
                        {
                            success = false,
                            message = "User agreement consent required",
                            code = "CONSENT_REQUIRED"
                        });
                        return;
                    }
                }
            }
        }

        await _next(context);
    }

    private static bool IsConsentExemptPath(string path)
    {
        if (path.StartsWith("/api/v1/auth", StringComparison.OrdinalIgnoreCase))
            return true;
        if (path.StartsWith("/health", StringComparison.OrdinalIgnoreCase))
            return true;
        if (path == "/" || path.Equals("/health/ready", StringComparison.OrdinalIgnoreCase))
            return true;
        return false;
    }
}
