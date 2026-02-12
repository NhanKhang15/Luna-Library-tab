namespace Backend.DTOs;

/// <summary>
/// Response DTO for successful login
/// </summary>
public class LoginResponseDto
{
    /// <summary>
    /// JWT access token
    /// </summary>
    public string AccessToken { get; set; } = string.Empty;

    /// <summary>
    /// Token expiration time in seconds
    /// </summary>
    public int ExpiresIn { get; set; }

    /// <summary>
    /// Refresh token for token renewal (placeholder for future implementation)
    /// </summary>
    public string? RefreshToken { get; set; }

    /// <summary>
    /// Authenticated user information
    /// </summary>
    public UserDto User { get; set; } = null!;
}
