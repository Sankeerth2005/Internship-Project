using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.ComponentModel.DataAnnotations;
using localink_be.Services.Interfaces;
using localink_be.Models.DTOs;

namespace localink_be.Controllers
{
    /// <summary>
    /// Voice Controller - Handles speech-to-text and AI-powered voice processing
    /// </summary>
    [ApiController]
    [Route("api/v1/voice")]
    public class VoiceController : ControllerBase
    {
        private readonly IAIGatewayService _aiGateway;
        private readonly IBusinessService _businessService;
        private readonly ILogger<VoiceController> _logger;

        public VoiceController(
            IAIGatewayService aiGateway,
            IBusinessService businessService,
            ILogger<VoiceController> logger)
        {
            _aiGateway = aiGateway ?? throw new ArgumentNullException(nameof(aiGateway));
            _businessService = businessService ?? throw new ArgumentNullException(nameof(businessService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        /// <summary>
        /// Process voice input: transcribe audio and parse intent
        /// </summary>
        [HttpPost("process")]
        [AllowAnonymous]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(typeof(VoiceProcessResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(VoiceProcessResponse), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(VoiceProcessResponse), StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> ProcessVoice([FromForm] VoiceProcessRequest request)
        {
            try
            {
                // Validate request
                if (request.AudioFile == null || request.AudioFile.Length == 0)
                {
                    return BadRequest(new VoiceProcessResponse
                    {
                        Success = false,
                        Message = "No audio file provided",
                        Transcript = null,
                        Intent = null
                    });
                }

                // Validate file size (max 10MB)
                if (request.AudioFile.Length > 10 * 1024 * 1024)
                {
                    return BadRequest(new VoiceProcessResponse
                    {
                        Success = false,
                        Message = "Audio file too large. Maximum size is 10MB.",
                        Transcript = null,
                        Intent = null
                    });
                }

                // Validate file type
                var allowedTypes = new[] { "audio/webm", "audio/mp4", "audio/wav", "audio/mpeg", "audio/ogg", "audio/mp3" };
                if (!allowedTypes.Contains(request.AudioFile.ContentType.ToLowerInvariant()))
                {
                    return BadRequest(new VoiceProcessResponse
                    {
                        Success = false,
                        Message = $"Unsupported audio format: {request.AudioFile.ContentType}. Supported formats: WebM, MP4, WAV, MP3, OGG.",
                        Transcript = null,
                        Intent = null
                    });
                }

                // Read audio data
                byte[] audioData;
                using (var ms = new MemoryStream())
                {
                    await request.AudioFile.CopyToAsync(ms);
                    audioData = ms.ToArray();
                }

                _logger.LogInformation("Processing voice input: {Size} bytes, Language: {Language}", 
                    audioData.Length, request.Language ?? "auto");

                // Step 1: Transcribe audio using AI Gateway
                var transcriptionResult = await _aiGateway.TranscribeAudioAsync(audioData, request.Language);

                if (!transcriptionResult.Success || string.IsNullOrEmpty(transcriptionResult.Transcript))
                {
                    _logger.LogWarning("Transcription failed: {Error}", transcriptionResult.Error);
                    
                    return StatusCode(StatusCodes.Status503ServiceUnavailable, new VoiceProcessResponse
                    {
                        Success = false,
                        Message = transcriptionResult.Error ?? "Failed to transcribe audio",
                        Transcript = null,
                        Intent = null,
                        Suggestion = "You can try using your browser's built-in speech recognition as a fallback."
                    });
                }

                _logger.LogInformation("Transcription successful: {Transcript}", transcriptionResult.Transcript);

                // Step 2: Parse intent using AI Gateway
                var intentResult = await _aiGateway.ParseIntentAsync(transcriptionResult.Transcript);

                if (!intentResult.Success)
                {
                    _logger.LogWarning("Intent parsing failed, using fallback");
                    // Use fallback intent parsing (already implemented in AIGatewayService)
                }

                // Get user location from headers if available
                double? userLat = null;
                double? userLng = null;

                if (Request.Headers.ContainsKey("X-User-Latitude") && 
                    Request.Headers.ContainsKey("X-User-Longitude"))
                {
                    if (double.TryParse(Request.Headers["X-User-Latitude"].ToString(), out var lat) &&
                        double.TryParse(Request.Headers["X-User-Longitude"].ToString(), out var lng))
                    {
                        userLat = lat;
                        userLng = lng;
                    }
                }

                // Build search request from intent
                var searchRequest = new VoiceSearchRequest
                {
                    Query = intentResult.Query ?? transcriptionResult.Transcript,
                    OpenNow = intentResult.OpenNow,
                    Radius = intentResult.RadiusKm ?? 5,
                    Category = intentResult.Category
                };

                // Execute search
                var searchResponse = await _businessService.VoiceSearchAsync(searchRequest, userLat, userLng);

                return Ok(new VoiceProcessResponse
                {
                    Success = true,
                    Message = searchResponse.Success 
                        ? $"Found {searchResponse.TotalCount} results for \"{transcriptionResult.Transcript}\"" 
                        : "Voice processed but search returned no results",
                    Transcript = transcriptionResult.Transcript,
                    Language = transcriptionResult.Language,
                    UsedFallback = transcriptionResult.UsedFallback,
                    Intent = new IntentDetails
                    {
                        Action = intentResult.Intent,
                        Category = intentResult.Category,
                        Query = intentResult.Query,
                        OpenNow = intentResult.OpenNow,
                        RadiusKm = intentResult.RadiusKm
                    },
                    SearchResults = searchResponse.Results,
                    TotalResults = searchResponse.TotalCount
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing voice input");
                
                return StatusCode(StatusCodes.Status500InternalServerError, new VoiceProcessResponse
                {
                    Success = false,
                    Message = "An unexpected error occurred while processing your voice input",
                    Transcript = null,
                    Intent = null,
                    Suggestion = "Please try again or use text search instead."
                });
            }
        }

        /// <summary>
        /// Process text directly (for browser speech recognition fallback)
        /// </summary>
        [HttpPost("process-text")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(VoiceProcessResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(VoiceProcessResponse), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> ProcessText([FromBody] TextProcessRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Text))
                {
                    return BadRequest(new VoiceProcessResponse
                    {
                        Success = false,
                        Message = "No text provided"
                    });
                }

                _logger.LogInformation("Processing text input: {Text}", request.Text);

                // Parse intent
                var intentResult = await _aiGateway.ParseIntentAsync(request.Text);

                // Get user location from headers
                double? userLat = null;
                double? userLng = null;

                if (Request.Headers.ContainsKey("X-User-Latitude") && 
                    Request.Headers.ContainsKey("X-User-Longitude"))
                {
                    if (double.TryParse(Request.Headers["X-User-Latitude"].ToString(), out var lat) &&
                        double.TryParse(Request.Headers["X-User-Longitude"].ToString(), out var lng))
                    {
                        userLat = lat;
                        userLng = lng;
                    }
                }

                // Build search request
                var searchRequest = new VoiceSearchRequest
                {
                    Query = intentResult.Query ?? request.Text,
                    OpenNow = intentResult.OpenNow,
                    Radius = intentResult.RadiusKm ?? 5,
                    Category = intentResult.Category
                };

                // Execute search
                var searchResponse = await _businessService.VoiceSearchAsync(searchRequest, userLat, userLng);

                return Ok(new VoiceProcessResponse
                {
                    Success = true,
                    Message = searchResponse.Success 
                        ? $"Found {searchResponse.TotalCount} results" 
                        : "No results found",
                    Transcript = request.Text,
                    UsedFallback = true, // Browser speech recognition was used
                    Intent = new IntentDetails
                    {
                        Action = intentResult.Intent,
                        Category = intentResult.Category,
                        Query = intentResult.Query,
                        OpenNow = intentResult.OpenNow,
                        RadiusKm = intentResult.RadiusKm
                    },
                    SearchResults = searchResponse.Results,
                    TotalResults = searchResponse.TotalCount
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing text input");
                
                return StatusCode(StatusCodes.Status500InternalServerError, new VoiceProcessResponse
                {
                    Success = false,
                    Message = "An error occurred while processing your request"
                });
            }
        }

        /// <summary>
        /// Health check endpoint for voice service
        /// </summary>
        [HttpGet("health")]
        [AllowAnonymous]
        public async Task<IActionResult> HealthCheck()
        {
            var isHealthy = await _aiGateway.HealthCheckAsync();
            
            return isHealthy 
                ? Ok(new { status = "healthy", service = "voice", timestamp = DateTime.UtcNow })
                : StatusCode(StatusCodes.Status503ServiceUnavailable, 
                    new { status = "unhealthy", service = "voice", timestamp = DateTime.UtcNow });
        }
    }

    #region Request/Response DTOs

    public class VoiceProcessRequest
    {
        [Required]
        public IFormFile AudioFile { get; set; } = null!;
        
        /// <summary>
        /// Optional language code (e.g., "en", "hi", "ta")
        /// </summary>
        public string? Language { get; set; }
    }

    public class TextProcessRequest
    {
        [Required]
        [StringLength(500, ErrorMessage = "Text cannot exceed 500 characters")]
        public string Text { get; set; } = string.Empty;
        
        public string? Language { get; set; }
    }

    public class VoiceProcessResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? Transcript { get; set; }
        public string? Language { get; set; }
        public bool UsedFallback { get; set; }
        public IntentDetails? Intent { get; set; }
        public List<BusinessDto>? SearchResults { get; set; }
        public int? TotalResults { get; set; }
        public string? Suggestion { get; set; }
    }

    public class IntentDetails
    {
        public string Action { get; set; } = "unknown";
        public string? Category { get; set; }
        public string? Query { get; set; }
        public bool OpenNow { get; set; }
        public int? RadiusKm { get; set; }
    }

    #endregion
}
