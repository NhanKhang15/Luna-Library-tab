using Backend.Entities;

namespace Backend.Services;

/// <summary>
/// Interface for JWT token generation service
/// </summary>
public interface IJwtTokenService
{
    /// <summary>
    /// Generates a JWT access token for the given user
    /// </summary>
    /// <param name="user">User entity to generate token for</param>
    /// <returns>JWT token string and expiration time in seconds</returns>
    (string Token, int ExpiresIn) GenerateAccessToken(User user);

    /// <summary>
    /// Generates a refresh token for the given user (placeholder for future implementation)
    /// </summary>
    /// <param name="user">User entity</param>
    /// <returns>Refresh token string or null if not implemented</returns>
    string? GenerateRefreshToken(User user);
}
