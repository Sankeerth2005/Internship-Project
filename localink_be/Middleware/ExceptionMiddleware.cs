using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;
    private readonly IWebHostEnvironment _env;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger, IWebHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Bad Request");
            await HandleException(context, HttpStatusCode.BadRequest, ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid Operation");
            await HandleException(context, HttpStatusCode.BadRequest, ex.Message);
        }
        catch (KeyNotFoundException ex)
        {
            _logger.LogWarning(ex, "Resource Not Found");
            await HandleException(context, HttpStatusCode.NotFound, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Unauthorized Access");
            await HandleException(context, HttpStatusCode.Unauthorized, ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Internal Server Error");
            
            var isDev = _env.IsDevelopment();
            var userMsg = "An unexpected error occurred. Please try again later.";
            var errorDetails = isDev ? ex.ToString() : null;

            await HandleException(context, HttpStatusCode.InternalServerError, userMsg, errorDetails);
        }
    }

    private static async Task HandleException(HttpContext context, HttpStatusCode statusCode, string message, string? details = null)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)statusCode;

        var response = new
        {
            success = false,
            message,
            error = details
        };

        await context.Response.WriteAsync(JsonSerializer.Serialize(response));
    }
}