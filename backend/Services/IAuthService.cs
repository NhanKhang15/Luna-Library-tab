using Backend.DTOs;

namespace Backend.Services;

/// <summary>
/// Authentication result containing login outcome
/// </summary>
public class AuthResult
{
    public bool Success { get; set; }
    public LoginResponseDto? Data { get; set; }
    public int StatusCode { get; set; }
    public string? ErrorMessage { get; set; }

    public static AuthResult Ok(LoginResponseDto data) => new()
    {
        Success = true,
        Data = data,
        StatusCode = 200
    };

    public static AuthResult Unauthorized(string message = "Invalid credentials") => new()
    {
        Success = false,
        StatusCode = 401,
        ErrorMessage = message
    };

    public static AuthResult Forbidden(string message = "Account is disabled") => new()
    {
        Success = false,
        StatusCode = 403,
        ErrorMessage = message
    };
}

/// <summary>
/// Registration result containing signup outcome
/// </summary>
public class RegisterResult
{
    public bool Success { get; set; }
    public SignupResponseDto? Data { get; set; }
    public int StatusCode { get; set; }
    public string? ErrorMessage { get; set; }

    public static RegisterResult Ok(SignupResponseDto data) => new()
    {
        Success = true,
        Data = data,
        StatusCode = 201
    };

    public static RegisterResult Conflict(string message = "Email already exists") => new()
    {
        Success = false,
        StatusCode = 409,
        ErrorMessage = message
    };

    public static RegisterResult BadRequest(string message) => new()
    {
        Success = false,
        StatusCode = 400,
        ErrorMessage = message
    };
}

/// <summary>
/// Interface for authentication service
/// </summary>
public interface IAuthService
{
    /// <summary>
    /// Authenticates a user with email/username and password
    /// </summary>
    Task<AuthResult> LoginAsync(LoginRequestDto request);

    /// <summary>
    /// Registers a new user account
    /// </summary>
    Task<RegisterResult> RegisterAsync(SignupRequestDto request);
}
