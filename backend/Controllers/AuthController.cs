using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers;

/// <summary>
/// Authentication controller for login/logout operations
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    /// <summary>
    /// Authenticate user with email and password
    /// </summary>
    /// <param name="request">Login credentials</param>
    /// <returns>JWT token and user info on success</returns>
    /// <response code="200">Login successful, returns access token and user info</response>
    /// <response code="400">Invalid request payload</response>
    /// <response code="401">Invalid email or password</response>
    /// <response code="403">Account is disabled</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(LoginResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
    {
        try
        {
            // Model validation is handled by [ApiController] attribute
            // Invalid payloads will return 400 automatically

            var result = await _authService.LoginAsync(request);

            if (!result.Success)
            {
                return StatusCode(result.StatusCode, new ErrorResponse
                {
                    Error = result.ErrorMessage ?? "Authentication failed"
                });
            }

            return Ok(result.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error during login for {Email}", request.EmailOrUsername);
            return StatusCode(500, new ErrorResponse
            {
                Error = "An unexpected error occurred. Please try again later."
            });
        }
    }

    /// <summary>
    /// Get current user info (protected endpoint - requires authentication)
    /// </summary>
    /// <returns>Current user info</returns>
    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public IActionResult GetCurrentUser()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                  ?? User.FindFirst("sub")?.Value;
        var email = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value
                  ?? User.FindFirst("email")?.Value;
        var role = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
        var name = User.FindFirst("name")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        return Ok(new UserDto
        {
            Id = int.Parse(userId),
            Email = email ?? string.Empty,
            Name = name ?? string.Empty,
            Role = role ?? "user"
        });
    }

    /// <summary>
    /// Register a new user account
    /// </summary>
    /// <param name="request">Registration details</param>
    /// <returns>Registered user info on success</returns>
    /// <response code="201">Registration successful</response>
    /// <response code="400">Invalid request payload or validation error</response>
    /// <response code="409">Email already exists</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("signup")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(SignupResponseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Signup([FromBody] SignupRequestDto request)
    {
        try
        {
            // Model validation is handled by [ApiController] attribute
            // Invalid payloads will return 400 automatically

            var result = await _authService.RegisterAsync(request);

            if (!result.Success)
            {
                return StatusCode(result.StatusCode, new ErrorResponse
                {
                    Error = result.ErrorMessage ?? "Registration failed"
                });
            }

            return StatusCode(201, result.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error during signup for {Email}", request.Email);
            return StatusCode(500, new ErrorResponse
            {
                Error = "An unexpected error occurred. Please try again later."
            });
        }
    }
}

/// <summary>
/// Standard error response format
/// </summary>
public class ErrorResponse
{
    public string Error { get; set; } = string.Empty;
}
